# PURPOSE: Versuch „Zwei Bücher“: kleinster Regelkern einer Karriere, in der Aktenlage und Fundament getrennte Größen sind.
# PURPOSE: Jede Figur entscheidet nur nach dem, was in der Akte steht. Kein Würfel, kein Zufall: Jeder Ausgang folgt aus den Entscheidungen.
# ARCHITECTURE: karriere_kern (reine Regeln, kein Knoten, keine Datei)
# DEPENDENCIES: none
# PIPELINE: runtime, test, untersuchung (docs/karriere-versuch-2026-11.md)
# LAST_VALIDATED: 2026-11-16
class_name KarriereKern
extends RefCounted

## Sitzungsperioden einer Wahlzeit. Danach stellt die Fraktion die Liste auf.
const PERIODS := 9
## Diensthandlungen je Periode.
const POINTS := 2
## Nach diesen Perioden rückt auf, wer die bessere Bilanz hat.
const CHECKPOINTS: Array = [3, 6]
const THINGS: Array = ["halle", "bruecke"]
const PLAYER := "spieler"
const RIVAL := "brandt"
const PERSONS: Array = [PLAYER, RIVAL]

const NAMES := {
	"halle": "Sporthalle", "bruecke": "Brücke am Radweg",
	"spieler": "Sie", "brandt": "Ratsherr Brandt", "demir": "Ratsfrau Demir", "kolbe": "Ratsherr Kolbe",
	"vogt": "Dezernent Vogt",
}
const CARRIERS := {"halle": "Hausmeister Mertens", "bruecke": "die Bauhof-Kolonne"}
const SUCCESSORS := {"halle": "demir", "bruecke": "kolbe"}
const RANKS: Array = ["Ratsmitglied", "Ausschussvorsitz", "Dezernat"]


## Stellschrauben des Versuchs. tools/karriere_kern_sweep.gd prüft, ob die Befunde an ihnen hängen.
static func default_params() -> Dictionary:
	return {
		"collapse": 9,        # ab diesem Schaden gibt das Bauwerk nach
		"carrier_max": 4,     # so viele Einsätze trägt, wer die Sache nebenher erledigt
		"aushilfe_jobs": 2,   # so viele Einsätze trägt eine Aushilfe
		"urgent_open": 2,     # ab so vielen offenen Vorgängen gilt eine Sache in der Akte als dringlich
		"sign_limit": 3,      # ab so vielen eigenen Erledigt-Vermerken hängt man im Ausschuss mit drin
		"report_malus": 3,    # ein Gutachten setzt einen Mangel in die Akte des Ausschusses
		"reform": false,      # Variante B: die Registratur kann Wiederholungen ausweisen
		"repeat_urgent": 3,   # Variante B: ab so vielen Wiederholungen gilt eine Sache als dringlich
	}


static func new_game(overrides: Dictionary = {}) -> Dictionary:
	var params := default_params()
	for k in overrides:
		params[k] = overrides[k]
	var s := {
		"params": params, "term": 1, "period": 0, "points": 0, "over": false, "end": "", "end_reasons": [],
		# Wahlzeit 2 und später: Die Spielfigur ist neu (Testannahme, Issue #27). "absent": Die Welt läuft ohne Spielfigur weiter.
		"figure": "", "absent": false, "archive": {},
		"rank": {PLAYER: 0, RIVAL: 0}, "gone": {PLAYER: false, RIVAL: false},
		"things": {}, "ledger": {}, "malus": {PLAYER: 0, RIVAL: 0}, "signed": {},
		"counting": false, "budget_used": false, "seen": {}, "log": [],
	}
	var start := {"halle": 1, "bruecke": 2}
	var keepers := {"halle": PLAYER, "bruecke": RIVAL}
	for id in THINGS:
		s["things"][id] = {
			"damage": int(start[id]), "fixed": false, "collapsed": false, "due": 0, "pending": false,
			"open": 0, "done": 0, "report": "", "load": 0, "out": false, "was_out": false, "aushilfe": false, "keeper": str(keepers[id]),
			"requested": "",
		}
	for p in PERSONS:
		s["ledger"][p] = {}
		s["signed"][p] = {}
		for id in THINGS:
			s["ledger"][p][id] = {"done": 0, "open": 0}
			s["signed"][p][id] = 0
	return s


