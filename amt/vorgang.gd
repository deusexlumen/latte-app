# PURPOSE: Vorgang BANK-01 als schlichter Klickprototyp (Etappe E1, Kap. 19): Ort, Personen, Handlungen, Aktenkoffer, Einreichung.
# PURPOSE: Jede Handlung geht als Befehl an den Weltkern und wird danach gespeichert. Minispiel-Ausgänge setzt in E1 nur die Entwicklungsansicht.
# ARCHITECTURE: ui
# DEPENDENCIES: Bank01, AmtWorld, AmtStore
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
extends Control

## Bedienziele mindestens 44 × 44 logische Pixel (Kap. 12.3).
const MIN_TARGET := Vector2(44, 44)
const BG := Color(0.078, 0.09, 0.114)
const WARN := Color(0.95, 0.75, 0.4)
const PRIMARY_MAX := 4

## Tests setzen eigene Werte, bevor die Szene in den Baum kommt.
var store_path := AmtStore.default_path()
## Entwicklungsansicht: Minispiel-Platzhalter und interne Werte. Nie in Release-Builds (Kap. 16.7).
var dev_mode := OS.is_debug_build()
var state: Dictionary = {}

var _status: Label
var _restart: Button
var _retry_save: Button
var _place: Label
var _scene: Label
var _people: Label
var _message: Label
var _actions: HFlowContainer
var _tabs: TabContainer
var _akte: Label
var _docs: VBoxContainer
var _reader: Label
var _cmp_a: OptionButton
var _cmp_b: OptionButton
var _log: Label
var _dev_info: Label
var _session_box: VBoxContainer
var _form: Control
var _f_antrag: OptionButton
var _f_req: Label
var _f_wording_pick: OptionButton
var _f_wording: LineEdit
var _f_findings: VBoxContainer
var _f_conclusion: OptionButton
var _f_conclusion_status: Label
var _f_question: OptionButton
var _f_error: Label
var _load_problem := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build()
	var loaded := AmtStore.load_state(store_path, Bank01.CONTENT_VERSION)
	if not loaded["state"].is_empty():
		state = loaded["state"]
		if loaded["from_prev"]:
			_show_message("%s Der vorherige Stand wurde geladen." % loaded["error"], true)
	elif not loaded["error"].is_empty():
		_load_problem = loaded["error"]
	else:
		state = Bank01.new_state()
	refresh()


## Ein Befehl an den Weltkern. Abgelehnt: Grund anzeigen, nichts ändern. Angenommen: speichern, neu zeichnen.
func run(type: String, params: Dictionary = {}) -> Dictionary:
	if state.is_empty():
		return {"ok": false, "reason": "Kein Vorgang geladen."}
	var r := AmtWorld.execute(state, Bank01.command(state, type, params), Bank01)
	if not r["ok"]:
		_show_message(str(r["reason"]), true)
		return r
	state = r["state"]
	if not r["duplicate"]:
		_save()
	_show_message("\n\n".join(Bank01.visible_texts(r["events"])), false)
	refresh()
	return r


func refresh() -> void:
	_clear(_actions)
	if state.is_empty():
		_status.text = "Vorgang BANK-01"
		_place.text = "Spielstand nicht ladbar"
		_scene.text = _load_problem
		_people.text = ""
		_actions.add_child(_button("Alten Stand beiseitelegen und neu beginnen", _start_over))
		return
	_status.text = "BANK-01 · %s" % Bank01.status_line(state)
	var sc := Bank01.scene(state)
	_place.text = sc["name"]
	_scene.text = sc["text"]
	_people.text = "Anwesend: %s" % ", ".join(PackedStringArray(sc["people"]))
	_people.visible = not (sc["people"] as Array).is_empty()
	_build_actions()
	_build_akte()
	_build_session()
	_log.text = "\n\n".join(Bank01.visible_texts(state["events"]))
	if _dev_info != null:
		_dev_info.text = Bank01.dev_info(state)


