# PURPOSE: Rückweg zum Flur aus jedem Spiel: kleiner Knopf unten in der Mitte plus Esc-Taste, außer im Flur selbst.
# ARCHITECTURE: autoload
# DEPENDENCIES: flur/flur.tscn
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-12
extends CanvasLayer

const FLUR := "res://flur/flur.tscn"

var _button: Button


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button = Button.new()
	_button.text = "Zum Flur"
	_button.tooltip_text = "Zurück in den Flur des Amts (Esc). Der Spielstand bleibt erhalten."
	_button.anchor_left = 0.5
	_button.anchor_right = 0.5
	_button.anchor_top = 1.0
	_button.anchor_bottom = 1.0
	_button.offset_left = -50
	_button.offset_right = 50
	_button.offset_top = -30
	_button.offset_bottom = -4
	_button.pressed.connect(go_to_flur)
	add_child(_button)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	_button.visible = scene != null and scene.scene_file_path != FLUR


func _unhandled_input(event: InputEvent) -> void:
	if _button.visible and event.is_action_pressed("ui_cancel"):
		go_to_flur()


func go_to_flur() -> void:
	# Karriere vorher sichern; DAME sichert seine Partie selbst.
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path.begins_with("res://addons/lobby_loop/"):
		SaveManager.autosave()
	get_tree().paused = false
	get_tree().change_scene_to_file(FLUR)
