# PURPOSE: Versuch „Zwei Bücher“ als Klickprototyp: eine Wahlzeit in neun Perioden, links was man sieht, rechts die Aktenlage, am Ende beide Fassungen.
# ARCHITECTURE: ui (Versuch, über den Flur erreichbar; rückbaubar durch Löschen von karriere_kern/ und der Zeile im Flur)
# DEPENDENCIES: KarriereKern, KarriereBericht, AmtTheme
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-11-16
extends Control

const Kern := preload("res://karriere_kern/kern.gd")
const Bericht := preload("res://karriere_kern/bericht.gd")
const AmtTheme := preload("res://app/amt_theme.gd")

var state := {}
## Variante B: Die Registratur kann Wiederholungen ausweisen.
var reform := false
## Anläufe in dieser Sitzung. Nichts wird gespeichert.
var attempt := 0

var _post_from := 0
var _body: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme = AmtTheme.make()
	var bg := ColorRect.new()
	bg.color = AmtTheme.CONCRETE
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	scroll.add_child(_body)
	show_intro()


# ---------------------------------------------------------------- Ablauf

func start(with_reform: bool) -> void:
	reform = with_reform
	attempt += 1
	state = Kern.new_game({"reform": reform})
	_post_from = 0
	Kern.begin_period(state)
	refresh()


func do_action(action: String, thing: String) -> void:
	if Kern.act(state, action, thing):
		refresh()


func next_period() -> void:
	_post_from = (state["log"] as Array).size()
	Kern.end_period(state)
	if not bool(state["over"]):
		Kern.begin_period(state)
	refresh()


# ---------------------------------------------------------------- Anzeige

func show_intro() -> void:
	_clear()
	_title("Versuch: Zwei Bücher")
	_text("Eine Wahlzeit im Stadtrat, neun Sitzungsperioden. Sie sind neu, zuständig für Ihren Bezirk mit der Sporthalle. Jede Periode geht eine Meldung ein, und Sie haben zwei Diensthandlungen.")
	_text("Die Fraktionsvorsitzende sagt es Ihnen am ersten Tag: „Nach der dritten und der sechsten Periode rückt auf, wer die bessere Bilanz hat. Erledigtes zählt einfach, Offenes doppelt dagegen. Brandt macht das seit Jahren ordentlich.“")
	_text("Hier wird nicht gewürfelt. Was geschieht, folgt aus dem, was Sie und die anderen tun. Dies ist ein Versuch und noch kein Teil der Karriere; nichts wird gespeichert.")
	_button("Wahlzeit beginnen", start.bind(false))
	_button("Wahlzeit beginnen, Variante B (die Registratur kann Wiederholungen ausweisen)", start.bind(true))


func refresh() -> void:
	if bool(state["over"]):
		show_end()
		return
	_clear()
	var rank := int(state["rank"][Kern.PLAYER])
	_title("Periode %d von %d · %s · %d Diensthandlungen frei" % [int(state["period"]), Kern.PERIODS, Kern.RANKS[rank], int(state["points"])])
	# Die Handlungen stehen oben: Bei langem Eingang lagen sie sonst unter dem Bildschirmrand.
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 14)
	actions.add_theme_constant_override("v_separation", 12)
	_body.add_child(actions)
	for a in Kern.available(state):
		_button(Bericht.action_label(a), do_action.bind(str(a["id"]), str(a["thing"])), actions)
	_button("Periode beenden", next_period, actions)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	_body.add_child(row)
	row.add_child(_make_panel("Was Sie sehen", Bericht.sight(state)))
	row.add_child(_make_panel("Aktenlage", Bericht.akte(state)))
	var post := post_lines()
	if not post.is_empty():
		_panel("Eingang", post)


func show_end() -> void:
	_clear()
	_title("Ende der Wahlzeit · Anlauf %d%s" % [attempt, " · Variante B" if reform else ""])
	var post := post_lines()
	if not post.is_empty():
		_panel("Zuletzt", post)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	_body.add_child(row)
	row.add_child(_make_panel("Amtliche Fassung", Bericht.official(state)))
	row.add_child(_make_panel("Tatsächlich", Bericht.actual(state)))
	for id in Kern.THINGS:
		_panel("Rückblick: %s" % Kern.NAMES[id], Kern.trace(state, id))
	_button("Noch einmal von unten", start.bind(reform))
	_button("Zum Anfang des Versuchs", show_intro)


## Was seit dem letzten Blick eingegangen ist (Ende der vorigen Periode und Beginn dieser).
func post_lines() -> Array:
	var out: Array = []
	var entries: Array = state["log"]
	for i in range(_post_from, entries.size()):
		var e: Dictionary = entries[i]
		# Eigene Handlungen dieser Periode stehen schon in der Anzeige, nicht noch einmal im Eingang.
		if str(e["who"]) == Kern.PLAYER and int(e["period"]) == int(state["period"]) and not bool(state["over"]):
			continue
		out.append(Bericht.post_line(state, e))
	return out


func button_texts() -> Array:
	var out: Array = []
	for b in _body.find_children("*", "Button", true, false):
		out.append((b as Button).text)
	return out


func press(text_part: String) -> bool:
	for b in _body.find_children("*", "Button", true, false):
		if (b as Button).text.contains(text_part):
			(b as Button).pressed.emit()
			return true
	return false


# ---------------------------------------------------------------- Bausteine

func _clear() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()


func _title(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	_body.add_child(l)


func _text(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(600, 0)
	_body.add_child(l)


func _button(text: String, action: Callable, parent: Node = null) -> void:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(action)
	(parent if parent != null else _body).add_child(b)


func _panel(heading: String, lines: Array) -> void:
	_body.add_child(_make_panel(heading, lines))


func _make_panel(heading: String, lines: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", AmtTheme.block(AmtTheme.PAPER, AmtTheme.INK, 3, 6))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var h := Label.new()
	h.text = heading
	h.add_theme_font_size_override("font_size", 18)
	h.add_theme_color_override("font_color", AmtTheme.SIGNAL)
	column.add_child(h)
	for line in lines:
		var l := Label.new()
		l.text = str(line)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(420, 0)
		l.add_theme_color_override("font_color", AmtTheme.INK)
		column.add_child(l)
	return panel