## Primäre Handlungen als Knöpfe (höchstens vier), alles Weitere in benannten Menüs (Kap. 12.2).
func _build_actions() -> void:
	var groups := {"hier": [], "anfordern": [], "gehen": [], "vorgang": []}
	for a in Bank01.available_actions(state):
		if a["type"] == "start_minigame" and not dev_mode:
			continue  # In E1 gibt es noch kein echtes Minispiel; ohne Entwicklungsansicht nicht anbieten.
		groups[a["group"]].append(a)
	var here: Array = groups["hier"]
	for a in here.slice(0, PRIMARY_MAX):
		_actions.add_child(_button(a["label"], _act.bind(a)))
	var menus := [["Weitere …", here.slice(PRIMARY_MAX)], ["Akte anfordern", groups["anfordern"]],
		["Gehen nach", groups["gehen"]], ["Vorgang", groups["vorgang"]]]
	for m in menus:
		if (m[1] as Array).is_empty():
			continue
		var mb := MenuButton.new()
		mb.text = m[0] + " ▾"
		mb.flat = false
		mb.focus_mode = Control.FOCUS_ALL
		mb.custom_minimum_size = MIN_TARGET
		var popup := mb.get_popup()
		for i in (m[1] as Array).size():
			popup.add_item(m[1][i]["label"], i)
		popup.id_pressed.connect(func(i: int) -> void: _act(m[1][i]))
		_actions.add_child(mb)


func _act(a: Dictionary) -> void:
	if a["type"] == "submit_form":
		open_form()
	else:
		run(a["type"], a["params"])


func _build_akte() -> void:
	var lines := []
	for e in Bank01.akte(state):
		lines.append("[%s] %s\n%s · %s · %s\nBelegt: %s\nBelegt nicht: %s" % [e["id"], e["titel"], e["art"], e["quelle"], e["zeit"], e["belegt"], e["belegt_nicht"]])
	_akte.text = "\n\n".join(lines) if not lines.is_empty() else "Noch nichts im Aktenkoffer."
	_clear(_docs)
	for d in Bank01.documents(state):
		_docs.add_child(_button("Lesen: %s" % d["titel"], func() -> void: _reader.text = d["text"]))
	for ob in [_cmp_a, _cmp_b]:
		var keep: Variant = ob.get_selected_metadata() if ob.selected >= 0 else null
		ob.clear()
		for e in Bank01.akte(state):
			ob.add_item("%s %s" % [e["id"], e["titel"]])
			ob.set_item_metadata(ob.item_count - 1, e["id"])
			if e["id"] == keep:
				ob.select(ob.item_count - 1)
	if _cmp_b.item_count > 1 and _cmp_b.selected == _cmp_a.selected:
		_cmp_b.select((_cmp_a.selected + 1) % _cmp_b.item_count)


## Laufende Partie: In E1 ein Platzhalter. Abbrechen darf jeder, Ausgänge setzen nur Entwickler (Kap. 19.1).
func _build_session() -> void:
	_clear(_session_box)
	var session := Bank01.running_session(state)
	if session.is_empty():
		return
	var info := Label.new()
	info.text = "Partie läuft (%s). In dieser Fassung ist sie ein Platzhalter." % ("DAME" if session["game"] == "dame" else "Widerlegung")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_session_box.add_child(info)
	var row := HFlowContainer.new()
	_session_box.add_child(row)
	if dev_mode:
		row.add_child(_button("[Entwicklung] gewonnen", _dev_result.bind("won")))
		row.add_child(_button("[Entwicklung] verloren", _dev_result.bind("lost")))
	row.add_child(_button("Partie abbrechen", _dev_result.bind("aborted")))


func _dev_result(outcome: String) -> void:
	run("minigame_result", {"result": Bank01.dev_result(state, outcome)})


func _compare() -> void:
	if _cmp_a.selected < 0 or _cmp_b.selected < 0:
		_show_message("Erst zwei Einträge im Aktenkoffer haben.", true)
		return
	run("compare", {"evidence": [_cmp_a.get_selected_metadata(), _cmp_b.get_selected_metadata()]})


# --- Einreichung (Kap. 7.1, 9.7) ---

func open_form() -> void:
	_f_antrag.clear()
	for key in Bank01.content()["antraege"]:
		_f_antrag.add_item(Bank01.content()["antraege"][key]["label"])
		_f_antrag.set_item_metadata(_f_antrag.item_count - 1, key)
	_f_wording_pick.clear()
	for w in Bank01.content()["wordings"]:
		_f_wording_pick.add_item(w)
	_f_wording_pick.add_item("Eigene Formulierung …")
	_f_wording.text = Bank01.content()["wordings"][0]
	_clear(_f_findings)
	for e in Bank01.akte(state):
		var cb := CheckBox.new()
		cb.set_meta("id", e["id"])
		cb.set_meta("label", "%s %s" % [e["id"], e["titel"]])
		cb.custom_minimum_size = MIN_TARGET
		# DAMEs Theme hinterlegt gewählte Knöpfe golden; heller Text wäre darauf kaum lesbar.
		for key in ["font_pressed_color", "font_hover_pressed_color"]:
			cb.add_theme_color_override(key, BG)
		cb.toggled.connect(func(_on: bool) -> void: _update_form())
		_f_findings.add_child(cb)
	_f_conclusion.clear()
	for key in Bank01.content()["conclusions"]:
		_f_conclusion.add_item(Bank01.content()["conclusions"][key]["text"])
		_f_conclusion.set_item_metadata(_f_conclusion.item_count - 1, key)
	_f_conclusion.select(_f_conclusion.item_count - 1)
	_f_question.clear()
	for key in Bank01.available_open_questions(state):
		_f_question.add_item(Bank01.content()["open_questions"][key]["text"])
		_f_question.set_item_metadata(_f_question.item_count - 1, key)
	_f_error.text = ""
	_form.visible = true
	_update_form()
	_f_antrag.grab_focus()


