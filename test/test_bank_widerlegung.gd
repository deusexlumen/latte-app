# PURPOSE: Widerlegung im Ausschuss von BANK-01 (Kap. 8.2, 9.7, 16.4, 16.5, 17.2, 20.2): Bank-Lehre (Form, Referenz, Validator mit gespeicherten Werten),
# PURPOSE: Nachspielen aus Seed und Kartenfolge, Nachweis des Ergebnisses, Abbruch/Niederlage/Fortsetzen, Panel ohne Einspruch und ohne Effekte.
# ARCHITECTURE: test
# DEPENDENCIES: BankWiderlegung, Bank01, AmtWorld, AmtStore, amt/bank_panel.gd, WiderlegungValidator
# PIPELINE: test
# LAST_VALIDATED: 2026-10-18
extends GutTest

const BankPanelScript := preload("res://amt/bank_panel.gd")
const Canon := preload("res://addons/lobby_loop/test/gut/helpers/widerlegung_canon.gd")
const LEHRE_PATH := "res://cases/bank_01/lehre/bib_bank_01.json"
const GOLDEN_PATH := "res://test/golden/bank_01_widerlegung.json"
const KNIFF_USE_ORDER := ["fass", "bettwaermer", "uniform"]
const MAX_REPORTED := 3
const SAVE := "user://test_bank_widerlegung.json"

var s: Dictionary
var _allow_dev := true


func before_all() -> void:
	_allow_dev = Bank01.allow_dev_results


func before_each() -> void:
	for p in [SAVE, AmtStore.prev_path(SAVE)]:
		JsonStore.remove(p)


func after_each() -> void:
	Bank01.allow_dev_results = _allow_dev


# --- Hilfen ---

func raw_lehre() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(LEHRE_PATH))


## Wie das Spiel nach Gegenbeispielen sucht: erst eine Karte, die die Lehre widerlegt, sonst die erste.
func pick(run: Dictionary, lehre: Dictionary) -> String:
	var hand: Array = run["inst"]["hand"]
	for id in hand:
		if WiderlegungRules.judge(lehre["card_map"][id], run["inst"]["lehre"]) != "confirm":
			return str(id)
	return str(hand[0])


## Kartenfolge einer ganzen Partie auf dem Seed.
func play_out(seed: String, limit: int = 99) -> Array:
	var data := BankWiderlegung.load_data()
	var idx := WiderlegungRules.index_of(data, BankWiderlegung.LEHRE_ID)
	var run := WiderlegungRules.new_run(seed)
	run["idx"] = idx
	WiderlegungRules.start_instanz(data, run)
	var plays := []
	while run["phase"] == "play" and plays.size() < limit:
		var card := pick(run, data["instanzen"][idx])
		plays.append(card)
		WiderlegungRules.play(data, run, card)
	return plays


func result_of(seed: String, plays: Array) -> Dictionary:
	return BankWiderlegung.outcome(BankWiderlegung.replay(seed, plays)["run"])


## Ein Seed, auf dem die Partie mit dem gewünschten Ausgang endet.
func seed_with(collapsed: bool) -> String:
	for i in 200:
		var seed := "T%d" % i
		var o := result_of(seed, play_out(seed))
		if o["finished"] and o["collapsed"] == collapsed:
			return seed
	fail_test("kein Seed mit Ausgang %s" % collapsed)
	return ""


func run(type: String, params: Dictionary = {}) -> Dictionary:
	var r := AmtWorld.execute(s, Bank01.command(s, type, params), Bank01)
	assert_true(r["ok"], "%s %s: %s" % [type, params, r["reason"]])
	s = r["state"]
	return r


func refuse(type: String, params: Dictionary = {}) -> String:
	var before := s.duplicate(true)
	var r := AmtWorld.execute(s, Bank01.command(s, type, params), Bank01)
	assert_false(r["ok"], "%s %s hätte abgelehnt werden müssen" % [type, params])
	assert_true(r["state"] == before, "abgelehnter Befehl ändert nichts")
	return str(r["reason"])


