# PURPOSE: DAME als Hinterzimmer des Vorgangs BANK-01 (Spezifikation 0.1, Kap. 8.3, 9.6, 12.1, 17.1): startet oder setzt die Partie fort, blendet über,
# PURPOSE: hält das Ergebnis bis der Vorgang es verbucht und führt nach der Partie in den Innenhof zurück. Nur eine Partie mit der match_id der Session zählt.
# ARCHITECTURE: autoload
# DEPENDENCIES: App (DAME), Uebergang, BankDame, Bank01
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
extends Node

const VORGANG := "res://amt/vorgang.tscn"
const FLUR := "res://flur/flur.tscn"
## Dorthin kehrt DAME nach der Partie zurück (App.home_scene, gesetzt vom Autoload Hinterzimmer).
const HOME := "res://hinterzimmer/hinterzimmer.tscn"
const ROOM := "room_amt"

## {"session_id", "match_id"} solange eine Partie dieses Vorgangs läuft.
var active := {}
## Beendete Partie, die der Vorgang noch nicht verbucht hat.
var result := {}
## Rückkehr in den Innenhof steht aus (sobald DAME den Tisch verlässt).
var return_pending := false
var _prev_room := ""
var _room_swapped := false


func _ready() -> void:
	var app := get_node_or_null("/root/App")
	if app != null:
		app.match_finished.connect(_on_match_finished)


func _process(_delta: float) -> void:
	if not return_pending:
		return
	var scene := get_tree().current_scene
	var path: String = scene.scene_file_path if scene != null else ""
	if path == HOME:
		return_pending = false
		_go_back()
	elif path == VORGANG or path == FLUR:
		# Wer von selbst zurückgegangen ist, wird nicht noch einmal umgeleitet.
		return_pending = false


## Neue Partie für die laufende Session. Gleiche Konfiguration und gleicher Seed wie bei jedem Neustart.
func start(state: Dictionary, session: Dictionary) -> void:
	var app := get_node("/root/App")
	active = {"session_id": str(session["session_id"]), "match_id": str(session["match_id"])}
	result = {}
	return_pending = false
	var cfg := BankDame.match_config(state, session, str(app.settings.get_value("player_name")))
	await _enter(func() -> void: app.new_match(cfg))


## Gehört der gespeicherte DAME-Spielstand zu dieser Session?
func can_resume(session: Dictionary) -> bool:
	var app := get_node_or_null("/root/App")
	if app == null or app.saves == null:
		return false
	var saved: Dictionary = app.saves.load_match()
	return not saved.is_empty() and str(saved["meta"].get("match_id", "")) == str(session["match_id"])


func resume(session: Dictionary) -> void:
	var app := get_node("/root/App")
	active = {"session_id": str(session["session_id"]), "match_id": str(session["match_id"])}
	result = {}
	return_pending = false
	await _enter(func() -> void: app.resume_match())


## Abbruch: Ein Spielstand dieser Session wird verworfen, ein fremder bleibt.
func discard(session: Dictionary) -> void:
	if can_resume(session):
		get_node("/root/App").saves.clear()
	active = {}
	result = {}
	return_pending = false
	_restore_room()


## Das Ergebnis der beendeten Partie, einmal. Danach ist die Session nicht mehr aktiv.
func take_result() -> Dictionary:
	var r := result
	result = {}
	if not r.is_empty():
		active = {}
	_restore_room()
	return r


func _enter(launch: Callable) -> void:
	_use_room()
	await Uebergang.cover("Hinterzimmer")
	launch.call()
	await Uebergang.reveal()


func _go_back() -> void:
	await Uebergang.cover("Innenhof")
	get_tree().change_scene_to_file(VORGANG)
	await Uebergang.reveal()


func _on_match_finished(match_result: Dictionary) -> void:
	if active.is_empty() or bool(match_result.get("online", false)):
		return
	if str(match_result.get("match_id", "")) != str(active["match_id"]):
		return
	result = match_result
	return_pending = true


## Die Begegnung findet in der Amtsstube statt, die Raumwahl des Spielers kommt danach zurück.
func _use_room() -> void:
	var app := get_node_or_null("/root/App")
	if app == null or app.profile == null or _room_swapped or not app.profile.owns(ROOM):
		return
	_prev_room = str(app.profile.equipped("room"))
	if _prev_room != ROOM:
		app.profile.equip(ROOM)
		_room_swapped = true


func _restore_room() -> void:
	if not _room_swapped:
		return
	_room_swapped = false
	var app := get_node_or_null("/root/App")
	if app != null and app.profile != null and not _prev_room.is_empty():
		app.profile.equip(_prev_room)
