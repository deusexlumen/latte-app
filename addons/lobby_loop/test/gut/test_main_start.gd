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
