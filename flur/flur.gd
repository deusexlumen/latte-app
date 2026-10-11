# PURPOSE: Flur des Amts: Startszene der App mit drei Türen (Karriere, Hörsaal, Hinterzimmer), dazu Akte und Einstellungen.
# ARCHITECTURE: ui
# DEPENDENCIES: addons/lobby_loop, addons/dame, hoersaal, akte, Migration
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-12
extends Control

const KARRIERE := "res://addons/lobby_loop/scenes/main.tscn"
const HOERSAAL := "res://hoersaal/hoersaal.tscn"
const HINTERZIMMER := "res://addons/dame/scenes/main_menu.tscn"
const AKTE := "res://akte/akte.tscn"
## Eine Einstellungsseite für alle Spiele: DAMEs Seite (Sprache, Ton, Musik, Vollbild) gilt app-weit.
const EINSTELLUNGEN := "res://addons/dame/scenes/settings.tscn"

const DOORS := [
	["Karriere", "Lobby-Loop: Kommunalpolitik bis Untersuchungsausschuss.", KARRIERE],
	["Hörsaal", "Widerlegung einzeln, Lehre frei wählbar. Zählt nicht für die Karriere.", HOERSAAL],
	["Hinterzimmer", "DAME. Kartenspiel unter Kollegen.", HINTERZIMMER],
]


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.078, 0.09, 0.114)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.custom_minimum_size = Vector2(520, 0)
	center.add_child(column)

	var title := Label.new()
	title.text = "Flur des Amts"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var sub := Label.new()
	sub.text = "Drei Türen. Hinter jeder liegt eine Akte, die nicht fertig wird."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(1, 1, 1, 0.7)
	column.add_child(sub)

	for door in DOORS:
		var b := Button.new()
		b.text = door[0]
		b.tooltip_text = door[1]
		b.custom_minimum_size = Vector2(0, 56)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_go.bind(door[2]))
		column.add_child(b)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	for extra in [["Akte", AKTE], ["Einstellungen", EINSTELLUNGEN]]:
		var b := Button.new()
		b.text = extra[0]
		b.pressed.connect(_go.bind(extra[1]))
		row.add_child(b)

	var migration := get_node_or_null("/root/Migration")
	if migration != null and not (migration.report as Array).is_empty():
		var note := Label.new()
		note.text = "Übernommen aus den Einzel-Apps: %s" % ", ".join(PackedStringArray(migration.report))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.modulate = Color(0.95, 0.85, 0.5)
		column.add_child(note)


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)
