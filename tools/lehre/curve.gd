# PURPOSE: Zeigt für Lehren-JSONs eines Ordners die Einsturzkurve je cap (Gelegenheit/Zufall/Ausnahme) und die Befunde — Werkzeug zum Nachstellen der Prüfung ohne API
# ARCHITECTURE: tools
# DEPENDENCIES: WiderlegungValidator, WiderlegungRules
# PIPELINE: manual
# LAST_VALIDATED: 2026-10-12
extends SceneTree

# Aufruf: godot --headless --path . -s tools/lehre/curve.gd -- <ordner>


func _init() -> void:
	var dir := OS.get_cmdline_user_args()[0]
	var base := WiderlegungRules.load_data()
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".json"):
			continue
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
		if not (raw is Dictionary):
			continue
		var r := WiderlegungValidator.validate(base, raw)
		print("== %s %s ok=%s paare=%s" % [f, raw.get("begriff", "?"), r["ok"], r["paare"]])
		for b in r["befunde"]:
			print("   B: %s" % b)
		var L: Dictionary = raw.duplicate(true)
		L["cap"] = 9
		var err := WiderlegungRules.prepare(L)
		if err.begins_with("Referenz"):
			WiderlegungValidator.repair_refs(L)
			err = WiderlegungRules.prepare(L)
		if not err.is_empty():
			continue
		var line := "   "
		for cap in range(WiderlegungValidator.CAP_RANGE[0], WiderlegungValidator.CAP_RANGE[1] + 1):
			var m := WiderlegungValidator.measure(base, L, cap, 100)
			line += "%d:%.0f/%.0f/%.0f  " % [cap, m["gelegenheit"] * 100, m["zufall"] * 100, m["ausnahme"] * 100]
		print(line)
	quit()
