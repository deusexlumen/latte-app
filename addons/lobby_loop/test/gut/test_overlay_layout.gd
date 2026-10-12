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
