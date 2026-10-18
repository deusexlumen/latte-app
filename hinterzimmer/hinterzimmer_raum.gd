# PURPOSE: Das Hinterzimmer als Ort (Spezifikation 0.1, Kap. 3.1, 8.3, 12.1, 12.2): derselbe Raum vor, während und nach der Partie.
# PURPOSE: Ersetzt DAMEs eigenes Hauptmenü in der App; App.home_scene zeigt hierher, „Zurück“ und „Hauptmenü“ landen also hier.
# ARCHITECTURE: ui
# DEPENDENCIES: addons/dame (screen_base, App), FlurButton (Rückweg und Esc)
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
extends "res://addons/dame/scripts/screens/screen_base.gd"

const TITLE_TEXT := "Hinterzimmer"
const ROOM_TEXT := "Feierabend. Ein Tisch, ein Kartenspiel, zwei Gläser, die niemand abräumt."

var resume_button: Button
var colleagues_button: Button
var people_button: Button
var people_box: VBoxContainer
var rules_button: Button
var favors_label: Label


func build() -> void:
	var app := app_node()
	# Kein eigener Zurück-Knopf: Der Rückweg in den Flur ist der Knopf der App (FlurButton, Esc).
	frame(TITLE_TEXT, 560, false)
	var room := label(ROOM_TEXT, 17)
	room.modulate = Color(1, 1, 1, 0.8)
	content.add_child(room)
	# Höchstens vier Haupthandlungen (Kap. 12.2), der Rest als Unterauswahl.
	resume_button = _action("Partie fortsetzen", func() -> void: app.resume_match())
	resume_button.visible = app != null and app.saves.has_save()
	colleagues_button = _action("Mit den Kollegen spielen", func() -> void: _open_setup("ai"))
	people_button = _action("Mit Menschen spielen", func() -> void: people_box.visible = not people_box.visible)
	people_box = VBoxContainer.new()
	people_box.visible = false
	people_box.add_theme_constant_override("separation", 8)
	content.add_child(people_box)
	people_box.add_child(_sub("Am selben Tisch", func() -> void: _open_setup("hotseat")))
	people_box.add_child(_sub("Über einen Raumcode", func() -> void: app.goto(app.ONLINE)))
	rules_button = _action("Regeln", func() -> void: app.goto(app.RULES))
	var more := HBoxContainer.new()
	more.alignment = BoxContainer.ALIGNMENT_CENTER
	more.add_theme_constant_override("separation", 12)
	content.add_child(more)
	more.add_child(button("Statistik", func() -> void: app.goto(app.STATS)))
	more.add_child(button("Schrank", func() -> void: app.goto(app.SHOP)))
	favors_label = label("", 15)
	favors_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	favors_label.modulate = Color(1, 1, 1, 0.7)
	content.add_child(favors_label)
	if app != null:
		favors_label.text = tr("%d Chips") % app.profile.chips()
	for b in [resume_button, colleagues_button]:
		if b.visible:
			b.grab_focus()
			break


func _action(text: String, cb: Callable) -> Button:
	var b := button(text, cb)
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 20)
	content.add_child(b)
	return b


func _sub(text: String, cb: Callable) -> Button:
	var b := button(text, cb)
	b.custom_minimum_size = Vector2(0, 40)
	return b


func _open_setup(mode: String) -> void:
	var app := app_node()
	if app == null:
		return
	app.pending = {"setup_mode": mode}
	app.goto(app.SETUP)


## Esc und Zurück übernimmt der Rückweg-Knopf der App; DAMEs Zurück würde wieder hierher führen.
func go_back() -> void:
	pass
