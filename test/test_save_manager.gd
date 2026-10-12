# PURPOSE: App-SaveManager: Lobby-Loop-Schnittstelle über JsonStore, kaputter Stand wird gesichert, Perma-Death schreibt frischen Stand.
# ARCHITECTURE: test
# DEPENDENCIES: app/save_manager.gd, SaveData
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const TEST_PATH := "user://test_latte_savegame.json"

var sm: Node


func before_each() -> void:
	sm = load("res://app/save_manager.gd").new()
	sm.path = TEST_PATH
	add_child_autofree(sm)
	for p in [TEST_PATH, TEST_PATH + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func test_autoload_is_the_app_version() -> void:
	assert_eq(get_node("/root/SaveManager").get_script().resource_path, "res://app/save_manager.gd")


func test_missing_save_is_empty() -> void:
	assert_false(sm.has_save())
	assert_eq(sm.load_game(), {})


func test_corrupt_save_is_backed_up_not_lost() -> void:
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("{kaputt")
	f.close()
	assert_eq(sm.load_game(), {})
	assert_true(FileAccess.file_exists(TEST_PATH + ".bak"))


func test_perma_death_writes_fresh_state_and_signals() -> void:
	watch_signals(sm)
	var fresh: Dictionary = sm.perma_death()
	assert_eq(fresh, SaveData.fresh_state())
	assert_eq(sm.load_game()["current_scene"], "kommunalpolitik")
	assert_signal_emitted(sm, "perma_death_restarted")
