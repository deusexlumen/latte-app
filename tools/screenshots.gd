# PURPOSE: Macht die Bildschirmfotos für die README aus einem echten Lauf (nicht headless, z. B. unter xvfb-run).
# ARCHITECTURE: tools
# DEPENDENCIES: Flur, Innenhof, Hörsaal, Hinterzimmer, Karriere-Szene
# PIPELINE: test
# LAST_VALIDATED: 2026-10-19
extends SceneTree

# Aufruf: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --script res://tools/screenshots.gd
# Schreibt nach docs/bilder/. Läuft mit Teststandort für Spielstände, damit nichts Echtes berührt wird.

const OUT := "res://docs/bilder/"
const SHOTS := [
	["flur", "res://flur/flur.tscn"],
	["innenhof", "res://amt/vorgang.tscn"],
	["karriere", "res://addons/lobby_loop/scenes/main.tscn"],
	["hoersaal", "res://hoersaal/hoersaal.tscn"],
	["hinterzimmer", "res://hinterzimmer/hinterzimmer.tscn"],
	["akte", "res://akte/akte.tscn"],
]


func _initialize() -> void:
	_run()


func _run() -> void:
	var app := root.get_node_or_null("App")
	if app != null:
		app.use_test_storage()
	root.size = Vector2i(1280, 720)
	for shot in SHOTS:
		change_scene_to_file(shot[1])
		for i in 40:
			await process_frame
		var img := root.get_texture().get_image()
		var path := ProjectSettings.globalize_path(OUT + "%s.png" % shot[0])
		var err := img.save_png(path)
		print("SHOT ", shot[0], " ", img.get_size(), " err=", err)
	quit(0)
