# PURPOSE: Klickprototyp BANK-01 (amt/vorgang): Knöpfe gehen über den Weltkern, Stand bleibt beim Wiedereintritt, das Formular nennt fehlende Belege,
# PURPOSE: Minispiel-Platzhalter nur in der Entwicklungsansicht, ein nicht ladbarer Stand wird gemeldet und beiseitegelegt statt überschrieben.
# ARCHITECTURE: test
# DEPENDENCIES: amt/vorgang.tscn, Bank01, BankWiderlegung, AmtStore
# PIPELINE: test
# LAST_VALIDATED: 2026-10-18
extends GutTest

const SAVE := "user://test_vorgang_ui.json"


func before_each() -> void:
	for p in [SAVE, AmtStore.prev_path(SAVE), SAVE + ".alt", SAVE + ".bak"]:
		JsonStore.remove(p)


func _scene(dev: bool = true) -> Control:
	var v: Control = load("res://amt/vorgang.tscn").instantiate()
	v.store_path = SAVE
	v.dev_mode = dev
	add_child_autofree(v)
	return v


func _button(v: Control, text: String) -> Button:
	for b in v.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _press(v: Control, text: String) -> void:
	var b := _button(v, text)
	assert_not_null(b, "Knopf »%s«" % text)
	if b != null:
		b.pressed.emit()


func _steps(v: Control, steps: Array) -> void:
	for step in steps:
		var r: Dictionary = v.run(step[0], step[1] if step.size() > 1 else {})
		assert_true(r["ok"], "%s: %s" % [step[0], r.get("reason", "")])


func test_buttons_drive_the_case_and_state_survives_reentry() -> void:
	var v := _scene()
	assert_eq(v.state["phase"], "tag1")
	assert_string_contains(v._status.text, "noch keine Prüfung")
	v.run("move", {"to": "innenhof"})
	_press(v, "Sperrung klären (Prüfung eröffnen)")
	assert_eq(v.state["cases"]["BANK-01"]["status"], "open")
	assert_string_contains(v._status.text, "8 von 8")
	assert_string_contains(v._message.text, "Antrag auf Prüfung angenommen")
	_press(v, "Umsehen (1)")
	assert_string_contains(v._status.text, "7 von 8")
	var again := _scene()
	assert_eq(again.state["cases"]["BANK-01"]["status"], "open", "gespeichert nach jeder Handlung")
	assert_eq(int(again.state["cases"]["BANK-01"]["hours_remaining"]), 7)


func test_refused_action_shows_reason_and_changes_nothing() -> void:
	var v := _scene()
	var before: Dictionary = v.state.duplicate(true)
	var r: Dictionary = v.run("observe")
	assert_false(r["ok"])
	assert_string_contains(v._message.text, "eröffneten Prüfung")
	assert_true(v.state == before)


func test_primary_actions_are_capped_and_targets_large_enough() -> void:
	var v := _scene()
	_steps(v, [["move", {"to": "innenhof"}], ["open_case"], ["move", {"to": "hausdienst"}],
		["request_document", {"document_id": "bench_inventory"}], ["wait"]])
	var plain: Array = v._actions.get_children().filter(func(c: Node) -> bool: return c is Button and not (c is MenuButton))
	assert_lte(plain.size(), 4, "höchstens vier primäre Handlungen")
	assert_not_null(_button(v, "Weitere … ▾"), "der Rest in einer Unterauswahl")
	for c in v._actions.get_children():
		assert_gte((c as Control).custom_minimum_size.y, 44.0)


func test_form_names_missing_evidence_and_keeps_open_on_refusal() -> void:
	var v := _scene()
	_steps(v, [["move", {"to": "innenhof"}], ["open_case"], ["request_document", {"document_id": "bench_inventory"}],
		["wait"], ["end_day"], ["end_evening"]])
	v.open_form()
	v._f_antrag.select(0)
	v._update_form()
	assert_eq(v.form_params()["antrag"], "formal")
	assert_string_contains(v._f_req.text, "fehlt: Reparaturzettel mit Freigabe (B-01)")
	assert_string_contains(v._f_req.text, "liegt vor: Bestandseintrag »Exponat« (B-02)")
	var r: Dictionary = v.submit_form()
	assert_false(r["ok"])
	assert_true(v._form.visible, "Formular bleibt offen")
	assert_ne(v._f_error.text, "")
	v._f_antrag.select(2)
	v._update_form()
	r = v.submit_form()
	assert_true(r["ok"], str(r.get("reason", "")))
	assert_false(v._form.visible)
	assert_eq(v.state["phase"], "rueckkehr")
	assert_not_null(_button(v, "Vorgang ▾"))


