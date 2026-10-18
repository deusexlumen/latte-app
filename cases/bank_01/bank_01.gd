# PURPOSE: Fallsteuerung BANK-01 "Die gesperrte Bank" (Spezifikation 0.1, Kap. 9–10): Anfangszustand, Befehle, Übergänge T-01 bis T-08,
# PURPOSE: Nachgangregeln und Abfragen für die Oberfläche. Ändert den Zustand nur über AmtTransaction.emit.
# ARCHITECTURE: core
# DEPENDENCIES: AmtWorld, AmtTransaction, cases/bank_01/bank_01.json
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
class_name Bank01
extends RefCounted

const CASE_ID := "BANK-01"
const CONTENT_VERSION := "bank_01@1"
const CONTENT_PATH := "res://cases/bank_01/bank_01.json"
const HOURS := 8
const LOCATIONS := ["vorhalle", "innenhof", "hausdienst", "registratur", "ausschussraum", "hinterzimmer"]
const PEOPLE := ["kern", "mertens", "seidel", "voss"]
## Stellen mit Aufmerksamkeit (Kap. 8.4). informs: wird ab Stufe 2 nach einer Befragung benachrichtigt.
const OFFICES := {
	"hausdienst": {"location": "hausdienst", "actor": "mertens", "informs": "registratur"},
	"registratur": {"location": "registratur", "actor": "seidel", "informs": "hausdienst"},
	"ausschuss": {"location": "ausschussraum", "actor": "voss", "informs": "registratur"},
}
const COSTED := ["observe", "interview", "request_document", "request_help", "wait"]
## Wer während einer solchen Handlung am Ort ist, sieht dort stattfindende Abläufe (Kap. 8.4, 9.5).
const WATCHING := ["observe", "wait"]
const TOPIC_LABELS := {"bank": "die Bank", "kunst": "der Kunstetat"}
const MAX_FINDINGS := 3
const MAX_WORDING := 160
## Minispiele dieses Vorgangs. In E1 setzt die Entwicklungsansicht ihre Ergebnisse (Kap. 19.1).
const SESSIONS := {
	"dame": {"content_id": "hinterzimmer_mertens", "ruleset_version": "dame-godot@1", "return_scene": "hinterzimmer"},
	"widerlegung": {"content_id": "bank_public_seating_v1", "ruleset_version": "huhn-port-v1", "return_scene": "ausschussraum"},
}
## Abschluss -> Nachgang (Kap. 10.1, 16.6). Nur die formelle Freigabe führt zu einer allgemeinen Regel.
const FOLLOWUP_OF := {
	"formal_release": "fu_accessibility_rule",
	"temporary_exception": "fu_renewal_reminder",
	"replacement_chair": "fu_return_slip",
	"unresolved": "fu_case_filed",
}

## Entwicklungsergebnisse (ohne gespielte Karten, "dev": true) gibt es nur in Debug-Builds. Tests dürfen es abschalten.
static var allow_dev_results := OS.is_debug_build()
static var _content := {}


static func content() -> Dictionary:
	if _content.is_empty():
		_content = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
	return _content


## Kanonischer Ausgangsfall (Kap. 9.2): Bank repariert, Bestand "Exponat", Band hängt. Keine Zufallswerte.
static func new_state(run_seed: String = "BANK-01-A") -> Dictionary:
	var s := AmtWorld.new_state(CONTENT_VERSION, "RUN-" + run_seed)
	s["phase"] = "tag1"
	s["location"] = "vorhalle"
	s["cases"][CASE_ID] = {
		"case_id": CASE_ID,
		"status": "not_opened",
		"hours_remaining": HOURS,
		"evidence_ids": [],
		"report": {},
		"resolution": "",
		"application": {},
		"definition": "",
		"scheduled_followups": [],
		"applied_followups": [],
		"requests": {},
		"observed": {},
		"audit_announced": false,
		"exception_review": false,
	}
	s["actors"] = {
		"kern": _actor("kern", "innenhof", ["sitzen"]),
		"mertens": _actor("mertens", "hausdienst", ["reparaturen_abschliessen"]),
		"seidel": _actor("seidel", "registratur", ["eintraege_zuordnen"]),
		"voss": _actor("voss", "ausschussraum", ["tragfaehiger_beschluss"]),
	}
	for office in OFFICES:
		s["offices"][office] = {"attention": 0, "last_contact": 0}
	s["objects"] = {
		"bench": {"physically_usable": true, "access": "blocked", "inventory_class": "exhibit", "intended_use": "public_seating", "tape": true},
		"chair": {"available": false, "location": "hausdienst"},
		"originals": {"location": "regal"},
		"hof_schild": {"text": ""},
		"nebeneingang": {"wartet": false},
	}
	return s


static func _actor(id: String, location: String, goals: Array) -> Dictionary:
	return {"actor_id": id, "location_id": location, "goals": goals, "known_fact_ids": [], "commitments": {}, "seat": ""}


## Ein Befehl im Format von Kap. 16.2. Die Kennung zählt die verbuchten Befehle: Ein Doppelklick erzeugt dieselbe Kennung.
static func command(s: Dictionary, type: String, params: Dictionary = {}) -> Dictionary:
	return {
		"schema_version": AmtWorld.SCHEMA_VERSION,
		"command_id": "cmd-bank01-%03d" % ((s["applied_transactions"] as Array).size() + 1),
		"actor_id": "player",
		"case_id": CASE_ID,
		"type": type,
		"params": params,
	}


# --- Befehle ---

static func handle(tx: AmtTransaction) -> void:
	var type := str(tx.command["type"])
	if not running_session(tx.state).is_empty() and type != "minigame_result" and type != "minigame_play":
		tx.fail("Erst die laufende Partie beenden.")
		return
	match type:
		"open_case":
			_open_case(tx)
		"move":
			_move(tx)
		"talk":
			_talk(tx)
		"compare":
			_compare(tx)
		"end_day":
			_end_day(tx)
		"start_minigame":
			_start_minigame(tx)
		"minigame_play":
			_minigame_play(tx)
		"minigame_result":
			_minigame_result(tx)
		"end_evening":
			_end_evening(tx)
		"submit":
			_submit(tx)
		"close_case":
			_close_case(tx)
		"advance":
			_advance(tx)
		"correct_report":
			_correct_report(tx)
		_:
			if COSTED.has(type):
				_costed(tx, type)
			else:
				tx.fail("Unbekannte Handlung: %s" % type)


## T-01: Das Schild im Hof führt in die Prüfung.
static func _open_case(tx: AmtTransaction) -> void:
	var s := tx.state
	if s["phase"] != "tag1" or _c(s)["status"] != "not_opened":
		tx.fail("Die Prüfung ist schon eröffnet.")
		return
	if s["location"] != "innenhof":
		tx.fail("Das Schild hängt im Innenhof.")
		return
	tx.emit("case_opened", "player", {"text": line("case_opened")}, [AmtWorld.op_set(_cp("status"), "open")])


static func _move(tx: AmtTransaction) -> void:
	var to := str(tx.params.get("to", ""))
	var err := move_error(tx.state, to)
	if not err.is_empty():
		tx.fail(err)
		return
	tx.emit("moved", "player", {"from": tx.state["location"], "to": to}, [AmtWorld.op_set(["location"], to)])


## Gespräche ohne Dienstcharakter kosten keine Handlung: Frau Kern jederzeit, Mertens am Abend.
static func _talk(tx: AmtTransaction) -> void:
	var s := tx.state
	var actor := str(tx.params.get("actor", ""))
	if actor == "kern" and s["actors"]["kern"]["location_id"] == s["location"]:
		tx.emit("talked", "kern", {"actor": "kern", "text": kern_line(s)})
	elif actor == "mertens" and s["phase"] == "abend":
		var ops := []
		var text := line("mertens_evening_again")
		if str(tx.params.get("topic", "bank")) != "bank":
			text = line("mertens_evening_other")
		elif not has_ev(s, "B-04"):
			text = line("mertens_evening_bank")
			ops = _evidence_ops(tx, "B-04", "mertens")
		tx.emit("talked", "mertens", {"actor": "mertens", "text": text}, ops)
	else:
		tx.fail("Hier ist niemand für ein Gespräch.")


