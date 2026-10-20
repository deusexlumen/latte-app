# PURPOSE: Tor-Messung Phase 2: N Lehren über den echten Weg (Proxy -> Prüfung -> eine Nachbesserung -> Bibliothek) erfinden und zählen
# ARCHITECTURE: tools
# DEPENDENCIES: WiderlegungForge, ApiClient (Autoload), laufender gm-proxy
# PIPELINE: manual
# LAST_VALIDATED: 2026-10-12
extends SceneTree

# Aufruf: godot --headless --path . -s tools/lehre/forge_gate.gd -- <anzahl> <bibliotheks-ordner> [pause-sekunden] [proxy-url] [themen,kommagetrennt]

const THEMEN := [
	"Parkplatz", "Haustier", "Brief", "Werkzeug", "Getränk", "Fahrzeug", "Gebäude", "Musikinstrument",
	"Kleidungsstück", "Spielzeug", "Obst", "Vogel", "Behältnis", "Sportgerät", "Lichtquelle", "Schreibgerät",
	"Kopfbedeckung", "Brücke", "Insekt", "Formular",
]


func _initialize() -> void:
	_run()


func _run() -> void:
	# Autoloads hängen erst nach dem ersten Frame im Baum.
	await process_frame
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 20
	var dir: String = args[1] if args.size() > 1 else "user://forge_gate/"
	var pause := float(args[2]) if args.size() > 2 else 10.0
	var api: Node = root.get_node("ApiClient")
	if args.size() > 3:
		api.url_override = args[3]
	var themen: Array = THEMEN
	if args.size() > 4:
		themen = Array(args[4].split(","))
	var direct := 0
	var after_fix := 0
	var offline := 0
	var ms_all: Array = []
	for i in n:
		var thema: String = themen[i % themen.size()]
		var r: Dictionary = await WiderlegungForge.forge(api, thema, dir)
		ms_all.append_array(r["pruef_ms"])
		if r["ok"]:
			if r["versuche"] == 1:
				direct += 1
			else:
				after_fix += 1
		elif str(r["befunde"]).contains("nicht erreichbar"):
			offline += 1
		elif r.get("raw") is Dictionary:
			# Gescheiterte Entwürfe aufheben: Damit lassen sich Prüfung und Befunde ohne API-Quota nachstellen.
			DirAccess.make_dir_recursive_absolute(dir.path_join("failed"))
			var f := FileAccess.open(dir.path_join("failed").path_join("%02d.json" % i), FileAccess.WRITE)
			f.store_string(JSON.stringify(r["raw"]))
		print("GATE %02d %-16s ok=%s versuche=%d pruef_ms=%s befunde=%s" % [i, thema, r["ok"], r["versuche"], r["pruef_ms"], r["befunde"]])
		if i < n - 1:
			await create_timer(pause).timeout
	ms_all.sort()
	var median: int = ms_all[ms_all.size() / 2] if not ms_all.is_empty() else 0
	print("GATE ERGEBNIS: %d/%d bestanden (direkt %d, nach Nachbesserung %d), Spielleiter nicht erreichbar %d, Prüfdauer Median %d ms, max %d ms" % [direct + after_fix, n, direct, after_fix, offline, median, ms_all.back() if not ms_all.is_empty() else 0])
	quit()