# ---------------------------------------------------------------- Abfragen

## Die Bilanz, nach der die Fraktionsvorsitzende entscheidet: Erledigtes zählt einfach, Offenes doppelt dagegen.
static func bilanz(s: Dictionary, person: String) -> int:
	var total := -int(s["malus"][person])
	for id in THINGS:
		var l: Dictionary = s["ledger"][person][id]
		total += int(l["done"]) - 2 * int(l["open"])
	return total


static func is_live(t: Dictionary) -> bool:
	return not bool(t["fixed"]) and not bool(t["collapsed"])


## Dringlich ist, was die Akte als dringlich zeigt. Der tatsächliche Schaden kommt hier nicht vor.
static func is_urgent(s: Dictionary, id: String, extra_open: int = 0) -> bool:
	var t: Dictionary = s["things"][id]
	var p: Dictionary = s["params"]
	if int(t["open"]) + extra_open >= int(p["urgent_open"]) or str(t["report"]) != "":
		return true
	return bool(s["counting"]) and int(t["done"]) >= int(p["repeat_urgent"])


## Die Handlungen, die dem Spieler in dieser Periode offenstehen: {id, thing, cost}.
static func available(s: Dictionary) -> Array:
	var out: Array = []
	if bool(s["over"]):
		return out
	var rank := int(s["rank"][PLAYER])
	var points := int(s["points"])
	for id in THINGS:
		var t: Dictionary = s["things"][id]
		if not is_live(t):
			continue
		var planned := int(t["due"]) > 0
		if rank == 0 and str(t["keeper"]) == PLAYER:
			if bool(t["pending"]) and not bool(t["out"]):
				out.append({"id": "erledigen", "thing": id, "cost": 1})
			if not planned and str(t["requested"]) == "":
				out.append({"id": "antrag", "thing": id, "cost": 1})
		if rank >= 1:
			if bool(t["out"]):
				out.append({"id": "aushilfe", "thing": id, "cost": 1})
			if not planned and str(t["requested"]) == "":
				out.append({"id": "antrag", "thing": id, "cost": 1})
			if not planned and str(t["report"]) == "":
				out.append({"id": "gutachten", "thing": id, "cost": 2})
		if rank == 2 and not planned and not bool(s["budget_used"]):
			out.append({"id": "sanieren", "thing": id, "cost": 2})
		var at_place := rank == 0 and str(t["keeper"]) == PLAYER
		if not at_place and int(s["seen"].get(id, {}).get("period", 0)) != int(s["period"]):
			out.append({"id": "nachsehen", "thing": id, "cost": 1})
	if rank >= 1 and bool(s["params"]["reform"]) and not bool(s["counting"]):
		out.append({"id": "zaehlweise", "thing": "", "cost": 2})
	return out.filter(func(a: Dictionary) -> bool: return int(a["cost"]) <= points)


static func can(s: Dictionary, action: String, thing: String) -> bool:
	for a in available(s):
		if str(a["id"]) == action and str(a["thing"]) == thing:
			return true
	return false


# ---------------------------------------------------------------- Ablauf

