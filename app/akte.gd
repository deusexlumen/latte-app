# PURPOSE: Karriere-Akte der App (Phase 3, M7): ein Abschnitt je Spiel (Karriere, Hörsaal, Hinterzimmer). Erweitert ADR 0005.
# ARCHITECTURE: core
# DEPENDENCIES: Bank01 (nur für den Abschnitt des Vorgangs)
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
class_name LatteAkte
extends RefCounted


## lobby: GameState.get_run_stats(), hoersaal: HoersaalStats.load_stats(), dame: App.stats.values.
## Ergebnis: [{"titel", "zeilen": [String]}], immer drei Abschnitte in fester Reihenfolge.
static func build(lobby: Dictionary, hoersaal: Dictionary, dame: Dictionary) -> Array:
	var rolls: Array = lobby.get("rolls", []) if lobby.get("rolls") is Array else []
	var minigames: Array = lobby.get("minigames", []) if lobby.get("minigames") is Array else []
	var karriere := [
		"Szene: %s" % str(lobby.get("current_scene", "kommunalpolitik")),
		"Fraktionsdisziplin: %d / 10" % int(lobby.get("fraktionsdisziplin", 5)),
		"Alignment: %+d" % int(lobby.get("alignment_score", 0)),
		"Würfe: %d" % rolls.size(),
		"Minispiele: %d" % minigames.size(),
	]
	var played := int(hoersaal.get("played", 0))
	var hs := [
		"Vorlesungen: %d" % played,
		"Eingestürzte Lehren: %d" % int(hoersaal.get("collapsed", 0)),
		"Bestes Ergebnis: %d Punkte" % int(hoersaal.get("best_score", 0)),
	]
	if played == 0:
		hs = ["Noch keine Vorlesung besucht."]
	var games := int(dame.get("games_played", 0))
	var hz := [
		"Partien: %d, davon gewonnen: %d" % [games, int(dame.get("games_won", 0))],
		"Dame gerufen: %d, davon richtig: %d" % [int(dame.get("dame_calls", 0)), int(dame.get("successful_dame_calls", 0))],
		"Strafkarten gesamt: %d" % int(dame.get("total_penalty_cards", 0)),
	]
	if games == 0:
		hz = ["Noch keine Partie im Hinterzimmer."]
	return [
		{"titel": "Karriere", "zeilen": karriere},
		{"titel": "Hörsaal", "zeilen": hs},
		{"titel": "Hinterzimmer", "zeilen": hz},
	]


## Abschnitt für den Vorgang BANK-01 (Kap. 13.1): die amtliche Fassung neben dem, was tatsächlich geschah.
## state ist der Weltzustand oder {} (noch kein Vorgang begonnen).
static func vorgang_section(state: Dictionary) -> Dictionary:
	if state.is_empty() or str(state["cases"]["BANK-01"]["status"]) == "not_opened":
		return {"titel": "Innenhof (BANK-01)", "zeilen": ["Noch kein Vorgang eröffnet."]}
	var c: Dictionary = state["cases"]["BANK-01"]
	var hearing := "noch nicht angefochten"
	match str(c["definition"]):
		"won":
			hearing = "Arbeitsdefinition widerlegt"
		"lost":
			hearing = "Arbeitsdefinition hat gehalten"
	var seat: String = {"bench": "auf der Bank", "chair": "auf einem Klappstuhl"}.get(str(state["actors"]["kern"]["seat"]), "")
	var lines := [
		"Stand: %s" % Bank01.status_line(state),
		"Amtlich: %s" % Bank01.official_summary(state),
		"Tatsächlich: Frau Kern %s." % ("sitzt " + seat if not seat.is_empty() else "steht noch"),
		"Diensthandlungen: %d von %d verbraucht" % [Bank01.HOURS - int(c["hours_remaining"]), Bank01.HOURS],
		"Belege im Aktenkoffer: %d" % (state["evidence"] as Dictionary).size(),
		"Widerlegung: %s" % hearing,
		"Partien DAME im Hinterzimmer: %d" % Bank01.completed_sessions(state, "dame").size(),
	]
	for rule in state["rules"]:
		lines.append("Aus diesem Vorgang erlassen: %s (%s)" % [rule["rule_id"], rule["herkunft"]])
	return {"titel": "Innenhof (BANK-01)", "zeilen": lines}
