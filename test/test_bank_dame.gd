# PURPOSE: E3 (Spezifikation 0.1, Kap. 8.3, 9.6, 11.3, 13.1, 17.1): DAME im Hinterzimmer von BANK-01 mit denselben Figuren wie tagsüber, Ergebnis nur mit der
# PURPOSE: match_id der Session, Start/Fortsetzen/Abbruch über VorgangDame, Raumwechsel nur für die Begegnung, Aktenhilfe, amtliche Fassung in der Akte.
# ARCHITECTURE: test
# DEPENDENCIES: BankDame, Bank01, VorgangDame, LatteAkte, App
# PIPELINE: test
# LAST_VALIDATED: 2026-10-18
extends GutTest

const SAVE := "user://test_bank_dame.json"

var s: Dictionary
var app: Node
var vd: Node
var _allow_dev := true


func before_all() -> void:
	app = get_node("/root/App")
	app.use_test_storage()
	vd = get_node("/root/VorgangDame")
	_allow_dev = Bank01.allow_dev_results


func before_each() -> void:
	vd.active = {}
	vd.result = {}
	vd.return_pending = false
	app.saves.clear()
	app.pending = {}


func after_each() -> void:
	Bank01.allow_dev_results = _allow_dev
	vd.active = {}
	vd.result = {}
	vd.return_pending = false
	app.saves.clear()


# --- Hilfen ---

func run(type: String, params: Dictionary = {}) -> Dictionary:
	var r := AmtWorld.execute(s, Bank01.command(s, type, params), Bank01)
	assert_true(r["ok"], "%s %s: %s" % [type, params, r["reason"]])
	s = r["state"]
	return r


func refuse(type: String, params: Dictionary = {}) -> String:
	var before := s.duplicate(true)
	var r := AmtWorld.execute(s, Bank01.command(s, type, params), Bank01)
	assert_false(r["ok"], "%s %s hätte abgelehnt werden müssen" % [type, params])
	assert_true(r["state"] == before)
	return str(r["reason"])


func to_evening(seed: String = "BANK-01-A") -> void:
	s = Bank01.new_state(seed)
	for step in [["move", {"to": "innenhof"}], ["open_case"], ["end_day"]]:
		run(step[0], step[1] if step.size() > 1 else {})


func session() -> Dictionary:
	return Bank01.running_session(s)


func dame_result(match_id: String, won: bool = true) -> Dictionary:
	return {"won": won, "score": 12, "online": false, "mode": "new", "match_id": match_id}


# --- Konfiguration und Ergebnis ---

func test_match_config_uses_the_figures_of_the_case() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	var cfg := BankDame.match_config(s, session(), "Erika")
	assert_eq(cfg["names"], ["Erika", "Herr Mertens", "Frau Seidel"])
	assert_eq(cfg["seat_count"], 3)
	assert_eq(cfg["ai_seats"], [1, 2])
	assert_eq(cfg["match_id"], session()["match_id"])
	assert_eq(BankDame.match_config(s, session(), "  ")["names"][0], "Sie", "ohne Namen: »Sie«")
	assert_eq(BankDame.match_config(s, session(), "Erika")["seed"], cfg["seed"], "gleicher Durchlauf, gleicher Seed")
	var other := Bank01.new_state("BANK-01-B")
	assert_ne(BankDame.match_config(other, session(), "Erika")["seed"], cfg["seed"], "anderer Durchlauf, anderer Seed")


func test_world_result_needs_the_sessions_match_id() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	var id: String = session()["match_id"]
	var ok := BankDame.world_result(session(), dame_result(id, true))
	assert_eq(ok["outcome"], "won")
	assert_eq(ok["match_id"], id)
	assert_eq(BankDame.world_result(session(), dame_result(id, false))["outcome"], "lost")
	assert_eq(BankDame.world_result(session(), dame_result("m42")), {}, "fremde Partie")
	assert_eq(BankDame.world_result(session(), dame_result("")), {})
	var online := dame_result(id)
	online["online"] = true
	assert_eq(BankDame.world_result(session(), online), {}, "Online-Partien zählen nie")


