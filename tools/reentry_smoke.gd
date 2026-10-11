# PURPOSE: Szenenfluss der App headless: Flur -> Karriere -> Flur -> Karriere (Wiedereintritt), Dialog offen blockiert den Rückweg, Hörsaal, Hinterzimmer, zurück. Gibt REENTRY_OK aus.
# ARCHITECTURE: tools
# DEPENDENCIES: FlurButton, Lobby-Loop main.tscn, DAME main_menu.tscn
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends SceneTree

# Aufruf: godot --headless --path . --script res://tools/reentry_smoke.gd
# tools/test-all.mjs wertet jede ERROR-Zeile als Fehlschlag.

const FLUR := "res://flur/flur.tscn"
const KARRIERE := "res://addons/lobby_loop/scenes/main.tscn"
const HOERSAAL := "res://hoersaal/hoersaal.tscn"
const HINTERZIMMER := "res://addons/dame/scenes/main_menu.tscn"

var _fail := []


func _initialize() -> void:
	_run()


func _settle(frames: int = 4) -> void:
	for i in frames:
		await process_frame


func _expect(cond: bool, msg: String) -> void:
	if not cond:
		_fail.append(msg)
		print("REENTRY_FAIL ", msg)


func _go(path: String) -> void:
	change_scene_to_file(path)
	await _settle()
	_expect(current_scene != null and current_scene.scene_file_path == path, "Szene %s nicht geladen" % path)


func _run() -> void:
	await _settle()
	# Testdateien statt echter Spielstände: Sonst läge beim ersten echten Start schon ein savegame.json
	# im Datenordner und die Migration würde den alten Lobby-Loop-Stand nicht übernehmen.
	root.get_node("App").use_test_storage()
	# use_test_storage schaltet auch DAMEs Szenenwechsel ab; hier wollen wir echte Wechsel.
	root.get_node("App").test_mode = false
	root.get_node("SaveManager").path = "user://test_smoke_savegame.json"
	var fb: Node = root.get_node("FlurButton")
	await _go(FLUR)
	_expect(not fb.can_leave(), "im Flur darf der Rückweg nicht angeboten werden")
	for round in 2:
		await _go(KARRIERE)
		_expect(fb.can_leave(), "Karriere ohne Dialog: Rückweg erlaubt")
		fb.go_to_flur()
		await _settle()
		_expect(current_scene.scene_file_path == FLUR, "Karriere -> Flur, Runde %d" % round)
	# Dialog offen: Rückweg gesperrt, Esc und Knopf tun nichts.
	await _go(KARRIERE)
	var overlay: Node = current_scene.get("_overlay")
	overlay.open_for_node({"id": "buergermeister", "type": "npc", "label": "Bürgermeister", "default_dc": 10, "fallback_dialogue": "x"}, "kommunalpolitik", [])
	await _settle()
	_expect(not fb.can_leave(), "offener Dialog sperrt den Rückweg")
	fb.go_to_flur()
	await _settle()
	_expect(current_scene.scene_file_path == KARRIERE, "go_to_flur bei offenem Dialog darf nicht wechseln")
	overlay.abort()
	await _settle()
	_expect(fb.can_leave(), "nach dem Schließen ist der Rückweg wieder frei")
	fb.go_to_flur()
	await _settle()
	await _go(HOERSAAL)
	await _go(HINTERZIMMER)
	_expect(fb.can_leave(), "DAME-Menü: Rückweg erlaubt")
	# Am Tisch kein Rückweg-Knopf: Ein Fehlklick würde die Partie verlassen, DAME hat dort ein eigenes Menü.
	var app: Node = root.get_node("App")
	app.new_match({"mode": "ai", "players": 4})
	await _settle(20)
	_expect(current_scene.scene_file_path == "res://addons/dame/scenes/table.tscn", "DAME-Tisch geladen")
	_expect(not fb.can_leave(), "am DAME-Tisch kein Rückweg-Knopf")
	app.goto(app.MAIN_MENU)
	await _settle()
	fb.go_to_flur()
	await _settle()
	_expect(current_scene.scene_file_path == FLUR, "Hinterzimmer -> Flur")
	print("REENTRY_OK" if _fail.is_empty() else "REENTRY_FAILED %d" % _fail.size())
	quit(0 if _fail.is_empty() else 1)
