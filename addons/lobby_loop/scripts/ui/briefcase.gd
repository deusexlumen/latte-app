# PURPOSE: Visuelle GM-Repräsentation: schwebender Aktenkoffer (Tween-Animation), Textur skaliert auf 96x84, nicht 1:1.
# ARCHITECTURE: ui
# DEPENDENCIES: none
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-04
extends Control

const FLOAT_DISTANCE := 10.0
const FLOAT_DURATION := 1.6

var _body: TextureRect
var _float_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(96, 84)
	size = custom_minimum_size
	mouse_filter = MOUSE_FILTER_IGNORE
	_draw_briefcase()
	_start_float()


func _draw_briefcase() -> void:
	_body = TextureRect.new()
	_body.texture = preload("res://addons/lobby_loop/content/art/schwarzer_koffer.png")
	_body.mouse_filter = MOUSE_FILTER_IGNORE
	_body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_body)


func _start_float() -> void:
	var base_y := position.y
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(self, "position:y", base_y - FLOAT_DISTANCE, FLOAT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(self, "position:y", base_y + FLOAT_DISTANCE, FLOAT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Kleiner Schuetteleffekt, wenn der GM spricht.
func flutter() -> void:
	var shake := create_tween()
	shake.tween_property(_body, "rotation", 0.08, 0.08)
	shake.tween_property(_body, "rotation", -0.08, 0.08)
	shake.tween_property(_body, "rotation", 0.0, 0.08)