## Zwei Akteneinträge nebeneinanderlegen. Kostet keine Handlung (Kap. 6.1).
static func _compare(tx: AmtTransaction) -> void:
	var s := tx.state
	var pair: Variant = tx.params.get("evidence", [])
	if not (pair is Array) or (pair as Array).size() != 2 or str(pair[0]) == str(pair[1]):
		tx.fail("Zwei verschiedene Einträge nebeneinanderlegen.")
		return
	for id in pair:
		if not has_ev(s, str(id)):
			tx.fail("Dieser Eintrag liegt nicht im Aktenkoffer.")
			return
	var rule := comparison(str(pair[0]), str(pair[1]))
	if rule.is_empty():
		tx.emit("compared", "player", {"pair": pair, "text": str(content()["compare_nothing"])})
		return
	tx.emit("compared", "player", {"pair": pair, "evidence": rule["evidence"], "text": rule["text"]},
		_evidence_ops(tx, str(rule["evidence"]), "abgleich"))


# --- Diensthandlungen (Tag 1) ---

static func _costed(tx: AmtTransaction, type: String) -> void:
	var s := tx.state
	if s["phase"] != "tag1" or _c(s)["status"] != "open":
		tx.fail("Diensthandlungen gibt es nur am ersten Tag einer eröffneten Prüfung.")
		return
	if int(_c(s)["hours_remaining"]) <= 0:
		tx.fail("Keine Diensthandlungen mehr. Lesen und Vergleichen geht weiter, dann Feierabend.")
		return
	# Reihenfolge nach Kap. 8.4: Handlung, Beobachtung, Aufmerksamkeit/Benachrichtigung, fällige Abläufe, Uhr.
	AmtWorld.begin_action(tx, type)
	match type:
		"observe":
			_observe(tx)
		"interview":
			_interview(tx)
		"request_document":
			_request(tx)
		"request_help":
			_request_help(tx)
		"wait":
			tx.emit("time_passed", "player", {"text": line("wait")})
	if not tx.error.is_empty():
		return
	AmtWorld.settle_attention(tx)
	var t := tx.turn
	AmtWorld.process_due(tx, func(p: Dictionary) -> bool: return int(p["due_turn"]) > 0 and int(p["due_turn"]) <= t,
		func(p: Dictionary, cause: String) -> void: _due(tx, p, cause))
	AmtWorld.advance_clock(tx, CASE_ID)


## Erstes Mal am Ort: keine Erhöhung. Jede weitere Beobachtung einer Stelle: +1. Der Text zeigt die Stufe vor der Erhöhung.
static func _observe(tx: AmtTransaction) -> void:
	var s := tx.state
	var loc := str(s["location"])
	var office := office_at(loc)
	var count := int(_c(s)["observed"].get(loc, 0))
	var level := int(s["offices"][office]["attention"]) if not office.is_empty() else 0
	var ops := [AmtWorld.op_set(["cases", CASE_ID, "observed", loc], count + 1)]
	if loc == "innenhof":
		ops += _evidence_ops(tx, "O-01", "innenhof")
	tx.emit("observed", "player", {"location": loc, "stufe": level, "text": observation_text(s, loc)}, ops)
	if not office.is_empty():
		AmtWorld.contact(tx, office)
		if count > 0:
			AmtWorld.raise_attention(tx, office, 1, "erneute Beobachtung")


static func _interview(tx: AmtTransaction) -> void:
	var s := tx.state
	var actor := str(tx.params.get("actor", ""))
	var topic := str(tx.params.get("topic", "bank"))
	if not topics(s, actor).has(topic):
		tx.fail("Dazu ist hier niemand zu befragen.")
		return
	var office := office_of(actor)
	var level := int(s["offices"][office]["attention"])
	var audit := bool(_c(s)["audit_announced"])
	var text := ""
	var ops := []
	match actor + "/" + topic:
		"mertens/bank":
			if has_ev(s, "B-01"):
				text = line("mertens_bank_again")
			else:
				# Bei offizieller Befragung sichert er sich schriftlich ab (Kap. 3.3).
				text = line("mertens_bank_formal") if level >= 2 else line("mertens_bank")
				ops = _doc_ops(tx, "repair_slip", "mertens")
			# Nur wer benachrichtigt wurde, weiß von der Prüfung (QA-11).
			if knows(s, "mertens", "pruefung_bekannt"):
				text = line("mertens_informed") + text
		"mertens/kunst":
			text = line("mertens_kunst_again") if has_ev(s, "B-04") else line("mertens_kunst")
			ops = _evidence_ops(tx, "B-04", "mertens")
		"seidel/bank":
			if not audit:
				text = line("seidel_closed")
			elif has_ev(s, "B-05"):
				text = line("seidel_again")
			else:
				text = line("seidel_audit")
				ops = _doc_ops(tx, "procedure_sheet", "seidel")
			if audit and s["objects"]["originals"]["location"] == "pruefschrank" and not has_ev(s, "S-02"):
				text += line("seidel_moved")
				ops += _evidence_ops(tx, "S-02", "seidel")
		"voss/bank":
			text = line("voss_again") if has_ev(s, "S-01") else line("voss_bank")
			ops = _evidence_ops(tx, "S-01", "voss")
	tx.emit("interviewed", actor, {"actor": actor, "topic": topic, "stufe": level, "text": text}, ops)
	if AmtWorld.raise_attention(tx, office, 1, "Befragung") >= 2:
		_inform(tx, office)


## Ab Stufe 2 erfährt eine zugehörige Stelle nach der Befragung von der Prüfung (Kap. 8.4).
static func _inform(tx: AmtTransaction, office: String) -> void:
	var target: String = OFFICES[office]["informs"]
	tx.emit("office_informed", office, {"from": office, "to": target}, _learn_ops(tx, OFFICES[target]["actor"], "pruefung_bekannt"))
	AmtWorld.raise_attention(tx, target, 1, "benachrichtigt")


## Akte anfordern: +2 bei der Stelle, Lieferung nach der nächsten Handlung. Die Registratur kündigt daraufhin die Prüfung an (Kap. 9.5).
static func _request(tx: AmtTransaction) -> void:
	var s := tx.state
	var key := str(tx.params.get("document_id", ""))
	var req: Dictionary = content()["requests"].get(key, {})
	if req.is_empty():
		tx.fail("Diese Unterlage gibt es nicht.")
		return
	if (_c(s)["requests"] as Dictionary).has(key):
		tx.fail("Schon angefordert.")
		return
	if _all_held(s, req["documents"]):
		tx.fail("Liegt schon im Aktenkoffer.")
		return
	var office: String = req["office"]
	tx.emit("document_requested", "player", {
		"document_id": key,
		"office": office,
		"text": "Angefordert bei %s: %s. Lieferung nach der nächsten Diensthandlung." % [office_name(office), req["label"]],
	}, [
		AmtWorld.op_set(["cases", CASE_ID, "requests", key], {"status": "requested", "turn": tx.turn}),
		_schedule_op(tx, "deliver_" + key, "deliver", {"request": key}, tx.turn + 1, ""),
	])
	AmtWorld.raise_attention(tx, office, 2, "Aktenanforderung")
	if office == "registratur" and not bool(_c(s)["audit_announced"]):
		var ops := [AmtWorld.op_set(_cp("audit_announced"), true)] + _learn_ops(tx, "seidel", "pruefung_bekannt")
		ops.append(_schedule_op(tx, "move_originals", "move_originals", {}, tx.turn + 1, ""))
		tx.emit("audit_announced", "registratur", {
			"document_id": key, "attention_delta": 2, "scheduled_action": "move_originals_to_review_cabinet",
		}, ops)


