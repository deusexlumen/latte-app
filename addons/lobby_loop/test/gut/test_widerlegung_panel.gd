# PURPOSE: Widerlegungs-Panel: ganze Partie bis zum Ergebnis, Ergebnis erst beim Schließen, Abbruch ohne Ergebnis, Lehre-Fallback.
# ARCHITECTURE: test
# DEPENDENCIES: scripts/ui/widerlegung_panel.gd, MinigameContract
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const PanelScript := preload("res://addons/lobby_loop/scripts/ui/widerlegung_panel.gd")

var panel: PanelContainer


func before_each() -> void:
	panel = PanelScript.new()
	# Eigener leerer Ordner: Sperrlisten auf dem Entwicklerrechner dürfen die Seeds nicht verändern.
	panel.library_dir = "user://test_panel_bibliothek_leer/"
	add_child_autofree(panel)


func _play_to_end() -> void:
	var guard := 0
	while panel.is_playing() and guard < 60:
		panel.play_card(panel.hand_ids()[0])
		guard += 1


func test_full_game_sends_result_only_on_close() -> void:
	watch_signals(panel)
	panel.start({"lehre": "amt", "seed": "LL-TEST0001"})
	assert_true(panel.is_open())
	assert_eq(panel.lehre_id(), "amt")
	_play_to_end()
	assert_false(panel.is_playing(), "Partie ist zu Ende")
	assert_true(panel.is_open(), "Ergebnis wird angezeigt, Panel noch offen")
	assert_signal_not_emitted(panel, "finished")
	panel.close()
	assert_false(panel.is_open())
	assert_signal_emitted(panel, "finished")
	var result: Dictionary = get_signal_parameters(panel, "finished")[0]
	assert_eq(result["game"], "widerlegung")
	assert_eq(result["lehre"], "amt")
	assert_false(MinigameContract.sanitize_effects(result["effects"]).is_empty())


func test_abort_sends_nothing() -> void:
	watch_signals(panel)
	panel.start({"lehre": "akademie", "seed": "LL-TEST0002"})
	panel.play_card(panel.hand_ids()[0])
	panel.abort()
	assert_false(panel.is_open())
	assert_false(panel.is_playing())
	panel.close()
	assert_signal_not_emitted(panel, "finished")


func test_unknown_lehre_falls_back_to_amt() -> void:
	panel.start({"lehre": "gibtsnicht", "seed": "LL-TEST0003"})
	assert_eq(panel.lehre_id(), "amt")


func test_same_seed_same_hand() -> void:
	panel.start({"lehre": "erfurt", "seed": "LL-SAME"})
	var first: Array = panel.hand_ids()
	panel.abort()
	panel.start({"lehre": "erfurt", "seed": "LL-SAME"})
	assert_eq(panel.hand_ids(), first)


func test_objection_removes_card_and_refills_hand() -> void:
	var dir := "user://test_panel_einspruch/"
	panel.library_dir = dir
	panel.start({"lehre": "amt", "seed": "LL-EINSPRUCH"})
	var hand: Array = panel.hand_ids()
	var target := ""
	for id in hand:
		if WiderlegungLibrary.can_block(panel._lehre, str(id)):
			target = str(id)
			break
	assert_ne(target, "")
	assert_true(panel.object_card(target))
	assert_false(panel.hand_ids().has(target))
	assert_eq(panel.hand_ids().size(), hand.size())
	assert_true((WiderlegungLibrary.sperrliste(dir).get("amt", []) as Array).has(target))
	# Nächste Partie: die Karte fehlt der Lehre ganz.
	panel.start({"lehre": "amt", "seed": "LL-EINSPRUCH-2"})
	assert_false((panel._lehre["card_map"] as Dictionary).has(target))
	_rm(dir)


func test_objection_refuses_reference_cards() -> void:
	panel.start({"lehre": "amt", "seed": "LL-REF"})
	assert_false(panel.object_card("kuechenstuhl"))


func _rm(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)
