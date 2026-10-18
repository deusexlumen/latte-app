# PURPOSE: Blende zwischen Szenen (Spezifikation 0.1, Kap. 12.1): Ein technischer Übergang darf sichtbar sein, solange Licht, Ton und Personen Kontinuität schaffen.
# PURPOSE: cover() blendet ab, reveal() wartet auf die neue Szene und blendet auf. Headless und bei reduzierter Bewegung (Einstellung "animations" aus) ohne Blende.
# ARCHITECTURE: autoload
# DEPENDENCIES: App (DAME-Einstellungen)
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
extends CanvasLayer

const FADE_OUT := 0.3
const FADE_IN := 0.4
## Darunter liegt der Rückweg-Knopf (Ebene 100): Er bleibt auch während der Blende bedienbar.
const LAYER := 90
const MAX_WAIT := 2.0
const COLOR := Color(0.05, 0.05, 0.07, 1.0)

var _rect: ColorRect
var _label: Label
var _from_scene := ""
var _tween: Tween


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = COLOR
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.modulate = Color(0.95, 0.85, 0.5)
	_rect.add_child(_label)


## Ohne Blende: Testlauf und reduzierte Bewegung. Die Szenen wechseln trotzdem.
func is_instant() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	var app := get_node_or_null("/root/App")
	return app != null and app.settings != null and not bool(app.settings.get_value("animations"))


func is_covered() -> bool:
	return _rect != null and _rect.modulate.a > 0.5


func cover(caption: String = "") -> void:
	var scene := get_tree().current_scene
	_from_scene = scene.scene_file_path if scene != null else ""
	_label.text = caption
	if is_instant():
		return
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade(1.0, FADE_OUT)


## Wartet, bis die neue Szene steht, und blendet auf. Ändert sich die Szene nicht (Wechsel unterdrückt), endet das nach MAX_WAIT.
func reveal() -> void:
	if is_instant():
		return
	var waited := 0.0
	while _scene_path() == _from_scene and waited < MAX_WAIT:
		await get_tree().process_frame
		waited += get_process_delta_time()
	for i in 3:
		await get_tree().process_frame
	await _fade(0.0, FADE_IN)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = ""


func _scene_path() -> String:
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene != null else ""


func _fade(target: float, seconds: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_rect, "modulate:a", target, seconds)
	await _tween.finished
