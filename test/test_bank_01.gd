# PURPOSE: Vorgang BANK-01 (Spezifikation 0.1, Kap. 9, 10, 20.1): Übergänge T-01 bis T-08, Beispielpfade A/B/C und die Regeltests QA-01 bis QA-17,
# PURPOSE: soweit sie ohne echte Minispiele prüfbar sind (E1: Ergebnisse kommen aus Bank01.dev_result).
# ARCHITECTURE: test
# DEPENDENCIES: Bank01, AmtWorld, AmtStore
# PIPELINE: test
# LAST_VALIDATED: 2026-10-18
extends GutTest

const SAVE := "user://test_bank_01.json"
const WORDING := "Sitzgelegenheiten müssen zugänglich sein."

var s: Dictionary


func before_each() -> void:
	s = Bank01.new_state()
	for p in [SAVE, AmtStore.prev_path(SAVE)]:
		JsonStore.remove(p)


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
	assert_true(r["state"] == before, "abgelehnter Befehl ändert nichts")
	return str(r["reason"])


func go(to: String) -> void:
	if s["location"] != to:
		run("move", {"to": to})


func open_case() -> void:
	go("innenhof")
	run("open_case")


func dev(outcome: String) -> void:
	run("minigame_result", {"result": Bank01.dev_result(s, outcome)})


func c() -> Dictionary:
	return s["cases"]["BANK-01"]


func has_ev(id: String) -> bool:
	return Bank01.has_ev(s, id)


func types() -> Array:
	return (s["events"] as Array).map(func(e: Dictionary) -> String: return e["type"])


func events_of(type: String) -> Array:
	return (s["events"] as Array).filter(func(e: Dictionary) -> bool: return e["type"] == type)


## Pfad A, Untersuchung (Kap. 10.3): fünf Handlungen, B-01 bis B-03, B-05, B-06.
func investigate_a() -> void:
	open_case()
	run("observe")
	go("hausdienst")
	run("interview", {"actor": "mertens", "topic": "bank"})
	run("request_document", {"document_id": "bench_inventory"})
	go("registratur")
	run("observe")
	run("compare", {"evidence": ["B-02", "D-01"]})
	run("interview", {"actor": "seidel", "topic": "bank"})


func to_tag2() -> void:
	run("end_day")
	run("end_evening")


func win_hearing() -> void:
	go("ausschussraum")
	run("start_minigame", {"game": "widerlegung"})
	dev("won")


func submit(antrag: String, findings: Array, conclusion: String = "keine", questions: Array = ["keine"], wording: String = "") -> void:
	run("submit", {"antrag": antrag, "findings": findings, "conclusion": conclusion, "open_questions": questions, "wording": wording})


# --- Beispielpfade (Kap. 10.3) ---

func test_path_a_formal_release_and_followup() -> void:
	investigate_a()
	for id in ["B-01", "B-02", "B-03", "B-05", "B-06"]:
		assert_true(has_ev(id), id)
	assert_eq(int(c()["hours_remaining"]), 3, "fünf Handlungen verbraucht")
	to_tag2()
	win_hearing()
	submit("formal", ["B-01", "B-02", "B-03"], "zweck_gegen_einstufung", ["zustaendigkeit"], WORDING)
	assert_eq(s["phase"], "rueckkehr", "erst der Hof, dann der Nachgang")
	assert_eq(s["location"], "innenhof")
	assert_eq(s["actors"]["kern"]["seat"], "bench", "Frau Kern sitzt auf der Bank")
	assert_eq(s["objects"]["bench"]["access"], "open")
	assert_eq(s["objects"]["bench"]["inventory_class"], "public_seating")
	assert_eq(s["rules"].size(), 0, "die Regel entsteht erst im Nachgang")
	run("advance")
	assert_eq(s["rules"].size(), 1)
	var rule: Dictionary = s["rules"][0]
	assert_eq(rule["herkunft"], "BANK-01")
	assert_eq(rule["begruendung"], WORDING)
	assert_true(has_ev("B-07"), "eigener Satz mit Fallnummer als Dokument")
	assert_string_contains(str(s["objects"]["hof_schild"]["text"]), "BANK-01")
	assert_eq(s["objects"]["bench"]["access"], "open", "die freigegebene Bank bleibt nutzbar")
	assert_true(AmtWorld.causality_errors(s).is_empty())


