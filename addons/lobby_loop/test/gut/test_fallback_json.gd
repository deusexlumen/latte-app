# PURPOSE: FallbackDb ohne SQLite (Web-Export): dieselben Knoten, Runden und Kombinationen direkt aus content/*.json.
# ARCHITECTURE: test
# DEPENDENCIES: scripts/autoload/FallbackDb.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const FallbackDbScript := preload("res://addons/lobby_loop/scripts/autoload/FallbackDb.gd")

var db: Node


func before_each() -> void:
	db = FallbackDbScript.new()
	db._load_json_source()


func after_each() -> void:
	db.free()


func test_json_source_is_available() -> void:
	assert_true(db.available)
	assert_eq(db.source, "json")


func test_node_fallback_matches_content() -> void:
	var scene: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://addons/lobby_loop/content/scenes/fraktionssitzung.json"))
	var node: Dictionary = scene["nodes"][0]
	var r: Dictionary = db.get_action_fallback("fraktionssitzung", str(node["id"]))
	assert_eq(r["gm_dialogue"], str(node["fallback_dialogue"]))
	assert_eq(r["difficulty_class"], StatRules.clamp_dc(int(node["default_dc"])))
	assert_null(r["trigger_event"])


func test_unknown_node_is_generic_not_error() -> void:
	assert_string_contains(db.get_action_fallback("gibtsnicht", "x")["gm_dialogue"], "Aktenkoffer")


func test_minigame_rounds_and_combinations() -> void:
	var r: Dictionary = db.get_minigame_round()
	assert_eq((r["phrases"] as Array).size(), 3)
	assert_between(int(r["correct_index"]), 0, 2)
	assert_gt(db.get_combinations().size(), 0)