## Beginn einer Periode: beschlossene Sanierungen werden ausgeführt, der Rest altert, Meldungen gehen ein.
static func begin_period(s: Dictionary) -> void:
	if bool(s["over"]):
		return
	s["period"] = int(s["period"]) + 1
	s["points"] = POINTS
	s["budget_used"] = false
	for id in THINGS:
		var t: Dictionary = s["things"][id]
		t["requested"] = ""
		if not is_live(t):
			continue
		if int(t["due"]) == int(s["period"]):
			t["fixed"] = true
			t["pending"] = false
			_log(s, "fundament", "repair", id, "%s: saniert. Es gehen keine Meldungen mehr ein." % NAMES[id])
			continue
		t["damage"] = int(t["damage"]) + 1
		if int(t["damage"]) >= int(s["params"]["collapse"]):
			_collapse(s, id)
		else:
			t["pending"] = true
			_log(s, "buerger", "case", id, "Meldung: %s." % _case_text(id, int(t["damage"])))


static func act(s: Dictionary, action: String, thing: String = "") -> bool:
	if not can(s, action, thing):
		return false
	for a in available(s):
		if str(a["id"]) == action and str(a["thing"]) == thing:
			s["points"] = int(s["points"]) - int(a["cost"])
	var p: Dictionary = s["params"]
	match action:
		"erledigen":
			_carrier_job(s, thing, PLAYER)
		"antrag":
			s["things"][thing]["requested"] = PLAYER
			_log(s, PLAYER, "request", thing, "Sie beantragen die Sanierung: %s." % NAMES[thing])
		"aushilfe":
			_aushilfe(s, thing, PLAYER)
		"gutachten":
			var t: Dictionary = s["things"][thing]
			t["report"] = PLAYER
			t["requested"] = PLAYER
			s["malus"][PLAYER] = int(s["malus"][PLAYER]) + int(p["report_malus"])
			_log(s, PLAYER, "report", thing, "Gutachten %s: %s. Aktenkundig mit Ihrem Namen. In der Bilanz des Ausschusses steht jetzt ein Mangel (−%d)." % [NAMES[thing], damage_text(thing, int(t["damage"])), int(p["report_malus"])])
		"sanieren":
			s["things"][thing]["due"] = int(s["period"]) + 1
			s["budget_used"] = true
			_log(s, PLAYER, "fund", thing, "Sie ordnen die Sanierung an: %s. Ausführung in der nächsten Periode." % NAMES[thing])
		"nachsehen":
			look(s, thing)
		"zaehlweise":
			s["counting"] = true
			_log(s, PLAYER, "reform", "", "Die Registratur weist ab jetzt je Sache aus, wie oft dieselbe Meldung erledigt wurde.")
	return true


## Ortstermin: Der Spieler sieht den tatsächlichen Zustand. Ändert nichts an der Welt, nur am eigenen Wissen.
static func look(s: Dictionary, thing: String) -> void:
	var t: Dictionary = s["things"][thing]
	s["seen"][thing] = {"period": int(s["period"]), "damage": int(t["damage"]), "load": int(t["load"]), "out": bool(t["out"]), "live": is_live(t)}


## Ende einer Periode: die anderen handeln, Liegengebliebenes wird offen gebucht, die Kämmerei entscheidet, ggf. rückt jemand auf.
static func end_period(s: Dictionary) -> void:
	if bool(s["over"]):
		return
	var boss := _npc_boss(s)
	for id in THINGS:
		var t: Dictionary = s["things"][id]
		if not is_live(t):
			continue
		var keeper := str(t["keeper"])
		if bool(t["out"]) and boss != "":
			_aushilfe(s, id, boss)
		if bool(t["pending"]) and not bool(t["out"]):
			if keeper != PLAYER:
				_carrier_job(s, id, keeper)
			elif boss != "":
				_log(s, boss, "order", id, "%s weist %s an, die Meldung zu erledigen. Offene Vorgänge stehen in seiner Bilanz." % [NAMES[boss], carrier_name(s, id)])
				_carrier_job(s, id, boss)
		if bool(t["pending"]):
			t["pending"] = false
			t["open"] = int(t["open"]) + 1
			for person in _accountable(s, id):
				s["ledger"][person][id]["open"] = int(s["ledger"][person][id]["open"]) + 1
			_log(s, "registratur", "open", id, "Registratur: Vorgang %s offen über die Frist. Offen insgesamt: %d." % [NAMES[id], int(t["open"])])
		# Wer eine Sache betreut und niemanden mehr hat, der sie nebenher erledigt, stellt den Antrag.
		if bool(t["out"]) and keeper != PLAYER and str(t["requested"]) == "" and int(t["due"]) == 0:
			t["requested"] = keeper
			_log(s, keeper, "request", id, "%s beantragt die Sanierung: %s." % [NAMES[keeper], NAMES[id]])
	_fund(s)
	if CHECKPOINTS.has(int(s["period"])):
		_checkpoint(s)
	if int(s["period"]) >= PERIODS:
		_final(s)