func test_path_b_chair_only() -> void:
	open_case()
	go("hausdienst")
	run("request_help", {"actor": "mertens"})
	assert_false(s["objects"]["chair"]["available"], "Lieferung erst nach der nächsten Handlung")
	go("innenhof")
	run("observe")
	assert_true(s["objects"]["chair"]["available"])
	assert_eq(s["actors"]["kern"]["seat"], "chair")
	run("close_case")
	assert_eq(c()["resolution"], "replacement_chair")
	assert_eq(s["objects"]["bench"]["access"], "blocked", "die Bank bleibt gesperrt")
	run("advance")
	assert_true((s["documents"] as Dictionary).has("return_slip"), "Rückgabezettel")
	assert_eq(s["actors"]["mertens"]["commitments"]["stuhl"]["status"], "rueckgabe_erbeten", "begrenzte Beziehungsspur")
	assert_eq(s["rules"].size(), 0, "keine neue Zugänglichkeitsregel")


func test_path_c_exception() -> void:
	open_case()
	go("hausdienst")
	run("interview", {"actor": "mertens", "topic": "bank"})
	run("request_document", {"document_id": "bench_inventory"})
	run("observe")
	to_tag2()
	submit("ausnahme", ["B-01", "B-02"], "bestand_nicht_abgeglichen", ["kunst"])
	assert_eq(c()["report"]["conclusion_status"], "belegt")
	assert_eq(s["actors"]["kern"]["seat"], "bench")
	assert_eq(s["objects"]["bench"]["access"], "temporary")
	assert_eq(s["objects"]["bench"]["inventory_class"], "exhibit", "der Eintrag »Exponat« bleibt")
	run("advance")
	assert_true(bool(c()["exception_review"]), "Ausnahme als überprüfungsbedürftig vermerkt")
	assert_true((s["documents"] as Dictionary).has("renewal_reminder"))
	assert_eq(s["rules"].size(), 0)


# --- Übergänge (Kap. 10.1) ---

func test_t01_open_case() -> void:
	assert_string_contains(refuse("observe"), "eröffneten Prüfung")
	assert_string_contains(refuse("open_case"), "Innenhof")
	open_case()
	assert_eq(c()["status"], "open")
	assert_eq(int(c()["hours_remaining"]), 8)
	refuse("open_case")
	assert_eq(s["rules"].size(), 0, "keine automatische Verordnung")


func test_t02_repair_proof_does_not_change_inventory() -> void:
	open_case()
	go("hausdienst")
	run("interview", {"actor": "mertens", "topic": "bank"})
	assert_true(has_ev("B-01"))
	assert_eq(s["objects"]["bench"]["inventory_class"], "exhibit")
	assert_eq(s["objects"]["bench"]["access"], "blocked")


func test_t03_compare_by_inventory_number_is_free() -> void:
	open_case()
	run("request_document", {"document_id": "bench_inventory"})
	run("wait")
	var hours := int(c()["hours_remaining"])
	assert_false(has_ev("B-03"))
	run("compare", {"evidence": ["D-01", "B-02"]})
	assert_true(has_ev("B-03"))
	assert_eq(int(c()["hours_remaining"]), hours, "Vergleichen kostet keine Handlung")
	assert_eq(s["evidence"]["B-03"]["kind"], "abgleich")


