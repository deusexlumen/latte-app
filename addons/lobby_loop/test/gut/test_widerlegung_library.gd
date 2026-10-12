# PURPOSE: Phase 2: Bibliothek erfundener Lehren (Ablage, kaputter Index, Sperrliste), Auswahl im Vertrag, Einspruch in den Regeln, Forge mit genau einer Nachbesserung.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungLibrary, WiderlegungRules, WiderlegungForge, WiderlegungValidator, MinigameContract
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const DIR := "user://test_bibliothek/"

## Test-Double für ApiClient: liefert die vorbereiteten Antworten der Reihe nach und merkt sich die Anfragen.
class FakeApi:
	extends Node

	var answers: Array = []
	var requests: Array = []

	func lehre_generate(payload: Dictionary) -> Variant:
		requests.append(payload.duplicate(true))
		await get_tree().process_frame
		return answers.pop_front() if not answers.is_empty() else null


func before_each() -> void:
	_clear()
	WiderlegungForge.busy = false


func after_all() -> void:
	_clear()


func _clear() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for f in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(f))
		DirAccess.remove_absolute(DIR)


func _raw(id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://addons/lobby_loop/content/widerlegung/%s.json" % id))


## Grundbestand-Lehre "amt" als erfundene Lehre verkleidet (22 Karten, damit die Formprüfung greift).
func _bib_amt() -> Dictionary:
	var L := _raw("amt")
	L["id"] = "bib_amt_test"
	L.erase("cap")
	var keep := []
	for c in L["cards"]:
		if keep.size() < 22 and not (c["id"] in ["kuh", "mauer"]):
			keep.append(c)
	L["cards"] = keep
	return L


func _passed() -> Dictionary:
	return {"ok": true, "cap": 9, "messung": {"gelegenheit": 0.7}, "paare": 6}


func test_save_and_list() -> void:
	assert_true(WiderlegungLibrary.save(_bib_amt(), _passed(), DIR))
	assert_eq(WiderlegungLibrary.ids(DIR), ["bib_amt_test"])
	var saved: Dictionary = WiderlegungLibrary.load_lehren(DIR)[0]
	assert_eq(int(saved["cap"]), 9)
	assert_false(saved.has("card_map"))


func test_save_refuses_failed_or_foreign() -> void:
	assert_false(WiderlegungLibrary.save(_bib_amt(), {"ok": false}, DIR))
	assert_false(WiderlegungLibrary.save(_raw("amt"), _passed(), DIR))
	assert_eq(WiderlegungLibrary.ids(DIR), [])


func test_corrupt_index_is_rebuilt() -> void:
	WiderlegungLibrary.save(_bib_amt(), _passed(), DIR)
	var f := FileAccess.open(DIR.path_join(WiderlegungLibrary.INDEX_FILE), FileAccess.WRITE)
	f.store_string("{kaputt")
	f.close()
	assert_eq(WiderlegungLibrary.ids(DIR), ["bib_amt_test"])


func test_missing_dir_is_empty_not_error() -> void:
	assert_eq(WiderlegungLibrary.list("user://gibt_es_nicht/"), [])
	assert_eq(WiderlegungLibrary.load_lehren("user://gibt_es_nicht/"), [])


func test_corrupt_lehre_file_is_skipped_by_load_data() -> void:
	WiderlegungLibrary.save(_bib_amt(), _passed(), DIR)
	var f := FileAccess.open(DIR.path_join("bib_amt_test.json"), FileAccess.WRITE)
	f.store_string("[]")
	f.close()
	var data := WiderlegungRules.load_data(DIR)
	assert_false(data.has("error"))
	assert_eq((data["instanzen"] as Array).size(), 5)


func test_load_data_adds_library_after_base() -> void:
	WiderlegungLibrary.save(_bib_amt(), _passed(), DIR)
	var data := WiderlegungRules.load_data(DIR)
	assert_eq((data["instanzen"] as Array).size(), 6)
	assert_eq(WiderlegungRules.index_of(data, "amt"), 1)
	assert_eq(WiderlegungRules.index_of(data, "bib_amt_test"), 5)


func test_without_library_dir_nothing_changes() -> void:
	WiderlegungLibrary.save(_bib_amt(), _passed(), DIR)
	assert_eq((WiderlegungRules.load_data()["instanzen"] as Array).size(), 5)


func test_sperrliste_applies_to_base_and_keeps_refs() -> void:
	var amt := _raw("amt")
	assert_false(WiderlegungLibrary.block_card(amt, "sofa", DIR), "Referenzmitglied ist nicht sperrbar")
	assert_true(WiderlegungLibrary.block_card(amt, "kuh", DIR))
	var data := WiderlegungRules.load_data(DIR)
	var L: Dictionary = data["instanzen"][WiderlegungRules.index_of(data, "amt")]
	assert_false((L["card_map"] as Dictionary).has("kuh"))
	assert_true((L["card_map"] as Dictionary).has("sofa"))


func test_apply_sperrliste_never_below_minimum() -> void:
	var amt := _raw("amt")
	var all := []
	for c in amt["cards"]:
		all.append(c["id"])
	assert_eq((WiderlegungLibrary.apply_sperrliste(amt, all)["cards"] as Array).size(), (amt["cards"] as Array).size())


func test_withdraw_card_refills_without_randomness() -> void:
	var data := WiderlegungRules.load_data()
	var run := WiderlegungRules.new_run("LL-WITHDRAW")
	run["idx"] = WiderlegungRules.index_of(data, "amt")
	WiderlegungRules.start_instanz(data, run)
	var st: Dictionary = run["inst"]
	var first: String = st["hand"][0]
	var next_in_deck: String = st["deck"][0]
	var rs_before: Variant = st.get("rs")
	assert_true(WiderlegungRules.withdraw_card(run, first))
	assert_false((st["hand"] as Array).has(first))
	assert_true((st["hand"] as Array).has(next_in_deck))
	assert_eq(st.get("rs"), rs_before)
	assert_false(WiderlegungRules.withdraw_card(run, "gibtsnicht"))


func test_params_bibliothek() -> void:
	var lib := ["bib_a", "bib_b"]
	var p := MinigameContract.widerlegung_params({"lehre": "bibliothek"}, "fraktionssitzung", "LL-1", lib)
	assert_true(lib.has(p["lehre"]))
	# Ohne Bibliothek fällt "bibliothek" auf den Szenen-Standard zurück.
	assert_eq(MinigameContract.widerlegung_params({"lehre": "bibliothek"}, "fraktionssitzung", "LL-1")["lehre"], "spiel")


func test_params_library_reachable_offline_about_half_the_time() -> void:
	var from_lib := 0
	for i in 200:
		var p := MinigameContract.widerlegung_params({"lehre": "amt"}, "untersuchungsausschuss", "LL-%d" % i, ["bib_x"])
		from_lib += 1 if p["lehre"] == "bib_x" else 0
	assert_between(from_lib, 70, 130)


func test_forge_saves_passing_lehre_first_try() -> void:
	var api := FakeApi.new()
	add_child_autofree(api)
	api.answers = [_bib_amt()]
	var r: Dictionary = await WiderlegungForge.forge(api, "Sitzen", DIR)
	assert_true(r["ok"], str(r["befunde"]))
	assert_eq(r["versuche"], 1)
	assert_eq(api.requests[0], {"thema": "Sitzen"})
	assert_eq(WiderlegungLibrary.ids(DIR), ["bib_amt_test"])


func test_forge_improves_exactly_once() -> void:
	var api := FakeApi.new()
	add_child_autofree(api)
	var bad := _bib_amt()
	bad["cards"] = (bad["cards"] as Array).slice(0, 10)
	api.answers = [bad, bad.duplicate(true), _bib_amt()]
	var r: Dictionary = await WiderlegungForge.forge(api, "", DIR)
	assert_false(r["ok"])
	assert_eq(api.requests.size(), 2, "genau eine Nachbesserung, dann Schluss")
	assert_true(api.requests[1].has("nachbesserung"))
	assert_true((api.requests[1]["nachbesserung"]["befunde"] as Array).size() > 0)
	assert_eq(WiderlegungLibrary.ids(DIR), [])


func test_forge_offline_is_quiet() -> void:
	var api := FakeApi.new()
	add_child_autofree(api)
	var r: Dictionary = await WiderlegungForge.forge(api, "", DIR)
	assert_false(r["ok"])
	assert_eq(r["versuche"], 1)
	assert_false(WiderlegungForge.busy)


func test_repair_refs_replaces_only_wrong_anchor() -> void:
	var L := _raw("amt")
	L["refNon"] = ["tisch", "kuechenstuhl"]  # kuechenstuhl ist in Wahrheit ein Mitglied
	assert_string_starts_with(WiderlegungRules.prepare(L), "Referenz")
	assert_true(WiderlegungValidator.repair_refs(L))
	assert_eq(L["refMembers"], ["kuechenstuhl", "sofa"])
	assert_eq((L["refNon"] as Array)[0], "tisch", "gültiger Anker bleibt")
	assert_eq((L["refNon"] as Array).size(), 2)
	assert_eq(WiderlegungRules.prepare(L), "")


func test_library_keeps_anchors_from_pruefung() -> void:
	var L := _bib_amt()
	L["refNon"] = ["kuechenstuhl"]
	var p := _passed()
	p["refMembers"] = ["kuechenstuhl", "sofa"]
	p["refNon"] = ["tisch", "aktenschrank"]
	assert_true(WiderlegungLibrary.save(L, p, DIR))
	var data := WiderlegungRules.load_data(DIR)
	assert_gte(WiderlegungRules.index_of(data, "bib_amt_test"), 0, "gespeicherte Lehre lädt mit den Ankern der Prüfung")