## Bis zum Beginn der Widerlegung im Ausschussraum (B-01, B-02, B-03 liegen vor).
func to_hearing(seed: String) -> void:
	s = Bank01.new_state(seed)
	for step in [["move", {"to": "innenhof"}], ["open_case"], ["request_document", {"document_id": "bench_inventory"}],
			["request_document", {"document_id": "repair_record"}], ["wait"], ["compare", {"evidence": ["B-02", "D-01"]}],
			["end_day"], ["end_evening"], ["move", {"to": "ausschussraum"}], ["start_minigame", {"game": "widerlegung"}]]:
		run(step[0], step[1] if step.size() > 1 else {})


func session() -> Dictionary:
	return Bank01.running_session(s)


func send_plays(plays: Array) -> void:
	for card in plays:
		run("minigame_play", {"session_id": session()["session_id"], "card": card})


## Das Ergebnis, das das Panel liefern würde (MinigameContract), als Weltergebnis.
func panel_result(seed: String, plays: Array) -> Dictionary:
	var data := BankWiderlegung.load_data()
	var lehre: Dictionary = data["instanzen"][WiderlegungRules.index_of(data, BankWiderlegung.LEHRE_ID)]
	var run_: Dictionary = BankWiderlegung.replay(seed, plays)["run"]
	var contract := MinigameContract.widerlegung_result(lehre, run_["results"][0])
	return BankWiderlegung.world_result(session(), contract)


# --- Lehre ---

func test_lehre_has_the_reference_form() -> void:
	var d := raw_lehre()
	assert_eq(d["content_id"], BankWiderlegung.CONTENT_ID)
	assert_eq(d["id"], BankWiderlegung.LEHRE_ID)
	assert_between((d["cards"] as Array).size(), 15, 22, "15 bis 22 Karten (Kap. 9.7)")
	assert_between((d["attrs"] as Dictionary).size(), 8, 12)
	assert_between((d["start"] as Array).size(), 2, 3)
	assert_between((d["prisma"] as Array).size(), 5, 7)
	for c in d["cards"]:
		assert_ne(str(c["note"]).strip_edges(), "", "Karte ohne Hinweistext: %s" % c["id"])
	assert_string_contains(str(d["intro"]), "Nutzungsauftrag", "das Spiel benennt seine Referenz")


func test_membership_follows_the_documented_purpose() -> void:
	# Die Referenz: Öffentliche Sitzgelegenheit ist, was für Wartende bereitgestellt wurde (Kap. 9.7).
	# Kein Sieg hängt an einer unausgesprochenen Definition: Mitglied ⇔ Merkmal »bereit«.
	for c in raw_lehre()["cards"]:
		assert_eq(bool(c["m"]), str(c["a"]).split(" ", false).has("bereit"), c["id"])


func test_the_cases_from_the_spec_are_in_the_pool() -> void:
	var ids: Array = raw_lehre()["cards"].map(func(c: Dictionary) -> String: return c["id"])
	for id in ["wartebank", "wartehocker", "bank01", "besucherstuhl", "miniatur", "ausstellungsstuhl", "sitzskulptur", "transportkiste"]:
		assert_has(ids, id)


func test_validator_confirms_the_stored_values() -> void:
	var d := raw_lehre()
	var res: Dictionary = WiderlegungValidator.validate(WiderlegungRules.load_data(), d)
	assert_true(res["ok"], str(res["befunde"]))
	assert_eq(int(res["cap"]), int(d["cap"]), "cap kommt aus der Prüfung, nicht aus der Hand")
	assert_eq(int(res["wuerfe"]), int(d["wuerfe"]))
	assert_gte(int(res["paare"]), WiderlegungValidator.MIN_PAIRS)
	var m: Dictionary = res["messung"]
	assert_between(float(m["gelegenheit"]), WiderlegungValidator.GELEGENHEIT_BAND[0], WiderlegungValidator.GELEGENHEIT_BAND[1])
	assert_lt(float(m["zufall"]), WiderlegungValidator.ZUFALL_MAX)
	assert_gte(float(m["ausnahme"]), WiderlegungValidator.AUSNAHME_MIN)


func test_lehre_loads_without_the_user_library() -> void:
	var data := BankWiderlegung.load_data()
	assert_false(data.has("error"), str(data.get("error")))
	assert_gte(WiderlegungRules.index_of(data, BankWiderlegung.LEHRE_ID), 0)
	assert_gte(WiderlegungRules.index_of(data, "amt"), 0, "Grundbestand bleibt erhalten")


