# PURPOSE: Andockpunkt für Minispiele einer einbettenden App (latte-app: dame) und einmalige Wurf-Boni (Item-Feld "once").
# ARCHITECTURE: test
# DEPENDENCIES: MinigameContract, EventApplier, GameState, ContentLoader
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

var started: Array = []
## Läuft der Test in einer Gastgeber-App (latte-app), ist dort schon ein Starter angedockt: beiseitelegen und zurückgeben.
var _host_games := {}


func before_each() -> void:
	_host_games = MinigameContract.external_games.duplicate()
	MinigameContract.external_games.clear()


func after_each() -> void:
	MinigameContract.external_games.clear()
	MinigameContract.external_games.merge(_host_games)
	started.clear()


func test_unknown_without_host() -> void:
	assert_false(EventApplier.is_valid({"type": "start_minigame", "game": "dame"}))
	assert_null(MinigameContract.fallback_trigger({"minigame": {"game": "dame"}}, true, null), "einzeln startet nichts")


func test_known_and_started_with_host() -> void:
	MinigameContract.register_external("dame", func(params: Dictionary) -> void: started.append(params))
	assert_true(EventApplier.is_valid({"type": "start_minigame", "game": "dame"}))
	var main: Node = load("res://addons/lobby_loop/scenes/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(1)
	GameState.start_minigame("dame", {})
	assert_eq(started.size(), 1)
	assert_eq(started[0].get("scene"), GameState.current_scene, "Gastgeber erfährt die Szene")


func test_once_bonus_is_consumed_after_one_roll() -> void:
	var defs: Array = ContentLoader.load_items()["items"]
	var before: Array = GameState.inventory.duplicate()
	GameState.add_item("eingeforderter_gefallen")
	var bonuses := GameState.get_roll_bonuses(defs)
	assert_true(bonuses.any(func(b: Dictionary) -> bool: return b["source"] == "eingeforderter_gefallen" and b["value"] == 2))
	GameState.record_roll(DiceCore.roll(10, bonuses))
	assert_false(GameState.inventory.has("eingeforderter_gefallen"), "nach einem Wurf verbraucht")
	GameState.inventory = before


func test_permanent_bonus_stays() -> void:
	var defs: Array = ContentLoader.load_items()["items"]
	var before: Array = GameState.inventory.duplicate()
	GameState.add_item("schmiergeld")
	GameState.record_roll(DiceCore.roll(10, GameState.get_roll_bonuses(defs)))
	assert_true(GameState.inventory.has("schmiergeld"))
	GameState.inventory = before
