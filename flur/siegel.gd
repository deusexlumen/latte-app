# PURPOSE: Zeichen über der Mitte des Flurs: sieben kleine Blöcke im Bogen über einem großen, im Ring. Eine Anspielung, keine Erklärung (docs/gestaltung.md, G-10).
# ARCHITECTURE: ui
# DEPENDENCIES: app/amt_theme.gd
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-19
extends Control

const AmtTheme := preload("res://app/amt_theme.gd")
const SEVEN := 7


func _init() -> void:
	custom_minimum_size = Vector2(170, 132)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.62)
	var r := minf(size.x, size.y) * 0.34
	draw_arc(c, r * 1.35, 0.0, TAU, 64, AmtTheme.INK, 4.0)
	# Sieben Blöcke auf dem oberen Bogen.
	for i in SEVEN:
		var a := lerpf(PI * 1.12, PI * 1.88, float(i) / float(SEVEN - 1))
		var p := c + Vector2(cos(a), sin(a)) * r * 1.35
		draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), AmtTheme.INK)
	# Der große Block in der Mitte, darin der Punkt in der Signalfarbe.
	draw_rect(Rect2(c - Vector2(r, r) * 0.62, Vector2(r, r) * 1.24), AmtTheme.INK)
	draw_circle(c, r * 0.22, AmtTheme.SIGNAL)