# ---------------------------------------------------------------- Regeln der anderen

## Ein Kollege mit Rang handelt wie jeder, der nach Bilanz befördert wird: Er sorgt dafür, dass nichts offen bleibt.
static func _npc_boss(s: Dictionary) -> String:
	return RIVAL if int(s["rank"][RIVAL]) >= 1 and not bool(s["gone"][RIVAL]) else ""


## Wem ein Vorgang angerechnet wird: der betreuenden Person und allen mit Rang (die Akte des Ausschusses ist ihre Akte).
static func _accountable(s: Dictionary, id: String) -> Array:
	var out: Array = []
	for person in PERSONS:
		if bool(s["gone"][person]):
			continue
		if str(s["things"][id]["keeper"]) == person or int(s["rank"][person]) >= 1:
			out.append(person)
	return out


static func _carrier_job(s: Dictionary, id: String, signer: String) -> void:
	var t: Dictionary = s["things"][id]
	t["pending"] = false
	t["done"] = int(t["done"]) + 1
	t["load"] = int(t["load"]) + 1
	for person in _accountable(s, id):
		s["ledger"][person][id]["done"] = int(s["ledger"][person][id]["done"]) + 1
	if PERSONS.has(signer):
		s["signed"][signer][id] = int(s["signed"][signer][id]) + 1
	_log(s, signer, "done", id, "%s: Meldung erledigt durch %s, gezeichnet %s. Akte: erledigt, fristgerecht." % [NAMES[id], carrier_name(s, id), by(signer)])
	if int(t["load"]) >= int(s["params"]["carrier_max"]):
		t["out"] = true
		if bool(t["aushilfe"]):
			_log(s, "fundament", "carrier_out", id, "%s: Der Vertrag der Aushilfe ist ausgelaufen." % NAMES[id])
		else:
			t["was_out"] = true
			_log(s, "fundament", "carrier_out", id, "%s fällt aus. Es war der %d. Einsatz neben der eigentlichen Arbeit." % [cap(str(CARRIERS[id])), int(t["load"])])


## Aushilfe: Die offenen Vorgänge werden nachträglich erledigt, die Sache läuft wieder. Am Bauwerk ändert sich nichts.
static func _aushilfe(s: Dictionary, id: String, signer: String) -> void:
	var t: Dictionary = s["things"][id]
	var p: Dictionary = s["params"]
	t["out"] = false
	t["aushilfe"] = true
	t["load"] = int(p["carrier_max"]) - int(p["aushilfe_jobs"])
	var cleared := int(t["open"])
	t["done"] = int(t["done"]) + cleared
	t["open"] = 0
	for person in PERSONS:
		var l: Dictionary = s["ledger"][person][id]
		l["done"] = int(l["done"]) + int(l["open"])
		l["open"] = 0
	if PERSONS.has(signer):
		s["signed"][signer][id] = int(s["signed"][signer][id]) + 1
	var cleared_text := "%s damit nachträglich erledigt." % cap(open_text(cleared)) if cleared > 0 else "Offen war nichts."
	_log(s, signer, "aushilfe", id, "%s eine Aushilfe ein: %s. %s" % ["Sie setzen" if signer == PLAYER else "%s setzt" % NAMES[signer], NAMES[id], cleared_text])
	if bool(t["pending"]):
		_carrier_job(s, id, signer)


