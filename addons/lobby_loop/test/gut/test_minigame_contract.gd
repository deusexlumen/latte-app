# PURPOSE: MinigameContract: Spielauswahl, Parameter, Seed, erlaubte Effekte, Ergebnis, Offline-Start, Reihenfolge Akte vor Effekt.
# ARCHITECTURE: test
# DEPENDENCIES: MinigameContract, EventApplier
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest


class StubState:
	extends RefCounted

	var calls: Array = []

	func record_minigame(result: Dictionary) -> void:
		calls.append(["record_minigame", result.get("chronik", "")])

	func apply_trigger_event(event: Variant) -> bool:
		calls.append(["apply", event.get("type"), event.get("item", event.get("delta"))])
		return true


func test_missing_game_means_beleidigungsfechten() -> void:
	assert_eq(MinigameContract.game_of({"type": "start_minigame"}), "beleidigungsfechten")
	assert_eq(MinigameContract.game_of({"type": "start_minigame", "game": "widerlegung"}), "widerlegung")


func test_params_unknown_lehre_falls_back_to_scene_default() -> void:
	var p := MinigameContract.widerlegung_params({"lehre": "gibtsnicht"}, "fraktionssitzung", "LL-1")
	assert_eq(p, {"lehre": "spiel", "seed": "LL-1"})
	p = MinigameContract.widerlegung_params({}, "kommunalpolitik", "LL-2")
	assert_eq(p["lehre"], "amt")


func test_params_ignore_seed_from_gm() -> void:
	var p := MinigameContract.widerlegung_params({"lehre": "erfurt", "seed": "VOM-MODELL"}, "untersuchungsausschuss", "LL-CLIENT")
	assert_eq(p, {"lehre": "erfurt", "seed": "LL-CLIENT"})


func test_derive_seed_is_stable_and_counts() -> void:
	var a := MinigameContract.derive_seed("save#2026-10-12T10:00:00", "fraktionssitzung", 0)
	assert_eq(a, MinigameContract.derive_seed("save#2026-10-12T10:00:00", "fraktionssitzung", 0))
	assert_ne(a, MinigameContract.derive_seed("save#2026-10-12T10:00:00", "fraktionssitzung", 1))
	assert_true(RegEx.create_from_string("^LL-[0-9A-F]{8}$").search(a) != null, a)


func test_sanitize_effects_keeps_only_items_and_stats() -> void:
	var effects := [
		{"type": "modify_stat", "stat": "discipline", "delta": 1},
		{"type": "add_item", "item": "weggefallener_paragraph"},
		{"type": "change_scene", "scene": "kommunalpolitik"},
		{"type": "start_minigame", "game": "widerlegung"},
		{"type": "remove_item", "item": "schwarzer_koffer"},
		"kaputt",
		null,
	]
	var kept := MinigameContract.sanitize_effects(effects)
	assert_eq(kept.size(), 2)
	assert_eq(kept[0]["type"], "modify_stat")
	assert_eq(kept[1]["type"], "add_item")
	assert_eq(MinigameContract.sanitize_effects("keine liste"), [])


func test_result_collapse_with_two_exceptions() -> void:
	var lehre := {"id": "amt", "begriff": "Sitzgelegenheit"}
	var res := MinigameContract.widerlegung_result(lehre, {"collapsed": true, "at_wurf": 5, "score": 14, "exceptions": 2})
	assert_eq(res["game"], "widerlegung")
	assert_true(res["won"])
	assert_eq(res["score"], 14)
	assert_eq(res["effects"], [
		{"type": "modify_stat", "stat": "discipline", "delta": 1},
		{"type": "add_item", "item": "weggefallener_paragraph"},
		{"type": "add_item", "item": "gerupftes_huhn"},
	])
	assert_eq(res["chronik"], "Definition 'Sitzgelegenheit' bei Wurf 5 eingestürzt, 2 Ausnahmen")


func test_result_hold_costs_discipline() -> void:
	var lehre := {"id": "spiel", "begriff": "Spiel"}
	var res := MinigameContract.widerlegung_result(lehre, {"collapsed": false, "at_wurf": 8, "score": 6, "exceptions": 0})
	assert_false(res["won"])
	assert_eq(res["effects"], [{"type": "modify_stat", "stat": "discipline", "delta": -1}])
	assert_eq(res["chronik"], "Definition 'Spiel' hielt nach 8 Würfen, 0 Ausnahmen")


func test_fallback_trigger_starts_node_minigame_on_success() -> void:
	var node := {"id": "zeugenstuhl", "minigame": {"game": "widerlegung", "params": {"lehre": "amt"}}}
	var t: Variant = MinigameContract.fallback_trigger(node, true, null)
	assert_eq(t, {"type": "start_minigame", "game": "widerlegung", "params": {"lehre": "amt"}})


func test_fallback_trigger_respects_gm_and_failure() -> void:
	var node := {"id": "zeugenstuhl", "minigame": {"game": "widerlegung", "params": {"lehre": "amt"}}}
	var gm_event := {"type": "add_item", "item": "schredder"}
	assert_eq(MinigameContract.fallback_trigger(node, true, gm_event), gm_event, "Spielleiter hat Vorrang")
	assert_null(MinigameContract.fallback_trigger(node, false, null), "Misserfolg startet nichts")
	assert_null(MinigameContract.fallback_trigger({"id": "x"}, true, null), "Knoten ohne Minispiel")
	assert_null(MinigameContract.fallback_trigger({"id": "x", "minigame": {"game": "schach"}}, true, null), "unbekanntes Spiel")


func test_apply_result_records_before_effects_and_filters() -> void:
	var state := StubState.new()
	MinigameContract.apply_result({
		"chronik": "Definition 'Spiel' hielt",
		"effects": [
			{"type": "modify_stat", "stat": "discipline", "delta": -1},
			{"type": "change_scene", "scene": "kommunalpolitik"},
		],
	}, state)
	assert_eq(state.calls, [
		["record_minigame", "Definition 'Spiel' hielt"],
		["apply", "modify_stat", -1],
	])