func test_t06_dame_favor_then_exception_returns_chair() -> void:
	open_case()
	go("hausdienst")
	run("interview", {"actor": "mertens", "topic": "bank"})
	run("request_document", {"document_id": "bench_inventory"})
	run("end_day")
	run("start_minigame", {"game": "dame"})
	dev("won")
	assert_eq(s["actors"]["mertens"]["commitments"]["stuhl"]["quelle"], "dame")
	assert_false(s["objects"]["chair"]["available"], "der Stuhl kommt am nächsten Morgen")
	run("end_evening")
	assert_true(s["objects"]["chair"]["available"])
	submit("ausnahme", ["B-01"])
	assert_false(s["objects"]["chair"]["available"], "nach der Freigabe zurückgestellt")
	assert_eq(s["actors"]["mertens"]["commitments"]["stuhl"]["status"], "zurueckgestellt", "die Hilfe bleibt erinnert")
	assert_eq(c()["resolution"], "temporary_exception")


func test_t07_close_without_solution() -> void:
	open_case()
	run("observe")
	run("close_case")
	assert_eq(c()["resolution"], "unresolved")
	assert_eq(s["actors"]["kern"]["seat"], "", "Frau Kern steht weiter")
	assert_string_contains(Bank01.kern_line(s), "steh")
	run("advance")
	assert_true((s["documents"] as Dictionary).has("filing_note"), "bleibt in der Zuständigkeit des Amts")
	assert_eq(s["rules"].size(), 0)


func test_t08_unproven_suspicion_gets_inquiry_and_correction() -> void:
	open_case()
	go("hausdienst")
	run("interview", {"actor": "mertens", "topic": "bank"})
	run("request_document", {"document_id": "bench_inventory"})
	go("registratur")
	run("observe")
	assert_true(has_ev("B-06"))
	assert_false(has_ev("B-05"))
	to_tag2()
	submit("ausnahme", ["B-01", "B-02", "B-06"], "verschleierung", ["originale"])
	assert_eq(c()["report"]["conclusion_status"], "vermutung", "als Vermutung gekennzeichnet")
	run("advance")
	assert_eq(c()["report"]["inquiry"], "offen", "Nachfrage der Registratur, kein Schuldspruch")
	assert_true(has_ev("B-05"), "das Verfahrensblatt kommt als Anlage")
	assert_eq(s["evidence"]["B-05"]["source_id"], "seidel")
	run("correct_report", {"conclusion": "umlagerung_regulaer", "findings": ["B-05", "B-06"]})
	assert_eq(c()["report"]["inquiry"], "beantwortet")
	assert_eq(c()["report"]["conclusion_status"], "belegt")
	refuse("correct_report", {"conclusion": "keine"})


func test_t08_needs_b06_and_no_b05() -> void:
	investigate_a()
	to_tag2()
	submit("keiner", ["B-06"], "verschleierung", ["zustaendigkeit"])
	run("advance")
	assert_does_not_have(c()["applied_followups"], "fu_registry_inquiry", "mit B-05 keine Rückfrage")
	assert_eq(c()["report"]["conclusion_status"], "vermutung")


# --- Regeltests (Kap. 20.1) ---

func _script_a() -> Array:
	return [
		["move", {"to": "innenhof"}], ["open_case", {}], ["observe", {}], ["move", {"to": "hausdienst"}],
		["interview", {"actor": "mertens", "topic": "bank"}], ["request_document", {"document_id": "bench_inventory"}],
		["move", {"to": "registratur"}], ["observe", {}], ["compare", {"evidence": ["B-02", "D-01"]}],
		["interview", {"actor": "seidel", "topic": "bank"}], ["end_day", {}], ["start_minigame", {"game": "dame"}],
	]


func test_qa01_same_actions_same_state() -> void:
	var states := []
	for i in 2:
		s = Bank01.new_state()
		for step in _script_a():
			run(step[0], step[1])
		dev("won")
		run("end_evening")
		states.append(s)
	assert_true(states[0] == states[1], "identischer regelrelevanter Zustand")


func test_qa02_same_command_id_twice() -> void:
	open_case()
	var cmd := Bank01.command(s, "request_document", {"document_id": "bench_inventory"})
	var first := AmtWorld.execute(s, cmd, Bank01)
	var second := AmtWorld.execute(first["state"], cmd, Bank01)
	assert_true(second["ok"])
	assert_true(second["duplicate"])
	assert_eq(second["events"].size(), 0)
	assert_eq(int(second["state"]["cases"]["BANK-01"]["hours_remaining"]), 7, "nur eine Handlung verbraucht")


