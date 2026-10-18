# PURPOSE: Eine laufende Transaktion des Weltkerns: Arbeitskopie des Zustands, der Befehl und die bisher erzeugten Ereignisse.
# PURPOSE: emit() stempelt ein Ereignis (Kennung, Zug, Phase, Ursache) und wendet seine Operationen an.
# ARCHITECTURE: core
# DEPENDENCIES: AmtWorld
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
class_name AmtTransaction
extends RefCounted

var state: Dictionary
var command: Dictionary
var params: Dictionary
var events: Array = []
## Erster Ablehnungsgrund. Ist er gesetzt, verwirft AmtWorld.execute die Arbeitskopie.
var error := ""
## Nummer der laufenden Diensthandlung; bei kostenlosen Befehlen der aktuelle Uhrstand.
var turn := 0
## Art und Ort der laufenden Diensthandlung ("" ohne Handlung, etwa beim Dienstschluss).
var action_kind := ""
var action_location := ""
## Stellen, mit denen diese Handlung Kontakt hatte.
var contacts := {}


func _init(p_state: Dictionary, p_command: Dictionary) -> void:
	state = p_state
	command = p_command
	params = command.get("params", {}) if command.get("params") is Dictionary else {}
	turn = int(state["turn"])


func command_id() -> String:
	return str(command["command_id"])


## Kennung, die das nächste emit() vergibt. Für Einträge, die auf ihr eigenes Ereignis verweisen (Wissen, Planung).
func next_event_id() -> String:
	return "evt-%s-%03d" % [str(command["case_id"]).to_lower().replace("-", ""), int(state["event_counter"]) + 1]


func emit(type: String, actor_id: String, payload: Dictionary, ops: Array = [], caused_by: Array = []) -> String:
	var id := next_event_id()
	state["event_counter"] = int(state["event_counter"]) + 1
	var ev := {
		"event_id": id,
		"transaction_id": "tx-" + command_id(),
		"type": type,
		"actor_id": actor_id,
		"case_id": str(command["case_id"]),
		"turn": turn,
		"phase": str(state["phase"]),
		"caused_by": caused_by.duplicate() if not caused_by.is_empty() else [command_id()],
		"payload": payload,
		"ops": ops,
	}
	AmtWorld.apply_ops(state, ops)
	(state["events"] as Array).append(ev)
	events.append(ev)
	return id


func fail(reason: String) -> void:
	if error.is_empty():
		error = reason