func test_minigame_placeholder_only_in_dev_mode() -> void:
	var player := _scene(false)
	_steps(player, [["move", {"to": "innenhof"}], ["open_case"], ["end_day"]])
	assert_null(_button(player, "Mit Mertens spielen (DAME)"), "ohne Entwicklungsansicht kein Platzhalter-Spiel")
	assert_not_null(_button(player, "Mit Mertens über die Bank sprechen"))
	var dev := _scene(true)
	_press(dev, "Mit Mertens spielen (DAME)")
	assert_false(Bank01.running_session(dev.state).is_empty())
	assert_not_null(_button(dev, "Partie abbrechen"))
	_press(dev, "[Entwicklung] gewonnen")
	assert_eq(dev.state["actors"]["mertens"]["commitments"]["stuhl"]["quelle"], "dame")


func test_unloadable_save_is_reported_and_set_aside() -> void:
	var foreign := Bank01.new_state()
	foreign["content_version"] = "bank_01@0"
	JsonStore.write_json(SAVE, foreign)
	var v := _scene()
	assert_true(v.state.is_empty())
	assert_string_contains(v._scene.text, "anderen Fassung")
	assert_true(FileAccess.file_exists(SAVE), "nicht still überschrieben")
	_press(v, "Alten Stand beiseitelegen und neu beginnen")
	assert_true(FileAccess.file_exists(SAVE + ".alt"))
	assert_eq(v.state["content_version"], Bank01.CONTENT_VERSION)


func _to_hearing(v: Control) -> void:
	_steps(v, [["move", {"to": "innenhof"}], ["open_case"], ["request_document", {"document_id": "bench_inventory"}],
		["request_document", {"document_id": "repair_record"}], ["wait"], ["compare", {"evidence": ["B-02", "D-01"]}],
		["end_day"], ["end_evening"], ["move", {"to": "ausschussraum"}]])


func _pick(panel: PanelContainer) -> String:
	var hand: Array = panel.hand_ids()
	for id in hand:
		if WiderlegungRules.judge(panel._lehre["card_map"][id], panel._run["inst"]["lehre"]) != "confirm":
			return str(id)
	return str(hand[0])


func test_hearing_opens_the_real_panel_and_resumes_after_reload() -> void:
	var v := _scene(true)
	_to_hearing(v)
	_press(v, "Einstufung anfechten (Widerlegung)")
	assert_true(v._panel.visible, "das Panel öffnet sich")
	assert_eq(v._panel.lehre_id(), BankWiderlegung.LEHRE_ID)
	v._panel.play_card(_pick(v._panel))
	v._panel.play_card(_pick(v._panel))
	var hand: Array = v._panel.hand_ids()
	assert_eq((Bank01.running_session(v.state)["checkpoint"]["plays"] as Array).size(), 2)
	# App neu gestartet: Der Vorgang bietet die laufende Partie an, mit derselben Hand.
	var again := _scene(true)
	assert_false(again._panel.visible)
	assert_string_contains(again._session_box.get_child(0).text, "Gespielte Karten: 2")
	_press(again, "Partie fortsetzen")
	assert_true(again._panel.visible)
	assert_eq(again._panel.hand_ids(), hand, "Fortsetzen ergibt denselben Stand")
	var guard := 0
	while again._panel.is_playing() and guard < 30:
		again._panel.play_card(_pick(again._panel))
		guard += 1
	assert_false(again._panel.is_playing())
	again._panel.close()
	assert_true(Bank01.running_session(again.state).is_empty(), "Ergebnis verbucht")
	assert_ne(again.state["cases"]["BANK-01"]["definition"], "")
	assert_false(again._panel.visible)


func test_panel_without_objection_buttons_in_the_scene() -> void:
	var v := _scene(true)
	_to_hearing(v)
	_press(v, "Einstufung anfechten (Widerlegung)")
	for b in v._panel.find_children("*", "Button", true, false):
		if (b as Button).text == "!":
			assert_false((b as Button).visible)
