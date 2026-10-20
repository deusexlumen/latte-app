# PURPOSE: Prüft alle Lehren-JSONs eines Ordners mit WiderlegungValidator und misst die Prüfdauer (Werkzeug, headless)
# ARCHITECTURE: tools
# DEPENDENCIES: WiderlegungValidator, WiderlegungRules
# PIPELINE: manual
# LAST_VALIDATED: 2026-10-12
extends SceneTree

# Aufruf: godot --headless --path . -s tools/lehre/validate_dir.gd -- <ordner>


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var dir := args[0] if args.size() > 0 else "user://lehre_probe"
	var base := WiderlegungRules.load_data()
	var passed := 0
	var total := 0
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".json"):
			continue
		total += 1
		var lehre: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
		var t0 := Time.get_ticks_msec()
		var r := WiderlegungValidator.validate(base, lehre)
		var ms := Time.get_ticks_msec() - t0
		passed += 1 if r["ok"] else 0
		print("%s %s ok=%s cap=%s wuerfe=%s paare=%s %d ms %s" % [f, lehre.get("begriff", "?"), r["ok"], r["cap"], r.get("wuerfe", "-"), r["paare"], ms, str(r["befunde"]).left(80)])
	print("BESTANDEN %d/%d" % [passed, total])
	quit()