func test_qa03_no_request_no_file_move() -> void:
	open_case()
	run("observe")
	go("registratur")
	run("observe")
	run("interview", {"actor": "seidel", "topic": "bank"})
	run("wait")
	run("end_day")
	assert_eq(s["objects"]["originals"]["location"], "regal")
	assert_does_not_have(types(), "audit_announced")
	assert_does_not_have(types(), "originals_moved")
	assert_false(has_ev("B-05"), "ohne Anforderung kein Verfahrensblatt von Seidel")


func test_qa04_move_is_timed_one_action_later() -> void:
	open_case()
	run("request_document", {"document_id": "bench_inventory"})
	assert_eq(s["objects"]["originals"]["location"], "regal", "nicht im selben Zug der Ankündigung")
	assert_true((s["pending_events"] as Dictionary).has("move_originals"))
	run("observe")
	assert_eq(s["objects"]["originals"]["location"], "pruefschrank")
	assert_eq(int(events_of("originals_moved")[0]["turn"]), 2)
	assert_eq(int(events_of("audit_announced")[0]["turn"]), 1)
	assert_false(has_ev("B-05"), "Begründung erst mit erworbener Quelle")
	assert_false(has_ev("B-06"), "im Hof gesehen wird nichts aus der Registratur")


func test_qa05_ninth_action_refused_and_late_delivery_arrives() -> void:
	open_case()
	for i in 7:
		run("wait")
	run("request_document", {"document_id": "repair_record"})
	assert_eq(int(c()["hours_remaining"]), 0)
	assert_string_contains(refuse("observe"), "Keine Diensthandlungen")
	assert_false((s["documents"] as Dictionary).has("repair_slip"))
	run("end_day")
	assert_true((s["documents"] as Dictionary).has("repair_slip"), "ausstehende Akte wird geliefert")
	assert_true(has_ev("B-01"))


func test_qa06_formal_release_one_rule_with_origin() -> void:
	investigate_a()
	to_tag2()
	win_hearing()
	submit("formal", ["B-01", "B-02", "B-03"], "keine", ["keine"], WORDING)
	run("advance")
	assert_eq(s["rules"].size(), 1)
	var origins: Array = s["rules"][0]["origin_event_ids"]
	assert_false(origins.is_empty())
	var ids := (s["events"] as Array).map(func(e: Dictionary) -> String: return e["event_id"])
	for o in origins:
		assert_has(ids, o, "Herkunft verweist auf ein vorhandenes Ereignis")
	assert_eq(events_of("rule_issued").size(), 1)


func test_qa07_exception_or_chair_never_create_the_rule() -> void:
	investigate_a()
	to_tag2()
	win_hearing()
	submit("ausnahme", ["B-01", "B-02"])
	run("advance")
	assert_eq(s["rules"].size(), 0, "Ausnahme trotz gewonnener Widerlegung: keine Regel")
	assert_does_not_have(c()["scheduled_followups"], "fu_accessibility_rule")


func test_qa08_won_hearing_without_repair_proof_releases_nothing() -> void:
	open_case()
	run("request_document", {"document_id": "bench_inventory"})
	run("wait")
	run("compare", {"evidence": ["B-02", "D-01"]})
	to_tag2()
	win_hearing()
	assert_eq(c()["definition"], "won")
	var reason := refuse("submit", {"antrag": "formal", "findings": ["B-02", "B-03"], "conclusion": "keine", "open_questions": ["keine"], "wording": WORDING})
	assert_string_contains(reason, "B-01")
	assert_eq(s["objects"]["bench"]["access"], "blocked")