# --- Nachspielen ---

func test_replay_is_deterministic() -> void:
	var seed := "BANK-01-A"
	var plays := play_out(seed)
	var a := BankWiderlegung.replay(seed, plays)
	var b := BankWiderlegung.replay(seed, plays)
	assert_true(a["ok"])
	assert_true(a["run"] == b["run"], "gleicher Seed, gleiche Karten, gleicher Verlauf")
	assert_true(BankWiderlegung.outcome(a["run"])["finished"])
	var other := BankWiderlegung.replay("BANK-01-B", [])
	assert_ne(other["run"]["inst"]["hand"], BankWiderlegung.replay(seed, [])["run"]["inst"]["hand"], "anderer Seed, andere Hand")


func test_replay_rejects_illegal_plays() -> void:
	var start: Dictionary = BankWiderlegung.replay("BANK-01-A", [])["run"]
	var in_deck: Array = start["inst"]["deck"]
	assert_false(BankWiderlegung.replay("BANK-01-A", [in_deck[0]])["ok"], "Karte noch nicht gezogen")
	assert_false(BankWiderlegung.replay("BANK-01-A", ["gibt_es_nicht"])["ok"])
	var plays := play_out("BANK-01-A")
	assert_false(BankWiderlegung.replay("BANK-01-A", plays + [plays[0]])["ok"], "Zug nach der Entscheidung")


# --- Vorgang mit echter Widerlegung ---

func test_won_hearing_opens_the_formal_way() -> void:
	var seed := seed_with(true)
	to_hearing(seed)
	assert_eq(session()["seed"], seed, "Seed des Durchlaufs")
	var plays := play_out(seed)
	send_plays(plays)
	assert_eq((session()["checkpoint"]["plays"] as Array).size(), plays.size())
	run("minigame_result", {"result": panel_result(seed, plays)})
	assert_eq(s["cases"]["BANK-01"]["definition"], "won")
	assert_true(Bank01.running_session(s).is_empty())
	run("submit", {"antrag": "formal", "findings": ["B-01", "B-02", "B-03"], "conclusion": "zweck_gegen_einstufung",
		"open_questions": ["kunst"], "wording": "Sitzgelegenheiten müssen zugänglich sein."})
	assert_eq(s["cases"]["BANK-01"]["resolution"], "formal_release")
	assert_eq(s["objects"]["bench"]["access"], "open")


func test_lost_hearing_still_leads_to_a_decision() -> void:
	var seed := seed_with(false)
	to_hearing(seed)
	var plays := play_out(seed)
	send_plays(plays)
	run("minigame_result", {"result": panel_result(seed, plays)})
	assert_eq(s["cases"]["BANK-01"]["definition"], "lost")
	assert_string_contains(refuse("submit", {"antrag": "formal", "findings": [], "conclusion": "keine",
		"open_questions": ["keine"], "wording": "x"}), "widerlegt")
	refuse("start_minigame", {"game": "widerlegung"})
	run("submit", {"antrag": "ausnahme", "findings": ["B-01", "B-02"], "conclusion": "keine", "open_questions": ["keine"]})
	assert_eq(s["cases"]["BANK-01"]["resolution"], "temporary_exception")
	assert_eq(s["actors"]["kern"]["seat"], "bench", "Niederlage ohne Blamage: Frau Kern sitzt trotzdem")


func test_result_must_follow_from_the_cards_played() -> void:
	var seed := seed_with(true)
	to_hearing(seed)
	var plays := play_out(seed)
	send_plays(plays)
	var good := panel_result(seed, plays)
	var flipped := good.duplicate(true)
	flipped["outcome"] = "lost"
	flipped["facts"] = {"definition_collapsed": false}
	assert_string_contains(refuse("minigame_result", {"result": flipped}), "Spielverlauf")
	var score := good.duplicate(true)
	score["score"] = int(good["score"]) + 50
	assert_string_contains(refuse("minigame_result", {"result": score}), "Punkte")
	run("minigame_result", {"result": good})