## Die Kämmerei gibt je Periode Mittel für eine Sanierung frei, und nur für das, was die Akte als dringlich zeigt.
static func _fund(s: Dictionary) -> void:
	var best := ""
	for id in THINGS:
		var t: Dictionary = s["things"][id]
		if str(t["requested"]) == "" or not is_live(t) or int(t["due"]) > 0:
			continue
		if not is_urgent(s, id):
			_log(s, "kaemmerei", "reject", id, "Kämmerei an %s: Sanierung %s zurückgestellt. Aktenlage: %s, %d fristgerecht erledigt. Es gibt dringlichere Aufgaben." % [NAMES[str(t["requested"])], NAMES[id], open_text(int(t["open"])), int(t["done"])])
			continue
		if best == "" or _urgency(s, id) > _urgency(s, best):
			best = id
	for id in THINGS:
		var t: Dictionary = s["things"][id]
		if str(t["requested"]) == "" or not is_live(t) or int(t["due"]) > 0 or not is_urgent(s, id):
			continue
		if id == best and not bool(s["budget_used"]):
			t["due"] = int(s["period"]) + 1
			s["budget_used"] = true
			_log(s, "kaemmerei", "fund", id, "Kämmerei an %s: Mittel für %s freigegeben. Grund laut Akte: %s. Ausführung in der nächsten Periode." % [NAMES[str(t["requested"])], NAMES[id], _urgent_reason(s, id)])
		else:
			_log(s, "kaemmerei", "defer", id, "Kämmerei an %s: %s ist dringlich, die Mittel dieser Periode sind gebunden. Neuer Antrag nötig." % [NAMES[str(t["requested"])], NAMES[id]])


static func _urgency(s: Dictionary, id: String) -> int:
	var t: Dictionary = s["things"][id]
	return int(t["open"]) * 100 + (50 if str(t["report"]) != "" else 0) + int(t["done"])


static func _urgent_reason(s: Dictionary, id: String) -> String:
	var t: Dictionary = s["things"][id]
	if str(t["report"]) != "":
		return "Gutachten liegt vor"
	if int(t["open"]) >= int(s["params"]["urgent_open"]):
		return open_text(int(t["open"]))
	return "%d Wiederholungen derselben Meldung" % int(t["done"])


## Wer die bessere Bilanz hat, rückt eine Stufe auf. Bei Gleichstand das neue Gesicht.
static func _checkpoint(s: Dictionary) -> void:
	var bs := bilanz(s, PLAYER)
	var winner := PLAYER
	var text := ""
	if bool(s["gone"][PLAYER]):
		# Die Spielfigur hat ihr Mandat verloren; die Fraktion entscheidet ohne sie.
		if bool(s["gone"][RIVAL]):
			return
		winner = RIVAL
		text = "Fraktionsvorsitzende: Bilanz Brandt %d. Sonst steht niemand zur Wahl." % bilanz(s, RIVAL)
	elif bool(s["gone"][RIVAL]):
		if bs < 0:
			_log(s, "fraktion", "checkpoint", "", "Fraktionsvorsitzende: Ihre Bilanz steht bei %d. Mit einer Akte im Minus rückt niemand auf." % bs)
			return
		text = "Fraktionsvorsitzende: Ihre Bilanz %d. Sonst steht niemand zur Wahl." % bs
	else:
		var bb := bilanz(s, RIVAL)
		winner = PLAYER if bs >= bb else RIVAL
		text = "Fraktionsvorsitzende: Bilanz Sie %d, Brandt %d." % [bs, bb]
	var rank := int(s["rank"][winner])
	var top_taken := false
	for person in PERSONS:
		if person != winner and int(s["rank"][person]) == 2 and not bool(s["gone"][person]):
			top_taken = true
	if rank >= 2 or (rank == 1 and top_taken):
		_log(s, "fraktion", "checkpoint", "", text + " Es ist keine Stelle frei.")
		return
	s["rank"][winner] = rank + 1
	_log(s, "fraktion", "checkpoint", "", "%s %s: %s." % [text, "Sie rücken auf" if winner == PLAYER else "Brandt rückt auf", RANKS[rank + 1]])
	_hand_over(s, winner)


