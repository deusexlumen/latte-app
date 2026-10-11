# PURPOSE: Rückweg zum Flur aus jedem Spiel: kleiner Knopf unten rechts plus Esc. Ausgeblendet im Flur, am DAME-Tisch und solange in Lobby-Loop ein Dialog offen ist.
# ARCHITECTURE: autoload
# DEPENDENCIES: flur/flur.tscn, SaveManager
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
extends CanvasLayer

const FLUR := "res://flur/flur.tscn"
## DAME hat am Tisch ein eigenes Menü; ein Fehlklick auf "Zum Flur" würde die Partie verlassen.
const HIDDEN_IN := [FLUR, "res://addons/dame/scenes/table.tscn"]
## Lobby-Loops Dialoge (main.gd). Solange einer offen ist, wartet dort eine Koroutine auf den Spielleiter
## oder eine Widerlegung läuft; ein Szenenwechsel würde sie gegen freigegebene Knoten laufen lassen.
const LOBBY_MODALS := ["_overlay", "_minigame", "_widerlegung"]

var _button: Button


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button = Button.new()
	_button.text = "Zum Flur"
	_button.tooltip_text = "Zurück in den Flur des Amts (Esc). Der Spielstand bleibt erhalten."
	# Unten rechts ist in allen drei Spielen frei (gemessen: Lobby-Inventar unten links, DAME-Hand unten Mitte).
	_button.anchor_left = 1.0
	_button.anchor_right = 1.0
	_button.anchor_top = 1.0
	_button.anchor_bottom = 1.0
	_button.offset_left = -112
	_button.offset_right = -6
	_button.offset_top = -32
	_button.offset_bottom = -6
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
	_button.visible = can_leave()


## Darf man jetzt zum Flur? Nicht im Flur, nicht am DAME-Tisch, nicht mit offenem Lobby-Dialog.
func can_leave() -> bool:
	var scene := get_tree().current_scene
	if scene == null or HIDDEN_IN.has(scene.scene_file_path):
		return false
	for name in LOBBY_MODALS:
		var modal: Variant = scene.get(name)
		if modal is CanvasItem and (modal as CanvasItem).visible:
			return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and can_leave():
		get_viewport().set_input_as_handled()
		go_to_flur()


func go_to_flur() -> void:
	if not can_leave():
		return
	# Karriere vorher sichern; DAME sichert seine Partie selbst.
	if get_tree().current_scene.scene_file_path.begins_with("res://addons/lobby_loop/"):
		SaveManager.autosave()
	get_tree().paused = false
	get_tree().change_scene_to_file(FLUR)