func form_params() -> Dictionary:
	var findings := []
	for cb in _f_findings.get_children():
		if (cb as CheckBox).button_pressed:
			findings.append(cb.get_meta("id"))
	return {
		"antrag": _f_antrag.get_selected_metadata(),
		"wording": _f_wording.text,
		"findings": findings,
		"conclusion": _f_conclusion.get_selected_metadata(),
		"open_questions": [_f_question.get_selected_metadata()] if _f_question.selected >= 0 else [],
	}


func submit_form() -> Dictionary:
	var r := run("submit", form_params())
	if r["ok"]:
		_form.visible = false
	else:
		_f_error.text = str(r["reason"])
	return r


func _update_form() -> void:
	var p := form_params()
	var lines := []
	for req in Bank01.antrag_requirements(state, str(p["antrag"])):
		lines.append("%s %s" % ["liegt vor:" if req["ok"] else "fehlt:", req["label"]])
	_f_req.text = "\n".join(lines) if not lines.is_empty() else "Keine Voraussetzungen."
	var formal: bool = p["antrag"] == "formal"
	_f_wording_pick.visible = formal
	_f_wording.visible = formal
	_f_wording.editable = _f_wording_pick.selected == _f_wording_pick.item_count - 1
	var count: int = (p["findings"] as Array).size()
	for cb in _f_findings.get_children():
		var on := (cb as CheckBox).button_pressed
		(cb as CheckBox).disabled = count >= Bank01.MAX_FINDINGS and not on
		# Zustand auch als Text, nicht nur als Symbol des Themes (Kap. 12.3).
		(cb as CheckBox).text = "%s %s" % ["[x]" if on else "[ ]", cb.get_meta("label")]
	var status := Bank01.conclusion_status(state, p["findings"], str(p["conclusion"]))
	_f_conclusion_status.text = {"belegt": "Durch die gewählten Feststellungen belegt.", "vermutung": "Nicht belegt: wird als Vermutung eingereicht.", "ohne": ""}[status]


func _on_wording_pick(i: int) -> void:
	if i < _f_wording_pick.item_count - 1:
		_f_wording.text = _f_wording_pick.get_item_text(i)
	_update_form()


# --- Speichern ---

func _save() -> void:
	var ok := AmtStore.save(state, store_path)
	_retry_save.visible = not ok
	if not ok:
		_show_message("Speichern fehlgeschlagen. Der Stand ist nicht gesichert.", true)


func _start_over() -> void:
	AmtStore.archive(store_path)
	_load_problem = ""
	state = Bank01.new_state()
	_save()
	_show_message("Neuer Vorgang. Der bisherige Stand liegt als .alt-Datei beiseite.", false)
	refresh()


func _on_restart() -> void:
	if _restart.text != "Wirklich neu beginnen?":
		_restart.text = "Wirklich neu beginnen?"
		return
	_restart.text = "Neu beginnen"
	_form.visible = false
	_start_over()


