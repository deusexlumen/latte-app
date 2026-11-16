# PURPOSE: Ein Lauf über mehrere Wahlzeiten als Folge von Befehlen mit eindeutiger Kennung. Dieselben Befehle ergeben dieselbe Welt (Nachspielen),
# PURPOSE: ein doppelt eingereichter Befehl wirkt nur einmal. Nur im Speicher: keine Datei, kein Spielstand (Issue #27).
# ARCHITECTURE: karriere_kern
# DEPENDENCIES: KarriereKern
# PIPELINE: test, untersuchung
# LAST_VALIDATED: 2026-11-16
class_name KarriereLauf
extends RefCounted

const Kern := preload("res://karriere_kern/kern.gd")


static func start(overrides: Dictionary = {}) -> Dictionary:
	var s := Kern.new_game(overrides)
	Kern.begin_period(s)
	return {"overrides": overrides.duplicate(), "state": s, "commands": [], "applied": {}, "counter": 0}


## Kennung über Wahlzeiten hinweg eindeutig: Wahlzeit, Periode, laufende Nummer des Laufs.
static func next_id(run: Dictionary) -> String:
	var s: Dictionary = run["state"]
	return "W%d-P%d-%d" % [int(s["term"]), int(s["period"]), int(run["counter"]) + 1]


## Befehl {id, type, action, thing}. type: "act" (Diensthandlung), "end" (Periode beenden), "term" (nächste Wahlzeit).
## Gibt false zurück, wenn der Befehl schon gewirkt hat oder nicht möglich ist. Dann ändert sich nichts.
static func apply(run: Dictionary, cmd: Dictionary) -> bool:
	var id := str(cmd.get("id", ""))
	if id == "" or (run["applied"] as Dictionary).has(id):
		return false
	var s: Dictionary = run["state"]
	match str(cmd.get("type", "")):
		"act":
			if not Kern.act(s, str(cmd.get("action", "")), str(cmd.get("thing", ""))):
				return false
		"end":
			if bool(s["over"]):
				return false
			Kern.end_period(s)
			if not bool(s["over"]):
				Kern.begin_period(s)
		"term":
			var next := Kern.next_term(s)
			if next.is_empty():
				return false
			run["state"] = next
			Kern.begin_period(next)
		_:
			return false
	run["applied"][id] = true
	run["counter"] = int(run["counter"]) + 1
	(run["commands"] as Array).append(cmd.duplicate())
	return true


static func act(run: Dictionary, action: String, thing: String = "") -> bool:
	return apply(run, {"id": next_id(run), "type": "act", "action": action, "thing": thing})


static func end(run: Dictionary) -> bool:
	return apply(run, {"id": next_id(run), "type": "end"})


static func term(run: Dictionary) -> bool:
	return apply(run, {"id": next_id(run), "type": "term"})


## Spielt Schritte "Periode:Handlung:Sache" in der laufenden Wahlzeit bis zu ihrem Ende. Nicht mögliche Schritte entfallen.
static func play_term(run: Dictionary, steps: Array) -> void:
	while not bool(run["state"]["over"]):
		for step in steps:
			var parts: PackedStringArray = str(step).split(":")
			if int(parts[0]) == int(run["state"]["period"]):
				act(run, parts[1], parts[2] if parts.size() > 2 else "")
		end(run)


## Nachspielen: dieselben Befehle auf eine frische Welt.
static func replay(overrides: Dictionary, commands: Array) -> Dictionary:
	var run := start(overrides)
	for cmd in commands:
		apply(run, cmd)
	return run
