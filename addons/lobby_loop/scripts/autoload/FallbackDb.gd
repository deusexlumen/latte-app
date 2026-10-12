# PURPOSE: Offline-Fallback ueber godot-sqlite (nodes, minigame_rounds), ohne SQLite (Web-Export) direkt aus content/*.json; liefert Proxy-kompatible Dictionaries.
# ARCHITECTURE: autoload
# DEPENDENCIES: godot-sqlite (GDExtension, Klasse SQLite), StatRules, MinigameShuffle
# PIPELINE: runtime
# LAST_VALIDATED: 2026-09-17
extends Node

const DB_PATH := "res://addons/lobby_loop/data/fallback.sqlite"

var db: Object = null
var available := false

const SCENES_DIR := "res://addons/lobby_loop/content/scenes/"
const MINIGAME_JSON := "res://addons/lobby_loop/content/fallback/minigame.json"
const ITEMS_JSON := "res://addons/lobby_loop/content/items.json"

## "sqlite", "json" oder "" (nichts verfuegbar, generische Antworten).
var source := ""

var _round_robin_index := 0
var _json_nodes: Array = []
var _json_rounds: Array = []
var _json_combinations: Array = []


func _ready() -> void:
	if not FileAccess.file_exists(DB_PATH) or not ClassDB.class_exists("SQLite"):
		# Web-Export ohne GDExtension-Unterstuetzung: dieselben Daten aus der JSON-Quelle (ADR 0002).
		_load_json_source()
		return
	var sqlite: Object = ClassDB.instantiate("SQLite")
	if sqlite == null:
		_load_json_source()
		return
	sqlite.path = DB_PATH
	var open_result: Variant = sqlite.open_db()
	var opened: bool = (typeof(open_result) == TYPE_BOOL and bool(open_result)) or open_result == OK
	if not opened:
		push_warning("FallbackDb: open_db() fehlgeschlagen — Offline-Modus mit generischen Antworten.")
		return
	db = sqlite
	available = true
	source = "sqlite"


## Liest Knoten, Minispiel-Runden und Kombinationen aus content/ in dieselben Zeilen-Formen wie die DB.
func _load_json_source() -> void:
	_json_nodes = []
	for f in DirAccess.get_files_at(SCENES_DIR):
		if not f.ends_with(".json"):
			continue
		var scene: Variant = _read_json(SCENES_DIR + f)
		if not (scene is Dictionary):
			continue
		for node in scene.get("nodes", []):
			if node is Dictionary:
				_json_nodes.append({
					"scene_id": str(scene.get("id", "")),
					"node_id": str(node.get("id", "")),
					"type": str(node.get("type", "")),
					"label": str(node.get("label", "")),
					"default_dc": int(node.get("default_dc", 10)),
					"fallback_dialogue": str(node.get("fallback_dialogue", "")),
				})
	var mg: Variant = _read_json(MINIGAME_JSON)
	_json_rounds = []
	if mg is Dictionary:
		var i := 0
		for r in mg.get("rounds", []):
			_json_rounds.append({"idx": i, "accusation": r.get("accusation", ""), "phrases": r.get("phrases", []), "correct_index": r.get("correct_index", 0)})
			i += 1
	var items: Variant = _read_json(ITEMS_JSON)
	_json_combinations = items.get("combinations", []) if items is Dictionary else []
	available = not _json_nodes.is_empty()
	source = "json" if available else ""
	if not available:
		push_warning("FallbackDb: weder SQLite noch content/*.json verfuegbar — generische Antworten.")


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return parser.data


## Aktion ohne API: fallback_dialogue + default_dc des Knotens aus der nodes-Tabelle,
## sonst generische GM-Antwort. Dictionary-Form exakt wie POST /gm/action.
func get_action_fallback(scene_id: String, node_id: String) -> Dictionary:
	var dialogue := "Der Aktenkoffer schwebt ratlos vorbei. 'Im Offline-Modus bleibe ich geheimnisvoll.'"
	var dc := 10
	if available:
		var rows := _query_nodes(scene_id, node_id)
		if not rows.is_empty():
			var row: Dictionary = rows[0]
			if not str(row.get("fallback_dialogue", "")).is_empty():
				dialogue = str(row["fallback_dialogue"])
			dc = StatRules.clamp_dc(int(row.get("default_dc", dc)))
	return {
		"gm_dialogue": dialogue,
		"required_roll": "W20",
		"difficulty_class": dc,
		"trigger_event": null,
	}


