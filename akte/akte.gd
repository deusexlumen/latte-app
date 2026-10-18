# PURPOSE: Akte-Seite: zeigt LatteAkte (ein Abschnitt je Spiel).
# ARCHITECTURE: ui
# DEPENDENCIES: LatteAkte, HoersaalStats, GameState, App, AmtStore
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-18
extends Control


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.08, 0.07)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.custom_minimum_size = Vector2(520, 0)
	center.add_child(column)
	var title := Label.new()
	title.text = "Akte"
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	var app := get_node_or_null("/root/App")
	var dame: Dictionary = app.stats.values if app != null and app.stats != null else {}
	var sections: Array = LatteAkte.build(GameState.get_run_stats(), HoersaalStats.load_stats(), dame)
	# Der Vorgang des Innenhofs, falls einer begonnen wurde. Ein nicht ladbarer Stand erscheint hier nicht; der Innenhof meldet ihn selbst.
	sections.append(LatteAkte.vorgang_section(AmtStore.load_state(AmtStore.default_path(), Bank01.CONTENT_VERSION)["state"]))
	for section in sections:
		var h := Label.new()
		h.text = section["titel"]
		h.add_theme_font_size_override("font_size", 20)
		h.modulate = Color(0.95, 0.85, 0.5)
		column.add_child(h)
		for line in section["zeilen"]:
			var l := Label.new()
			l.text = "  " + str(line)
			column.add_child(l)

	var hz := get_node_or_null("/root/Hinterzimmer")
	if hz != null and app != null:
		var favor := Button.new()
		favor.text = "Gefallen einfordern (%d Gefälligkeiten, Stand: %d)" % [hz.FAVOR_PRICE, app.profile.chips()]
		favor.tooltip_text = "Einmal +2 auf den nächsten Wurf in der Karriere. Gefälligkeiten verdient man im Hinterzimmer."
		favor.disabled = not hz.can_claim_favor()
		favor.pressed.connect(func() -> void:
			if hz.claim_favor():
				favor.text = "Gefallen eingefordert. Er gilt beim nächsten Wurf."
				favor.disabled = true
		)
		column.add_child(favor)
