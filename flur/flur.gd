# PURPOSE: Flur des Amts: Startszene der App mit vier Türen (Karriere, Hörsaal, Hinterzimmer, Innenhof), dazu Akte und Einstellungen.
# ARCHITECTURE: ui
# DEPENDENCIES: addons/lobby_loop, addons/dame, hoersaal, akte, amt, Migration
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-18
extends Control

const LatteText := preload("res://app/latte_text.gd")
const AmtTheme := preload("res://app/amt_theme.gd")
const Siegel := preload("res://flur/siegel.gd")
const KARRIERE := "res://addons/lobby_loop/scenes/main.tscn"
const HOERSAAL := "res://hoersaal/hoersaal.tscn"
const HINTERZIMMER := "res://hinterzimmer/hinterzimmer.tscn"
const AKTE := "res://akte/akte.tscn"
## Erster Vorgang der gemeinsamen Welt (Spezifikation 0.1, Kap. 9), Etappe E1.
const INNENHOF := "res://amt/vorgang.tscn"
## Eine Einstellungsseite für alle Spiele: DAMEs Seite (Sprache, Ton, Musik, Vollbild) gilt app-weit.
const EINSTELLUNGEN := "res://addons/dame/scenes/settings.tscn"

const DOORS := [
	["Karriere", "Lobby-Loop: Kommunalpolitik bis Untersuchungsausschuss.", KARRIERE],
	["Hörsaal", "Widerlegung einzeln, Lehre frei wählbar. Zählt nicht für die Karriere.", HOERSAAL],
	["Hinterzimmer", "Feierabend. DAME unter Kollegen.", HINTERZIMMER],
	["Innenhof", "Vorgang BANK-01: Die gesperrte Bank. Prototyp.", INNENHOF],
]


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme = AmtTheme.make()
	var bg := ColorRect.new()
	bg.color = AmtTheme.CONCRETE
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)

	column.add_child(Siegel.new())

	var plaque := PanelContainer.new()
	plaque.add_theme_stylebox_override("panel", AmtTheme.block(AmtTheme.PAPER))
	plaque.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(plaque)
	var title := Label.new()
	title.text = LatteText.t("Flur des Amts")
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque.add_child(title)
	var sub := Label.new()
	sub.text = LatteText.t("Vier Türen. Hinter jeder liegt eine Akte, die nicht fertig wird.")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	column.add_child(sub)

	var portals := HBoxContainer.new()
	portals.alignment = BoxContainer.ALIGNMENT_CENTER
	portals.add_theme_constant_override("separation", 30)
	column.add_child(portals)
	var numerals := ["I", "II", "III", "IV"]
	for i in DOORS.size():
		portals.add_child(_portal(numerals[i], DOORS[i]))

	# Stufen unter den Portalen.
	for width in [1090, 1150]:
		var step := ColorRect.new()
		step.color = AmtTheme.INK
		step.custom_minimum_size = Vector2(width, 10)
		step.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(step)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	for extra in [["Akte", AKTE], ["Einstellungen", EINSTELLUNGEN]]:
		var b := Button.new()
		b.text = LatteText.t(extra[0])
		b.custom_minimum_size = Vector2(190, 44)
		b.pressed.connect(_go.bind(extra[1]))
		row.add_child(b)

	var migration := get_node_or_null("/root/Migration")
	if migration != null and not (migration.report as Array).is_empty():
		var note := Label.new()
		note.text = LatteText.t("Übernommen aus den Einzel-Apps: %s") % ", ".join(PackedStringArray(migration.report))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(700, 0)
		column.add_child(note)


## Ein Portal: hoher dunkler Block mit Doppelrahmen wie ein Türgewände, Zahl oben, Name in der Mitte, Beschreibung unten.
## Der Knopftext bleibt der Name.
func _portal(numeral: String, door: Array) -> Button:
	var b := Button.new()
	b.text = LatteText.t(door[0])
	b.tooltip_text = LatteText.t(door[1])
	b.custom_minimum_size = Vector2(250, 300)
	b.add_theme_font_size_override("font_size", 28)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, AmtTheme.PAPER)
	b.add_theme_stylebox_override("normal", AmtTheme.block(AmtTheme.INK, AmtTheme.INK, 4, 10, AmtTheme.CONCRETE_DARK))
	b.add_theme_stylebox_override("hover", AmtTheme.block(AmtTheme.INK, AmtTheme.SIGNAL, 6, 10, AmtTheme.CONCRETE_DARK))
	b.add_theme_stylebox_override("pressed", AmtTheme.block(AmtTheme.INK, AmtTheme.SIGNAL, 6, 3, AmtTheme.CONCRETE_DARK))
	# Inneres Gewände.
	var frame := Panel.new()
	var fs := StyleBoxFlat.new()
	fs.draw_center = false
	fs.border_color = AmtTheme.PAPER
	fs.set_border_width_all(3)
	frame.add_theme_stylebox_override("panel", fs)
	frame.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	frame.offset_left = 12
	frame.offset_top = 12
	frame.offset_right = -12
	frame.offset_bottom = -12
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(frame)
	var num := Label.new()
	num.text = numeral
	num.add_theme_font_size_override("font_size", 44)
	num.add_theme_color_override("font_color", AmtTheme.SIGNAL)
	num.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	num.offset_top = 26
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(num)
	var caption := Label.new()
	caption.text = LatteText.t(door[1])
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", AmtTheme.PAPER)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	caption.offset_left = 26
	caption.offset_right = -26
	caption.offset_top = -100
	caption.offset_bottom = -26
	caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(caption)
	return b


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)