## Hilfe am Tag (T-06): Mertens bringt nach der nächsten Handlung einen Klappstuhl.
static func _request_help(tx: AmtTransaction) -> void:
	var s := tx.state
	if str(tx.params.get("actor", "mertens")) != "mertens" or s["actors"]["mertens"]["location_id"] != s["location"]:
		tx.fail("Um einen Stuhl bitten Sie am besten den Hausdienst.")
		return
	if has_chair_commitment(s):
		tx.fail("Mertens hat schon einen Stuhl zugesagt.")
		return
	tx.emit("help_promised", "mertens", {"quelle": "tag", "text": line("mertens_help")}, [
		AmtWorld.op_set(["actors", "mertens", "commitments", "stuhl"], {"id": "stuhl", "quelle": "tag", "status": "zugesagt"}),
		_schedule_op(tx, "deliver_chair", "deliver_chair", {"quelle": "tag"}, tx.turn + 1, ""),
	])
	AmtWorld.contact(tx, "hausdienst")


## Ein fälliger Ablauf. cause: das Ereignis, das ihn ausgetragen hat.
static func _due(tx: AmtTransaction, p: Dictionary, cause: String) -> void:
	var s := tx.state
	var action := str(p["action"])
	match action:
		"deliver":
			var key := str(p["params"]["request"])
			var req: Dictionary = content()["requests"][key]
			var ops := [AmtWorld.op_set(["cases", CASE_ID, "requests", key, "status"], "delivered")]
			var titles := []
			for doc in req["documents"]:
				ops += _doc_ops(tx, doc, req["office"])
				titles.append(doc_title(doc))
			tx.emit("documents_delivered", req["office"], {
				"request": key, "text": "Hauspost aus der Stelle %s: %s." % [office_name(req["office"]), ", ".join(titles)],
			}, ops, [cause])
		"move_originals":
			var moved := tx.emit("originals_moved", "seidel", {"from": "regal", "to": "pruefschrank", "grund": "R-3"},
				[AmtWorld.op_set(["objects", "originals", "location"], "pruefschrank")], [cause])
			# Nur wer gerade dort beobachtet, ist Augenzeuge. Keine rückwirkende Beobachtung (QA-17).
			if WATCHING.has(tx.action_kind) and tx.action_location == "registratur":
				tx.emit("witnessed", "player", {"location": "registratur", "text": line("witnessed_move")},
					_evidence_ops(tx, "B-06", "registratur"), [moved])
		"deliver_chair":
			tx.emit("chair_delivered", "mertens", {"quelle": p["params"]["quelle"], "text": line("chair_delivered")}, [
				AmtWorld.op_set(["objects", "chair"], {"available": true, "location": "innenhof"}),
				AmtWorld.op_set(["actors", "kern", "seat"], "chair"),
				AmtWorld.op_set(["actors", "mertens", "commitments", "stuhl", "status"], "erfuellt"),
			], [cause])
		_:
			if action.begins_with("fu_"):
				_followup(tx, p, cause)
			else:
				push_error("Unbekannter Ablauf: %s" % action)


# --- Phasen ---

static func _end_day(tx: AmtTransaction) -> void:
	if tx.state["phase"] != "tag1" or _c(tx.state)["status"] != "open":
		tx.fail("Feierabend gibt es erst mit eröffneter Prüfung.")
		return
	_flush_until(tx, "abend")
	_change_phase(tx, "abend", "hinterzimmer", line("day_end"), [
		AmtWorld.op_set(["actors", "mertens", "location_id"], "hinterzimmer"),
		AmtWorld.op_set(["actors", "seidel", "location_id"], "hinterzimmer"),
	])


static func _end_evening(tx: AmtTransaction) -> void:
	if tx.state["phase"] != "abend":
		tx.fail("Es ist nicht Abend.")
		return
	_change_phase(tx, "tag2", "vorhalle", line("evening_end"), [
		AmtWorld.op_set(["actors", "mertens", "location_id"], "hausdienst"),
		AmtWorld.op_set(["actors", "seidel", "location_id"], "registratur"),
	])
	_flush_until(tx, "tag2")


static func _advance(tx: AmtTransaction) -> void:
	if tx.state["phase"] != "rueckkehr":
		tx.fail("Noch nicht.")
		return
	_change_phase(tx, "nachgang", "innenhof", line("advance"), [AmtWorld.op_set(["actors", "kern", "location_id"], "")])
	_flush_until(tx, "nachgang")


static func _change_phase(tx: AmtTransaction, phase: String, location: String, text: String, extra: Array) -> void:
	tx.emit("phase_changed", "", {"from": tx.state["phase"], "to": phase, "text": text},
		[AmtWorld.op_set(["phase"], phase), AmtWorld.op_set(["location"], location)] + extra)


## Offene Abläufe bis einschließlich der Phase verarbeiten. Ohne laufende Handlung: niemand ist Augenzeuge.
## Lieferungen nach der achten Handlung kommen so noch vor Dienstschluss an (Kap. 6.1).
static func _flush_until(tx: AmtTransaction, phase: String) -> void:
	tx.action_kind = ""
	var phases := ["tag2"] if phase == "tag2" else (["tag2", "nachgang"] if phase == "nachgang" else [])
	AmtWorld.process_due(tx, func(p: Dictionary) -> bool: return int(p["due_turn"]) > 0 or phases.has(str(p["due_phase"])),
		func(p: Dictionary, cause: String) -> void: _due(tx, p, cause))


# --- Minispiele (Kap. 16.4/16.5): der Fall übersetzt geprüfte Ergebnisse, Spiele setzen keine Weltwerte ---

static func _start_minigame(tx: AmtTransaction) -> void:
	var s := tx.state
	var game := str(tx.params.get("game", ""))
	var err := minigame_error(s, game)
	if not err.is_empty():
		tx.fail(err)
		return
	var n := sessions_of(s, game).size() + 1
	var id := "session-bank01-%s-%d" % [game, n]
	var spec: Dictionary = SESSIONS[game]
	var session := {
		"session_id": id, "game": game, "case_id": CASE_ID,
		"ruleset_version": spec["ruleset_version"], "content_id": spec["content_id"],
		# Die Widerlegung behält den Seed des Durchlaufs: Ein Abbruch würfelt keine neue Hand (Kap. 10.2).
		"seed": BankWiderlegung.seed_for(s) if game == "widerlegung" else "%s-%s-%d" % [CASE_ID, game, n],
		"status": "running", "outcome": "", "score": 0,
		# Eine DAME-Partie trägt diese Kennung durch Spielstand und Ergebnis; nur ein Ergebnis mit ihr gehört zur Session.
		"match_id": "%s-%s" % [CASE_ID, id],
		"checkpoint": {"location": s["location"], "return_scene": spec["return_scene"], "plays": []},
	}
	tx.emit("minigame_started", "player", {
		"session_id": id, "game": game, "seed": session["seed"],
		"text": line("dame_started") if game == "dame" else line("hearing_started"),
	}, [AmtWorld.op_set(["sessions", id], session)])


## Ein Zug der Widerlegung. Gilt nur, wenn die Karte beim Nachspielen auf dem Seed in der Hand liegt (Kap. 17.1: fortsetzbar).
static func _minigame_play(tx: AmtTransaction) -> void:
	var s := tx.state
	var session := running_session(s)
	if session.is_empty() or session["game"] != "widerlegung" or str(tx.params.get("session_id", "")) != session["session_id"]:
		tx.fail("Es läuft keine Widerlegung.")
		return
	var card := str(tx.params.get("card", ""))
	var plays: Array = session["checkpoint"]["plays"]
	var replayed := BankWiderlegung.replay(str(session["seed"]), plays + [card])
	if not replayed["ok"]:
		tx.fail(str(replayed["error"]))
		return
	tx.emit("minigame_card_played", "player", {"session_id": session["session_id"], "card": card},
		[AmtWorld.op_append(["sessions", session["session_id"], "checkpoint", "plays"], card)])


