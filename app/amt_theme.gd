# PURPOSE: Aussehen des Amts (docs/gestaltung.md): schwere Blöcke, dicke Tintenkonturen, harte Versatzschatten, Beton und Papier, eine Signalfarbe.
# PURPOSE: Gilt für App-eigene Szenen (derzeit Flur); Lobby-Loop und DAME behalten ihr Aussehen.
# ARCHITECTURE: ui
# DEPENDENCIES: addons/dame/assets/fonts
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-19
extends RefCounted

const CONCRETE := Color("b5b2a8")
const CONCRETE_DARK := Color("8f8c82")
const PAPER := Color("ece7da")
const INK := Color("16130f")
const SIGNAL := Color("d9381e")
const FONT_PATH := "res://addons/dame/assets/fonts/Inter.ttf"


## Schwere Grotesk: Inter, künstlich verstärkt. Fehlt die Schrift, bleibt die Standardschrift.
static func heavy_font() -> Font:
	if not ResourceLoader.exists(FONT_PATH):
		return null
	var v := FontVariation.new()
	v.base_font = load(FONT_PATH)
	v.variation_embolden = 0.9
	return v


## Block mit Tintenkontur und hartem Versatzschatten (Neobrutalismus).
static func block(fill: Color, border_color: Color = INK, border := 4, shadow := 8, shadow_color: Color = INK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border_color
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	if shadow > 0:
		sb.shadow_color = shadow_color
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(shadow, shadow)
	return sb


static func focus_ring() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = SIGNAL
	sb.set_border_width_all(5)
	sb.set_expand_margin_all(6)
	return sb


static func make() -> Theme:
	var t := Theme.new()
	var font := heavy_font()
	if font != null:
		t.default_font = font
	t.default_font_size = 18
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_stylebox("normal", "Button", block(PAPER))
	t.set_stylebox("hover", "Button", block(Color("f6f1e4"), SIGNAL))
	t.set_stylebox("pressed", "Button", block(Color("d8d2c2"), INK, 4, 2))
	t.set_stylebox("focus", "Button", focus_ring())
	return t
