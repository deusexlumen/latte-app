# PURPOSE: Flur des Amts (M6), Hörsaal und Akte (M7): Türen führen zu ladbaren Szenen, Hörsaal spielt ohne Karriere-Effekte, Akte hat drei Abschnitte.
# ARCHITECTURE: test
# DEPENDENCIES: flur/flur.gd, hoersaal/hoersaal.gd, LatteAkte, HoersaalStats
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const FlurScript := preload("res://flur/flur.gd")
const STATS := "user://test_hoersaal.json"


func before_each() -> void:
	if FileAccess.file_exists(STATS):
		DirAccess.remove_absolute(STATS)


func test_main_scene_is_flur() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://flur/flur.tscn")


func test_every_door_points_to_a_loadable_scene() -> void:
	var paths := [FlurScript.AKTE, FlurScript.EINSTELLUNGEN]
	for door in FlurScript.DOORS:
		paths.append(door[2])
	assert_eq(FlurScript.DOORS.size(), 3, "drei Türen: Karriere, Hörsaal, Hinterzimmer")
	for path in paths:
		assert_true(ResourceLoader.exists(path), path)
		assert_not_null(load(path), path)


func test_flur_builds_door_buttons() -> void:
	var flur: Control = load("res://flur/flur.tscn").instantiate()
	add_child_autofree(flur)
	var texts := []
	for b in flur.find_children("*", "Button", true, false):
		texts.append((b as Button).text)
	for t in ["Karriere", "Hörsaal", "Hinterzimmer", "Akte", "Einstellungen"]:
		assert_has(texts, t)


func test_hoersaal_lists_lehren_and_plays_without_career_effects() -> void:
	var h: Control = load("res://hoersaal/hoersaal.tscn").instantiate()
	h.library_dir = "user://test_hoersaal_leer/"
	h.stats_path = STATS
	add_child_autofree(h)
	var ids := []
	for L in h.lehren():
		ids.append(L["id"])
	assert_has(ids, "amt")
	var discipline_before: int = GameState.fraktionsdisziplin
	var inventory_before: Array = GameState.inventory.duplicate()
	h.start("amt")
	var p: PanelContainer = h.panel()
	var guard := 0
	while p.is_playing() and guard < 60:
		p.play_card(p.hand_ids()[0])
		guard += 1
	p.close()
	assert_eq(HoersaalStats.load_stats(STATS)["played"], 1)
	assert_eq(GameState.fraktionsdisziplin, discipline_before, "Hörsaal ändert keine Karriere")
	assert_eq(GameState.inventory, inventory_before)


func test_akte_has_one_section_per_game() -> void:
	var sections := LatteAkte.build(
		{"current_scene": "fraktionssitzung", "fraktionsdisziplin": 3, "alignment_score": -2, "rolls": [{}, {}], "minigames": [{}]},
		{"played": 4, "collapsed": 3, "best_score": 120},
		{"games_played": 5, "games_won": 2, "dame_calls": 7, "successful_dame_calls": 4, "total_penalty_cards": 9})
	assert_eq(sections.map(func(s: Dictionary) -> String: return s["titel"]), ["Karriere", "Hörsaal", "Hinterzimmer"])
	assert_has(sections[0]["zeilen"], "Würfe: 2")
	assert_has(sections[1]["zeilen"], "Eingestürzte Lehren: 3")
	assert_has(sections[2]["zeilen"], "Partien: 5, davon gewonnen: 2")


func test_akte_empty_sections_say_so() -> void:
	var sections := LatteAkte.build({}, {}, {})
	assert_eq(sections[1]["zeilen"], ["Noch keine Vorlesung besucht."])
	assert_eq(sections[2]["zeilen"], ["Noch keine Partie im Hinterzimmer."])