## Wer aufrückt oder geht, gibt seine Sache ab. Die Nachfolge erbt die Sache, die Gewohnheit und den Hausmeister.
static func _hand_over(s: Dictionary, person: String) -> void:
	for id in THINGS:
		var t: Dictionary = s["things"][id]
		if str(t["keeper"]) == person:
			t["keeper"] = str(SUCCESSORS[id])
			if is_live(t):
				_log(s, "fraktion", "handover", id, "%s übernimmt: %s." % [NAMES[SUCCESSORS[id]], NAMES[id]])


## Einsturz. Der Untersuchungsausschuss fragt, wer zuständig war und wer es wissen konnte. Er liest die Akte.
static func _collapse(s: Dictionary, id: String) -> void:
	var t: Dictionary = s["things"][id]
	t["collapsed"] = true
	t["pending"] = false
	_log(s, "fundament", "collapse", id, "%s." % _collapse_text(id))
	for person in PERSONS:
		if bool(s["gone"][person]):
			continue
		var reasons: Array = []
		if int(s["rank"][person]) == 2:
			reasons.append("zuständig als Dezernent")
		if int(s["signed"][person][id]) >= int(s["params"]["sign_limit"]):
			reasons.append("%d-mal „erledigt“ gezeichnet" % int(s["signed"][person][id]))
		if str(t["report"]) == person:
			reasons.append("Kenntnis durch eigenes Gutachten")
		if reasons.is_empty():
			continue
		_log(s, "ausschuss", "removed", id, "Untersuchungsausschuss %s: %s, %s. Mandat verloren." % [NAMES[id], NAMES[person], ", ".join(PackedStringArray(reasons))])
		s["gone"][person] = true
		if person == PLAYER:
			s["over"] = true
			s["end"] = "ausschuss"
			s["end_reasons"] = reasons
		else:
			_hand_over(s, person)


static func _final(s: Dictionary) -> void:
	if bool(s["over"]):
		return
	s["over"] = true
	if bool(s["absent"]):
		return
	var b := bilanz(s, PLAYER)
	if int(s["rank"][PLAYER]) == 2:
		s["end"] = "dezernent"
		_log(s, "fraktion", "final", "", "Ende der Wahlzeit. Sie sind Dezernent und bleiben es.")
	elif b >= 0:
		s["end"] = "bleibt"
		_log(s, "fraktion", "final", "", "Ende der Wahlzeit. Bilanz %d. Sie stehen wieder auf der Liste, als %s." % [b, RANKS[int(s["rank"][PLAYER])]])
	else:
		s["end"] = "liste"
		_log(s, "fraktion", "final", "", "Ende der Wahlzeit. Bilanz %d. Die Fraktion stellt Sie nicht wieder auf. Mandat verloren." % b)


static func _log(s: Dictionary, who: String, kind: String, thing: String, text: String) -> void:
	(s["log"] as Array).append({"term": int(s["term"]), "period": int(s["period"]), "who": who, "kind": kind, "thing": thing, "text": text})


# ---------------------------------------------------------------- Texte und Auswertung

## Wer die Meldungen einer Sache gerade nebenher erledigt.
static func carrier_name(s: Dictionary, id: String) -> String:
	return "die Aushilfe" if bool(s["things"][id]["aushilfe"]) else str(CARRIERS[id])


static func open_text(count: int) -> String:
	return "1 offener Vorgang" if count == 1 else "%d offene Vorgänge" % count


static func by(person: String) -> String:
	return "von Ihnen" if person == PLAYER else "von %s" % NAMES[person]