## Minispiel-Runde (scene-agnostisch, Round-Robin ueber minigame_rounds).
## Liefert {"accusation", "phrases", "correct_index"}; phrases ist ein Array.
## Die Phrasen werden pro Abruf deterministisch neu gemischt, damit der
## korrekte Index nicht auswendig gelernt werden kann (Content hat durchgehend Index 2).
func get_minigame_round() -> Dictionary:
	if available:
		var rows := _json_rounds if db == null else _query_all("SELECT idx, accusation, phrases, correct_index FROM minigame_rounds ORDER BY idx")
		if not rows.is_empty():
			var row: Dictionary = rows[_round_robin_index % rows.size()]
			_round_robin_index += 1
			var phrases := _parse_phrases(row.get("phrases", "[]"))
			if phrases.size() >= 2:
				var correct_index := int(row.get("correct_index", 0))
				var seed_material := "%s#%d" % [str(row.get("accusation", "")), _round_robin_index]
				var shuffled: Dictionary = MinigameShuffle.shuffle_round(phrases, correct_index, seed_material)
				return {
					"accusation": str(row.get("accusation", "Unbekannter Vorwurf.")),
					"phrases": shuffled["phrases"],
					"correct_index": int(shuffled["correct_index"]),
				}
	return {
		"accusation": "Herr Zeuge, stimmt es, dass Sie 'nein' gesagt haben?",
		"phrases": [
			"Ich sage grundsaetzlich nur 'vorlaeufig'.",
			"'Nein' ist eine Form von 'noch nicht erklaert'.",
			"Diese Frage ist bereits beantwortet, nur nicht von mir.",
		],
		"correct_index": 2,
	}


## Generischer Ergebnis-Kommentar, wenn /gm/result offline ist.
func get_result_commentary(success: bool) -> Dictionary:
	var text := "Der Aktenkoffer klappert zufrieden. Erfolg — die Aktenlage verbessert sich spuerbar."
	if not success:
		text = "Der Aktenkoffer seufzt. Misserfolg — irgendwo im Protokoll wird das nachhallen."
	return {"gm_dialogue": text, "trigger_event": null}


## Kombinations-Matrix aus der DB (Fallback, wenn items.json fehlt).
func get_combinations() -> Array:
	if not available:
		return []
	if db == null:
		return _json_combinations
	return _query_all("SELECT a, b, result, flavor FROM item_combinations")


func _query_nodes(scene_id: String, node_id: String) -> Array:
	if db == null:
		return _json_nodes.filter(func(n: Dictionary) -> bool: return n["scene_id"] == scene_id and n["node_id"] == node_id)
	return _query_all(
		"SELECT scene_id, node_id, type, label, default_dc, fallback_dialogue FROM nodes WHERE scene_id = ? AND node_id = ?",
		[scene_id, node_id]
	)


func _query_all(sql: String, bindings: Array = []) -> Array:
	if db == null:
		return []
	var ok: Variant
	if bindings.is_empty():
		ok = db.query(sql)
	else:
		ok = db.query_with_bindings(sql, bindings)
	if not (typeof(ok) == TYPE_BOOL and ok):
		return []
	var result: Variant = db.query_result
	if not (result is Array):
		return []
	return result


func _parse_phrases(raw: Variant) -> Array:
	var phrases: Array = []
	var parsed: Variant = raw
	if raw is String:
		var parser := JSON.new()
		if parser.parse(raw) == OK:
			parsed = parser.data
	if parsed is Array:
		for entry in parsed:
			phrases.append(str(entry))
	return phrases
