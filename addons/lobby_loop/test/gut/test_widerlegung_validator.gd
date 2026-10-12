# PURPOSE: Validator für erfundene Lehren: Form, Paare, Spielbarkeit, cap-Suche.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungValidator, WiderlegungRules
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

var base: Dictionary = {}


func before_all() -> void:
	base = WiderlegungRules.load_data()


func _raw(id: String) -> Dictionary:
	var f := FileAccess.open("res://addons/lobby_loop/content/widerlegung/%s.json" % id, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func test_report_existing_lehren() -> void:
	var passed := 0
	for id in ["akademie", "amt", "erfurt", "division7b", "spiel"]:
		var r := WiderlegungValidator.validate(base, _raw(id), true)
		passed += 1 if r["ok"] else 0
		gut.p("%s ok=%s cap=%s paare=%s befunde=%s mess=%s" % [id, r["ok"], r["cap"], r["paare"], r["befunde"], r["messung"]])
	# Kalibrierung: die handgebaute Lehre "erfurt" hat nur 2 Paare und fällt durch, die übrigen vier bestehen.
	assert_gte(passed, 4)


func test_form_rejects_missing_note() -> void:
	var L := _raw("amt")
	L["cards"][0].erase("note")
	assert_true(WiderlegungValidator.check_form(L).size() > 0)


func test_form_rejects_too_few_cards() -> void:
	var L := _raw("amt")
	L["cards"] = (L["cards"] as Array).slice(0, 10)
	assert_true(WiderlegungValidator.check_form(L).size() > 0)


func test_pairs_counted() -> void:
	var L := _raw("amt")
	assert_eq(WiderlegungRules.prepare(L), "")
	assert_gte(WiderlegungValidator.count_pairs(L), WiderlegungValidator.MIN_PAIRS)


func test_validate_is_deterministic() -> void:
	assert_eq(WiderlegungValidator.validate(base, _raw("amt")), WiderlegungValidator.validate(base, _raw("amt")))


## Feste Kurve statt Simulation: {cap: [gelegenheit, zufall, ausnahme]}.
func _curve(points: Dictionary) -> Callable:
	return func(cap: int) -> Dictionary:
		var p: Array = points.get(cap, points[points.keys().back()])
		return {"cap": cap, "gelegenheit": p[0], "zufall": p[1], "ausnahme": p[2]}


func test_diagnose_names_the_broken_band() -> void:
	var too_easy := _curve({5: [1.0, 1.0, 1.0], 20: [1.0, 0.6, 1.0]})
	assert_string_starts_with(WiderlegungValidator._diagnose(too_easy, 5, 20, 21), "Zu viele Gegenbeispiele")
	var too_hard := _curve({5: [0.2, 0.0, 0.9], 20: [0.0, 0.0, 0.9]})
	assert_string_starts_with(WiderlegungValidator._diagnose(too_hard, 5, 20), "Zu wenige Gegenbeispiele")
	var no_exceptions := _curve({5: [0.7, 0.2, 0.3], 20: [0.0, 0.0, 0.3]})
	assert_string_starts_with(WiderlegungValidator._diagnose(no_exceptions, 5, 20), "Zu wenige Ausnahmen")
	var pts := {}
	for c in range(5, 21):
		pts[c] = [0.95, 0.9, 1.0] if c < 10 else ([0.94, 0.2, 1.0] if c < 13 else [0.36, 0.02, 1.0])
	var gap := WiderlegungValidator._diagnose(_curve(pts), 5, 20)
	assert_string_starts_with(gap, "Alles oder nichts")
	assert_string_contains(gap, "94 %")


## Erfundene Lehre (Messlauf 6), die bei 7 Würfen in keinem Band landete.
func test_validator_sets_wuerfe_when_seven_does_not_fit() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://addons/lobby_loop/test/fixtures/lehre_parkplatz.json"))
	var r := WiderlegungValidator.validate(base, raw)
	assert_true(r["ok"], str(r["befunde"]))
	assert_ne(int(r["wuerfe"]), 7)
	var dir := "user://test_bib_wuerfe/"
	assert_true(WiderlegungLibrary.save(raw, r, dir))
	var saved: Dictionary = WiderlegungLibrary.load_lehren(dir)[0]
	assert_eq(int(saved["wuerfe"]), int(r["wuerfe"]))
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)


func test_standard_lehren_keep_seven_wuerfe() -> void:
	var r := WiderlegungValidator.validate(base, _raw("amt"), true)
	assert_true(r["ok"])
	assert_eq(int(r["wuerfe"]), 7)


func test_async_with_pump_matches_sync_and_yields() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://addons/lobby_loop/test/fixtures/lehre_parkplatz.json"))
	var steps := [0]
	var longest := [0]
	var last := [Time.get_ticks_msec()]
	var pump := func() -> Signal:
		var now := Time.get_ticks_msec()
		longest[0] = maxi(longest[0], now - last[0])
		steps[0] += 1
		last[0] = now
		return get_tree().process_frame
	var r: Dictionary = await WiderlegungValidator.validate_async(base, raw, false, pump)
	assert_eq(r, WiderlegungValidator.validate(base, raw))
	assert_gt(steps[0], 3)
	gut.p("Häppchen: %d, längstes %d ms" % [steps[0], longest[0]])