# --- Aufbau ---

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	# Unten rechts liegt der Knopf "Zum Flur".
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 18)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(_status)
	_retry_save = _button("Erneut speichern", _save)
	_retry_save.visible = false
	header.add_child(_retry_save)
	_restart = _button("Neu beginnen", _on_restart)
	header.add_child(_restart)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	root.add_child(split)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_stretch_ratio = 3
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(left_scroll)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	left_scroll.add_child(left)
	_place = Label.new()
	_place.add_theme_font_size_override("font_size", 28)
	left.add_child(_place)
	_scene = _text_label()
	left.add_child(_scene)
	_people = _text_label()
	_people.modulate = Color(1, 1, 1, 0.75)
	left.add_child(_people)
	_message = _text_label()
	left.add_child(_message)
	_session_box = VBoxContainer.new()
	left.add_child(_session_box)
	_actions = HFlowContainer.new()
	_actions.add_theme_constant_override("h_separation", 8)
	_actions.add_theme_constant_override("v_separation", 8)
	left.add_child(_actions)

	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_stretch_ratio = 2
	split.add_child(_tabs)
	_akte = _text_label()
	_tabs.add_child(_scrolled("Akte", _akte))
	var docs_box := VBoxContainer.new()
	_docs = VBoxContainer.new()
	docs_box.add_child(_docs)
	_reader = _text_label()
	docs_box.add_child(_reader)
	_tabs.add_child(_scrolled("Unterlagen", docs_box))
	var cmp := VBoxContainer.new()
	var hint := _text_label()
	hint.text = "Zwei Einträge nebeneinanderlegen. Kostet keine Diensthandlung."
	cmp.add_child(hint)
	_cmp_a = OptionButton.new()
	_cmp_b = OptionButton.new()
	for ob in [_cmp_a, _cmp_b]:
		ob.custom_minimum_size = MIN_TARGET
		ob.fit_to_longest_item = false
		cmp.add_child(ob)
	cmp.add_child(_button("Nebeneinanderlegen", _compare))
	_tabs.add_child(_scrolled("Vergleichen", cmp))
	_log = _text_label()
	_tabs.add_child(_scrolled("Verlauf", _log))
	if dev_mode:
		_dev_info = _text_label()
		_dev_info.modulate = WARN
		_tabs.add_child(_scrolled("Entwicklung", _dev_info))

	_build_form()


func _build_form() -> void:
	_form = Control.new()
	_form.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_form.visible = false
	add_child(_form)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_form.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_form.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 560)
	# Eigener, deckender Hintergrund: DAMEs globales Theme macht Panels durchscheinend.
	var style := StyleBoxFlat.new()
	style.bg_color = BG.lightened(0.04)
	style.border_color = Color(0.62, 0.48, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "Bericht und Antrag · verbindlich"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	box.add_child(_caption("Antrag"))
	_f_antrag = OptionButton.new()
	_f_antrag.custom_minimum_size = MIN_TARGET
	_f_antrag.item_selected.connect(func(_i: int) -> void: _update_form())
	box.add_child(_f_antrag)
	_f_req = _text_label()
	box.add_child(_f_req)
	_f_wording_pick = OptionButton.new()
	_f_wording_pick.custom_minimum_size = MIN_TARGET
	_f_wording_pick.item_selected.connect(_on_wording_pick)
	box.add_child(_f_wording_pick)
	_f_wording = LineEdit.new()
	_f_wording.max_length = Bank01.MAX_WORDING
	_f_wording.custom_minimum_size = MIN_TARGET
	_f_wording.placeholder_text = "Formulierung des Antrags (wird wörtlich übernommen)"
	box.add_child(_f_wording)
	box.add_child(_caption("Feststellungen (höchstens drei)"))
	_f_findings = VBoxContainer.new()
	box.add_child(_f_findings)
	box.add_child(_caption("Schlussfolgerung"))
	_f_conclusion = OptionButton.new()
	_f_conclusion.custom_minimum_size = MIN_TARGET
	_f_conclusion.fit_to_longest_item = false
	_f_conclusion.item_selected.connect(func(_i: int) -> void: _update_form())
	box.add_child(_f_conclusion)
	_f_conclusion_status = _text_label()
	box.add_child(_f_conclusion_status)
	box.add_child(_caption("Offene Frage"))
	_f_question = OptionButton.new()
	_f_question.custom_minimum_size = MIN_TARGET
	_f_question.fit_to_longest_item = false
	box.add_child(_f_question)
	_f_error = _text_label()
	_f_error.modulate = WARN
	box.add_child(_f_error)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	row.add_child(_button("Verbindlich einreichen", submit_form))
	row.add_child(_button("Abbrechen", func() -> void: _form.visible = false))


func _show_message(text: String, warn: bool) -> void:
	_message.text = text
	_message.modulate = WARN if warn else Color(1, 1, 1)


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = MIN_TARGET
	b.pressed.connect(on_press)
	return b


func _text_label() -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(200, 0)
	return l


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1, 1, 1, 0.7)
	return l


func _scrolled(title: String, content: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	return sc


## Sofort aus dem Baum nehmen (Tests und Neuaufbau sehen keine Reste), freigeben erst am Bildende:
## Ein Knopf kann gerade sein eigenes Signal senden.
func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()
