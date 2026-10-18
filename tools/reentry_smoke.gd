# PURPOSE: Szenenfluss der App headless: Flur -> Karriere -> Flur -> Karriere (Wiedereintritt), Dialog offen blockiert den Rückweg, Hörsaal, Innenhof (BANK-01, inkl. DAME-Tisch und Rückkehr), Hinterzimmer, zurück. Gibt REENTRY_OK aus.
# ARCHITECTURE: tools
# DEPENDENCIES: FlurButton, Lobby-Loop main.tscn, Hinterzimmer (hinterzimmer.tscn), amt/vorgang.tscn, AmtStore, VorgangDame
# PIPELINE: test
# LAST_VALIDATED: 2026-10-18
extends SceneTree

# Aufruf: godot --headless --path . --script res://tools/reentry_smoke.gd
# tools/test-all.mjs wertet jede ERROR-Zeile als Fehlschlag.

const FLUR := "res://flur/flur.tscn"
const KARRIERE := "res://addons/lobby_loop/scenes/main.tscn"
const HOERSAAL := "res://hoersaal/hoersaal.tscn"
const HINTERZIMMER := "res://hinterzimmer/hinterzimmer.tscn"
const INNENHOF := "res://amt/vorgang.tscn"

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
	# Der Innenhof liest headless seine Testdatei; jeder Lauf beginnt frisch.
	for p in [AmtStore.HEADLESS_PATH, AmtStore.prev_path(AmtStore.HEADLESS_PATH)]:
		JsonStore.remove(p)
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
	# Innenhof (BANK-01): Handlung ausführen, Rückweg frei, Stand bleibt beim Wiedereintritt erhalten.
	await _go(INNENHOF)
	_expect(fb.can_leave(), "Innenhof: Rückweg erlaubt")
	current_scene.run("move", {"to": "innenhof"})
	current_scene.run("open_case")
	fb.go_to_flur()
	await _settle()
	await _go(INNENHOF)
	_expect(str(current_scene.state["cases"]["BANK-01"]["status"]) == "open", "Innenhof: Stand nach Wiedereintritt erhalten")
	# E3: Abend im Hinterzimmer. Innenhof -> DAME-Tisch (eigene Partie des Vorgangs) -> Ergebnis -> zurück in den Innenhof.
	current_scene.run("end_day")
	current_scene.run("start_minigame", {"game": "dame"})
	var session: Dictionary = Bank01.running_session(current_scene.state)
	_expect(not session.is_empty(), "DAME-Session läuft")
	current_scene.start_dame()
	await _settle(20)
	_expect(current_scene.scene_file_path == "res://addons/dame/scenes/table.tscn", "Innenhof startet den DAME-Tisch")
	_expect(not fb.can_leave(), "am DAME-Tisch kein Rückweg-Knopf")
	var vd: Node = root.get_node("VorgangDame")
	_expect(str(vd.active.get("match_id", "")) == str(session["match_id"]), "VorgangDame kennt die Partie")
	var table_app: Node = root.get_node("App")
	# Eine fremde Partie ändert nichts am Vorgang.
	table_app.match_finished.emit({"won": true, "score": 1, "online": false, "mode": "new", "match_id": "m42"})
	_expect(vd.result.is_empty(), "fremde Partie wird ignoriert")
	table_app.match_finished.emit({"won": true, "score": 9, "online": false, "mode": "new", "match_id": session["match_id"]})
	table_app.goto(table_app.home_scene)
	await _settle(8)
	_expect(current_scene.scene_file_path == INNENHOF, "nach der Partie zurück in den Innenhof")
	_expect(Bank01.running_session(current_scene.state).is_empty(), "Ergebnis der Partie verbucht")
	_expect(current_scene.state["actors"]["mertens"]["commitments"].has("stuhl"), "Sieg im Hinterzimmer: Mertens sagt den Stuhl zu")
	await _go(HINTERZIMMER)
	_expect(fb.can_leave(), "Hinterzimmer: Rückweg erlaubt")
	# Am Tisch kein Rückweg-Knopf: Ein Fehlklick würde die Partie verlassen, DAME hat dort ein eigenes Menü.
	var app: Node = root.get_node("App")
	app.new_match({"mode": "ai", "players": 4})
	await _settle(20)
	_expect(current_scene.scene_file_path == "res://addons/dame/scenes/table.tscn", "DAME-Tisch geladen")
	_expect(not fb.can_leave(), "am DAME-Tisch kein Rückweg-Knopf")
	app.goto(app.home_scene)
	await _settle()
	# Phase 4: Karriere -> Hinterzimmer-Tür -> DAME-Tisch -> Ergebnis -> zurück in die Karriere.
	await _go(KARRIERE)
	var gs: Node = root.get_node("GameState")
	gs.start_minigame("dame", {})
	await _settle(20)
	_expect(current_scene.scene_file_path == "res://addons/dame/scenes/table.tscn", "Karriere startet den DAME-Tisch")
	var disziplin: int = gs.fraktionsdisziplin
	app.match_finished.emit({"won": true, "score": 5, "online": false})
	app.goto(app.home_scene)
	await _settle(6)
	_expect(current_scene.scene_file_path == KARRIERE, "nach der Karriere-Partie zurück in die Karriere")
	_expect(gs.fraktionsdisziplin == mini(disziplin + 1, 10), "Sieg im Hinterzimmer zählt für die Karriere")
	fb.go_to_flur()
	await _settle()
	await _go(HINTERZIMMER)
	fb.go_to_flur()
	await _settle()
	_expect(current_scene.scene_file_path == FLUR, "Hinterzimmer -> Flur")
	print("REENTRY_OK" if _fail.is_empty() else "REENTRY_FAILED %d" % _fail.size())
	quit(0 if _fail.is_empty() else 1)