## Erster Buchstabe groß. (String.capitalize() schreibt jedes Wort groß und ersetzt Bindestriche.)
static func cap(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1)


static func damage_text(id: String, damage: int) -> String:
	var halle := ["trocken", "ein Fleck an der Decke", "ein Fleck an der Decke", "Wasser läuft an der Wand herunter", "Wasser läuft an der Wand herunter",
		"drei Eimer auf dem Spielfeld", "drei Eimer auf dem Spielfeld", "die Tribüne ist gesperrt, ein Balken hat sich gesenkt", "die Tribüne ist gesperrt, ein Balken hat sich gesenkt"]
	var bruecke := ["fest", "Rost an den Lagern", "Rost an den Lagern", "Rost an den Lagern", "das Geländer wackelt, Bohlen federn",
		"das Geländer wackelt, Bohlen federn", "zwei Bohlen sind durch, ein Flatterband hängt davor", "zwei Bohlen sind durch, ein Flatterband hängt davor", "ein Träger ist sichtbar verformt"]
	var texts: Array = halle if id == "halle" else bruecke
	return str(texts[clampi(damage, 0, texts.size() - 1)])


static func _case_text(id: String, damage: int) -> String:
	if id == "halle":
		return "Der Sportverein meldet Wasser in der Halle (%s)" % damage_text(id, damage)
	return "Ein Radfahrer meldet einen Schaden an der Brücke (%s)" % damage_text(id, damage)


static func _collapse_text(id: String) -> String:
	if id == "halle":
		return "Das Dach der Sporthalle gibt nach. Die Halle ist geschlossen, der Verein hat keinen Ort mehr"
	return "Die Brücke am Radweg sackt ab. Der Radweg ist gesperrt"


## Was am Ende tatsächlich ist, unabhängig von jeder Akte.
static func actual(s: Dictionary) -> Dictionary:
	var out := {"fixed": 0, "collapsed": 0, "rotting": 0, "carriers_out": 0, "out_names": []}
	for id in THINGS:
		var t: Dictionary = s["things"][id]
		if bool(t["fixed"]):
			out["fixed"] += 1
		elif bool(t["collapsed"]):
			out["collapsed"] += 1
		else:
			out["rotting"] += 1
		# Wer einmal ausgefallen ist, bleibt es; eine Aushilfe ersetzt die Person, nicht ihre Gesundheit.
		if bool(t["was_out"]):
			out["carriers_out"] += 1
			(out["out_names"] as Array).append(str(CARRIERS[id]))
	return out


## Kurzform eines Ausgangs für die Auswertung aller Verläufe.
static func outcome(s: Dictionary) -> String:
	var a := actual(s)
	var states: Array = []
	for id in THINGS:
		var t: Dictionary = s["things"][id]
		states.append("%s %s%s" % [NAMES[id], "saniert" if bool(t["fixed"]) else ("eingestürzt" if bool(t["collapsed"]) else "verrottet weiter"), ", Träger ausgefallen" if bool(t["was_out"]) else ""])
	return "%s|Rang %d|Bilanz %+d|%s" % [str(s["end"]), int(s["rank"][PLAYER]), bilanz(s, PLAYER), "|".join(PackedStringArray(states))]


## Rückblick: zu einer Sache die Kette aus Ursache, verarbeitender Stelle und Spur (Spezifikation G-06).
static func trace(s: Dictionary, id: String) -> Array:
	var out: Array = []
	for e in s["log"]:
		if str(e["thing"]) == id and ["done", "aushilfe", "open", "reject", "fund", "defer", "report", "carrier_out", "repair", "collapse", "removed", "order", "request"].has(str(e["kind"])):
			var when := "Periode %d" % int(e["period"])
			if int(s["term"]) > 1:
				when = "Wahlzeit %d, %s" % [int(e.get("term", 1)), when]
			out.append("%s: %s" % [when, str(e["text"])])
	return out


