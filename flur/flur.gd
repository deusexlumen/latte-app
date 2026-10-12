# PURPOSE: Flur des Amts: Startszene der App mit drei Türen (Karriere, Hörsaal, Hinterzimmer).
# ARCHITECTURE: ui
# DEPENDENCIES: addons/lobby_loop, addons/dame
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-12
extends Control

const KARRIERE := "res://addons/lobby_loop/scenes/main.tscn"
const HINTERZIMMER := "res://addons/dame/scenes/main_menu.tscn"


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_preset(PRESET_CENTER)
	add_child(column)
	for door in [["Karriere", KARRIERE], ["Hinterzimmer", HINTERZIMMER]]:
		var b := Button.new()
		b.text = door[0]
		b.pressed.connect(get_tree().change_scene_to_file.bind(door[1]))
		column.add_child(b)
