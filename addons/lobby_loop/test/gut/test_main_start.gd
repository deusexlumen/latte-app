# PURPOSE: Hauptszene startet ohne Perma-Death-Schirm (Regression: "Mandat verloren" beim ersten Start).
# ARCHITECTURE: test
# DEPENDENCIES: scenes/main.tscn
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest


func test_perma_screen_hidden_on_start() -> void:
	var main: Node = load("res://addons/lobby_loop/scenes/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(1)
	var screen := main.find_child("PermaDeathScreen", true, false) as Control
	assert_not_null(screen)
	assert_false(screen.visible)


## Regression aus latte-app: main.tscn ein zweites Mal laden darf Autoload-Signale nicht doppelt verbinden.
func test_main_can_be_loaded_twice() -> void:
	for i in 2:
		var main: Node = load("res://addons/lobby_loop/scenes/main.tscn").instantiate()
		add_child(main)
		await wait_process_frames(1)
		main.free()
	var hits := 0
	for c in DiceRoller.roll_performed.get_connections():
		if c["callable"] == Callable(GameState, "record_roll"):
			hits += 1
	assert_eq(hits, 1)


## Regression aus latte-app: Perma-Death während einer Hinterzimmer-Partie (Karriere-Szene nicht geladen)
## zeigt den Schirm, sobald die Karriere-Szene wieder lädt, und nur einmal.
func test_pending_perma_death_shows_screen_on_load() -> void:
	GameState.perma_death_pending = true
	var main: Node = load("res://addons/lobby_loop/scenes/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(1)
	var screen := main.find_child("PermaDeathScreen", true, false) as Control
	assert_true(screen.visible)
	assert_false(GameState.perma_death_pending)
	var again: Node = load("res://addons/lobby_loop/scenes/main.tscn").instantiate()
	add_child_autofree(again)
	await wait_process_frames(1)
	assert_false((again.find_child("PermaDeathScreen", true, false) as Control).visible)
