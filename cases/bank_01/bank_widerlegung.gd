# PURPOSE: Widerlegung im Ausschuss von BANK-01 (Spezifikation 0.1, Kap. 8.2, 16.4, 16.5): fester Lehren-Ordner, Nachspielen einer Partie aus Seed und Kartenfolge
# PURPOSE: und Umsetzung des Panel-Ergebnisses in das Weltergebnis. Das Panel liefert nie Effekte an den Weltkern; der Fall übersetzt nur den Ausgang.
# ARCHITECTURE: core
# DEPENDENCIES: WiderlegungRules (Lobby-Loop), cases/bank_01/lehre/bib_bank_01.json
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
class_name BankWiderlegung
extends RefCounted

const LEHRE_DIR := "res://cases/bank_01/lehre/"
const LEHRE_ID := "bib_bank_01"
const CONTENT_ID := "bank_public_seating_v1"
const CHRONICLE_WON := "bank_definition_rejected"
const CHRONICLE_LOST := "bank_definition_upheld"


## Grundbestand der Widerlegung plus die Bank-Lehre. Nie die Bibliothek unter user://: Der Fall ändert sich nicht zur Laufzeit.
static func load_data() -> Dictionary:
	return WiderlegungRules.load_data(LEHRE_DIR)


## Seed einer Partie: je Durchlauf fest, damit ein Abbruch keine neue Hand würfelt (Kap. 10.2).
static func seed_for(state: Dictionary) -> String:
	return str(state["run_id"]).trim_prefix("RUN-")


## Spielt die Karten auf dem Seed nach, wie das Panel sie spielen würde.
## Ergebnis {"ok", "error", "run"}. Eine Karte, die nicht in der Hand liegt, oder ein Zug nach der Entscheidung ist ein Fehler.
static func replay(seed: String, plays: Array) -> Dictionary:
	var data := load_data()
	if data.has("error"):
		return {"ok": false, "error": str(data["error"]), "run": {}}
	var idx := WiderlegungRules.index_of(data, LEHRE_ID)
	if idx < 0:
		return {"ok": false, "error": "Die Lehre für diesen Vorgang fehlt.", "run": {}}
	var run := WiderlegungRules.new_run(seed)
	run["idx"] = idx
	WiderlegungRules.start_instanz(data, run)
	for card in plays:
		if run["phase"] != "play":
			return {"ok": false, "error": "Die Partie ist schon entschieden.", "run": run}
		if not (run["inst"]["hand"] as Array).has(str(card)):
			return {"ok": false, "error": "Diese Karte liegt nicht in der Hand.", "run": run}
		WiderlegungRules.play(data, run, str(card))
	return {"ok": true, "error": "", "run": run}


## Stand einer nachgespielten Partie: {"finished", "collapsed", "score"}.
static func outcome(run: Dictionary) -> Dictionary:
	if run.get("phase") != "result":
		return {"finished": false, "collapsed": false, "score": 0}
	var r: Dictionary = run["results"][0]
	return {"finished": true, "collapsed": bool(r["collapsed"]), "score": int(r["score"])}


## Panel-Ergebnis (MinigameContract.widerlegung_result) -> Weltergebnis nach Kap. 16.5.
## Die mitgelieferte Effektliste wird nicht übernommen. Eine fremde Lehre ergibt {}.
static func world_result(session: Dictionary, panel_result: Dictionary) -> Dictionary:
	if str(panel_result.get("lehre", "")) != LEHRE_ID:
		return {}
	var won := bool(panel_result.get("won", false))
	return {
		"schema_version": AmtWorld.SCHEMA_VERSION,
		"session_id": session["session_id"],
		"game": "widerlegung",
		"case_id": session["case_id"],
		"ruleset_version": session["ruleset_version"],
		"status": "completed",
		"outcome": "won" if won else "lost",
		"score": int(panel_result.get("score", 0)),
		"facts": {"definition_collapsed": won},
		"chronicle_key": CHRONICLE_WON if won else CHRONICLE_LOST,
	}
