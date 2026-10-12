# PURPOSE: Widerlegungs-Panel: Saal, Lehre, Last gegen Tragfähigkeit, Hand, Herzschlag, Protokoll; meldet ein Vertrags-Ergebnis.
# ARCHITECTURE: ui
# DEPENDENCIES: WiderlegungRules, WiderlegungLibrary, MinigameContract
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-12
extends PanelContainer

## Ergebnis nach dem Minispiel-Vertrag. Wird erst beim Schließen gesendet,
## damit Effekte (auch ein Perma-Death) nie in ein offenes Panel fallen.
signal finished(result: Dictionary)

const MAX_PROTOCOL_LINES := 8
const VERDICT_TEXT := {
	"broad": "passt zur Lehre, gehört aber nicht dazu",
	"narrow": "gehört dazu, passt aber nicht zur Lehre",
	"confirm": "bestätigt die Lehre",
}
const KIND_TEXT := {
	"add": "Ergänzung (+1)",
	"repair": "Nachbesserung (+1)",
	"excl": "Ausnahme (+3)",
	"incl": "Ausnahme (+3)",
	"confirm": "Bestätigung",
}

## Bibliothek erfundener Lehren (Phase 2). Leer = nur Grundbestand.
var library_dir := WiderlegungLibrary.DEFAULT_DIR
var _data := {}
var _run := {}
var _lehre := {}
var _result := {}
var _aborted := false
var _protocol: Array = []

var _title_label: Label
var _lehre_label: Label
var _status_label: Label
var _last_bar: ProgressBar
var _telegraph_label: Label
var _hand_box: HFlowContainer
var _preview_label: Label
var _protocol_label: Label
var _end_button: Button


func _ready() -> void:
	visible = false
	set_anchors_preset(PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.95)
	add_theme_stylebox_override("panel", style)

	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.14)
	panel_style.border_color = Color(0.62, 0.48, 0.2)
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	_title_label = _label(column, 22, Color(0.95, 0.8, 0.45))
	_lehre_label = _label(column, 16, Color(0.95, 0.93, 0.85))
	_status_label = _label(column, 13, Color(0.85, 0.87, 0.92))
	_last_bar = ProgressBar.new()
	_last_bar.show_percentage = false
	_last_bar.custom_minimum_size = Vector2(0, 14)
	column.add_child(_last_bar)
	_telegraph_label = _label(column, 13, Color(0.9, 0.6, 0.4))
	_hand_box = HFlowContainer.new()
	_hand_box.add_theme_constant_override("h_separation", 6)
	_hand_box.add_theme_constant_override("v_separation", 6)
	column.add_child(_hand_box)
	_preview_label = _label(column, 12, Color(0.7, 0.8, 0.95))
	_protocol_label = _label(column, 13, Color(0.85, 0.9, 0.85))
	_end_button = Button.new()
	_end_button.text = "Saal verlassen"
	_end_button.visible = false
	_end_button.pressed.connect(close)
	column.add_child(_end_button)


