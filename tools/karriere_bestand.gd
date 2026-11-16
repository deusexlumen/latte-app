# PURPOSE: Bestandslauf der Karriere über ihren regulären Einstieg (Flur -> Tür „Karriere“), ohne Spielleiter (wie im Browser).
# PURPOSE: Verfolgt eine Entscheidung bis zum Ende ihrer Spur und vergleicht sie mit der Gegenentscheidung. Gibt ein Protokoll aus.
# ARCHITECTURE: tools
# DEPENDENCIES: Flur, Lobby-Loop main.tscn, GameState, SaveManager, ApiClient (unerreichbar = Rückfall)
# PIPELINE: untersuchung (docs/karriere-versuch-2026-11.md)
# LAST_VALIDATED: 2026-11-16
extends SceneTree

# Aufruf: godot --headless --path . --script res://tools/karriere_bestand.gd

const FLUR := "res://flur/flur.tscn"
const SAVE := "user://test_bestand_savegame.json"


func _initialize() -> void:
	_run()


func _settle(frames: int = 4) -> void:
	for i in frames:
		await process_frame


func _log(text: String) -> void:
	print("BESTAND | ", text)


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text.contains(text):
		return node
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _all_buttons(node: Node, out: Array) -> void:
	if node is Button and (node as Button).is_visible_in_tree():
		out.append((node as Button).text)
	for child in node.get_children():
		_all_buttons(child, out)


func _hotspots() -> Array:
	var out := []
	for child in current_scene.get("_room_area").get_children():
		if child is Button and not child.is_queued_for_deletion():
			out.append(child.text)
	return out


func _snapshot() -> String:
	var gs: Node = root.get_node("GameState")
	return JSON.stringify(gs.get_save_dict())


## Eine Handlung an einem Knoten: Hotspot anklicken, eine der angebotenen Aktionen wählen, würfeln, schließen.
func _act(hotspot: String, action_index: int) -> Dictionary:
	var gs: Node = root.get_node("GameState")
	var before := _snapshot()
	_find_button(current_scene.get("_room_area"), hotspot).pressed.emit()
	await _settle()
	var overlay: Node = current_scene.get("_overlay")
	var known_before := "Titel=%s | Hinweis=%s" % [overlay._title_label.text, overlay._hint_label.text]
	var actions: Array = overlay._absurd_box.get_children()
	var chosen := ""
	if action_index >= 0 and action_index < actions.size():
		chosen = actions[action_index].text
		actions[action_index].pressed.emit()
	else:
		chosen = "(eigene Absicht) Ich bitte um eine ehrliche Auskunft."
		overlay._intent_edit.text = chosen
		overlay._submit_button.pressed.emit()
	# Der Spielleiter ist nicht erreichbar: warten, bis der Rückfall geantwortet hat (Würfelknopf frei).
	var guard := 0
	while overlay._roll_button.disabled and guard < 2000:
		await process_frame
		guard += 1
	var dc_text: String = overlay._dc_label.text
	var gm_text: String = overlay._gm_label.text
	overlay._roll_button.pressed.emit()
	guard = 0
	while overlay._close_button.disabled and guard < 2000 and overlay.visible:
		await process_frame
		guard += 1
	var roll_text: String = overlay._roll_result_label.text
	var commentary: String = overlay._commentary_label.text
	if overlay.visible:
		overlay._close_button.pressed.emit()
	await _settle()
	return {
		"hotspot": hotspot, "chosen": chosen, "known_before": known_before, "offline": overlay._offline,
		"gm": gm_text, "dc": dc_text, "roll": roll_text, "commentary": commentary,
		"state_changed": before != _snapshot(), "state_after": _snapshot(),
		"scene": gs.current_scene,
	}


func _fresh() -> void:
	var gs: Node = root.get_node("GameState")
	gs.load_from_dict(SaveData.fresh_state())
	gs.run_stats = RunStats.new()
	JsonStore.remove(SAVE)


func _enter_career() -> void:
	change_scene_to_file(FLUR)
	await _settle()
	var door := _find_button(current_scene, "Karriere")
	_log("Flur: Tür gefunden = %s" % (door != null))
	door.pressed.emit()
	await _settle(8)
	_log("Szene nach dem Klick: %s" % current_scene.scene_file_path)


