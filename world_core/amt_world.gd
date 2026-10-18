# PURPOSE: Weltkern des Amts (Spezifikation 0.1, Kap. 5, 15.3, 16): ein Zustand, ein Änderungspfad. Ein Befehl wird geprüft und erzeugt Ereignisse;
# PURPOSE: nur deren Operationen ändern den Zustand. Dazu Uhr, Aufmerksamkeit der Stellen und geplante Abläufe der Dienstaufsicht (Kap. 8.4).
# ARCHITECTURE: core
# DEPENDENCIES: AmtTransaction
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
class_name AmtWorld
extends RefCounted

const SCHEMA_VERSION := 1
const ATTENTION_MAX := 3
## Nach so vielen Diensthandlungen ohne Kontakt sinkt die Aufmerksamkeit einer Stelle um 1.
const ATTENTION_DECAY_AFTER := 2
## Buchführung des Kerns, kein Weltzustand: beim Nachspielen der Ereignisse nicht vergleichen.
const BOOKKEEPING := ["events", "applied_transactions", "event_counter"]


## Gerüst eines Zustands (WorldState, Kap. 16.1). Der Fall füllt cases, actors, offices, objects.
static func new_state(content_version: String, run_id: String) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"content_version": content_version,
		"run_id": run_id,
		"phase": "",
		"turn": 0,
		"location": "",
		"cases": {},
		"actors": {},
		"offices": {},
		"objects": {},
		"documents": {},
		"evidence": {},
		"knowledge": [],
		"rules": [],
		"pending_events": {},
		"sessions": {},
		"events": [],
		"applied_transactions": [],
		"event_counter": 0,
	}


## Ein Befehl = eine Transaktion. Ergebnis: {"ok", "state", "events", "reason", "duplicate"}.
## Der übergebene Zustand bleibt unberührt. Scheitert die Prüfung, gilt keine einzige Änderung.
## rules: Skript der Fallsteuerung mit static func handle(tx: AmtTransaction) -> void.
static func execute(state: Dictionary, command: Variant, rules: GDScript) -> Dictionary:
	var reason := command_error(state, command)
	if not reason.is_empty():
		return {"ok": false, "state": state, "events": [], "reason": reason, "duplicate": false}
	# Doppelklick, doppelt übertragen: dieselbe Kennung ändert nichts ein zweites Mal.
	if (state["applied_transactions"] as Array).has(command["command_id"]):
		return {"ok": true, "state": state, "events": [], "reason": "", "duplicate": true}
	var tx := AmtTransaction.new(state.duplicate(true), command)
	rules.handle(tx)
	if not tx.error.is_empty():
		return {"ok": false, "state": state, "events": [], "reason": tx.error, "duplicate": false}
	(tx.state["applied_transactions"] as Array).append(command["command_id"])
	return {"ok": true, "state": tx.state, "events": tx.events, "reason": "", "duplicate": false}


## Form eines Befehls (Kap. 16.2). Fachliche Voraussetzungen prüft der Fall.
static func command_error(state: Dictionary, command: Variant) -> String:
	if not (command is Dictionary):
		return "Befehl ist kein Objekt."
	var c: Dictionary = command
	if int(c.get("schema_version", 0)) != SCHEMA_VERSION:
		return "Unbekannte Befehlsfassung."
	if not (c.get("command_id") is String) or str(c["command_id"]).is_empty():
		return "Befehl ohne Kennung."
	if not (c.get("type") is String) or str(c["type"]).is_empty():
		return "Befehl ohne Art."
	if not (state["cases"] as Dictionary).has(str(c.get("case_id", ""))):
		return "Unbekannter Vorgang."
	if c.has("params") and not (c["params"] is Dictionary):
		return "Parameter sind kein Objekt."
	return ""


# --- Operationen: der einzige Ort, an dem sich der Weltzustand ändert ---

static func op_set(path: Array, value: Variant) -> Dictionary:
	return {"op": "set", "path": path, "value": value}


static func op_inc(path: Array, delta: int, lo: int, hi: int) -> Dictionary:
	return {"op": "inc", "path": path, "delta": delta, "min": lo, "max": hi}


static func op_append(path: Array, value: Variant) -> Dictionary:
	return {"op": "append", "path": path, "value": value}


static func op_erase(path: Array) -> Dictionary:
	return {"op": "erase", "path": path}


static func apply_ops(state: Dictionary, ops: Array) -> void:
	for op in ops:
		var path: Array = op["path"]
		var parent: Variant = state
		for i in path.size() - 1:
			parent = parent[path[i]]
		var key: Variant = path[path.size() - 1]
		match str(op["op"]):
			"set":
				parent[key] = _copy(op["value"])
			"inc":
				parent[key] = clampi(int(parent[key]) + int(op["delta"]), int(op["min"]), int(op["max"]))
			"append":
				(parent[key] as Array).append(_copy(op["value"]))
			"erase":
				(parent as Dictionary).erase(key)
			_:
				push_error("Unbekannte Operation: %s" % str(op["op"]))


## Werte aus Ereignissen nie teilen: Sonst würde eine spätere Änderung am Zustand das Protokoll umschreiben.
static func _copy(v: Variant) -> Variant:
	if v is Dictionary or v is Array:
		return v.duplicate(true)
	return v


