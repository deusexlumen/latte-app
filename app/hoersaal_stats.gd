# PURPOSE: Zählt Widerlegungen im Hörsaal (außerhalb der Karriere, ohne Effekte) in user://hoersaal.json.
# ARCHITECTURE: core
# DEPENDENCIES: JsonStore (amt_core)
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name HoersaalStats
extends RefCounted

const PATH := "user://hoersaal.json"


static func load_stats(path: String = PATH) -> Dictionary:
	var d := JsonStore.read_json(path)
	return {
		"played": int(d.get("played", 0)),
		"collapsed": int(d.get("collapsed", 0)),
		"best_score": int(d.get("best_score", 0)),
		"lehren": d.get("lehren", {}) if d.get("lehren") is Dictionary else {},
	}


## Nimmt ein Vertrags-Ergebnis (MinigameContract.widerlegung_result) auf. Effekte werden ignoriert:
## Der Hörsaal ist Übung, er ändert keine Karriere.
static func record(result: Dictionary, path: String = PATH) -> Dictionary:
	var s := load_stats(path)
	s["played"] += 1
	if bool(result.get("won", false)):
		s["collapsed"] += 1
	s["best_score"] = maxi(int(s["best_score"]), int(result.get("score", 0)))
	var lehre := str(result.get("lehre", ""))
	s["lehren"][lehre] = int(s["lehren"].get(lehre, 0)) + 1
	JsonStore.write_json(path, s)
	return s
