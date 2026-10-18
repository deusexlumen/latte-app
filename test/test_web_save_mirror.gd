# PURPOSE: Browser-Sicherung der Spielstände: sichern, zurückspielen, Löschungen und neuere Dateien respektieren.
# ARCHITECTURE: test
# DEPENDENCIES: app/web_save_mirror.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-10-18
extends GutTest

const Mirror := preload("res://app/web_save_mirror.gd")

var root := ""
var storage: MemoryStorage


## Steht im Test für localStorage.
class MemoryStorage:
	var items := {}

	func get_item(key: String):
		return items.get(key, null)

	func set_item(key: String, value: String) -> void:
		items[key] = value

	func remove_item(key: String) -> void:
		items.erase(key)


func before_each() -> void:
	root = OS.get_user_data_dir().path_join("test_web_mirror")
	_rm(root)
	DirAccess.make_dir_recursive_absolute(root.path_join("widerlegung_bibliothek"))
	DirAccess.make_dir_recursive_absolute(root.path_join("logs"))
	_write("savegame.json", '{"current_scene": "kommunalpolitik"}')
	_write("widerlegung_bibliothek/index.json", '{"lehren": []}')
	_write("logs/godot.json", "{}")
	_write("notiz.txt", "nicht sichern")
	storage = MemoryStorage.new()


func after_all() -> void:
	_rm(OS.get_user_data_dir().path_join("test_web_mirror"))


func test_flush_takes_only_savegames() -> void:
	var stored := Mirror.flush(root, storage)
	stored.sort()
	assert_eq(stored, ["savegame.json", "widerlegung_bibliothek/index.json"])


func test_restore_brings_back_lost_write() -> void:
	_write("savegame.json", '{"current_scene": "fraktionssitzung"}')
	Mirror.flush(root, storage)
	# IndexedDB hat die letzte Handlung nicht mehr geschrieben: alter Stand auf der Platte.
	_write("savegame.json", '{"current_scene": "kommunalpolitik"}')
	_backdate_flush(10)
	var changed := Mirror.restore(root, storage)
	assert_eq(changed, ["savegame.json"])
	assert_eq(_read("savegame.json"), '{"current_scene": "fraktionssitzung"}')


func test_restore_recreates_missing_file() -> void:
	Mirror.flush(root, storage)
	DirAccess.remove_absolute(root.path_join("widerlegung_bibliothek/index.json"))
	Mirror.restore(root, storage)
	assert_eq(_read("widerlegung_bibliothek/index.json"), '{"lehren": []}')


func test_restore_keeps_file_newer_than_flush() -> void:
	Mirror.flush(root, storage)
	_write("savegame.json", '{"current_scene": "bundestag"}')
	# Sicherung liegt vor dem letzten Schreiben (Absturz ohne erneute Sicherung).
	_backdate_flush(-10)
	assert_eq(Mirror.restore(root, storage), [])
	assert_eq(_read("savegame.json"), '{"current_scene": "bundestag"}')


func test_restore_removes_file_deleted_before_flush() -> void:
	DirAccess.remove_absolute(root.path_join("savegame.json"))
	Mirror.flush(root, storage)
	# Löschen hat IndexedDB nicht mehr erreicht: Datei ist wieder da.
	_write("savegame.json", '{"current_scene": "kommunalpolitik"}')
	_backdate_flush(10)
	Mirror.restore(root, storage)
	assert_false(FileAccess.file_exists(root.path_join("savegame.json")))


func test_restore_without_flush_changes_nothing() -> void:
	assert_eq(Mirror.restore(root, storage), [])
	assert_true(FileAccess.file_exists(root.path_join("savegame.json")))


func test_flush_drops_stale_entries() -> void:
	Mirror.flush(root, storage)
	DirAccess.remove_absolute(root.path_join("savegame.json"))
	Mirror.flush(root, storage)
	assert_false(storage.items.has(Mirror.PREFIX + "savegame.json"))


## Verschiebt den Zeitpunkt der Sicherung um `seconds` in die Zukunft (positiv) oder Vergangenheit.
func _backdate_flush(seconds: float) -> void:
	storage.set_item(Mirror.AT_KEY, str(Time.get_unix_time_from_system() + seconds))


func _write(rel: String, text: String) -> void:
	var f := FileAccess.open(root.path_join(rel), FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _read(rel: String) -> String:
	return FileAccess.get_file_as_string(root.path_join(rel))


func _rm(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_rm(dir.path_join(d))
	DirAccess.remove_absolute(dir)
