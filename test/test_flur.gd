# PURPOSE: Flur des Amts: Startszene lädt, jede Tür führt zu einer ladbaren Szene.
# ARCHITECTURE: test
# DEPENDENCIES: flur/flur.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const FlurScript := preload("res://flur/flur.gd")


func test_doors_point_to_loadable_scenes() -> void:
	for path in [FlurScript.KARRIERE, FlurScript.HINTERZIMMER]:
		assert_true(ResourceLoader.exists(path), path)
		assert_not_null(load(path), path)


func test_main_scene_is_flur() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://flur/flur.tscn")
