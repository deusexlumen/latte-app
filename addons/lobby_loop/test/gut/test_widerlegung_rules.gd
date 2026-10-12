# PURPOSE: Die 13 Regeltests aus huhn/test/engine.test.js, übertragen auf WiderlegungRules.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungRules, test/gut/helpers/widerlegung_canon.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const Canon := preload("res://addons/lobby_loop/test/gut/helpers/widerlegung_canon.gd")

var data: Dictionary = {}


func before_all() -> void:
	data = WiderlegungRules.load_data()


func _inst(lehre_id: String) -> Dictionary:
	return data["instanzen"][WiderlegungRules.index_of(data, lehre_id)]


func test_data_loads_without_error() -> void:
	assert_false(data.has("error"), str(data.get("error", "")))
	assert_eq((data["instanzen"] as Array).size(), 5)


func test_startlehre_platon() -> void:
	var D := _inst("akademie")
	var lehre := WiderlegungRules.initial_lehre(D)
	assert_eq(WiderlegungRules.judge(D["card_map"]["huhn"], lehre), "broad")
	assert_eq(WiderlegungRules.judge(D["card_map"]["saeugling"], lehre), "narrow")
	assert_eq(WiderlegungRules.judge(D["card_map"]["pferd"], lehre), "confirm")


func _start_at(idx: int, az: String = "TEST-1") -> Dictionary:
	var run := WiderlegungRules.new_run(az)
	run["idx"] = idx
	WiderlegungRules.start_instanz(data, run)
	return run


func _patch(events: Array) -> Dictionary:
	for e in events:
		if e["type"] == "patch":
			return e
	return {}


func test_patch_broad_takes_first_prisma_lit() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["huhn"]
	var p := _patch(WiderlegungRules.play(data, r, "huhn"))
	assert_eq(p["kind"], "add")
	assert_eq(p["lit"]["a"], "naegel")
	assert_eq(WiderlegungRules.last(r["inst"]), 4)


func test_patch_broad_without_free_lit_makes_exception() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["hermes"]
	var p := _patch(WiderlegungRules.play(data, r, "hermes"))
	assert_eq(p["kind"], "excl")
	assert_eq(WiderlegungRules.last(r["inst"]), 6)


func test_blockade_then_exception() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["pythagoreer", "kyklop", "huhn"]
	r["inst"]["deck"] = []
	assert_eq(_patch(WiderlegungRules.play(data, r, "pythagoreer"))["kind"], "confirm")
	assert_eq(_patch(WiderlegungRules.play(data, r, "kyklop"))["kind"], "excl")


func test_patch_narrow_keeps_gone_clause() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["veteran"]
	var before := WiderlegungRules.last(r["inst"])
	var p := _patch(WiderlegungRules.play(data, r, "veteran"))
	assert_eq(p["kind"], "repair")
	var has_gone := false
	for c in r["inst"]["lehre"]:
		if c["t"] == "gone" and c["a"] == "zweibeinig":
			has_gone = true
	assert_true(has_gone, "gestrichene Bestimmung bleibt als weggefallen stehen")
	assert_true(WiderlegungRules.last(r["inst"]) >= before)


func test_patch_narrow_with_leak_makes_inclusion() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["kyklop", "pythagoreer"]
	r["inst"]["deck"] = []
	assert_eq(_patch(WiderlegungRules.play(data, r, "kyklop"))["lit"]["a"], "lacht")
	assert_eq(_patch(WiderlegungRules.play(data, r, "pythagoreer"))["kind"], "incl")


func test_invariant_10000_random_moves() -> void:
	var violations := []
	var moves := 0
	var s := 0
	while moves < 10000:
		for idx in (data["instanzen"] as Array).size():
			var r := _start_at(idx, "INV-%d" % s)
			var D: Dictionary = data["instanzen"][idx]
			while r["inst"]["status"] == "play":
				var hand: Array = r["inst"]["hand"]
				WiderlegungRules.play(data, r, hand[(s * 7 + moves) % hand.size()])
				moves += 1
				for id in r["inst"]["members"]:
					if not WiderlegungRules.satisfies(D["card_map"][id], r["inst"]["lehre"]):
						violations.append("Mitglied ausgeschlossen: %s in %s" % [id, D["id"]])
				for id in r["inst"]["non_members"]:
					if WiderlegungRules.satisfies(D["card_map"][id], r["inst"]["lehre"]):
						violations.append("Nicht-Mitglied eingeschlossen: %s in %s" % [id, D["id"]])
		s += 1
	assert_eq(violations, [], "Lehre ordnet nach jedem Zug alle Fallakten richtig ein")


func _play_log(az: String) -> String:
	var r := WiderlegungRules.new_run(az)
	var log := []
	while r["phase"] != "end":
		match r["phase"]:
			"intro":
				WiderlegungRules.start_instanz(data, r)
				log.append(Canon.join(r["inst"]["hand"]))
				log.append(Canon.join(r["inst"]["deck"]))
			"play":
				for e in WiderlegungRules.play(data, r, r["inst"]["hand"][0]):
					log.append(Canon.event(e))
			"result":
				WiderlegungRules.next_phase(data, r)
			"tonne":
				log.append(Canon.join(r["offers"]))
				WiderlegungRules.choose_kniff(data, r, r["offers"][0])
			"alexander":
				WiderlegungRules.choose_alexander(r, "sonne")
	log.append(str(r["total"]))
	log.append(WiderlegungRules.pruefcode(r))
	return Canon.join(log, "|")