static func _minigame_result(tx: AmtTransaction) -> void:
	var s := tx.state
	var r: Variant = tx.params.get("result")
	var err := result_error(s, r)
	if not err.is_empty():
		tx.fail(err)
		return
	var sid := str(r["session_id"])
	var game := str(s["sessions"][sid]["game"])
	if r["status"] == "aborted":
		# Abbruch: Szene wie vor der Partie, kein Sieg und kein Verlust (Kap. 10.2).
		tx.emit("minigame_aborted", "player", {"session_id": sid, "text": line("minigame_aborted")},
			[AmtWorld.op_set(["sessions", sid, "status"], "aborted")])
		return
	var outcome := str(r["outcome"])
	var ops := [
		AmtWorld.op_set(["sessions", sid, "status"], "completed"),
		AmtWorld.op_set(["sessions", sid, "outcome"], outcome),
		AmtWorld.op_set(["sessions", sid, "score"], int(r.get("score", 0))),
	]
	if game == "widerlegung":
		# Entscheidet nur die Definitionsfrage dieses Vorgangs; die Freigabe braucht weiter den Reparaturbeleg (Kap. 8.2).
		ops.append(AmtWorld.op_set(_cp("definition"), outcome))
		tx.emit("definition_rejected" if outcome == "won" else "definition_upheld", "voss", {
			"session_id": sid, "chronicle_key": str(r.get("chronicle_key", "")),
			"text": line("definition_rejected") if outcome == "won" else line("definition_upheld"),
		}, ops)
		return
	# DAME: Nur die erste beendete Partie kann eine Gefälligkeit bringen, und nur, wenn noch keine Hilfe zugesagt ist (QA-10).
	var first := completed_sessions(s, "dame").is_empty()
	var favor := false
	var text := line("dame_lost")
	if outcome == "won":
		if not first:
			text = line("dame_won_again")
		elif has_chair_commitment(s):
			text = line("dame_won_no_favor")
		else:
			text = line("dame_won_favor")
			favor = true
	var fin := tx.emit("minigame_finished", "mertens", {"session_id": sid, "outcome": outcome, "text": text}, ops)
	if favor:
		tx.emit("favor_promised", "mertens", {"quelle": "dame"}, [
			AmtWorld.op_set(["actors", "mertens", "commitments", "stuhl"], {"id": "stuhl", "quelle": "dame", "status": "zugesagt"}),
			_schedule_op(tx, "deliver_chair", "deliver_chair", {"quelle": "dame"}, 0, "tag2"),
		], [fin])


# --- Abschluss ---

## Einreichung am zweiten Tag: Bericht plus Antrag, verbindlich mit diesem Befehl (T-04, T-05, T-08).
static func _submit(tx: AmtTransaction) -> void:
	var s := tx.state
	if s["phase"] != "tag2" or _c(s)["status"] != "open":
		tx.fail("Eingereicht wird am zweiten Tag, einmal.")
		return
	var err := submission_error(s, tx.params)
	if not err.is_empty():
		tx.fail(err)
		return
	var antrag := str(tx.params.get("antrag", "keiner"))
	var report := _report(s, tx.params)
	report["antrag"] = antrag
	report["wording"] = clean_wording(tx.params.get("wording", "")) if antrag == "formal" else ""
	var sub := tx.emit("report_submitted", "player", {"antrag": antrag, "text": line("submitted")}, [
		AmtWorld.op_set(_cp("report"), report),
		AmtWorld.op_set(_cp("status"), "submitted"),
		AmtWorld.op_set(_cp("application"), {"antrag": antrag, "wording": report["wording"], "confirmed": true}),
	])
	var resolution := "replacement_chair" if bool(s["objects"]["chair"]["available"]) else "unresolved"
	if antrag == "formal":
		resolution = "formal_release"
		_release(tx, "bench_released", "open", "public_seating", line("bench_released"), sub)
		# Voss erhält den Beschluss samt Wortlaut; erst damit kann er ihn weiterverarbeiten (Kap. 16.6).
		tx.emit("decision_forwarded", "voss", {"wording": report["wording"]}, _learn_ops(tx, "voss", "beschluss_bank01"), [sub])
	elif antrag == "ausnahme":
		resolution = "temporary_exception"
		_release(tx, "exception_granted", "temporary", "exhibit", line("exception_granted"), sub)
	_conclude(tx, resolution, report, sub)


## T-07: jederzeit vor der Einreichung. Zusagen werden noch eingelöst, dann zurück in den Hof.
static func _close_case(tx: AmtTransaction) -> void:
	var s := tx.state
	if not ["tag1", "abend", "tag2"].has(str(s["phase"])) or _c(s)["status"] != "open":
		tx.fail("Der Vorgang ist nicht offen.")
		return
	_flush_until(tx, "tag2")
	var closed := tx.emit("case_closed", "player", {"text": line("closed")}, [AmtWorld.op_set(_cp("status"), "closed")])
	_conclude(tx, "replacement_chair" if bool(s["objects"]["chair"]["available"]) else "unresolved", {}, closed)


static func _release(tx: AmtTransaction, type: String, access: String, inventory_class: String, text: String, cause: String) -> void:
	var s := tx.state
	var ops := [
		AmtWorld.op_set(["objects", "bench", "access"], access),
		AmtWorld.op_set(["objects", "bench", "inventory_class"], inventory_class),
		AmtWorld.op_set(["objects", "bench", "tape"], access != "open"),
		AmtWorld.op_set(["actors", "kern", "seat"], "bench"),
	]
	# T-06 mit T-04/T-05: Der Stuhl geht zurück, die Hilfe bleibt erinnert.
	if bool(s["objects"]["chair"]["available"]):
		ops.append(AmtWorld.op_set(["objects", "chair"], {"available": false, "location": "hausdienst"}))
		ops.append(AmtWorld.op_set(["actors", "mertens", "commitments", "stuhl", "status"], "zurueckgestellt"))
		text += line("chair_returned")
	tx.emit(type, "mertens", {"access": access, "text": text}, ops, [cause])


## Abschluss festhalten, genau die zugehörigen Nachgangregeln planen, dann zuerst zurück in den Hof (Kap. 9.8).
static func _conclude(tx: AmtTransaction, resolution: String, report: Dictionary, cause: String) -> void:
	var s := tx.state
	var ops := [AmtWorld.op_set(_cp("resolution"), resolution)]
	ops += _followup_ops(tx, FOLLOWUP_OF[resolution])
	if bool(_c(s)["audit_announced"]):
		ops += _followup_ops(tx, "fu_seidel_statement")
	# T-08: Verdacht "Verschleierung" mit Beobachtung B-06, aber ohne Verfahrensblatt B-05.
	if str(report.get("conclusion", "")) == "verschleierung" and has_ev(s, "B-06") and not has_ev(s, "B-05"):
		ops += _followup_ops(tx, "fu_registry_inquiry")
	tx.emit("case_resolved", "player", {"resolution": resolution}, ops, [cause])
	_change_phase(tx, "rueckkehr", "innenhof", "", [])


