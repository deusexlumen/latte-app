# PURPOSE: Spielt Pfad A von BANK-01 (formeller Erfolg) vollständig durch, mit echter Widerlegung (Kartenfolge auf dem Seed) und DAME-Ergebnis mit match_id,
# PURPOSE: und schreibt den Weltzustand als Fixture für die Auswertung (tools/spieltest-auswertung.mjs). Das Fixture enthält nur Spieldaten.
# ARCHITECTURE: tools
# DEPENDENCIES: Bank01, BankWiderlegung, BankDame, AmtWorld, MinigameContract
# PIPELINE: build, test
# LAST_VALIDATED: 2026-10-18
extends SceneTree

# Aufruf: godot --headless --path . --script res://tools/make_spieltest_fixture.gd -- tools/fixtures/bank01-pfad-a.json

var s: Dictionary


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if not args.is_empty() else "res://tools/fixtures/bank01-pfad-a.json"
	var seed := _seed_with_won_hearing()
	s = Bank01.new_state(seed)
	for step in [["move", {"to": "innenhof"}], ["open_case"], ["observe"], ["move", {"to": "hausdienst"}],
			["interview", {"actor": "mertens", "topic": "bank"}], ["request_document", {"document_id": "bench_inventory"}],
			["move", {"to": "registratur"}], ["observe"], ["compare", {"evidence": ["B-02", "D-01"]}],
			["interview", {"actor": "seidel", "topic": "bank"}], ["end_day"], ["start_minigame", {"game": "dame"}]]:
		_run(step[0], step[1] if step.size() > 1 else {})
	_run("minigame_result", {"result": BankDame.world_result(Bank01.running_session(s), {"won": true, "score": 11, "online": false, "match_id": Bank01.running_session(s)["match_id"]})})
	for step in [["end_evening"], ["move", {"to": "ausschussraum"}], ["start_minigame", {"game": "widerlegung"}]]:
		_run(step[0], step[1] if step.size() > 1 else {})
	var plays := _play_out(seed)
	for card in plays:
		_run("minigame_play", {"session_id": Bank01.running_session(s)["session_id"], "card": card})
	var data := BankWiderlegung.load_data()
	var lehre: Dictionary = data["instanzen"][WiderlegungRules.index_of(data, BankWiderlegung.LEHRE_ID)]
	var replayed: Dictionary = BankWiderlegung.replay(seed, plays)["run"]
	var contract := MinigameContract.widerlegung_result(lehre, replayed["results"][0])
	_run("minigame_result", {"result": BankWiderlegung.world_result(Bank01.running_session(s), contract)})
	_run("submit", {"antrag": "formal", "findings": ["B-01", "B-02", "B-03"], "conclusion": "zweck_gegen_einstufung",
		"open_questions": ["kunst"], "wording": "Sitzgelegenheiten müssen zugänglich sein."})
	_run("advance")
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(s) + "\n")
	f.close()
	print("FIXTURE_OK ", out, " Ereignisse: ", (s["events"] as Array).size())
	quit(0)


func _run(type: String, params: Dictionary = {}) -> void:
	var r := AmtWorld.execute(s, Bank01.command(s, type, params), Bank01)
	if not bool(r["ok"]):
		push_error("%s %s: %s" % [type, params, r["reason"]])
		print("FIXTURE_FAIL ", type, " ", r["reason"])
		quit(1)
		return
	s = r["state"]


func _pick(run_: Dictionary, lehre: Dictionary) -> String:
	var hand: Array = run_["inst"]["hand"]
	for id in hand:
		if WiderlegungRules.judge(lehre["card_map"][id], run_["inst"]["lehre"]) != "confirm":
			return str(id)
	return str(hand[0])


func _play_out(seed: String) -> Array:
	var data := BankWiderlegung.load_data()
	var idx := WiderlegungRules.index_of(data, BankWiderlegung.LEHRE_ID)
	var run_ := WiderlegungRules.new_run(seed)
	run_["idx"] = idx
	WiderlegungRules.start_instanz(data, run_)
	var plays := []
	while run_["phase"] == "play":
		var card := _pick(run_, data["instanzen"][idx])
		plays.append(card)
		WiderlegungRules.play(data, run_, card)
	return plays


## Der Durchlauf soll eine gewonnene Widerlegung zeigen (formelle Freigabe). Erster passender Seed, deterministisch.
func _seed_with_won_hearing() -> String:
	for i in 100:
		var seed := "SPIELTEST-%d" % i
		var o := BankWiderlegung.outcome(BankWiderlegung.replay(seed, _play_out(seed))["run"])
		if o["finished"] and o["collapsed"]:
			return seed
	return "SPIELTEST-0"
