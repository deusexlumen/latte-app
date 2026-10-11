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
	# Eigenes Aussehen: DAME setzt ein globales Theme (root.theme), das den Knopf sonst unsichtbar macht.
	_button.theme = Theme.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.14, 0.9)
	style.border_color = Color(0.62, 0.48, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	for state in ["normal", "hover", "pressed", "focus"]:
		_button.add_theme_stylebox_override(state, style)
	_button.add_theme_color_override("font_color", Color(0.95, 0.88, 0.6))
	_button.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.75))
	_button.add_theme_font_size_override("font_size", 14)
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