func test_unfinished_game_cannot_be_reported() -> void:
	var seed := seed_with(true)
	to_hearing(seed)
	var plays := play_out(seed)
	send_plays(plays.slice(0, 1))
	var claim := Bank01.dev_result(s, "won")
	assert_string_contains(refuse("minigame_result", {"result": claim}), "nicht entschieden")


func test_result_without_cards_only_as_debug_stub() -> void:
	to_hearing("BANK-01-A")
	var claim := Bank01.dev_result(s, "won")
	Bank01.allow_dev_results = false
	assert_string_contains(refuse("minigame_result", {"result": claim}), "nachvollziehbar")
	var plain := claim.duplicate(true)
	plain.erase("dev")
	Bank01.allow_dev_results = true
	assert_string_contains(refuse("minigame_result", {"result": plain}), "nachvollziehbar", "ohne Kennzeichnung nie")
	run("minigame_result", {"result": claim})
	assert_eq(s["cases"]["BANK-01"]["definition"], "won")


func test_illegal_play_commands_change_nothing() -> void:
	to_hearing("BANK-01-A")
	var sid: String = session()["session_id"]
	var in_deck: String = str(BankWiderlegung.replay("BANK-01-A", [])["run"]["inst"]["deck"][0])
	assert_string_contains(refuse("minigame_play", {"session_id": sid, "card": in_deck}), "Hand")
	assert_string_contains(refuse("minigame_play", {"session_id": "session-fremd", "card": "besucherstuhl"}), "keine Widerlegung")
	assert_string_contains(refuse("move", {"to": "innenhof"}), "Partie")


func test_abort_keeps_the_deal_and_resume_reproduces_the_state() -> void:
	var seed := "BANK-01-A"
	to_hearing(seed)
	var first_hand: Array = BankWiderlegung.replay(seed, [])["run"]["inst"]["hand"].duplicate()
	var plays := play_out(seed, 3)
	send_plays(plays)
	# Speichern und Laden mitten in der Partie: Der Zustand ergibt sich aus Seed und Karten.
	assert_true(AmtStore.save(s, SAVE))
	s = AmtStore.load_state(SAVE, Bank01.CONTENT_VERSION)["state"]
	var resumed: Array = session()["checkpoint"]["plays"]
	assert_eq(resumed, plays)
	assert_true(BankWiderlegung.replay(seed, resumed)["run"] == BankWiderlegung.replay(seed, plays)["run"])
	run("minigame_result", {"result": Bank01.dev_result(s, "aborted")})
	assert_eq(s["cases"]["BANK-01"]["definition"], "", "Abbruch verbucht nichts")
	run("start_minigame", {"game": "widerlegung"})
	assert_eq(session()["seed"], seed)
	assert_eq(BankWiderlegung.replay(session()["seed"], [])["run"]["inst"]["hand"], first_hand, "Abbruch würfelt keine neue Hand")
	assert_eq((session()["checkpoint"]["plays"] as Array).size(), 0)


func test_panel_cannot_inject_effects() -> void:
	to_hearing("BANK-01-A")
	var contract := {"game": "widerlegung", "won": true, "score": 40, "lehre": BankWiderlegung.LEHRE_ID,
		"effects": [{"type": "modify_stat", "stat": "discipline", "delta": 9}], "chronik": "x"}
	var world := BankWiderlegung.world_result(session(), contract)
	assert_false(world.has("effects"))
	assert_eq(world["outcome"], "won")
	assert_eq(BankWiderlegung.world_result(session(), {"lehre": "amt", "won": true}), {}, "fremde Lehre wird nicht übersetzt")


# --- Panel ---

func _panel(gate: Callable) -> PanelContainer:
	var p: PanelContainer = BankPanelScript.new()
	p.gate = gate
	add_child_autofree(p)
	return p