## Zustand ohne Protokoll und ohne Spielerwissen: zwei Verläufe mit gleichem Schlüssel sind für die Welt derselbe.
static func key(s: Dictionary) -> String:
	var copy := s.duplicate(true)
	copy.erase("log")
	copy.erase("seen")
	return JSON.stringify(copy)


# ---------------------------------------------------------------- Über die Wahlzeit hinaus (Issue #27)

## Gibt es noch etwas, das verfällt, gemeldet oder entschieden werden kann?
static func has_matter(s: Dictionary) -> bool:
	for id in THINGS:
		if is_live(s["things"][id]):
			return true
	return false


## Verliert die Spielfigur ihr Mandat vor dem Ende der Wahlzeit, läuft die Welt nach denselben Regeln ohne sie weiter.
static func run_out(s: Dictionary) -> void:
	if int(s["period"]) >= PERIODS or not bool(s["over"]):
		return
	s["absent"] = true
	s["over"] = false
	_hand_over(s, PLAYER)
	# Die Periode, in der das Mandat verloren ging, läuft für die anderen zu Ende.
	end_period(s)
	while not bool(s["over"]):
		begin_period(s)
		end_period(s)


## Die nächste Wahlzeit beginnt in der Welt, die die vorige hinterlassen hat. Aus dem vollen Zustand, nicht aus outcome().
## Bleibt: Bauwerke, Schäden, beschlossene Sanierungen, Ausfälle, die Akte je Sache, Gutachten, Unterschriften, Brandts Stellung, das Protokoll.
## Neu je Wahlzeit: Periode, Diensthandlungen, Bilanz.
## Bleibt die Spielfigur im Amt, spielt man sie weiter: mit ihrem Rang und ihren Unterschriften.
## Testannahme: Hat sie ihr Mandat verloren, spielt man eine neue Figur im selben Bezirk. Die alte bleibt mit ihren
## Unterschriften in der Akte ("archive") und ist nicht aus der Welt.
static func next_term(prev: Dictionary, figure: String = "Nachrückerin (Testannahme)") -> Dictionary:
	if not bool(prev["over"]):
		return {}
	var s: Dictionary = prev.duplicate(true)
	var lost := ["ausschuss", "liste"].has(str(prev["end"]))
	run_out(s)
	s["term"] = int(s["term"]) + 1
	s["period"] = 0
	s["points"] = 0
	s["over"] = false
	s["absent"] = false
	s["end"] = ""
	s["end_reasons"] = []
	s["seen"] = {}
	s["budget_used"] = false
	for person in PERSONS:
		s["malus"][person] = 0
		for id in THINGS:
			s["ledger"][person][id] = {"done": 0, "open": 0}
	for id in THINGS:
		var t: Dictionary = s["things"][id]
		t["requested"] = ""
		# Eine beschlossene Sanierung wird ausgeführt, auch wenn dazwischen gewählt wurde.
		if int(t["due"]) > 0 and is_live(t):
			t["due"] = 1
	if not lost:
		_log(s, "fraktion", "term", "", "Neue Wahlzeit. Sie bleiben: %s." % RANKS[int(s["rank"][PLAYER])])
		return s
	(s["archive"] as Dictionary)["Wahlzeit %d: %s" % [int(s["term"]) - 1, "Ihre Vorgängerin" if str(s["figure"]) == "" else str(s["figure"])]] = (s["signed"][PLAYER] as Dictionary).duplicate()
	s["figure"] = figure
	s["gone"][PLAYER] = false
	s["rank"][PLAYER] = 0
	for id in THINGS:
		s["signed"][PLAYER][id] = 0
	# Die neue Figur übernimmt den Bezirk mit der Sporthalle von der, die ihn zuletzt betreut hat.
	s["things"]["halle"]["keeper"] = PLAYER
	_log(s, "fraktion", "term", "", "Neue Wahlzeit. Sie übernehmen den Bezirk mit der Sporthalle.")
	return s