func _label(parent: Node, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


# ---------------------------------------------------------------- Öffentlich

## params: {"lehre": String, "seed": String} aus GameState.start_minigame.
func start(params: Dictionary) -> void:
	_aborted = false
	_result = {}
	_run = {}
	_protocol = []
	# Jedes Mal neu laden: Die Bibliothek wächst und Einsprüche wirken ab der nächsten Partie.
	_data = WiderlegungRules.load_data(library_dir)
	if _data.has("error"):
		push_warning("WiderlegungPanel: %s" % _data["error"])
		_show_missing_file(str(_data["error"]))
		return
	var idx := WiderlegungRules.index_of(_data, str(params.get("lehre", "")))
	if idx < 0:
		idx = WiderlegungRules.index_of(_data, MinigameContract.DEFAULT_LEHRE)
	_lehre = _data["instanzen"][idx]
	_run = WiderlegungRules.new_run(str(params.get("seed", "LL-00000000")))
	_run["idx"] = idx
	WiderlegungRules.start_instanz(_data, _run)
	_title_label.text = "Widerlegung — %s" % str(_lehre.get("ort", ""))
	_push(str(_lehre.get("intro", "")))
	_push("%s: %s" % [str(_lehre.get("gegner", "")), str(_lehre.get("startSatz", ""))])
	_end_button.visible = false
	_hand_box.visible = true
	visible = true
	_refresh()


func play_card(card_id: String) -> void:
	if not is_playing():
		return
	for e in WiderlegungRules.play(_data, _run, card_id):
		_describe(e)
	if _run["phase"] == "result":
		_finish()
	else:
		_refresh()


## Einspruch: Karte ist sachlich falsch. Sie verlässt die Hand, kommt auf die Sperrliste
## und fehlt dieser Lehre ab der nächsten Partie. Kein Wurf, keine Last.
func object_card(card_id: String) -> bool:
	if not is_playing() or not WiderlegungLibrary.can_block(_lehre, card_id):
		return false
	if not WiderlegungRules.withdraw_card(_run, card_id):
		return false
	WiderlegungLibrary.block_card(_lehre, card_id, library_dir)
	_push("Einspruch: %s wird aus der Akte gestrichen." % _card_name(card_id))
	_refresh()
	return true


func hand_ids() -> Array:
	if not is_playing():
		return []
	return (_run["inst"]["hand"] as Array).duplicate()


func is_playing() -> bool:
	return is_open() and not _run.is_empty() and _run.get("phase") == "play"


func is_open() -> bool:
	return visible and not _aborted


func lehre_id() -> String:
	return str(_lehre.get("id", ""))


## Schließt nach dem Ergebnis und sendet es. Ohne Ergebnis passiert nichts.
func close() -> void:
	if not is_open() or _result.is_empty():
		return
	visible = false
	finished.emit(_result)


## Abbruch von außen (Perma-Death, Szenenwechsel): kein Ergebnis, keine Effekte.
func abort() -> void:
	_aborted = true
	visible = false


# ---------------------------------------------------------------- Anzeige

func _refresh() -> void:
	var st: Dictionary = _run["inst"]
	var view := WiderlegungRules.lehre_view(_lehre, st["lehre"])
	var lines := PackedStringArray([str(_lehre.get("lehreHead", ""))])
	for r in view["reqs"]:
		var prefix := "  (weggefallen) " if r["gone"] else "  • "
		lines.append(prefix + str(r["text"]) + ("   ← neu" if r["fresh"] else ""))
	for x in view["excl"]:
		lines.append("  ausgenommen: %s%s" % [x["name"], " (überstrichen)" if x["painted"] else ""])
	for x in view["incl"]:
		lines.append("  eingeschlossen: %s%s" % [x["name"], " (überstrichen)" if x["painted"] else ""])
	_lehre_label.text = "\n".join(lines)

	var last_value := WiderlegungRules.last(st)
	var cap := int(st["cap"])
	_status_label.text = "Last %d / Tragfähigkeit %d · Würfe übrig %d" % [last_value, cap, int(st["wuerfe"])]
	_last_bar.max_value = cap
	_last_bar.value = mini(last_value, cap)
	_telegraph_label.text = _telegraph_text(st.get("telegraph"))
	_preview_label.text = ""

	for child in _hand_box.get_children():
		child.queue_free()
	for id in st["hand"]:
		var card: Dictionary = _lehre["card_map"][id]
		var slot := HBoxContainer.new()
		slot.add_theme_constant_override("separation", 0)
		var button := Button.new()
		button.text = "%s %s" % [_icon(card), str(card.get("name", id))]
		button.tooltip_text = "Laut Akte: %s" % str(card.get("note", ""))
		button.pressed.connect(play_card.bind(str(id)))
		if bool(_lehre.get("laterneLeihgabe", false)):
			button.mouse_entered.connect(_show_preview.bind(str(id)))
		slot.add_child(button)
		var objection := Button.new()
		objection.text = "!"
		objection.tooltip_text = "Einspruch: Die Akte irrt bei dieser Karte. Sie wird aus der Lehre gestrichen."
		objection.disabled = not WiderlegungLibrary.can_block(_lehre, str(id))
		objection.pressed.connect(object_card.bind(str(id)))
		slot.add_child(objection)
		_hand_box.add_child(slot)
	_protocol_label.text = "\n".join(PackedStringArray(_protocol))


## Emojis nur auf dem Desktop: Der Web-Export hat keine Emoji-Schrift und zeigt leere Kästchen.
func _icon(d: Dictionary) -> String:
	return "" if OS.has_feature("web") else str(d.get("icon", ""))


func _telegraph_text(tg: Variant) -> String:
	if not (tg is Dictionary):
		return ""
	var info: Dictionary = _data["rhetorik"].get(tg["type"], {})
	var text := "Nächster Herzschlag: %s %s — %s" % [_icon(info), str(info.get("name", tg["type"])), str(info.get("tele", ""))]
	if tg.get("target") != null:
		text += " (%s)" % _card_name(str(tg["target"]))
	return text


func _show_preview(card_id: String) -> void:
	if not is_playing():
		return
	var p := WiderlegungRules.preview(_data, _run, card_id)
	_preview_label.text = "🏮 Laterne: %s → %s, Last danach %d%s" % [
		_card_name(card_id),
		str(KIND_TEXT.get(p["kind"], p["kind"])),
		int(p["last"]),
		" — Einsturz!" if p["collapse"] else "",
	]


func _card_name(card_id: String) -> String:
	var card: Dictionary = _lehre.get("card_map", {}).get(card_id, {})
	return str(card.get("name", card_id))


func _describe(e: Dictionary) -> void:
	match str(e.get("type", "")):
		"throw":
			_push("Du wirfst %s: %s." % [_card_name(str(e["card"])), str(VERDICT_TEXT.get(e["verdict"], ""))])
		"patch":
			_push(_patch_text(e))
		"beat":
			_push(_beat_text(e))
		"collapse":
			_push("Der Boden bricht. Die Lehre stürzt in die Sickergrube. Bonus +%d." % int(e["bonus"]))
		"hold":
			_push("Exakt wie erwartet. Die Lehre hält.")


func _patch_text(e: Dictionary) -> String:
	var gegner := str(_lehre.get("gegner", "Der Gegner"))
	match str(e["kind"]):
		"add":
			return "%s ergänzt: … was %s." % [gegner, WiderlegungRules.lit_phrase(_lehre, e["lit"])]
		"repair":
			return "%s bessert nach und streicht, was nicht mehr passt." % gegner
		"excl":
			return "%s nimmt %s ausdrücklich aus. Ausnahmen wiegen schwer." % [gegner, _card_name(str(e["card"]))]
		"incl":
			return "%s schließt %s ausdrücklich ein. Ausnahmen wiegen schwer." % [gegner, _card_name(str(e["card"]))]
	return "Beweisaufnahme: kostet keinen Wurf." if e.get("frei", false) else "Zur Kenntnis genommen."


func _beat_text(e: Dictionary) -> String:
	match str(e["effect"]):
		"sonne":
			return "Geh mir aus der Sonne: Der Herzschlag verpufft."
		"seized":
			return "Beschlagnahmt: %s." % _card_name(str(e["card"]))
		"wurf":
			return "Die Redezeit wird gekürzt: ein Wurf weniger."
		"cap":
			return "Ein Stützbalken wird eingezogen: Tragfähigkeit +1."
		"painted":
			return "Eine Ausnahme wird braun überstrichen und wiegt nur noch 1."
	return "Der Herzschlag verpufft."


func _push(line: String) -> void:
	if line.strip_edges().is_empty():
		return
	_protocol.append(line)
	while _protocol.size() > MAX_PROTOCOL_LINES:
		_protocol.pop_front()


func _finish() -> void:
	_result = MinigameContract.widerlegung_result(_lehre, _run["results"][0])
	_refresh()
	for child in _hand_box.get_children():
		child.queue_free()
	_hand_box.visible = false
	_telegraph_label.text = ""
	_preview_label.text = str(_result["chronik"])
	_end_button.visible = true


## Content fehlt: kein Spiel, keine Strafe für unseren Fehler.
func _show_missing_file(error: String) -> void:
	_lehre = {}
	_title_label.text = "Widerlegung — Akte unvollständig"
	_lehre_label.text = "Die Registratur findet die Lehre nicht. Die Sitzung wird vertagt."
	_status_label.text = ""
	_telegraph_label.text = ""
	_preview_label.text = ""
	_protocol_label.text = error
	_hand_box.visible = false
	_result = {
		"game": MinigameContract.GAME_WIDERLEGUNG,
		"won": false,
		"score": 0,
		"effects": [],
		"chronik": "Widerlegung vertagt: Akte unvollständig",
		"lehre": "",
	}
	_end_button.visible = true
	visible = true