func _run() -> void:
	await _settle()
	root.get_node("App").use_test_storage()
	root.get_node("App").test_mode = false
	root.get_node("SaveManager").path = SAVE
	var gs: Node = root.get_node("GameState")

	# ---- Lauf A: Entscheidung 1 beim Bürgermeister (erste angebotene Aktion)
	_fresh()
	await _enter_career()
	_log("Titel: %s" % current_scene.get("_title_label").text)
	_log("Einleitung: %s" % current_scene.get("_intro_label").text)
	_log("Anzeige: %s" % current_scene.get("_stats_label").text)
	_log("Anklickbar im Raum: %s" % str(_hotspots()))
	_log("Inventar zu Beginn: %s" % str(gs.inventory))
	seed(20261116)
	var a: Dictionary = await _act("Bürgermeister", 0)
	_log("A gewählt: %s" % a["chosen"])
	_log("A vorher bekannt: %s" % a["known_before"])
	_log("A Rückfall statt Spielleiter: %s | Antwort: %s | %s" % [a["offline"], a["gm"], a["dc"]])
	_log("A Wurf: %s" % a["roll"])
	_log("A Kommentar: %s" % a["commentary"])
	_log("A Spielstand verändert: %s" % a["state_changed"])
	var save_a := FileAccess.get_file_as_string(SAVE)

	# ---- Lauf B: dieselbe Stelle, Gegenentscheidung (zweite Aktion), derselbe Würfel-Seed
	_fresh()
	await _enter_career()
	seed(20261116)
	var b: Dictionary = await _act("Bürgermeister", 1)
	_log("B gewählt: %s" % b["chosen"])
	_log("B Wurf: %s" % b["roll"])
	_log("B Kommentar: %s" % b["commentary"])
	var save_b := FileAccess.get_file_as_string(SAVE)
	_log("Spielstand-Datei A == B: %s" % (save_a == save_b))
	_log("Antwort des Amts A == B: %s" % (a["gm"] == b["gm"] and a["commentary"] == b["commentary"]))

	# ---- Die Spur der Entscheidung: wo taucht sie noch auf?
	var stats: Dictionary = gs.get_run_stats()
	_log("Spur in der Sitzungsakte: %d Würfe, %d Ereignisse; der Wortlaut der Absicht ist gespeichert: %s" % [
		(stats["rolls"] as Array).size(), (stats["events"] as Array).size(), JSON.stringify(stats).contains("Bürgermeister")])
	_log("Spur in der Spielstand-Datei: %s" % save_b.replace("\n", " ").replace("  ", ""))

	# ---- Alle vier Knoten der Kommunalpolitik einmal, dann „Nach Berlin“
	for h in ["Aktenordner", "Fahrradweg-Planungskarte", "Kündigung Sportheim"]:
		var r: Dictionary = await _act(h, 0)
		_log("%s: %s -> %s | Stand verändert: %s" % [h, r["roll"], r["commentary"], r["state_changed"]])
	_log("Ausgang gesucht: Bedingung für „Nach Berlin“? Würfe bisher %d, Erfolge %d" % [gs.run_stats.roll_count(), gs.run_stats.successful_rolls()])
	_find_button(current_scene.get("_room_area"), "Nach Berlin").pressed.emit()
	await _settle()
	_log("Nach dem Klick auf „Nach Berlin“: Szene = %s, Anklickbar = %s" % [gs.current_scene, str(_hotspots())])
	var exits: Array = current_scene.get("_scene_data").get("exits", [])
	_log("Ausgänge aus dem Untersuchungsausschuss: %d" % exits.size())

	# ---- Untersuchungsausschuss: Ermittlungsführer (Kreuzverhör laut Text) und Zeugenstuhl
	var e: Dictionary = await _act("Ermittlungsführer", 0)
	var mg: Node = current_scene.get("_minigame")
	_log("Ermittlungsführer: %s -> %s | Kreuzverhör gestartet: %s | Stand verändert: %s" % [e["roll"], e["commentary"], mg.is_open(), e["state_changed"]])
	var tries := 0
	var wid: Node = current_scene.get("_widerlegung")
	while not wid.is_open() and tries < 12:
		var z: Dictionary = await _act("Zeugenstuhl", 0)
		tries += 1
		_log("Zeugenstuhl Versuch %d: %s | Widerlegung offen: %s" % [tries, z["roll"], wid.is_open()])
	if wid.is_open():
		_log("Widerlegung: Lehre %s, Hand %s" % [wid.lehre_id(), str(wid.hand_ids())])
		var guard := 0
		while wid.is_playing() and guard < 60:
			var hand: Array = wid.hand_ids()
			if hand.is_empty():
				break
			wid.play_card(str(hand[0]))
			guard += 1
		_log("Widerlegung beendet nach %d Karten: %s" % [guard, JSON.stringify(wid._result)])
		wid.close()
		await _settle()
		_log("Anzeige danach: %s | Inventar: %s" % [current_scene.get("_stats_label").text, str(gs.inventory)])

	# ---- Der „Aufstieg“: Welche Bedingung hat der Weg durch die Szenen?
	var route: Array = [gs.current_scene]
	for step in 6:
		var exits_here: Array = current_scene.get("_scene_data").get("exits", [])
		if exits_here.is_empty():
			break
		var last: Dictionary = exits_here[exits_here.size() - 1]
		_find_button(current_scene.get("_room_area"), str(last["label"])).pressed.emit()
		await _settle()
		route.append(gs.current_scene)
	_log("Weg durch die Szenen, jeweils letzter Ausgang, ohne eine einzige Handlung: %s" % " -> ".join(PackedStringArray(route)))
	_log("Fraktionsdisziplin danach: %d. Sie fällt ohne Spielleiter nur in Widerlegung, Kreuzverhör und Hinterzimmer." % gs.fraktionsdisziplin)
	print("BESTAND_OK")
	quit(0)