func test_core_refuses_results_of_other_matches() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	var id: String = session()["match_id"]
	var good := BankDame.world_result(session(), dame_result(id))
	var foreign := good.duplicate(true)
	foreign["match_id"] = "m42"
	assert_string_contains(refuse("minigame_result", {"result": foreign}), "nicht zu dieser Partie")
	var missing := good.duplicate(true)
	missing.erase("match_id")
	assert_string_contains(refuse("minigame_result", {"result": missing}), "nicht zu dieser Partie")
	run("minigame_result", {"result": good})
	assert_eq(s["actors"]["mertens"]["commitments"]["stuhl"]["quelle"], "dame", "die Gefälligkeit gibt es einmal")


func test_dev_stub_only_in_debug_builds() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	var stub := Bank01.dev_result(s, "won")
	Bank01.allow_dev_results = false
	assert_string_contains(refuse("minigame_result", {"result": stub}), "nicht zu dieser Partie")
	Bank01.allow_dev_results = true
	run("minigame_result", {"result": stub})


func test_lost_game_still_leaves_the_conversation_open() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	run("minigame_result", {"result": BankDame.world_result(session(), dame_result(session()["match_id"], false))})
	assert_eq(s["actors"]["mertens"]["commitments"].size(), 0, "keine Gefälligkeit, nichts gesperrt")
	assert_true(Bank01.available_actions(s).any(func(a: Dictionary) -> bool: return a["type"] == "talk"))
	run("talk", {"actor": "mertens", "topic": "bank"})
	assert_true(Bank01.has_ev(s, "B-04"), "die Information gibt es ohne Sieg")


# --- Figuren und Kontinuität ---

func test_seidel_sits_in_the_back_room_in_the_evening_only() -> void:
	s = Bank01.new_state()
	run("move", {"to": "innenhof"})
	run("open_case")
	assert_eq(s["actors"]["seidel"]["location_id"], "registratur")
	run("end_day")
	assert_eq(s["actors"]["seidel"]["location_id"], "hinterzimmer")
	assert_eq(s["actors"]["mertens"]["location_id"], "hinterzimmer")
	var people: Array = Bank01.scene(s)["people"]
	assert_eq(people.size(), 2)
	assert_string_contains(" ".join(PackedStringArray(people)), "Frau Seidel")
	assert_string_contains(Bank01.scene(s)["text"], "Frau Seidel")
	run("end_evening")
	assert_eq(s["actors"]["seidel"]["location_id"], "registratur", "am nächsten Morgen wieder an ihrem Platz")
	run("move", {"to": "registratur"})
	assert_eq(Bank01.scene(s)["people"].size(), 1)


# --- VorgangDame ---

func test_start_hands_the_match_to_dame_with_the_cases_config() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	await vd.start(s, session())
	assert_eq(vd.active["match_id"], session()["match_id"])
	assert_eq(app.pending["mode"], "new")
	assert_eq(app.pending["config"]["match_id"], session()["match_id"])
	assert_eq(app.pending["config"]["names"][1], "Herr Mertens")


func test_only_the_sessions_match_counts() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	await vd.start(s, session())
	app.match_finished.emit(dame_result("m42"))
	assert_true(vd.result.is_empty(), "fremde Partie")
	assert_false(vd.return_pending)
	var online := dame_result(session()["match_id"])
	online["online"] = true
	app.match_finished.emit(online)
	assert_true(vd.result.is_empty(), "Online-Partie")
	app.match_finished.emit(dame_result(session()["match_id"], true))
	assert_eq(vd.result["won"], true)
	assert_true(vd.return_pending)
	var taken: Dictionary = vd.take_result()
	assert_eq(taken["match_id"], session()["match_id"])
	assert_true(vd.take_result().is_empty(), "das Ergebnis gibt es einmal")
	assert_true(vd.active.is_empty())