func test_determinism_same_az_same_game() -> void:
	assert_eq(_play_log("HUHN-20261011"), _play_log("HUHN-20261011"))
	assert_ne(_play_log("HUHN-20261011"), _play_log("HUHN-20261012"))


func test_preview_changes_nothing_and_predicts() -> void:
	var mismatches := []
	for s in 200:
		var r := _start_at(s % 5, "PV-%d" % s)
		while r["inst"]["status"] == "play":
			var id: String = r["inst"]["hand"][0]
			var snap := JSON.stringify(r["inst"])
			var p := WiderlegungRules.preview(data, r, id)
			if JSON.stringify(r["inst"]) != snap:
				mismatches.append("Laterne veränderte Zustand (PV-%d)" % s)
			var pe := _patch(WiderlegungRules.play(data, r, id))
			if pe["kind"] != p["kind"] or pe["last"] != p["last"]:
				mismatches.append("Laterne lag falsch bei %s (PV-%d)" % [id, s])
	assert_eq(mismatches, [])


func test_kniffe_inspektion_huhn2_uniform() -> void:
	var r := WiderlegungRules.new_run("K-1", {"kniffe": ["inspektion", "huhn2", "uniform"]})
	WiderlegungRules.start_instanz(data, r)
	assert_eq(r["inst"]["cap"], int(data["instanzen"][0]["cap"]) - 1)
	assert_eq(r["inst"]["wuerfe"], int(data["instanzen"][0]["wuerfe"]) + 1)
	r["inst"]["hand"] = ["huhn", "kaenguru"]
	WiderlegungRules.use_kniff(r, "uniform")
	assert_eq(_patch(WiderlegungRules.play(data, r, "huhn"))["kind"], "excl")
	assert_null(WiderlegungRules.use_kniff(r, "uniform"), "nur einmal je Instanz")


func test_heartbeat_autoritaet_seizes_marked_card() -> void:
	var r := _start_at(0, "HB-3")
	var tg: Dictionary = r["inst"]["telegraph"]
	assert_eq(tg["type"], "autoritaet")
	var target: String = tg["target"]
	var beat: Dictionary = {}
	for i in 3:
		if r["inst"]["status"] != "play":
			break
		var id: String = ""
		for h in r["inst"]["hand"]:
			if h != target:
				id = h
				break
		for e in WiderlegungRules.play(data, r, id):
			if e["type"] == "beat":
				beat = e
	if r["inst"]["status"] == "play":
		assert_false(beat.is_empty(), "Herzschlag nach dem dritten Wurf")
		assert_eq(beat["effect"], "seized")
		assert_false((r["inst"]["hand"] as Array).has(target))


func test_pruefcode_is_four_hex_chars() -> void:
	var r := WiderlegungRules.new_run("HUHN-20261011")
	while r["phase"] != "end":
		match r["phase"]:
			"intro": WiderlegungRules.start_instanz(data, r)
			"play": WiderlegungRules.play(data, r, r["inst"]["hand"][0])
			"result": WiderlegungRules.next_phase(data, r)
			"tonne": WiderlegungRules.choose_kniff(data, r, r["offers"][0])
			"alexander": WiderlegungRules.choose_alexander(r, "gold")
	var code := WiderlegungRules.pruefcode(r)
	assert_true(RegEx.create_from_string("^[0-9A-F]{4}$").search(code) != null, code)


func test_beweisaufnahme_blocking_confirm_is_free() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["pythagoreer", "kyklop", "huhn"]
	r["inst"]["deck"] = []
	var w: int = r["inst"]["wuerfe"]
	var pv := WiderlegungRules.preview(data, r, "pythagoreer")
	assert_true(pv["frei"] and (pv["blocks"] as Array).size() >= 1)
	var p := _patch(WiderlegungRules.play(data, r, "pythagoreer"))
	assert_true(p["frei"])
	assert_eq(r["inst"]["wuerfe"], w)
	assert_eq(r["inst"]["plays"], 1)
	# nicht blockierende Bestätigung kostet einen Wurf
	var r2 := _start_at(1)
	var D: Dictionary = data["instanzen"][1]
	var id := ""
	for c in D["cards"]:
		if not c["member"] and not WiderlegungRules.satisfies(c, r2["inst"]["lehre"]) and not (D["refNon"] as Array).has(c["id"]):
			id = c["id"]
			break
	r2["inst"]["hand"] = [id]
	r2["inst"]["deck"] = ["bett"]
	var w2: int = r2["inst"]["wuerfe"]
	WiderlegungRules.play(data, r2, id)
	assert_eq(r2["inst"]["wuerfe"], w2 - 1)
