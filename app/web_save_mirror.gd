# PURPOSE: Schützt Spielstände im Browser vor dem schnellen Schließen des Tabs. Godot schreibt user:// dort asynchron
# PURPOSE: in IndexedDB; wer kurz nach einer Handlung schließt, verlor sie. Beim Verbergen oder Schließen der Seite
# PURPOSE: werden die Spielstände zusätzlich synchron in localStorage gesichert und beim nächsten Start zurückgespielt.
# ARCHITECTURE: autoload
# DEPENDENCIES: JavaScriptBridge (nur im Browser)
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
extends Node

const PREFIX := "latte:file:"
const INDEX_KEY := "latte:files"
const AT_KEY := "latte:flushed_at"
## Nur Spielstände, keine Logs oder Caches.
const EXTENSIONS := ["json", "cfg", "dat"]
const SKIP_DIRS := ["logs", "shader_cache", "vulkan"]
## localStorage fasst je Origin etwa 5 MB, Base64 kostet ein Drittel mehr.
const MAX_FILE_BYTES := 512 * 1024
const MAX_TOTAL_BYTES := 2 * 1024 * 1024

var _storage = null
# Die JS-Rückrufe müssen am Leben bleiben, solange die Seite läuft.
var _callbacks: Array = []


func _ready() -> void:
	# Läuft als erster Autoload, damit alle anderen schon die zurückgespielten Dateien lesen.
	if not OS.has_feature("web"):
		return
	_storage = LocalStorage.new()
	if not _storage.ok():
		return
	restore("user://", _storage)
	var flush_cb := JavaScriptBridge.create_callback(_on_page_hidden)
	_callbacks.append(flush_cb)
	var window := JavaScriptBridge.get_interface("window")
	var document := JavaScriptBridge.get_interface("document")
	window.addEventListener("pagehide", flush_cb)
	document.addEventListener("visibilitychange", flush_cb)


func _on_page_hidden(_args: Array) -> void:
	flush("user://", _storage)


## Sichert alle Spielstände unter `root` in `storage` (Schlüssel-Wert-Speicher mit get_item/set_item/remove_item).
## Liefert die gesicherten Pfade relativ zu `root`.
static func flush(root: String, storage) -> Array:
	var files := collect(root)
	var old_index := _read_index(storage)
	# Der Index nennt alle vorhandenen Dateien, auch die über der Gesamtgrenze ohne Inhalt,
	# damit restore() sie nicht für gelöscht hält.
	var stored: Array = []
	var total := 0
	for rel in files:
		var raw: PackedByteArray = files[rel]
		if total + raw.size() > MAX_TOTAL_BYTES:
			continue
		total += raw.size()
		storage.set_item(PREFIX + rel, Marshalls.raw_to_base64(raw))
		stored.append(rel)
	for rel in old_index:
		if not stored.has(rel):
			storage.remove_item(PREFIX + rel)
	storage.set_item(INDEX_KEY, JSON.stringify(files.keys()))
	storage.set_item(AT_KEY, str(Time.get_unix_time_from_system()))
	return stored


## Spielt die letzte Sicherung zurück. Die Sicherung gilt für alles, was vor ihr geschrieben wurde: Dateien, die
## fehlen oder nicht neuer als die Sicherung sind, bekommen ihren Stand von dort; was die Sicherung nicht mehr
## kennt und älter ist, war beim Sichern schon gelöscht. Neuere Dateien (Absturz ohne Sicherung) bleiben.
## Liefert die geänderten Pfade relativ zu `root`.
static func restore(root: String, storage) -> Array:
	var at_raw = storage.get_item(AT_KEY)
	if at_raw == null:
		return []
	var flushed_at := float(str(at_raw))
	var index := _read_index(storage)
	var changed: Array = []
	for rel in index:
		var encoded = storage.get_item(PREFIX + rel)
		if encoded == null:
			continue
		var path := root.path_join(rel)
		var raw := Marshalls.base64_to_raw(str(encoded))
		if FileAccess.file_exists(path):
			if FileAccess.get_modified_time(path) > flushed_at:
				continue
			if FileAccess.get_file_as_bytes(path) == raw:
				continue
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_buffer(raw)
			f.close()
			changed.append(rel)
	for rel in collect(root):
		var path := root.path_join(rel)
		if not index.has(rel) and FileAccess.get_modified_time(path) <= flushed_at:
			DirAccess.remove_absolute(path)
			changed.append(rel)
	return changed


## Alle Spielstand-Dateien unter `root`, Pfad relativ zu `root` -> Inhalt.
static func collect(root: String, sub: String = "") -> Dictionary:
	var out := {}
	var dir := DirAccess.open(root.path_join(sub))
	if dir == null:
		return out
	for name in dir.get_files():
		var rel := sub.path_join(name) if not sub.is_empty() else name
		if not EXTENSIONS.has(name.get_extension().to_lower()):
			continue
		var raw := FileAccess.get_file_as_bytes(root.path_join(rel))
		if raw.size() <= MAX_FILE_BYTES:
			out[rel] = raw
	for name in dir.get_directories():
		if sub.is_empty() and SKIP_DIRS.has(name):
			continue
		out.merge(collect(root, sub.path_join(name) if not sub.is_empty() else name))
	return out


static func _read_index(storage) -> Array:
	var raw = storage.get_item(INDEX_KEY)
	if raw == null:
		return []
	var parsed = JSON.parse_string(str(raw))
	return parsed if parsed is Array else []


## localStorage des Browsers. getItem liefert null für fehlende Schlüssel.
class LocalStorage:
	var _ls = null

	func _init() -> void:
		_ls = JavaScriptBridge.get_interface("localStorage")

	func ok() -> bool:
		return _ls != null

	func get_item(key: String):
		return _ls.getItem(key)

	func set_item(key: String, value: String) -> void:
		_ls.setItem(key, value)

	func remove_item(key: String) -> void:
		_ls.removeItem(key)