func test_free_matches_without_a_session_are_ignored() -> void:
	app.match_finished.emit(dame_result("m1"))
	assert_true(vd.result.is_empty())
	assert_false(vd.return_pending)


func test_resume_only_for_the_saved_match_of_this_session() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	assert_false(vd.can_resume(session()), "noch nichts gespeichert")
	app.saves.save_match({"state": {}}, {"match_id": "m42"})
	assert_false(vd.can_resume(session()), "Spielstand einer fremden Partie")
	app.saves.save_match({"state": {}}, {"match_id": session()["match_id"]})
	assert_true(vd.can_resume(session()))
	await vd.resume(session())
	assert_eq(app.pending["mode"], "resume")


func test_discard_removes_only_its_own_save() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	app.saves.save_match({"state": {}}, {"match_id": "m42"})
	vd.discard(session())
	assert_true(app.saves.has_save(), "fremder Spielstand bleibt")
	app.saves.save_match({"state": {}}, {"match_id": session()["match_id"]})
	vd.discard(session())
	assert_false(app.saves.has_save())


func test_room_is_the_office_only_for_the_encounter() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	app.profile.grant("room_casino")
	app.profile.grant("room_amt")
	app.profile.equip("room_casino")
	await vd.start(s, session())
	assert_eq(app.profile.equipped("room"), "room_amt", "Hinterzimmer als Amtsstube")
	app.match_finished.emit(dame_result(session()["match_id"]))
	vd.take_result()
	assert_eq(app.profile.equipped("room"), "room_casino", "Raumwahl des Spielers kommt zurück")


func test_room_untouched_without_the_office_room() -> void:
	to_evening()
	run("start_minigame", {"game": "dame"})
	var before: String = app.profile.equipped("room")
	app.profile.equip("room_casino")
	await vd.start(s, session())
	vd.discard(session())
	assert_eq(app.profile.equipped("room"), "room_casino")
	app.profile.equip(before)


# --- Aktenhilfe (Kap. 11.3) ---

func test_help_missing_lists_what_the_forms_need() -> void:
	s = Bank01.new_state()
	assert_string_contains(Bank01.help_missing(s), "Formelle Freigabe")
	assert_string_contains(Bank01.help_missing(s), "Reparaturzettel mit Freigabe (B-01)")
	assert_string_contains(Bank01.help_missing(s), "Arbeitsdefinition im Ausschuss widerlegt")
	run("move", {"to": "innenhof"})
	run("open_case")
	for step in [["request_document", {"document_id": "bench_inventory"}], ["request_document", {"document_id": "repair_record"}], ["wait"]]:
		run(step[0], step[1] if step.size() > 1 else {})
	run("compare", {"evidence": ["B-02", "D-01"]})
	var text := Bank01.help_missing(s)
	assert_false(text.contains("Reparaturzettel"), "was vorliegt, fehlt nicht")
	assert_false(text.contains("Befristete Ausnahme"), "für die Ausnahme liegt alles vor")
	assert_string_contains(text, "widerlegt")


func test_help_costs_no_action_and_changes_nothing() -> void:
	s = Bank01.new_state()
	run("move", {"to": "innenhof"})
	run("open_case")
	var before := s.duplicate(true)
	Bank01.help_missing(s)
	Bank01.help_requested(s)
	Bank01.help_when(s, "O-01")
	assert_true(s == before)


