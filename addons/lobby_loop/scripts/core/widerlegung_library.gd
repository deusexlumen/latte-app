# PURPOSE: Lokale Bibliothek geprüfter, vom Spielleiter erfundener Lehren plus Sperrliste für Einsprüche; offline spielbar.
# ARCHITECTURE: core
# DEPENDENCIES: WiderlegungRules
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name WiderlegungLibrary
extends RefCounted

const DEFAULT_DIR := "user://widerlegung_bibliothek/"
const INDEX_FILE := "index.json"
const SPERR_FILE := "sperrliste.json"
## Unter dieser Kartenzahl wird nichts mehr gesperrt, sonst ist die Lehre nicht mehr spielbar.
const MIN_CARDS_AFTER_BLOCK := 12


## Index der Bibliothek: [{"id", "begriff", "cap", "saved_at"}]. Ein kaputter oder fehlender
## Index wird aus den Lehren-Dateien neu aufgebaut, nie ein Fehler nach außen.
static func list(dir: String = DEFAULT_DIR) -> Array:
	var raw: Variant = _read_json(dir.path_join(INDEX_FILE))
	if raw is Dictionary and raw.get("lehren") is Array:
		var out := []
		for e in raw["lehren"]:
			if e is Dictionary and FileAccess.file_exists(dir.path_join(str(e.get("id", "")) + ".json")):
				out.append(e)
		return out
	return _rebuild_index(dir)


static func ids(dir: String = DEFAULT_DIR) -> Array:
	var out := []
	for e in list(dir):
		out.append(str(e["id"]))
	return out


## Legt eine geprüfte Lehre ab. `cap` kommt aus der Prüfung (WiderlegungValidator), nie vom Modell.
static func save(lehre: Dictionary, pruefung: Dictionary, dir: String = DEFAULT_DIR) -> bool:
	var id := str(lehre.get("id", ""))
	if not id.begins_with("bib_") or not bool(pruefung.get("ok", false)):
		return false
	DirAccess.make_dir_recursive_absolute(dir)
	var clean := _strip_prepared(lehre)
	clean["cap"] = int(pruefung["cap"])
	clean["wuerfe"] = int(pruefung.get("wuerfe", clean.get("wuerfe", 7)))
	# Wie cap: Hat die Prüfung die Anker neu gewählt, gelten ihre.
	for key in ["refMembers", "refNon"]:
		if pruefung.get(key) is Array:
			clean[key] = pruefung[key]
	clean["pruefung"] = {"messung": pruefung.get("messung", {}), "paare": pruefung.get("paare", 0)}
	if not _write_json(dir.path_join(id + ".json"), clean):
		return false
	var entries := list(dir).filter(func(e: Dictionary) -> bool: return str(e["id"]) != id)
	entries.append({"id": id, "begriff": str(clean.get("begriff", "")), "cap": clean["cap"], "saved_at": Time.get_datetime_string_from_system()})
	return _write_json(dir.path_join(INDEX_FILE), {"lehren": entries})


## Alle Lehren der Bibliothek als Rohdaten (nicht vorbereitet). Kaputte Dateien werden übersprungen.
static func load_lehren(dir: String = DEFAULT_DIR) -> Array:
	var out := []
	for e in list(dir):
		var lehre: Variant = _read_json(dir.path_join(str(e["id"]) + ".json"))
		if lehre is Dictionary:
			out.append(lehre)
	return out


# ---------------------------------------------------------------- Einspruch

## {lehre_id: [card_id, ...]}
static func sperrliste(dir: String = DEFAULT_DIR) -> Dictionary:
	var raw: Variant = _read_json(dir.path_join(SPERR_FILE))
	return raw if raw is Dictionary else {}


## Darf diese Karte gesperrt werden? Referenzfälle tragen die Lehre, und zu wenige Karten machen sie unspielbar.
static func can_block(lehre: Dictionary, card_id: String) -> bool:
	if (lehre.get("refMembers", []) as Array).has(card_id) or (lehre.get("refNon", []) as Array).has(card_id):
		return false
	return (lehre.get("cards", []) as Array).size() > MIN_CARDS_AFTER_BLOCK


## Einspruch: Karte kommt auf die Sperrliste und fehlt dieser Lehre ab dem nächsten Laden.
static func block_card(lehre: Dictionary, card_id: String, dir: String = DEFAULT_DIR) -> bool:
	if not can_block(lehre, card_id):
		return false
	DirAccess.make_dir_recursive_absolute(dir)
	var list_ := sperrliste(dir)
	var lehre_id := str(lehre.get("id", ""))
	var blocked: Array = list_.get(lehre_id, [])
	if not blocked.has(card_id):
		blocked.append(card_id)
	list_[lehre_id] = blocked
	return _write_json(dir.path_join(SPERR_FILE), list_)


## Entfernt gesperrte Karten aus einer Rohlehre (vor prepare()). Referenzfälle bleiben immer.
static func apply_sperrliste(lehre: Dictionary, blocked: Array) -> Dictionary:
	if blocked.is_empty():
		return lehre
	var refs: Array = (lehre.get("refMembers", []) as Array) + (lehre.get("refNon", []) as Array)
	var kept := []
	for c in lehre.get("cards", []):
		if not blocked.has(str(c.get("id", ""))) or refs.has(str(c.get("id", ""))):
			kept.append(c)
	if kept.size() < MIN_CARDS_AFTER_BLOCK:
		return lehre
	var out := lehre.duplicate(true)
	out["cards"] = kept
	return out


# ---------------------------------------------------------------- intern

static func _rebuild_index(dir: String) -> Array:
	var out := []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for f in DirAccess.get_files_at(dir):
		if not f.begins_with("bib_") or not f.ends_with(".json"):
			continue
		var lehre: Variant = _read_json(dir.path_join(f))
		if lehre is Dictionary and lehre.has("cap"):
			out.append({"id": str(lehre.get("id", f.get_basename())), "begriff": str(lehre.get("begriff", "")), "cap": int(lehre["cap"]), "saved_at": ""})
	_write_json(dir.path_join(INDEX_FILE), {"lehren": out})
	return out


## prepare() hängt Laufzeitfelder an (card_map, attr_set, ...). Die gehören nicht in die Datei.
static func _strip_prepared(lehre: Dictionary) -> Dictionary:
	var out := lehre.duplicate(true)
	for key in ["card_map", "prisma_lits", "start_lits"]:
		out.erase(key)
	for c in out.get("cards", []):
		c.erase("attr_set")
		c.erase("member")
	return out


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	# JSON.new().parse statt parse_string: Eine kaputte Datei soll still übersprungen werden, ohne Engine-Fehler im Log.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return json.data


static func _write_json(path: String, value: Variant) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(value, " "))
	return true