func test_qa09_lost_aborted_or_missing_minigame_still_completes() -> void:
	investigate_a()
	to_tag2()
	go("ausschussraum")
	run("start_minigame", {"game": "widerlegung"})
	refuse("move", {"to": "innenhof"})
	dev("aborted")
	assert_eq(c()["definition"], "", "Abbruch verbucht weder Sieg noch Niederlage")
	assert_eq(s["location"], "ausschussraum", "Szene wie vor der Partie")
	run("start_minigame", {"game": "widerlegung"})
	dev("lost")
	assert_eq(c()["definition"], "lost")
	refuse("start_minigame", {"game": "widerlegung"})
	assert_string_contains(refuse("submit", {"antrag": "formal", "findings": [], "conclusion": "keine", "open_questions": ["keine"], "wording": WORDING}), "widerlegt")
	submit("ausnahme", ["B-01", "B-02"])
	assert_eq(c()["resolution"], "temporary_exception", "nach Niederlage befristete Ausnahme")
	# Ganz ohne Minispiel: Abschluss bleibt erreichbar.
	s = Bank01.new_state()
	open_case()
	run("end_day")
	run("end_evening")
	run("close_case")
	assert_eq(s["phase"], "rueckkehr")


func test_qa10_at_most_one_favor() -> void:
	open_case()
	run("end_day")
	run("start_minigame", {"game": "dame"})
	var result := Bank01.dev_result(s, "won")
	dev("won")
	# Dasselbe Ergebnis erneut (neue Befehlskennung) und nach Speichern/Laden.
	assert_string_contains(refuse("minigame_result", {"result": result}), "bereits verbucht")
	assert_true(AmtStore.save(s, SAVE))
	s = AmtStore.load_state(SAVE, Bank01.CONTENT_VERSION)["state"]
	refuse("minigame_result", {"result": result})
	run("start_minigame", {"game": "dame"})
	dev("won")
	assert_eq(events_of("favor_promised").size(), 1)
	run("end_evening")
	assert_eq(events_of("chair_delivered").size(), 1)
	# Hilfe schon am Tag erbeten: Ein DAME-Sieg bringt keinen zweiten Vorteil.
	s = Bank01.new_state()
	open_case()
	go("hausdienst")
	run("request_help", {"actor": "mertens"})
	run("end_day")
	run("start_minigame", {"game": "dame"})
	dev("won")
	assert_eq(events_of("favor_promised").size(), 0)
	assert_eq(s["actors"]["mertens"]["commitments"]["stuhl"]["quelle"], "tag")


func test_qa11_actor_without_information_does_not_know() -> void:
	open_case()
	go("hausdienst")
	run("interview", {"actor": "mertens", "topic": "bank"})
	var first := str(events_of("interviewed")[0]["payload"]["text"])
	assert_false(first.contains("Prüfung. Hat sich"), "Mertens weiß noch nichts")
	assert_false(Bank01.knows(s, "mertens", "pruefung_bekannt"))
	run("request_document", {"document_id": "bench_inventory"})
	go("registratur")
	run("interview", {"actor": "seidel", "topic": "bank"})
	assert_true(Bank01.knows(s, "mertens", "pruefung_bekannt"), "die Registratur informiert den Hausdienst ab Stufe 2")
	assert_eq(s["objects"]["originals"]["location"], "pruefschrank", "die Umlagerung lief während der Befragung")
	assert_false(has_ev("B-06"), "wer Seidel befragt, beobachtet nicht: keine Augenzeugenschaft")
	go("hausdienst")
	run("interview", {"actor": "mertens", "topic": "bank"})
	var later := str(events_of("interviewed").back()["payload"]["text"])
	assert_string_contains(later, "Hat sich schon rumgesprochen")
	var entry: Array = (s["knowledge"] as Array).filter(func(k: Dictionary) -> bool: return k["observer_id"] == "mertens")
	var source: Array = (s["events"] as Array).filter(func(e: Dictionary) -> bool: return e["event_id"] == entry[0]["learned_from"])
	assert_eq(source[0]["type"], "office_informed")