# --- Nachprüfbarkeit ---

## Spielt die Operationen aller Ereignisse auf einem Anfangszustand nach.
static func replay(initial: Dictionary, events: Array) -> Dictionary:
	var s := initial.duplicate(true)
	for ev in events:
		apply_ops(s, ev["ops"])
	return s


## Zustand ohne Buchführung (für Vergleiche nach dem Nachspielen).
static func world_part(state: Dictionary) -> Dictionary:
	var out := state.duplicate(true)
	for k in BOOKKEEPING:
		out.erase(k)
	return out


## Herkunft prüfen (Kap. 16.3): Jede Ursache ist ein Befehl dieses Verlaufs oder ein früheres Ereignis.
## Damit kann kein zukünftiges Ereignis Quelle eines vergangenen sein, und Zyklen sind ausgeschlossen.
static func causality_errors(state: Dictionary) -> Array:
	var commands := {}
	for c in state["applied_transactions"]:
		commands[c] = true
	var seen := {}
	var out := []
	for ev in state["events"]:
		var causes: Array = ev["caused_by"]
		if causes.is_empty():
			out.append("%s ohne Ursache" % ev["event_id"])
		for cause in causes:
			if not seen.has(cause) and not commands.has(cause):
				out.append("%s: Ursache %s unbekannt oder später" % [ev["event_id"], cause])
		seen[ev["event_id"]] = true
	return out


# --- Dienstaufsicht: Uhr, Aufmerksamkeit, geplante Abläufe (Kap. 6.1, 8.4) ---

## Beginn einer Diensthandlung: Ereignisse dieser Handlung tragen ihre Nummer.
static func begin_action(tx: AmtTransaction, kind: String) -> void:
	tx.turn = int(tx.state["turn"]) + 1
	tx.action_kind = kind
	tx.action_location = str(tx.state["location"])
	tx.contacts = {}


## Kontakt mit einer Stelle hält ihre Aufmerksamkeit wach.
static func contact(tx: AmtTransaction, office: String) -> void:
	tx.contacts[office] = true


## Aufmerksamkeit einer Stelle ändern (0 bis 3). Gibt die neue Stufe zurück.
static func raise_attention(tx: AmtTransaction, office: String, delta: int, grund: String) -> int:
	contact(tx, office)
	var before := int(tx.state["offices"][office]["attention"])
	var after := clampi(before + delta, 0, ATTENTION_MAX)
	if after != before:
		tx.emit("attention_changed", office, {"office": office, "from": before, "to": after, "grund": grund},
			[op_set(["offices", office, "attention"], after)])
	return after


## Schritt 3, Abbau: Stellen ohne Kontakt in den letzten zwei Handlungen werden ruhiger. Kontakte merken sich die Handlung.
static func settle_attention(tx: AmtTransaction) -> void:
	var ops := []
	var sunk := []
	for office in tx.state["offices"]:
		var o: Dictionary = tx.state["offices"][office]
		if tx.contacts.has(office):
			ops.append(op_set(["offices", office, "last_contact"], tx.turn))
		elif int(o["attention"]) > 0 and tx.turn - int(o["last_contact"]) >= ATTENTION_DECAY_AFTER:
			ops.append(op_set(["offices", office, "attention"], int(o["attention"]) - 1))
			ops.append(op_set(["offices", office, "last_contact"], tx.turn))
			sunk.append(office)
	if not ops.is_empty():
		tx.emit("attention_settled", "", {"kontakt": tx.contacts.keys(), "gesunken": sunk}, ops)


## Schritt 5: Uhr fortschreiben, eine Diensthandlung des Vorgangs verbraucht.
static func advance_clock(tx: AmtTransaction, case_id: String) -> void:
	tx.emit("clock_advanced", "", {"turn": tx.turn}, [
		op_set(["turn"], tx.turn),
		op_inc(["cases", case_id, "hours_remaining"], -1, 0, 99),
	])


## Eintrag für einen geplanten Ablauf. Mit der Operation ins planende Ereignis legen; scheduled_by ist dessen Kennung.
static func pending_entry(id: String, action: String, params: Dictionary, due_turn: int, due_phase: String, scheduled_by: String) -> Dictionary:
	return {"id": id, "action": action, "params": params, "due_turn": due_turn, "due_phase": due_phase, "scheduled_by": scheduled_by}


## Fällige Abläufe in der Reihenfolge ihrer Planung ausführen. Je Ablauf trägt ein Ereignis "due" ihn aus;
## run(pending, due_event_id) erzeugt die Folgen und nennt dieses Ereignis als Ursache.
static func process_due(tx: AmtTransaction, is_due: Callable, run: Callable) -> void:
	for id in (tx.state["pending_events"] as Dictionary).keys():
		if not (tx.state["pending_events"] as Dictionary).has(id):
			continue
		var p: Dictionary = tx.state["pending_events"][id]
		if not is_due.call(p):
			continue
		var ev := tx.emit("due", "", {"pending_id": id, "action": p["action"]},
			[op_erase(["pending_events", id])], [str(p["scheduled_by"])])
		run.call(p, ev)