## Nachgang (Kap. 9.8, 16.6). Jede Regel greift höchstens einmal (QA-16).
static func _followup(tx: AmtTransaction, p: Dictionary, cause: String) -> void:
	var s := tx.state
	var c := _c(s)
	var id := str(p["action"])
	if (c["applied_followups"] as Array).has(id):
		return
	var done := AmtWorld.op_append(_cp("applied_followups"), id)
	match id:
		"fu_accessibility_rule":
			var wording := str(c["application"].get("wording", ""))
			if c["resolution"] != "formal_release" or wording.is_empty() or not knows(s, "voss", "beschluss_bank01"):
				return
			var cfg: Dictionary = content()["rule"]
			var rule := {
				"rule_id": cfg["id"], "scope": cfg["scope"], "issuer_id": "voss",
				"valid_from": {"phase": "nachgang", "turn": tx.turn},
				"origin_event_ids": [str(p["scheduled_by"]), cause], "status": "in_kraft",
				"text": cfg["text"], "begruendung": wording, "herkunft": CASE_ID,
			}
			var notice := str(content()["documents"]["rule_notice"]["text"]).replace("{wording}", wording)
			var ops := [
				done,
				AmtWorld.op_append(["rules"], rule),
				AmtWorld.op_set(["objects", "hof_schild", "text"], cfg["sign"]),
				AmtWorld.op_set(["objects", "nebeneingang", "wartet"], true),
			] + _doc_ops(tx, "rule_notice", "voss", notice)
			var issued := tx.emit("rule_issued", "voss", {"rule_id": cfg["id"], "text": line("rule_issued")}, ops, [cause])
			tx.emit("thanks", "ausschussbuero", {"text": line("thanks")}, [], [issued])
		"fu_renewal_reminder":
			tx.emit("reminder_sent", "voss", {"text": line("renewal")},
				[done, AmtWorld.op_set(_cp("exception_review"), true)] + _doc_ops(tx, "renewal_reminder", "voss"), [cause])
		"fu_return_slip":
			tx.emit("return_slip_sent", "mertens", {"text": line("return_slip")},
				[done, AmtWorld.op_set(["actors", "mertens", "commitments", "stuhl", "status"], "rueckgabe_erbeten")]
				+ _doc_ops(tx, "return_slip", "mertens"), [cause])
		"fu_case_filed":
			tx.emit("case_filed", "registratur", {"text": line("filed")}, [done] + _doc_ops(tx, "filing_note", "registratur"), [cause])
		"fu_registry_inquiry":
			tx.emit("registry_inquiry", "seidel", {"text": line("inquiry")},
				[done, AmtWorld.op_set(["cases", CASE_ID, "report", "inquiry"], "offen")]
				+ _doc_ops(tx, "registry_inquiry", "seidel") + _doc_ops(tx, "procedure_sheet", "seidel"), [cause])
		"fu_seidel_statement":
			tx.emit("statement", "seidel", {"text": line("seidel_later")}, [done] + _evidence_ops(tx, "S-02", "seidel"), [cause])


## T-08 Korrektur: Auf die Rückfrage hin darf die Schlussfolgerung (und die Belegauswahl) geändert werden.
static func _correct_report(tx: AmtTransaction) -> void:
	var s := tx.state
	var report: Dictionary = _c(s)["report"]
	if s["phase"] != "nachgang" or str(report.get("inquiry", "")) != "offen":
		tx.fail("Es liegt keine Rückfrage vor.")
		return
	var p := {
		"findings": tx.params.get("findings", report["findings"]),
		"conclusion": tx.params.get("conclusion", ""),
		"open_questions": report["open_questions"],
	}
	var err := _findings_error(s, p["findings"])
	if err.is_empty() and not content()["conclusions"].has(str(p["conclusion"])):
		err = "Unbekannte Schlussfolgerung."
	if not err.is_empty():
		tx.fail(err)
		return
	var fixed := _report(s, p)
	tx.emit("report_corrected", "player", {"text": line("report_corrected")}, [
		AmtWorld.op_set(["cases", CASE_ID, "report", "findings"], fixed["findings"]),
		AmtWorld.op_set(["cases", CASE_ID, "report", "conclusion"], fixed["conclusion"]),
		AmtWorld.op_set(["cases", CASE_ID, "report", "conclusion_status"], fixed["conclusion_status"]),
		AmtWorld.op_set(["cases", CASE_ID, "report", "inquiry"], "beantwortet"),
	])


# --- Prüfungen ---

static func move_error(s: Dictionary, to: String) -> String:
	if not LOCATIONS.has(to):
		return "Diesen Ort gibt es hier nicht."
	if to == s["location"]:
		return "Sie sind schon dort."
	if s["phase"] == "abend":
		return "Der Abend findet im Hinterzimmer statt."
	if s["phase"] == "rueckkehr":
		return "Erst ansehen, was im Hof geworden ist."
	return ""


static func minigame_error(s: Dictionary, game: String) -> String:
	var c := _c(s)
	match game:
		"dame":
			if s["phase"] != "abend":
				return "DAME gibt es abends im Hinterzimmer."
			return ""
		"widerlegung":
			if s["phase"] != "tag2" or s["location"] != "ausschussraum":
				return "Der Ausschuss tagt am zweiten Tag im Ausschussraum."
			if c["status"] != "open":
				return "Der Vorgang ist abgeschlossen."
			var missing := missing_evidence(s, ["B-02", "B-03"])
			if not missing.is_empty():
				return "Für die Anfechtung fehlt: %s." % ", ".join(missing)
			if not str(c["definition"]).is_empty():
				return "Die Definitionsfrage ist für diesen Vorgang entschieden."
			return ""
	return "Unbekanntes Spiel."


## Ergebnisprüfung (Kap. 16.5, QA-14): gehört zur laufenden Session, zum Spiel, zum Vorgang und zur Regelversion.
## Mitgeschickte Effektlisten werden nie ausgeführt; der Fall übersetzt nur den Ausgang.
static func result_error(s: Dictionary, r: Variant) -> String:
	if not (r is Dictionary):
		return "Ergebnis fehlt."
	if int(r.get("schema_version", 0)) != AmtWorld.SCHEMA_VERSION:
		return "Unbekanntes Ergebnisformat."
	var sid := str(r.get("session_id", ""))
	if not (s["sessions"] as Dictionary).has(sid):
		return "Keine solche Partie."
	var session: Dictionary = s["sessions"][sid]
	if session["status"] != "running":
		return "Das Ergebnis dieser Partie ist bereits verbucht."
	if str(r.get("game", "")) != session["game"]:
		return "Das Ergebnis gehört zu einem anderen Spiel."
	if str(r.get("case_id", "")) != CASE_ID:
		return "Das Ergebnis gehört zu einem anderen Vorgang."
	if str(r.get("ruleset_version", "")) != session["ruleset_version"]:
		return "Das Ergebnis passt nicht zur Regelversion."
	match str(r.get("status", "")):
		"aborted":
			return ""
		"completed":
			var outcome := str(r.get("outcome", ""))
			if not ["won", "lost"].has(outcome):
				return "Unbekannter Ausgang."
			if session["game"] == "widerlegung":
				var facts: Variant = r.get("facts", {})
				var collapsed: bool = facts is Dictionary and facts.get("definition_collapsed", false) == true
				if collapsed != (outcome == "won"):
					return "Ausgang und Befund widersprechen sich."
				return _replay_error(session, r, outcome)
			# DAME lässt sich nicht nachspielen. Das Ergebnis muss zur Partie dieser Session gehören (match_id), außer als Debug-Stub.
			if r.get("dev", false) == true and allow_dev_results:
				return ""
			if str(r.get("match_id", "")) != str(session["match_id"]):
				return "Das Ergebnis gehört nicht zu dieser Partie."
			return ""
	return "Unbekannter Status."


