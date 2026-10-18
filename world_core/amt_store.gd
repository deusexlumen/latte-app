# PURPOSE: Speichert und lädt den Weltzustand (Kap. 17): atomar über JsonStore, mit dem vorherigen funktionsfähigen Stand als Rückfall.
# PURPOSE: Unbekannte Fassungen werden gemeldet, nie still verworfen oder überschrieben.
# ARCHITECTURE: core
# DEPENDENCIES: JsonStore (amt_core), AmtWorld
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
class_name AmtStore
extends RefCounted

const PATH := "user://amt_vorgang.json"
## Headless heißt Testlauf: nie in den echten Spielstand schreiben.
const HEADLESS_PATH := "user://test_headless_amt_vorgang.json"
const REQUIRED := {
	"schema_version": TYPE_INT, "content_version": TYPE_STRING, "run_id": TYPE_STRING, "phase": TYPE_STRING,
	"turn": TYPE_INT, "location": TYPE_STRING, "cases": TYPE_DICTIONARY, "actors": TYPE_DICTIONARY,
	"offices": TYPE_DICTIONARY, "objects": TYPE_DICTIONARY, "documents": TYPE_DICTIONARY, "evidence": TYPE_DICTIONARY,
	"knowledge": TYPE_ARRAY, "rules": TYPE_ARRAY, "pending_events": TYPE_DICTIONARY, "sessions": TYPE_DICTIONARY,
	"events": TYPE_ARRAY, "applied_transactions": TYPE_ARRAY, "event_counter": TYPE_INT,
}


static func default_path() -> String:
	return HEADLESS_PATH if DisplayServer.get_name() == "headless" else PATH


static func prev_path(path: String) -> String:
	return path + ".prev"


## Vor dem Schreiben wird der bisherige Stand als .prev aufgehoben (nur wenn er selbst lesbar war).
static func save(state: Dictionary, path: String) -> bool:
	if FileAccess.file_exists(path) and _read(path, str(state["content_version"]))["error"].is_empty():
		JsonStore.write_text(prev_path(path), JsonStore.read_text(path))
	return JsonStore.write_json(path, state)


## Ergebnis {"state", "error", "from_prev"}. Fehlt die Datei: state leer, error leer.
## Ist der Hauptstand unbrauchbar, wird der vorherige versucht; scheitert auch er, bleibt error gesetzt.
static func load_state(path: String, content_version: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"state": {}, "error": "", "from_prev": false}
	var main := _read(path, content_version)
	if main["error"].is_empty():
		return {"state": main["state"], "error": "", "from_prev": false}
	var prev := _read(prev_path(path), content_version)
	if prev["error"].is_empty() and FileAccess.file_exists(prev_path(path)):
		return {"state": prev["state"], "error": main["error"], "from_prev": true}
	return {"state": {}, "error": main["error"], "from_prev": false}


## Einen nicht ladbaren Stand beiseitelegen, bevor neu begonnen wird (keine stillen Datenverluste).
static func archive(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var target := path + ".alt"
	JsonStore.write_text(target, JsonStore.read_text(path))
	JsonStore.remove(path)
	JsonStore.remove(prev_path(path))
	return target


static func _read(path: String, content_version: String) -> Dictionary:
	var text := JsonStore.read_text(path)
	var json := JSON.new()
	if text.is_empty() or json.parse(text) != OK or not (json.data is Dictionary):
		return {"state": {}, "error": "Der Spielstand ist beschädigt."}
	var state: Dictionary = normalize(json.data)
	var reason := validate(state, content_version)
	return {"state": state if reason.is_empty() else {}, "error": reason}


static func validate(state: Dictionary, content_version: String) -> String:
	for key in REQUIRED:
		if not state.has(key) or typeof(state[key]) != REQUIRED[key]:
			return "Der Spielstand ist unvollständig (%s)." % key
	if int(state["schema_version"]) != AmtWorld.SCHEMA_VERSION:
		return "Der Spielstand hat ein unbekanntes Format (%d)." % int(state["schema_version"])
	if str(state["content_version"]) != content_version:
		return "Der Spielstand gehört zu einer anderen Fassung des Vorgangs (%s, erwartet %s)." % [state["content_version"], content_version]
	var causes := AmtWorld.causality_errors(state)
	if not causes.is_empty():
		return "Der Spielstand ist widersprüchlich: %s" % causes[0]
	return ""


## JSON kennt nur Gleitkommazahlen. Ganze Werte zurück in int, damit geladene und laufende Zustände gleich sind.
static func normalize(v: Variant) -> Variant:
	if v is float and is_equal_approx(v, roundf(v)):
		return int(v)
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = normalize(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(normalize(x))
		return a
	return v
