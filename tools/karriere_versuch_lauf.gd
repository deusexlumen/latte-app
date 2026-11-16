# PURPOSE: Spielt den Versuch „Zwei Bücher“ über den Flur (Knopf „Versuch“) mit zwei gegensätzlichen Haltungen und gibt aus, was der Spieler jeweils liest.
# PURPOSE: Unter xvfb (nicht headless) mit „-- bilder <Ordner>“ zusätzlich Bildschirmfotos.
# ARCHITECTURE: tools
# DEPENDENCIES: Flur, karriere_kern/versuch.tscn
# PIPELINE: untersuchung (docs/karriere-versuch-2026-11.md)
# LAST_VALIDATED: 2026-11-16
extends SceneTree

# Aufruf: godot --headless --path . --script res://tools/karriere_versuch_lauf.gd

const FLUR := "res://flur/flur.tscn"
## Je Lauf: was der Spieler in jeder Periode anklickt (Teil des Knopftexts), in dieser Reihenfolge.
const RUNS := {
	"Lauf 1, tüchtig: jede Meldung erledigen, nichts offen lassen": {
		1: ["Mertens anrufen"], 2: ["Mertens anrufen"], 3: ["Mertens anrufen"],
		5: ["Aushilfe einsetzen: Sporthalle", "Aushilfe einsetzen: Brücke"],
	},
	"Lauf 2, sichtbar: liegen lassen und beantragen": {
		1: ["Sanierung beantragen: Sporthalle"], 2: ["Sanierung beantragen: Sporthalle"],
	},
}

var _shots := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("bilder") and args.size() > args.find("bilder") + 1:
		_shots = args[args.find("bilder") + 1]
	_run()


func _settle(frames: int = 6) -> void:
	for i in frames:
		await process_frame


func _screen() -> void:
	for node in current_scene.find_children("*", "Label", true, false):
		if (node as Label).is_visible_in_tree():
			print("    ", (node as Label).text)
	print("    Knöpfe: ", current_scene.button_texts())


func _shot(name: String) -> void:
	if _shots == "":
		return
	await _settle(20)
	root.get_texture().get_image().save_png("%s/%s.png" % [_shots, name])


func _run() -> void:
	await _settle()
	var app := root.get_node_or_null("App")
	if app != null:
		app.use_test_storage()
		app.test_mode = false
	root.size = Vector2i(1280, 720)
	change_scene_to_file(FLUR)
	await _settle()
	for b in current_scene.find_children("*", "Button", true, false):
		if (b as Button).text == "Versuch":
			(b as Button).pressed.emit()
	await _settle(10)
	print("VERSUCH | Szene nach dem Klick im Flur: ", current_scene.scene_file_path)
	_screen()
	await _shot("0-anfang")
	var n := 0
	for title in RUNS:
		n += 1
		print("\nVERSUCH | ===== ", title, " =====")
		if n > 1:
			current_scene.press("Zum Anfang des Versuchs")
		current_scene.press("Wahlzeit beginnen")
		var plan: Dictionary = RUNS[title]
		while not bool(current_scene.state["over"]):
			var period := int(current_scene.state["period"])
			print("VERSUCH | --- Periode ", period)
			_screen()
			if period == 1 or period == 5 or period == 7:
				await _shot("%d-periode-%d" % [n, period])
			for click in plan.get(period, []):
				print("VERSUCH | Klick: ", click, " -> ", current_scene.press(click))
			current_scene.press("Periode beenden")
		print("VERSUCH | --- Ende")
		_screen()
		await _shot("%d-ende" % n)
	print("VERSUCH_OK")
	quit(0)