## Der Ausgang einer Widerlegung muss sich aus Seed und Kartenfolge ergeben. Ohne gespielte Karten gilt nur ein
## Entwicklungsergebnis, und das nur in Debug-Builds.
static func _replay_error(session: Dictionary, r: Dictionary, outcome: String) -> String:
	var plays: Array = session["checkpoint"]["plays"]
	if plays.is_empty():
		if r.get("dev", false) == true and allow_dev_results:
			return ""
		return "Das Ergebnis ist nicht nachvollziehbar: Es wurden keine Karten gespielt."
	var replayed := BankWiderlegung.replay(str(session["seed"]), plays)
	if not replayed["ok"]:
		return str(replayed["error"])
	var o := BankWiderlegung.outcome(replayed["run"])
	if not bool(o["finished"]):
		return "Die Partie ist noch nicht entschieden."
	if bool(o["collapsed"]) != (outcome == "won"):
		return "Der Ausgang passt nicht zum Spielverlauf."
	if int(r.get("score", 0)) != int(o["score"]):
		return "Die Punkte passen nicht zum Spielverlauf."
	return ""


static func submission_error(s: Dictionary, p: Dictionary) -> String:
	var antrag := str(p.get("antrag", "keiner"))
	if not content()["antraege"].has(antrag):
		return "Unbekannter Antrag."
	var err := _findings_error(s, p.get("findings", []))
	if not err.is_empty():
		return err
	if not content()["conclusions"].has(str(p.get("conclusion", ""))):
		return "Eine Schlussfolgerung auswählen (oder »Keine Schlussfolgerung«)."
	var questions: Variant = p.get("open_questions", [])
	if not (questions is Array) or (questions as Array).is_empty():
		return "Mindestens eine offene Frage nennen oder »Keine weiteren offenen Punkte bekannt«."
	var available := available_open_questions(s)
	for q in questions:
		if not available.has(str(q)):
			return "Diese offene Frage ergibt sich aus der Akte nicht."
	if (questions as Array).has("keine") and (questions as Array).size() > 1:
		return "Entweder offene Fragen oder »Keine weiteren offenen Punkte bekannt«."
	var missing := missing_evidence(s, content()["antraege"][antrag]["requires"])
	if not missing.is_empty():
		return "Für den Antrag fehlt: %s." % ", ".join(missing)
	if antrag == "formal":
		if _c(s)["definition"] != "won":
			return "Für die formelle Freigabe muss die Arbeitsdefinition im Ausschuss widerlegt sein."
		if clean_wording(p.get("wording", "")).is_empty():
			return "Für die formelle Freigabe fehlt die Formulierung des Antrags."
	return ""


static func _findings_error(s: Dictionary, findings: Variant) -> String:
	if not (findings is Array):
		return "Feststellungen als Liste von Belegen angeben."
	if (findings as Array).size() > MAX_FINDINGS:
		return "Höchstens drei Feststellungen."
	var seen := {}
	for f in findings:
		if not has_ev(s, str(f)):
			return "Der Beleg %s liegt nicht vor." % str(f)
		if seen.has(str(f)):
			return "Jede Feststellung nur einmal."
		seen[str(f)] = true
	return ""


# --- Abfragen ---

static func _report(s: Dictionary, p: Dictionary) -> Dictionary:
	var findings := []
	for f in p.get("findings", []):
		findings.append(str(f))
	var conclusion := str(p.get("conclusion", "keine"))
	var questions := []
	for q in p.get("open_questions", []):
		questions.append(str(q))
	return {
		"findings": findings,
		"conclusion": conclusion,
		"conclusion_status": conclusion_status(s, findings, conclusion),
		"open_questions": questions,
		"inquiry": "",
	}


## "belegt", wenn die zitierten Feststellungen jede nötige Behauptung tragen; sonst "vermutung" (Kap. 7.1).
static func conclusion_status(s: Dictionary, findings: Array, conclusion: String) -> String:
	var requires: Array = content()["conclusions"].get(conclusion, {}).get("requires", [])
	if requires.is_empty():
		return "ohne"
	var claims := {}
	for f in findings:
		if has_ev(s, str(f)):
			for cl in s["evidence"][str(f)]["claim_ids"]:
				claims[cl] = true
	for r in requires:
		if not claims.has(r):
			return "vermutung"
	return "belegt"


static func available_open_questions(s: Dictionary) -> Array:
	var out := []
	for key in content()["open_questions"]:
		var q: Dictionary = content()["open_questions"][key]
		if not missing_evidence(s, q.get("if", [])).is_empty():
			continue
		var any: Array = q.get("if_any", [])
		if not any.is_empty() and any.all(func(id: String) -> bool: return not has_ev(s, id)):
			continue
		if (q.get("unless", []) as Array).any(func(id: String) -> bool: return has_ev(s, id)):
			continue
		out.append(key)
	return out


## Was für einen Antrag vorliegt und was fehlt (Kap. 9.7: das Bedienfeld nennt beides ausdrücklich).
static func antrag_requirements(s: Dictionary, antrag: String) -> Array:
	var out := []
	for id in content()["antraege"][antrag]["requires"]:
		out.append({"label": evidence_label(id), "ok": has_ev(s, id)})
	if antrag == "formal":
		out.append({"label": "Arbeitsdefinition im Ausschuss widerlegt", "ok": _c(s)["definition"] == "won"})
	return out


static func missing_evidence(s: Dictionary, ids: Array) -> Array:
	var out := []
	for id in ids:
		if not has_ev(s, str(id)):
			out.append(evidence_label(str(id)))
	return out


static func clean_wording(raw: Variant) -> String:
	var w := str(raw).replace("\n", " ").replace("\t", " ").strip_edges()
	return w.substr(0, MAX_WORDING)


static func comparison(a: String, b: String) -> Dictionary:
	for rule in content()["comparisons"]:
		var pair: Array = rule["pair"]
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return rule
	return {}


static func topics(s: Dictionary, actor: String) -> Array:
	if s["phase"] != "tag1" or not OFFICES.values().any(func(o: Dictionary) -> bool: return o["actor"] == actor):
		return []
	if s["actors"][actor]["location_id"] != s["location"]:
		return []
	if actor == "mertens" and has_ev(s, "B-02"):
		return ["bank", "kunst"]
	return ["bank"]


static func running_session(s: Dictionary) -> Dictionary:
	for sid in s["sessions"]:
		if s["sessions"][sid]["status"] == "running":
			return s["sessions"][sid]
	return {}


static func sessions_of(s: Dictionary, game: String) -> Array:
	return (s["sessions"] as Dictionary).values().filter(func(x: Dictionary) -> bool: return x["game"] == game)


static func completed_sessions(s: Dictionary, game: String) -> Array:
	return sessions_of(s, game).filter(func(x: Dictionary) -> bool: return x["status"] == "completed")


static func has_chair_commitment(s: Dictionary) -> bool:
	return (s["actors"]["mertens"]["commitments"] as Dictionary).has("stuhl")


static func has_ev(s: Dictionary, id: String) -> bool:
	return (s["evidence"] as Dictionary).has(id)


static func knows(s: Dictionary, actor: String, fact: String) -> bool:
	return (s["actors"][actor]["known_fact_ids"] as Array).has(fact)


static func office_at(loc: String) -> String:
	for office in OFFICES:
		if OFFICES[office]["location"] == loc:
			return office
	return ""


static func office_of(actor: String) -> String:
	for office in OFFICES:
		if OFFICES[office]["actor"] == actor:
			return office
	return ""


## Was man beim Umsehen sieht. Bei Stellen hängt es von der Aufmerksamkeit ab, nie rückwirkend.
static func observation_text(s: Dictionary, loc: String) -> String:
	var texts: Array = content()["observe"][loc]
	var office := office_at(loc)
	var text := str(texts[mini(int(s["offices"][office]["attention"]), texts.size() - 1)]) if not office.is_empty() else str(texts[0])
	if loc == "registratur" and s["objects"]["originals"]["location"] == "pruefschrank":
		text += str(content()["observe"]["registratur_leer"])
	return text


static func kern_line(s: Dictionary) -> String:
	match str(s["actors"]["kern"]["seat"]):
		"bench":
			return line("kern_bench")
		"chair":
			return line("kern_chair")
	if _c(s)["status"] == "not_opened":
		return line("kern_before")
	if s["phase"] == "rueckkehr":
		return line("kern_still")
	return line("kern_tag2") if s["phase"] == "tag2" else line("kern_open")