func test_qa12_own_wording_is_used_verbatim() -> void:
	var own := "Wer wartet,\n darf sitzen."
	investigate_a()
	to_tag2()
	win_hearing()
	submit("formal", ["B-01", "B-02", "B-03"], "keine", ["keine"], own)
	run("advance")
	var expected := Bank01.clean_wording(own)
	assert_eq(expected, "Wer wartet,  darf sitzen.")
	assert_eq(c()["application"]["wording"], expected)
	assert_eq(s["rules"][0]["begruendung"], expected)
	assert_string_contains(str(s["documents"]["rule_notice"]["text"]), "»%s«" % expected)


func test_qa13_load_after_every_phase_change() -> void:
	open_case()
	run("request_document", {"document_id": "bench_inventory"})
	go("registratur")
	run("observe")
	run("compare", {"evidence": ["B-02", "D-01"]})
	go("hausdienst")
	run("interview", {"actor": "mertens", "topic": "bank"})
	for step in [["end_day", {}], ["end_evening", {}], ["submit", {"antrag": "ausnahme", "findings": ["B-01"], "conclusion": "keine", "open_questions": ["keine"]}], ["advance", {}]]:
		run(step[0], step[1])
		assert_true(AmtStore.save(s, SAVE))
		var loaded := AmtStore.load_state(SAVE, Bank01.CONTENT_VERSION)
		assert_eq(loaded["error"], "", step[0])
		assert_true(loaded["state"] == s, "Stand nach %s identisch" % step[0])
		assert_eq(loaded["state"]["location"], s["location"])
		s = loaded["state"]
	assert_eq(c()["resolution"], "temporary_exception")


func test_qa14_foreign_or_manipulated_results_are_rejected() -> void:
	investigate_a()
	to_tag2()
	go("ausschussraum")
	run("start_minigame", {"game": "widerlegung"})
	var good := Bank01.dev_result(s, "won")
	var bad := {
		"Session": {"session_id": "session-fremd"},
		"Spiel": {"game": "dame"},
		"Vorgang": {"case_id": "BANK-02"},
		"Regelversion": {"ruleset_version": "huhn-port-v0"},
		"Befund": {"facts": {"definition_collapsed": false}},
		"Status": {"status": "gewonnen"},
		"Ausgang": {"outcome": "remis"},
	}
	for name in bad:
		var r := good.duplicate(true)
		r.merge(bad[name], true)
		refuse("minigame_result", {"result": r})
	refuse("minigame_result", {"result": "won"})
	# Effektlisten werden nie ausgeführt; nur der Ausgang zählt.
	var with_effects := good.duplicate(true)
	with_effects["effects"] = [{"op": "set", "path": ["objects", "bench", "access"], "value": "open"}]
	run("minigame_result", {"result": with_effects})
	assert_eq(c()["definition"], "won")
	assert_eq(s["objects"]["bench"]["access"], "blocked")


func test_qa15_courtyard_shows_current_outcome() -> void:
	investigate_a()
	to_tag2()
	win_hearing()
	submit("formal", ["B-01", "B-02", "B-03"], "keine", ["keine"], WORDING)
	var sc: Dictionary = Bank01.content()["scene"]
	assert_string_contains(Bank01.scene(s)["text"], sc["bench_open"])
	assert_string_contains(Bank01.scene(s)["text"], sc["kern_bench"])
	run("advance")
	go("vorhalle")
	go("innenhof")
	var text: String = Bank01.scene(s)["text"]
	assert_string_contains(text, sc["bench_open"])
	assert_string_contains(text, "BANK-01")
	assert_string_contains(text, sc["neuer_stuhl"])
	assert_false(text.contains(sc["bench_blocked"]))


func test_qa16_followup_never_runs_twice() -> void:
	investigate_a()
	to_tag2()
	win_hearing()
	submit("formal", ["B-01", "B-02", "B-03"], "keine", ["keine"], WORDING)
	run("advance")
	refuse("advance")
	# Dieselbe Folge erneut einspeisen: Die Regel greift nicht ein zweites Mal.
	var tx := AmtTransaction.new(s.duplicate(true), Bank01.command(s, "advance"))
	var pending := AmtWorld.pending_entry("fu_accessibility_rule", "fu_accessibility_rule", {}, 0, "nachgang", "evt-bank01-001")
	Bank01._followup(tx, pending, "evt-bank01-001")
	assert_eq(tx.events.size(), 0)
	assert_eq(tx.state["rules"].size(), 1)


