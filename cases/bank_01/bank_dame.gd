# PURPOSE: DAME-Partie im Hinterzimmer von BANK-01 (Spezifikation 0.1, Kap. 8.3, 9.6): Konfiguration mit denselben Figuren wie tagsüber und
# PURPOSE: Umsetzung des DAME-Ergebnisses in das Weltergebnis. Nur ein Ergebnis mit der match_id der Session gehört zur Partie.
# ARCHITECTURE: core
# DEPENDENCIES: AmtWorld, WiderlegungRng (Lobby-Loop, nur für den Seed)
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
class_name BankDame
extends RefCounted

## Die Gegner sind Figuren des Vorgangs: Mertens teilt aus (Kap. 9.6), Seidel sitzt abends im Hinterzimmer.
const OPPONENTS := ["Herr Mertens", "Frau Seidel"]
const DIFFICULTY := "medium"


## Partie-Konfiguration für App.new_match. Der Seed folgt dem Durchlauf, die match_id der Session.
static func match_config(state: Dictionary, session: Dictionary, player_name: String) -> Dictionary:
	var names := [player_name if not player_name.strip_edges().is_empty() else "Sie"]
	names.append_array(OPPONENTS)
	var difficulties := {}
	var ai := []
	for seat in range(1, names.size()):
		ai.append(seat)
		difficulties[seat] = DIFFICULTY
	return {
		"seat_count": names.size(),
		"ai_seats": ai,
		"difficulties": difficulties,
		"names": names,
		"seed": int(WiderlegungRng.hash_str("%s#dame" % state["run_id"]) % 1000000) + 1,
		"match_id": str(session["match_id"]),
	}


## DAME-Ergebnis (App.match_finished) -> Weltergebnis nach Kap. 16.5. Fremde Partien und Online-Partien ergeben {}.
static func world_result(session: Dictionary, dame_result: Dictionary) -> Dictionary:
	if bool(dame_result.get("online", false)) or str(dame_result.get("match_id", "")) != str(session["match_id"]):
		return {}
	return {
		"schema_version": AmtWorld.SCHEMA_VERSION,
		"session_id": session["session_id"],
		"game": "dame",
		"case_id": session["case_id"],
		"ruleset_version": session["ruleset_version"],
		"status": "completed",
		"outcome": "won" if bool(dame_result.get("won", false)) else "lost",
		"score": int(dame_result.get("score", 0)),
		"match_id": str(session["match_id"]),
	}
