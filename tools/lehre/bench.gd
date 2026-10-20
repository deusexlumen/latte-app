# PURPOSE: Misst die Prüfdauer (WiderlegungValidator.validate) im jeweiligen Export, z. B. Web/WASM; Ausgabe in die Konsole
# ARCHITECTURE: tools
# DEPENDENCIES: WiderlegungValidator, WiderlegungRules
# PIPELINE: manual
# LAST_VALIDATED: 2026-10-12
extends Node


func _ready() -> void:
	await get_tree().process_frame
	var base := WiderlegungRules.load_data()
	for id in ["amt", "division7b", "akademie", "spiel"]:
		var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://addons/lobby_loop/content/widerlegung/%s.json" % id))
		var t := Time.get_ticks_msec()
		var r := WiderlegungValidator.validate(base, raw, true)
		print("BENCH %s ok=%s cap=%d %d ms" % [id, r["ok"], r["cap"], Time.get_ticks_msec() - t])