func test_qa17_elsewhere_during_move_gets_statement_not_observation() -> void:
	open_case()
	go("hausdienst")
	run("request_document", {"document_id": "bench_inventory"})
	run("interview", {"actor": "mertens", "topic": "bank"})
	assert_eq(s["objects"]["originals"]["location"], "pruefschrank")
	assert_false(has_ev("B-06"), "keine rückwirkende Augenzeugenschaft")
	go("registratur")
	run("observe")
	assert_false(has_ev("B-06"), "auch später gesehen: kein Eintrag als Augenzeuge")
	run("interview", {"actor": "seidel", "topic": "bank"})
	assert_true(has_ev("S-02"))
	assert_eq(s["evidence"]["S-02"]["kind"], "aussage")
	var entry: Array = Bank01.akte(s).filter(func(e: Dictionary) -> bool: return e["id"] == "S-02")
	assert_eq(entry[0]["art"], "Aussage")


# --- Dienstaufsicht (Kap. 8.4) ---

func test_attention_rules() -> void:
	open_case()
	go("registratur")
	run("observe")
	assert_eq(int(s["offices"]["registratur"]["attention"]), 0, "erste Beobachtung: keine Erhöhung")
	run("observe")
	assert_eq(int(s["offices"]["registratur"]["attention"]), 1, "weitere Beobachtung: +1")
	run("request_document", {"document_id": "procedure_sheet"})
	assert_eq(int(s["offices"]["registratur"]["attention"]), 3, "Anforderung +2, höchstens 3")
	go("innenhof")
	run("wait")
	assert_eq(int(s["offices"]["registratur"]["attention"]), 3)
	run("wait")
	assert_eq(int(s["offices"]["registratur"]["attention"]), 2, "nach zwei Handlungen ohne Kontakt -1")
	run("wait")
	assert_eq(int(s["offices"]["registratur"]["attention"]), 2)
	run("wait")
	assert_eq(int(s["offices"]["registratur"]["attention"]), 1)
	assert_true(has_ev("B-05"), "angefordertes Verfahrensblatt geliefert")


func test_observation_text_never_shows_later_alarm() -> void:
	open_case()
	run("request_document", {"document_id": "bench_inventory"})
	go("registratur")
	run("observe")
	var obs: Dictionary = events_of("observed").back()
	assert_eq(int(obs["payload"]["stufe"]), 2, "die Anforderung kam vorher an")
	assert_true(has_ev("B-06"), "beim Beobachten während der Umlagerung")
	var witnessed: Dictionary = events_of("witnessed")[0]
	var moved: Dictionary = events_of("originals_moved")[0]
	assert_eq(witnessed["caused_by"], [moved["event_id"]])
	assert_eq(int(s["evidence"]["B-06"]["observed_at"]["turn"]), 2, "zeitlich zugeordnet")


func test_report_validation() -> void:
	investigate_a()
	to_tag2()
	var base := {"antrag": "keiner", "findings": ["B-01"], "conclusion": "keine", "open_questions": ["keine"]}
	var cases := [
		[{"findings": ["B-01", "B-02", "B-03", "B-05"]}, "drei"],
		[{"findings": ["B-04"]}, "B-04"],
		[{"findings": ["B-01", "B-01"]}, "einmal"],
		[{"conclusion": "irgendwas"}, "Schlussfolgerung"],
		[{"open_questions": []}, "offene Frage"],
		[{"open_questions": ["keine", "zustaendigkeit"]}, "Entweder"],
		[{"open_questions": ["originale"]}, "ergibt sich"],
		[{"antrag": "formal", "wording": WORDING}, "widerlegt"],
	]
	for case in cases:
		var p := base.duplicate(true)
		p.merge(case[0], true)
		assert_string_contains(refuse("submit", p), case[1])
	submit("keiner", ["B-01"])
	assert_eq(c()["resolution"], "unresolved")
	refuse("submit", base)