## Ort, wie er jetzt ist (QA-15: jeder Besuch zeigt den aktuellen Zustand).
static func scene(s: Dictionary) -> Dictionary:
	var loc := str(s["location"])
	var sc: Dictionary = content()["scene"]
	var parts := [str(content()["locations"][loc]["text"])]
	match loc:
		"innenhof":
			parts.append(sc["bench_" + str(s["objects"]["bench"]["access"])])
			if bool(s["objects"]["chair"]["available"]) and s["objects"]["chair"]["location"] == "innenhof":
				parts.append(sc["chair"])
			if s["actors"]["kern"]["location_id"] == "innenhof":
				var seat := str(s["actors"]["kern"]["seat"])
				parts.append(sc["kern_" + seat] if not seat.is_empty() else sc["kern_standing"])
			if not str(s["objects"]["hof_schild"]["text"]).is_empty():
				parts.append("%s: »%s«" % [sc["aushang_label"], s["objects"]["hof_schild"]["text"]])
			if bool(s["objects"]["nebeneingang"]["wartet"]):
				parts.append(sc["neuer_stuhl"])
			# Der Spatz ist einfach manchmal da (Kap. 3.5).
			if (int(s["turn"]) + str(s["phase"]).length()) % 3 == 0:
				parts.append(sc["spatz"])
		"hinterzimmer":
			parts.append(sc["hinterzimmer_abend"] if s["phase"] == "abend" else sc["hinterzimmer_tag"])
		"registratur":
			if s["objects"]["originals"]["location"] == "pruefschrank":
				parts.append(str(content()["observe"]["registratur_leer"]).strip_edges())
	var people := []
	for actor in PEOPLE:
		if s["actors"][actor]["location_id"] == loc:
			people.append("%s (%s)" % [person_name(actor), content()["people"][actor]["rolle"]])
	return {"name": location_name(loc), "text": " ".join(parts), "people": people}


## Amtliche Fassung des Abschlusses (Kap. 13.1). Sie beschreibt das Erlebte anders, überschreibt aber nie die Ereignisse.
static func official_summary(s: Dictionary) -> String:
	var key := str(_c(s)["resolution"])
	return str(content()["official"].get(key if not key.is_empty() else "open", content()["official"]["open"]))


## Aktenhilfe (Kap. 11.3): beantwortet nur operative Fragen und nur aus dem, was der Spieler schon weiß.
static func help_missing(s: Dictionary) -> String:
	var h: Dictionary = content()["help"]
	var lines := []
	for antrag in ["formal", "ausnahme"]:
		var missing := antrag_requirements(s, antrag).filter(func(r: Dictionary) -> bool: return not r["ok"])
		if missing.is_empty():
			continue
		lines.append(str(h["missing_head"]) % str(content()["antraege"][antrag]["label"]))
		for r in missing:
			lines.append("  – %s" % r["label"])
	return "\n".join(lines) if not lines.is_empty() else str(h["missing_none"])


static func help_when(s: Dictionary, id: String) -> String:
	if not has_ev(s, id):
		return str(content()["help"]["when_none"])
	var e: Dictionary = s["evidence"][id]
	var def: Dictionary = content()["evidence"][id]
	return "%s: %s, %s, %s." % [def["titel"], content()["kinds"][e["kind"]], time_label(e["observed_at"]), source_name(str(e["source_id"]))]


## Welche Stellen der Spieler selbst angesprochen hat. Aufmerksamkeit und Benachrichtigungen bleiben unsichtbar (Kap. 12.2).
static func help_requested(s: Dictionary) -> String:
	var did := {}
	for ev in s["events"]:
		var office := ""
		var how := ""
		match str(ev["type"]):
			"document_requested":
				office = str(ev["payload"]["office"])
				how = "angefordert"
			"interviewed":
				office = office_of(str(ev["payload"]["actor"]))
				how = "befragt"
			"observed":
				office = office_at(str(ev["payload"]["location"]))
				how = "beobachtet"
		if office.is_empty():
			continue
		var list: Array = did.get(office, [])
		if not list.has(how):
			list.append(how)
		did[office] = list
	var h: Dictionary = content()["help"]
	if did.is_empty():
		return str(h["requested_none"])
	var lines := []
	for office in did:
		lines.append("%s: %s" % [office_name(office), ", ".join(PackedStringArray(did[office]))])
	lines.append(str(h["requested_tail"]))
	return "\n".join(lines)


static func status_line(s: Dictionary) -> String:
	var label := str(content()["phases"][s["phase"]])
	var c := _c(s)
	if s["phase"] == "tag1":
		if c["status"] == "not_opened":
			return label + " · noch keine Prüfung"
		return "%s · Diensthandlungen: %d von %d" % [label, int(c["hours_remaining"]), HOURS]
	return label


## Handlungen für die Oberfläche, nach Gruppen (Kap. 12.2: wenige primäre, der Rest als Unterauswahl).
## "submit_form" öffnet das Formular; erst dessen Bestätigung sendet "submit".
static func available_actions(s: Dictionary) -> Array:
	var out := []
	if not running_session(s).is_empty():
		return out
	var c := _c(s)
	var phase := str(s["phase"])
	var loc := str(s["location"])
	var open: bool = c["status"] == "open"
	if phase == "rueckkehr":
		return [_a("vorgang", "Einige Wochen später …", "advance")]
	if phase == "tag1" and c["status"] == "not_opened" and loc == "innenhof":
		out.append(_a("hier", "Sperrung klären (Prüfung eröffnen)", "open_case"))
	if s["actors"]["kern"]["location_id"] == loc:
		out.append(_a("hier", "Mit Frau Kern sprechen", "talk", {"actor": "kern"}))
	if phase == "tag1" and open and int(c["hours_remaining"]) > 0:
		out.append(_a("hier", "Umsehen (1)", "observe"))
		for actor in ["mertens", "seidel", "voss"]:
			for topic in topics(s, actor):
				out.append(_a("hier", "%s befragen: %s (1)" % [person_name(actor), TOPIC_LABELS[topic]], "interview", {"actor": actor, "topic": topic}))
		if s["actors"]["mertens"]["location_id"] == loc and not has_chair_commitment(s):
			out.append(_a("hier", "Mertens um einen Stuhl für Frau Kern bitten (1)", "request_help", {"actor": "mertens"}))
		out.append(_a("hier", "Zeit verstreichen lassen (1)", "wait"))
		for key in content()["requests"]:
			var req: Dictionary = content()["requests"][key]
			if not (c["requests"] as Dictionary).has(key) and not _all_held(s, req["documents"]):
				out.append(_a("anfordern", "%s (%s) (1)" % [req["label"], office_name(req["office"])], "request_document", {"document_id": key}))
	if phase == "abend":
		if completed_sessions(s, "dame").is_empty():
			out.append(_a("hier", "Mit Mertens spielen (DAME)", "start_minigame", {"game": "dame"}))
		out.append(_a("hier", "Mit Mertens über die Bank sprechen", "talk", {"actor": "mertens", "topic": "bank"}))
		out.append(_a("vorgang", "Abend beenden", "end_evening"))
	if phase == "tag2" and minigame_error(s, "widerlegung").is_empty():
		out.append(_a("hier", "Einstufung anfechten (Widerlegung)", "start_minigame", {"game": "widerlegung"}))
	if phase == "tag2" and open:
		out.append(_a("vorgang", "Bericht und Antrag einreichen …", "submit_form"))
	if phase == "tag1" and open:
		out.append(_a("vorgang", "Untersuchung beenden (Feierabend)", "end_day"))
	if ["tag1", "abend", "tag2"].has(phase) and open:
		out.append(_a("vorgang", "Vorgang ohne Antrag abschließen", "close_case"))
	if phase == "nachgang" and str(c["report"].get("inquiry", "")) == "offen":
		for key in content()["conclusions"]:
			if key != c["report"]["conclusion"]:
				out.append(_a("vorgang", "Rückfrage beantworten: %s" % content()["conclusions"][key]["text"], "correct_report", {"conclusion": key}))
	for to in LOCATIONS:
		if move_error(s, to).is_empty():
			out.append(_a("gehen", location_name(to), "move", {"to": to}))
	return out


