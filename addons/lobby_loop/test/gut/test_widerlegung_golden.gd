# PURPOSE: Gleichheitstest: 200 Partien und 10 Vorgänge liefern in Godot exakt dieselben Züge, Lasten und Punkte wie die JS-Fassung.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungRules, test/gut/helpers/widerlegung_canon.gd, test/golden/widerlegung.json
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const Canon := preload("res://addons/lobby_loop/test/gut/helpers/widerlegung_canon.gd")
const GOLDEN_PATH := "res://addons/lobby_loop/test/golden/widerlegung.json"
const KNIFF_USE_ORDER := ["fass", "bettwaermer", "uniform"]
const MAX_REPORTED := 3

var golden: Dictionary = {}
var data: Dictionary = {}


func before_all() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	if parsed is Dictionary:
		golden = parsed
	data = WiderlegungRules.load_data()


func _play_game(g: int, kniffe: Array) -> Dictionary:
	var n: int = (data["instanzen"] as Array).size()
	var idx := g % n
	var run := WiderlegungRules.new_run("GOLD-%d" % g, {"kniffe": kniffe})
	run["idx"] = idx
	if idx == n - 1:
		run["alexander"] = "sonne" if g % 2 == 0 else "gold"
	var st := WiderlegungRules.start_instanz(data, run)
	var start := Canon.start(st)
	var lines := []
	while run["inst"]["status"] == "play":
		if int(run["inst"]["plays"]) == 1:
			for k in KNIFF_USE_ORDER:
				if WiderlegungRules.use_kniff(run, k) != null:
					lines.append("K|" + k + "|" + Canon.join(run["inst"]["hand"]))
		var hand: Array = run["inst"]["hand"]
		var card: String = hand[(int(run["inst"]["plays"]) * 7 + g) % hand.size()]
		lines.append("P|" + card)
		for e in WiderlegungRules.play(data, run, card):
			lines.append(Canon.event(e))
	return {"start": start, "lines": lines, "result": Canon.result(run["results"][0])}


func _first_diff(want: Dictionary, got: Dictionary) -> String:
	if str(want["start"]) != str(got["start"]):
		return "Start: erwartet %s, bekommen %s" % [want["start"], got["start"]]
	var a: Array = want["lines"]
	var b: Array = got["lines"]
	for i in mini(a.size(), b.size()):
		if str(a[i]) != str(b[i]):
			return "Zeile %d: erwartet %s, bekommen %s" % [i, a[i], b[i]]
	if a.size() != b.size():
		return "Zeilenzahl: erwartet %d, bekommen %d" % [a.size(), b.size()]
	if str(want["result"]) != str(got["result"]):
		return "Ergebnis: erwartet %s, bekommen %s" % [want["result"], got["result"]]
	return ""


func test_200_games_match_js() -> void:
	var games: Array = golden.get("games", [])
	assert_eq(games.size(), 200, "Golden fehlt oder unvollständig")
	var ok := 0
	var reported := 0
	for g in games:
		var diff := _first_diff(g, _play_game(int(g["g"]), g["kniffe"]))
		if diff.is_empty():
			ok += 1
		elif reported < MAX_REPORTED:
			reported += 1
			gut.p("Partie %d (%s, Kniffe %s): %s" % [int(g["g"]), g["az"], g["kniffe"], diff])
	assert_eq(ok, games.size(), "Gleichheitstest %d/%d" % [ok, games.size()])


func _run_full(i: int) -> String:
	var run := WiderlegungRules.new_run("FULL-%d" % i)
	while run["phase"] != "end":
		match run["phase"]:
			"intro": WiderlegungRules.start_instanz(data, run)
			"play": WiderlegungRules.play(data, run, run["inst"]["hand"][0])
			"result": WiderlegungRules.next_phase(data, run)
			"tonne": WiderlegungRules.choose_kniff(data, run, run["offers"][0])
			"alexander": WiderlegungRules.choose_alexander(run, "gold" if i % 2 == 0 else "sonne")
	var results := []
	for r in run["results"]:
		results.append(Canon.result(r))
	return Canon.join([run["total"], WiderlegungRules.pruefcode(run), Canon.join(run["kniffe"]), Canon.join(results, ";")], "|")


func test_full_runs_match_js_including_pruefcode() -> void:
	var full: Array = golden.get("full", [])
	assert_eq(full.size(), 10)
	for i in full.size():
		assert_eq(_run_full(i), str(full[i]), "Vorgang FULL-%d" % i)