func test_help_requested_reports_only_own_actions() -> void:
	s = Bank01.new_state()
	assert_eq(Bank01.help_requested(s), Bank01.content()["help"]["requested_none"])
	run("move", {"to": "innenhof"})
	run("open_case")
	run("move", {"to": "registratur"})
	run("request_document", {"document_id": "bench_inventory"})
	run("observe")
	var text := Bank01.help_requested(s)
	assert_string_contains(text, "Registratur: angefordert, beobachtet")
	assert_false(text.contains("Hausdienst"), "keine Stelle, die der Spieler nie angesprochen hat")
	assert_false(text.contains("Aufmerksamkeit"), "keine interne Anzeige")
	assert_false(text.contains("informiert"), "keine Benachrichtigung zwischen Stellen")
	run("move", {"to": "hausdienst"})
	run("interview", {"actor": "mertens", "topic": "bank"})
	assert_string_contains(Bank01.help_requested(s), "Hausdienst: befragt")


func test_help_when_names_source_and_time() -> void:
	s = Bank01.new_state()
	assert_eq(Bank01.help_when(s, "B-01"), Bank01.content()["help"]["when_none"])
	run("move", {"to": "innenhof"})
	run("open_case")
	run("move", {"to": "hausdienst"})
	run("interview", {"actor": "mertens", "topic": "bank"})
	var text := Bank01.help_when(s, "B-01")
	assert_string_contains(text, "Reparaturzettel mit Freigabe")
	assert_string_contains(text, "Tag 1, Handlung 1")
	assert_string_contains(text, "Herr Mertens")


# --- Akte (Kap. 13.1) ---

func test_official_summary_differs_from_what_happened() -> void:
	s = Bank01.new_state()
	assert_eq(Bank01.official_summary(s), Bank01.content()["official"]["open"])
	run("move", {"to": "innenhof"})
	run("open_case")
	run("move", {"to": "hausdienst"})
	run("request_help", {"actor": "mertens"})
	run("move", {"to": "innenhof"})
	run("observe")
	run("close_case")
	assert_eq(Bank01.official_summary(s), "Vorläufige Auslagerung eines Sitzmittels abgeschlossen. Sperrung unverändert.")
	var section := LatteAkte.vorgang_section(s)
	var lines: Array = section["zeilen"]
	assert_true(lines.any(func(l: String) -> bool: return l.begins_with("Amtlich: Vorläufige Auslagerung")))
	assert_has(lines, "Tatsächlich: Frau Kern sitzt auf einem Klappstuhl.")
	assert_eq(s["objects"]["bench"]["access"], "blocked", "intern bleibt das Ereignis erhalten")


func test_akte_section_empty_and_formal() -> void:
	assert_eq(LatteAkte.vorgang_section({})["zeilen"], ["Noch kein Vorgang eröffnet."])
	assert_eq(LatteAkte.vorgang_section(Bank01.new_state())["zeilen"], ["Noch kein Vorgang eröffnet."])
	s = Bank01.new_state()
	for step in [["move", {"to": "innenhof"}], ["open_case"], ["request_document", {"document_id": "bench_inventory"}],
			["request_document", {"document_id": "repair_record"}], ["wait"], ["compare", {"evidence": ["B-02", "D-01"]}],
			["end_day"], ["end_evening"], ["move", {"to": "ausschussraum"}], ["start_minigame", {"game": "widerlegung"}]]:
		run(step[0], step[1] if step.size() > 1 else {})
	run("minigame_result", {"result": Bank01.dev_result(s, "won")})
	run("submit", {"antrag": "formal", "findings": ["B-01", "B-02", "B-03"], "conclusion": "keine", "open_questions": ["keine"], "wording": "Sitzgelegenheiten müssen zugänglich sein."})
	run("advance")
	var lines: Array = LatteAkte.vorgang_section(s)["zeilen"]
	assert_true(lines.any(func(l: String) -> bool: return l.contains("Prüfanforderung PA-12 erlassen")))
	assert_has(lines, "Widerlegung: Arbeitsdefinition widerlegt")
	assert_has(lines, "Aus diesem Vorgang erlassen: PA-12 (BANK-01)")
	assert_has(lines, "Diensthandlungen: 3 von 8 verbraucht")
