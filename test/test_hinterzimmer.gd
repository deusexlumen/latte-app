# PURPOSE: Phase 4: DAME als Hinterzimmer. Karriere-Ergebnis nach dem Vertrag, Online-Partien zählen nie, Gefälligkeiten, einmaliger Gefallen.
# ARCHITECTURE: test
# DEPENDENCIES: app/hinterzimmer.gd, GameState, App, MinigameContract
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const HZ := preload("res://app/hinterzimmer.gd")

var hz: Node
var app: Node
var _saved := {}
var _save_path := ""


func before_all() -> void:
	app = get_node("/root/App")
	app.use_test_storage()
	hz = get_node("/root/Hinterzimmer")


func before_each() -> void:
	_saved = {"discipline": GameState.fraktionsdisziplin, "inventory": GameState.inventory.duplicate()}
	GameState.fraktionsdisziplin = 5
	hz.career_match = {}
	hz.return_pending = false
	_save_path = SaveManager.path
	SaveManager.path = "user://test_hinterzimmer_savegame.json"


func after_each() -> void:
	GameState.fraktionsdisziplin = _saved["discipline"]
	GameState.inventory = _saved["inventory"]
	hz.career_match = {}
	hz.return_pending = false
	SaveManager.path = _save_path


func test_dame_is_docked_in_the_contract() -> void:
	assert_true(MinigameContract.is_known("dame"))
	assert_true(EventApplier.is_valid({"type": "start_minigame", "game": "dame"}))


func test_career_result_uses_only_allowed_effects() -> void:
	for won in [true, false]:
		var r := HZ.career_result({"won": won, "score": 12})
		assert_eq(r["game"], "dame")
		assert_eq(MinigameContract.sanitize_effects(r["effects"]).size(), (r["effects"] as Array).size(), "nur add_item/modify_stat")
		assert_string_contains(r["chronik"], "gewonnen" if won else "verloren")


func test_career_win_changes_career_and_returns() -> void:
	hz.career_match = {"scene": "aufsichtsratssitzung"}
	app.match_finished.emit({"won": true, "score": 8, "online": false})
	assert_eq(GameState.fraktionsdisziplin, 6)
	assert_has(GameState.inventory, HZ.REWARD_ITEM)
	assert_true(hz.return_pending)
	assert_true(hz.career_match.is_empty())


func test_online_match_never_counts_for_the_career() -> void:
	hz.career_match = {"scene": "aufsichtsratssitzung"}
	app.match_finished.emit({"won": true, "score": 8, "online": true})
	assert_eq(GameState.fraktionsdisziplin, 5, "Online-Partie ändert die Karriere nicht")
	assert_does_not_have(GameState.inventory, HZ.REWARD_ITEM)
	assert_false(hz.return_pending)


func test_free_match_in_hinterzimmer_does_not_count() -> void:
	app.match_finished.emit({"won": true, "score": 8, "online": false})
	assert_eq(GameState.fraktionsdisziplin, 5)


func test_chips_are_called_gefaelligkeiten() -> void:
	var o := HZ.gefaelligkeiten_overrides()
	assert_eq(o.get("%d Chips"), "%d Gefälligkeiten")
	assert_false(o.values().any(func(v: String) -> bool: return v.contains("Chips")))
	assert_eq(TranslationServer.translate("%d Chips"), "%d Gefälligkeiten")


func test_favor_costs_gefaelligkeiten_and_is_single() -> void:
	GameState.inventory.erase(HZ.FAVOR_ITEM)
	app.profile.award("t-favor-%d" % Time.get_ticks_usec(), 250)
	var before: int = app.profile.chips()
	assert_true(hz.claim_favor())
	assert_eq(app.profile.chips(), before - HZ.FAVOR_PRICE)
	assert_has(GameState.inventory, HZ.FAVOR_ITEM)
	assert_false(hz.claim_favor(), "nur einer gleichzeitig")
