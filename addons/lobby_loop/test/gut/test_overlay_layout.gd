# PURPOSE: P&P-Overlay: Wurfergebnis bricht nicht nach jedem Zeichen um (Regression aus dem Web-Test).
# ARCHITECTURE: test
# DEPENDENCIES: scripts/ui/pnp_overlay.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest


func test_roll_result_label_has_width() -> void:
	var overlay: Control = load("res://addons/lobby_loop/scripts/ui/pnp_overlay.gd").new()
	add_child_autofree(overlay)
	overlay.visible = true
	overlay._roll_result_label.text = "W20: 4 + 3 (berufspolitisches Netzwerk) = 7 vs DC 10 → Misserfolg"
	await wait_process_frames(3)
	assert_gt(overlay._roll_result_label.size.x, 150.0)


## Regression aus dem Web-Test: set_anchors_preset ohne Offsets ließ Panels oben links kleben.
func test_full_rect_panels_fill_the_viewport() -> void:
	for path in ["res://addons/lobby_loop/scripts/ui/widerlegung_panel.gd", "res://addons/lobby_loop/scripts/ui/pnp_overlay.gd", "res://addons/lobby_loop/scripts/ui/minigame_panel.gd"]:
		var host := Control.new()
		host.size = Vector2(1280, 720)
		add_child_autofree(host)
		var panel: Control = load(path).new()
		host.add_child(panel)
		await wait_process_frames(2)
		assert_eq(panel.size, Vector2(1280, 720), path)