func test_panel_plays_through_the_world_gate_without_objections() -> void:
	var seed := "BANK-01-A"
	to_hearing(seed)
	var gate := func(card: String) -> bool:
		var r := AmtWorld.execute(s, Bank01.command(s, "minigame_play", {"session_id": session()["session_id"], "card": card}), Bank01)
		if r["ok"]:
			s = r["state"]
		return bool(r["ok"])
	var p := _panel(gate)
	p.start({"lehre": BankWiderlegung.LEHRE_ID, "seed": seed})
	assert_true(p.is_playing())
	var blocked := 0
	for b in p.find_children("*", "Button", true, false):
		if (b as Button).text == "!" and (b as Button).visible:
			blocked += 1
	assert_eq(blocked, 0, "kein Einspruch-Knopf sichtbar")
	assert_false(p.object_card(p.hand_ids()[0]), "Einspruch wirkungslos")
	assert_false(FileAccess.file_exists(BankWiderlegung.LEHRE_DIR + "sperrliste.json"), "nichts in die Fall-Daten geschrieben")
	var guard := 0
	while p.is_playing() and guard < 30:
		p.play_card(pick(p._run, p._lehre))
		guard += 1
	assert_false(p.is_playing())
	assert_eq((session()["checkpoint"]["plays"] as Array).size(), p._run["inst"]["plays"], "jeder Zug steht im Vorgang")
	var got := []
	p.finished.connect(func(r: Dictionary) -> void: got.append(r))
	p.close()
	assert_eq(got.size(), 1)
	run("minigame_result", {"result": BankWiderlegung.world_result(session(), got[0])})
	assert_ne(s["cases"]["BANK-01"]["definition"], "")


func test_panel_gate_can_veto_a_card() -> void:
	var p := _panel(func(_card: String) -> bool: return false)
	p.start({"lehre": BankWiderlegung.LEHRE_ID, "seed": "BANK-01-A"})
	var hand: Array = p.hand_ids()
	p.play_card(hand[0])
	assert_eq(p.hand_ids(), hand, "ohne Bestätigung des Vorgangs wird nicht gespielt")


# --- Gleichheit mit dem JS-Original (Kap. 20.2) ---

func _play_golden_game(data: Dictionary, g: int, kniffe: Array) -> Dictionary:
	var idx := WiderlegungRules.index_of(data, BankWiderlegung.LEHRE_ID)
	var run_ := WiderlegungRules.new_run("BANKGOLD-%d" % g, {"kniffe": kniffe})
	run_["idx"] = idx
	var st := WiderlegungRules.start_instanz(data, run_)
	var start := Canon.start(st)
	var lines := []
	while run_["inst"]["status"] == "play":
		if int(run_["inst"]["plays"]) == 1:
			for k in KNIFF_USE_ORDER:
				if WiderlegungRules.use_kniff(run_, k) != null:
					lines.append("K|" + k + "|" + Canon.join(run_["inst"]["hand"]))
		var hand: Array = run_["inst"]["hand"]
		var card: String = hand[(int(run_["inst"]["plays"]) * 7 + g) % hand.size()]
		lines.append("P|" + card)
		for e in WiderlegungRules.play(data, run_, card):
			lines.append(Canon.event(e))
	return {"start": start, "lines": lines, "result": Canon.result(run_["results"][0])}


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


func test_200_games_on_the_bank_lehre_match_the_js_original() -> void:
	var golden: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	assert_true(golden is Dictionary, "Golden fehlt: node tools/bank-lehre-golden.mjs")
	if not (golden is Dictionary):
		return
	assert_eq(golden["lehre"], BankWiderlegung.LEHRE_ID)
	var games: Array = golden["games"]
	assert_eq(games.size(), 200)
	var data := BankWiderlegung.load_data()
	var ok := 0
	var reported := 0
	var collapsed := 0
	for g in games:
		var got := _play_golden_game(data, int(g["g"]), g["kniffe"])
		var diff := _first_diff(g, got)
		if diff.is_empty():
			ok += 1
			collapsed += 1 if str(g["result"]).begins_with("1|") else 0
		elif reported < MAX_REPORTED:
			reported += 1
			gut.p("Partie %d (%s, Kniffe %s): %s" % [int(g["g"]), g["az"], g["kniffe"], diff])
	assert_eq(ok, games.size(), "Gleichheit %d/%d. Nach Änderung der Lehre: node tools/bank-lehre-golden.mjs" % [ok, games.size()])
	assert_between(collapsed, 20, 180, "die Golden-Partien enthalten Einstürze und Standhalten")