static func _a(group: String, label: String, type: String, params: Dictionary = {}) -> Dictionary:
	return {"group": group, "label": label, "type": type, "params": params}


## Spielerakte: Inhalt, Quelle, Zeitpunkt, Status (Kap. 7.1). Reihenfolge des Erwerbs.
static func akte(s: Dictionary) -> Array:
	var out := []
	for id in s["evidence"]:
		var e: Dictionary = s["evidence"][id]
		var def: Dictionary = content()["evidence"][id]
		out.append({
			"id": id, "titel": def["titel"], "art": content()["kinds"][e["kind"]],
			"quelle": source_name(str(e["source_id"])), "zeit": time_label(e["observed_at"]),
			"belegt": def["belegt"], "belegt_nicht": def["belegt_nicht"],
		})
	return out


static func documents(s: Dictionary) -> Array:
	var out := []
	for doc in s["documents"]:
		var entry: Dictionary = s["documents"][doc]
		out.append({"id": doc, "titel": doc_title(doc), "text": str(entry.get("text", content()["documents"][doc]["text"]))})
	return out


## Was der Spieler mitbekommen hat. Aufmerksamkeit, Planung und Uhr bleiben unsichtbar (Kap. 12.2).
static func visible_texts(events: Array) -> Array:
	var out := []
	for ev in events:
		var text := str(ev["payload"].get("text", ""))
		if not text.is_empty():
			out.append(text)
	return out


## Für die Entwicklungsansicht: interne Werte, nie in öffentlichen Builds (Kap. 16.7).
static func dev_info(s: Dictionary) -> String:
	var lines := []
	for office in s["offices"]:
		lines.append("Aufmerksamkeit %s: %d (Kontakt Handlung %d)" % [office, int(s["offices"][office]["attention"]), int(s["offices"][office]["last_contact"])])
	lines.append("Geplant: %s" % ", ".join(PackedStringArray((s["pending_events"] as Dictionary).keys())))
	lines.append("Abschluss: %s · Definition: %s" % [_c(s)["resolution"], _c(s)["definition"]])
	lines.append("Ereignisse: %d · Befehle: %d" % [(s["events"] as Array).size(), (s["applied_transactions"] as Array).size()])
	return "\n".join(lines)


## Gültiges Ergebnis für die laufende Partie: Ersatz für das echte Minispiel in E1 (Entwicklungsansicht, Tests).
static func dev_result(s: Dictionary, outcome: String) -> Dictionary:
	var session := running_session(s)
	var r := {
		"schema_version": AmtWorld.SCHEMA_VERSION, "session_id": session.get("session_id", ""),
		"game": session.get("game", ""), "case_id": CASE_ID, "ruleset_version": session.get("ruleset_version", ""),
		"status": "aborted" if outcome == "aborted" else "completed",
		"dev": true,
	}
	if outcome != "aborted":
		r["outcome"] = outcome
		r["score"] = 0
		if session.get("game") == "widerlegung":
			r["facts"] = {"definition_collapsed": outcome == "won"}
			r["chronicle_key"] = "bank_definition_rejected" if outcome == "won" else "bank_definition_upheld"
	return r


static func line(key: String) -> String:
	return str(content()["lines"][key])


static func location_name(loc: String) -> String:
	return str(content()["locations"][loc]["name"])


static func person_name(actor: String) -> String:
	return str(content()["people"][actor]["name"])


static func office_name(office: String) -> String:
	return str(content()["offices"][office])


static func doc_title(doc: String) -> String:
	return str(content()["documents"][doc]["titel"])


static func evidence_label(id: String) -> String:
	return "%s (%s)" % [content()["evidence"][id]["titel"], id]


static func source_name(id: String) -> String:
	if content()["people"].has(id):
		return person_name(id)
	if content()["offices"].has(id):
		return office_name(id)
	if content()["locations"].has(id):
		return location_name(id)
	return "Eigener Abgleich" if id == "abgleich" else id


static func time_label(at: Dictionary) -> String:
	match str(at["phase"]):
		"tag1":
			return "Tag 1, Handlung %d" % int(at["turn"]) if int(at["turn"]) > 0 else "Tag 1"
		"abend":
			return "Abend"
		"nachgang":
			return "Später"
	return "Tag 2"


# --- Bausteine ---

static func _c(s: Dictionary) -> Dictionary:
	return s["cases"][CASE_ID]


static func _cp(key: String) -> Array:
	return ["cases", CASE_ID, key]


static func _all_held(s: Dictionary, docs: Array) -> bool:
	return docs.all(func(d: String) -> bool: return (s["documents"] as Dictionary).has(d))


## Hinweis für den Spieler (Inhalt, Quelle, Zeitpunkt, Status; Kap. 7.1). Unmittelbar vor dem emit() bilden,
## denn der Wissenseintrag verweist auf das kommende Ereignis.
static func _evidence_ops(tx: AmtTransaction, id: String, source_id: String) -> Array:
	if has_ev(tx.state, id):
		return []
	var def: Dictionary = content()["evidence"][id]
	return [
		AmtWorld.op_set(["evidence", id], {
			"evidence_id": id, "case_id": CASE_ID, "kind": def["kind"], "source_id": source_id,
			"observed_at": {"phase": tx.state["phase"], "turn": tx.turn},
			"content_ref": "evidence." + id, "claim_ids": (def["claims"] as Array).duplicate(),
		}),
		AmtWorld.op_append(_cp("evidence_ids"), id),
		AmtWorld.op_append(["knowledge"], {"observer_id": "player", "fact_id": id, "learned_from": tx.next_event_id(), "learned_at": tx.turn}),
	]


## Eine Figur erfährt eine Tatsache (ActorState.known_fact_ids plus KnowledgeEntry).
static func _learn_ops(tx: AmtTransaction, actor: String, fact: String) -> Array:
	if knows(tx.state, actor, fact):
		return []
	return [
		AmtWorld.op_append(["actors", actor, "known_fact_ids"], fact),
		AmtWorld.op_append(["knowledge"], {"observer_id": actor, "fact_id": fact, "learned_from": tx.next_event_id(), "learned_at": tx.turn}),
	]


## Ein Dokument geht in den Aktenkoffer, samt zugehörigem Hinweis.
static func _doc_ops(tx: AmtTransaction, doc: String, from: String, text: String = "") -> Array:
	if (tx.state["documents"] as Dictionary).has(doc):
		return []
	var entry := {"from": from, "phase": tx.state["phase"], "turn": tx.turn}
	if not text.is_empty():
		entry["text"] = text
	var ops := [AmtWorld.op_set(["documents", doc], entry)]
	var ev_id := str(content()["document_evidence"].get(doc, ""))
	if not ev_id.is_empty():
		ops += _evidence_ops(tx, ev_id, from)
	return ops


static func _schedule_op(tx: AmtTransaction, id: String, action: String, params: Dictionary, due_turn: int, due_phase: String) -> Dictionary:
	return AmtWorld.op_set(["pending_events", id], AmtWorld.pending_entry(id, action, params, due_turn, due_phase, tx.next_event_id()))


static func _followup_ops(tx: AmtTransaction, id: String) -> Array:
	return [_schedule_op(tx, id, id, {}, 0, "nachgang"), AmtWorld.op_append(_cp("scheduled_followups"), id)]
