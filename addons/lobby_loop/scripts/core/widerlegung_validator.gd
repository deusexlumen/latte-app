# PURPOSE: Prüft vom Spielleiter erfundene Lehren: Form, Kartenpaare, Logik und Spielbarkeit (cap-Suche über WiderlegungSim).
# ARCHITECTURE: core
# DEPENDENCIES: WiderlegungRules, WiderlegungSim
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name WiderlegungValidator
extends RefCounted

const ATTRS_RANGE := [8, 12]
const START_RANGE := [2, 3]
const PRISMA_RANGE := [5, 7]
const CARDS_RANGE := [15, 22]
const MIN_PAIRS := 3
## Bis 20: Lehren mit vielen Paaren brauchen mehr Tragfähigkeit (gemessen: 21 Paare, bei 14 noch 62 % Zufallseinsturz).
const CAP_RANGE := [5, 20]
## Wurfzahlen, die die Prüfung ausprobiert, Standard zuerst.
const WUERFE_OPTIONS := [7, 6, 8, 5, 9]
## Partien pro Häppchen in validate_async (auf dem Desktop ~30 ms).
const SIM_CHUNK := 50
const COARSE_N := 100
const CONFIRM_N := 300
const GELEGENHEIT_BAND := [0.55, 0.80]
const ZUFALL_MAX := 0.35
const AUSNAHME_MIN := 0.60


## Formprüfung ohne Spiellogik. Liefert eine Liste von Befunden (leer = in Ordnung).
static func check_form(lehre: Dictionary) -> Array:
	var f := []
	for key in ["id", "begriff", "startSatz", "attrs", "start", "prisma", "cards", "refMembers", "refNon"]:
		if not lehre.has(key):
			f.append("Feld fehlt: %s" % key)
	if not f.is_empty():
		return f
	_range(f, "Merkmale", (lehre["attrs"] as Dictionary).size(), ATTRS_RANGE)
	_range(f, "Startbestimmungen", (lehre["start"] as Array).size(), START_RANGE)
	_range(f, "Prisma", (lehre["prisma"] as Array).size(), PRISMA_RANGE)
	_range(f, "Karten", (lehre["cards"] as Array).size(), CARDS_RANGE)
	for c in lehre["cards"]:
		if str(c.get("note", "")).strip_edges().is_empty():
			f.append("Karte ohne note: %s" % str(c.get("id", "?")))
	return f


static func _range(f: Array, what: String, n: int, r: Array) -> void:
	if n < r[0] or n > r[1]:
		f.append("%s: %d (erlaubt %d bis %d)" % [what, n, r[0], r[1]])


## Paare (Nichtmitglied, Mitglied): das Nichtmitglied scheitert an genau einer Startbestimmung,
## das Mitglied verletzt dieselbe. Braucht eine mit prepare() vorbereitete Lehre.
## Das ist die Entscheidung, die das Spiel trägt: Ausnahme machen oder nicht.
static func count_pairs(lehre: Dictionary) -> int:
	var near_non := {}
	var member_fail := {}
	for c in lehre["cards"]:
		var failed := []
		for l in lehre["start_lits"]:
			if not WiderlegungRules.lit_holds(c, {"a": l["a"], "neg": l["neg"]}):
				failed.append(l["a"])
		if bool(c["member"]):
			for a in failed:
				member_fail[a] = int(member_fail.get(a, 0)) + 1
		elif failed.size() == 1:
			near_non[failed[0]] = int(near_non.get(failed[0], 0)) + 1
	var n := 0
	for a in near_non:
		n += int(near_non[a]) * int(member_fail.get(a, 0))
	return n


## Referenzfälle sind Buchhaltung (Anker, nie im Deck). Wie cap setzt sie deshalb die Prüfung,
## wenn die des Modells nicht zur Startlehre passen: Gültige Anker des Modells bleiben, nur
## falsche werden ersetzt, in Kartenreihenfolge. Bevorzugt Karten, die kein Paar tragen
## (Nichtmitglieder, die an mindestens zwei Bestimmungen scheitern). Ob die Lehre danach
## noch spielbar ist, entscheidet wie immer die Simulation.
## Braucht eine Lehre nach prepare() (attr_set). true, wenn danach je mindestens ein Anker steht.
static func repair_refs(lehre: Dictionary) -> bool:
	var start := WiderlegungRules.initial_lehre(lehre)
	var cards: Dictionary = lehre.get("card_map", {})
	var ok_member := func(id: String) -> bool:
		return cards.has(id) and bool(cards[id]["member"]) and WiderlegungRules.satisfies(cards[id], start)
	var ok_non := func(id: String) -> bool:
		return cards.has(id) and not bool(cards[id]["member"]) and not WiderlegungRules.satisfies(cards[id], start)
	var members: Array = (lehre.get("refMembers", []) as Array).filter(ok_member)
	var nons: Array = (lehre.get("refNon", []) as Array).filter(ok_non)
	var want_m: int = maxi(1, (lehre.get("refMembers", []) as Array).size())
	var want_n: int = maxi(1, (lehre.get("refNon", []) as Array).size())
	var spare_nons := []
	for c in lehre.get("cards", []):
		var id := str(c["id"])
		if members.has(id) or nons.has(id):
			continue
		if members.size() < want_m and ok_member.call(id):
			members.append(id)
		elif not bool(c["member"]) and ok_non.call(id):
			var failed := 0
			for l in lehre["start_lits"]:
				if not WiderlegungRules.lit_holds(c, l):
					failed += 1
			if failed >= 2 and nons.size() < want_n:
				nons.append(id)
			else:
				spare_nons.append(id)
	while nons.size() < want_n and not spare_nons.is_empty():
		nons.append(spare_nons.pop_front())
	if members.is_empty() or nons.is_empty():
		return false
	lehre["refMembers"] = members
	lehre["refNon"] = nons
	return true


## Welche Startbestimmungen tragen kein Paar, und warum? Ein Satz pro Bestimmung, fürs Modell.
static func pair_hint(lehre: Dictionary) -> String:
	var parts := []
	for l in lehre["start_lits"]:
		var lit := ("-" if l["neg"] else "+") + str(l["a"])
		var members := 0
		var nons := 0
		for c in lehre["cards"]:
			var failed := 0
			var fails_this := false
			for k in lehre["start_lits"]:
				if not WiderlegungRules.lit_holds(c, {"a": k["a"], "neg": k["neg"]}):
					failed += 1
					fails_this = fails_this or (k["a"] == l["a"])
			if bool(c["member"]) and fails_this:
				members += 1
			elif not bool(c["member"]) and fails_this and failed == 1:
				nons += 1
		if members == 0 or nons == 0:
			var missing := []
			if members == 0:
				missing.append("kein Mitglied verletzt sie")
			if nons == 0:
				missing.append("kein Nichtmitglied scheitert nur an ihr")
			parts.append("%s: %s" % [lit, " und ".join(missing)])
	return "" if parts.is_empty() else "Startbestimmungen ohne Paar: " + "; ".join(parts) + "."


## Daten-Wrapper für die Simulation. Zwei Instanzen, damit Index 0 nie als letzte (Alexander) gilt.
static func _sim_data(base: Dictionary, lehre: Dictionary) -> Dictionary:
	return {"instanzen": [lehre, lehre], "rhetorik": base.get("rhetorik", {}), "kniffe": base.get("kniffe", []), "raenge": base.get("raenge", [])}


## Misst eine Lehre mit festem cap. Gibt die drei Kennzahlen zurück.
static func measure(base: Dictionary, lehre: Dictionary, cap: int, n: int) -> Dictionary:
	return measure_async.call(base, lehre, cap, n, Callable())


## Wie measure, aber nach je SIM_CHUNK Partien `await pump.call()`. Gleiche Zahlen.
static func measure_async(base: Dictionary, lehre: Dictionary, cap: int, n: int, pump: Callable) -> Dictionary:
	var L: Dictionary = lehre.duplicate(true)
	L["cap"] = cap
	var data := _sim_data(base, L)
	var out := {}
	for strategy in ["gelegenheit", "zufall"]:
		var st := WiderlegungSim.start(strategy, 0)
		while int(st["s"]) < n:
			WiderlegungSim.run_games(data, 0, strategy, st, mini(SIM_CHUNK, n - int(st["s"])))
			if pump.is_valid():
				await pump.call()
		out[strategy] = WiderlegungSim.result(st)
	return {"cap": cap, "gelegenheit": out["gelegenheit"]["einsturz"], "zufall": out["zufall"]["einsturz"], "ausnahme": out["gelegenheit"]["ausnahme_quote"]}


static func _in_bands(m: Dictionary) -> bool:
	return float(m["gelegenheit"]) >= GELEGENHEIT_BAND[0] and float(m["gelegenheit"]) <= GELEGENHEIT_BAND[1] \
		and float(m["zufall"]) < ZUFALL_MAX and float(m["ausnahme"]) >= AUSNAHME_MIN


## Gesamtprüfung. `base` ist WiderlegungRules.load_data() (für rhetorik/kniffe/raenge).
## Ergebnis: {"ok", "befunde": [..], "cap", "wuerfe", "messung", "paare"}. Setzt cap und Würfe selbst, nie das Modell.
static func validate(base: Dictionary, lehre_in: Dictionary, skip_form: bool = false) -> Dictionary:
	# Ohne pump pausiert validate_async nie und liefert das Ergebnis sofort zurück.
	return validate_async.call(base, lehre_in, skip_form, Callable())


## Wie validate, aber mit `pump`: Nach jedem Messschritt wartet die Prüfung auf `await pump.call()`
## (z. B. ein Frame). So stockt ein Spiel ohne Threads (Web-Export) nie länger als einen Messschritt.
static func validate_async(base: Dictionary, lehre_in: Dictionary, skip_form: bool, pump: Callable) -> Dictionary:
	var lehre: Dictionary = lehre_in.duplicate(true)
	var befunde := [] if skip_form else check_form(lehre)
	if not befunde.is_empty():
		return {"ok": false, "befunde": befunde, "cap": 0, "messung": {}, "paare": 0}
	lehre["cap"] = 9
	for key in ["hand", "wuerfe"]:
		lehre[key] = int(lehre.get(key, 5 if key == "hand" else 7))
	var err := WiderlegungRules.prepare(lehre)
	if err.begins_with("Referenz") and repair_refs(lehre):
		err = WiderlegungRules.prepare(lehre)
	if not err.is_empty():
		return {"ok": false, "befunde": [err], "cap": 0, "messung": {}, "paare": 0}
	var paare := count_pairs(lehre)
	if paare < MIN_PAIRS:
		befunde.append("Zu wenige Kartenpaare: %d (mindestens %d). Ein Nichtmitglied scheitert an genau einer Startbestimmung, ein Mitglied verletzt dieselbe." % [paare, MIN_PAIRS])
		var hint := pair_hint(lehre)
		if not hint.is_empty():
			befunde.append(hint)
		return {"ok": false, "befunde": befunde, "cap": 0, "messung": {}, "paare": paare}
	# Würfe setzt die Prüfung wie cap (LO, 12.10.2026): Ausnahmen wiegen 3, die Kurve über cap
	# springt deshalb in Stufen. Andere Wurfzahlen verschieben die Stufen. Erst der Standard 7,
	# dann die Nachbarn, damit bestandene Lehren möglichst beim gewohnten Tempo bleiben.
	var first: Dictionary = {}
	for w in WUERFE_OPTIONS:
		lehre["wuerfe"] = w
		var s: Dictionary = await _search_cap(base, lehre, pump)
		if s["ok"]:
			var sure: Dictionary = s["sure"]
			return {"ok": true, "befunde": [], "cap": s["cap"], "wuerfe": w, "messung": sure, "paare": paare,
				"refMembers": lehre["refMembers"], "refNon": lehre["refNon"]}
		if first.is_empty():
			first = s
	# Befunde aus dem Standard-Tempo: dort soll die Lehre beim Nachbessern landen.
	lehre["wuerfe"] = WUERFE_OPTIONS[0]
	var coarse: Callable = first["coarse"]
	var lo: int = CAP_RANGE[0]
	var hi: int = CAP_RANGE[1]
	for text in [_diagnose(coarse, lo, hi, paare), _steepness(coarse, int(first["first_ok"]), lo)]:
		if not str(text).is_empty():
			befunde.append(text)
	if befunde.is_empty():
		befunde.append("Kein cap trägt alle Bänder gleichzeitig (Gelegenheit 55 bis 80 %, Zufall unter 35 %, Ausnahme ab 60 %).")
	var last: Dictionary = coarse.call(int(first["first_ok"]) if int(first["first_ok"]) >= 0 else hi)
	return {"ok": false, "befunde": befunde, "cap": 0, "messung": last, "paare": paare}


## Handy-Laufzeit (Spec: unter 3 s): Beide Einsturzquoten fallen mit wachsendem cap.
## Also binär die kleinste Tragfähigkeit suchen, bei der Zufallsspiel nicht mehr reicht,
## von dort aufwärts nur die Kandidaten grob messen und genau einen mit 300 Partien bestätigen.
## Ergebnis {"ok", "cap", "sure", "coarse" (Callable mit Zwischenspeicher), "first_ok"}.
static func _search_cap(base: Dictionary, lehre: Dictionary, pump: Callable = Callable()) -> Dictionary:
	var memo := {}
	# Synchroner Zugriff für die Befunde danach; die Suche selbst füllt memo häppchenweise.
	var coarse := func(cap: int) -> Dictionary:
		if not memo.has(cap):
			memo[cap] = measure(base, lehre, cap, COARSE_N)
		return memo[cap]
	var lo: int = CAP_RANGE[0]
	var hi: int = CAP_RANGE[1]
	var out := {"ok": false, "cap": 0, "sure": {}, "coarse": coarse, "first_ok": -1}
	var m_hi: Dictionary = await _coarse_memo(memo, base, lehre, hi, pump)
	if float(m_hi["zufall"]) >= ZUFALL_MAX:
		return out
	var a := lo
	var b := hi
	while a < b:
		var mid := (a + b) / 2
		var m_mid: Dictionary = await _coarse_memo(memo, base, lehre, mid, pump)
		if float(m_mid["zufall"]) < ZUFALL_MAX:
			b = mid
		else:
			a = mid + 1
	out["first_ok"] = a
	for cap in range(a, hi + 1):
		var m: Dictionary = await _coarse_memo(memo, base, lehre, cap, pump)
		if float(m["gelegenheit"]) < GELEGENHEIT_BAND[0]:
			break
		if _in_bands(m):
			var sure: Dictionary = await measure_async(base, lehre, cap, CONFIRM_N, pump)
			if _in_bands(sure):
				out["ok"] = true
				out["cap"] = cap
				out["sure"] = sure
				return out
	return out


static func _coarse_memo(memo: Dictionary, base: Dictionary, lehre: Dictionary, cap: int, pump: Callable) -> Dictionary:
	if not memo.has(cap):
		memo[cap] = await measure_async(base, lehre, cap, COARSE_N, pump)
	return memo[cap]


## Kippt die Lehre zwischen zwei benachbarten Tragfähigkeiten von "zu leicht" auf "zu schwer"?
## Dann fehlt Feinkörnigkeit: mehr Karten und Paare, nicht ein anderes cap.
static func _steepness(coarse: Callable, first_ok: int, lo: int) -> String:
	if first_ok <= lo:
		return ""
	var a: Dictionary = coarse.call(first_ok - 1)
	var b: Dictionary = coarse.call(first_ok)
	if float(b["gelegenheit"]) >= GELEGENHEIT_BAND[0]:
		return ""
	return "Die Lehre kippt zu abrupt: Bei Tragfähigkeit %d stürzt sie auch bei Zufallsspiel zu oft (%.0f %%), bei %d hält sie gegen überlegtes Spiel zu oft (nur %.0f %% Einsturz). Mehr Karten (20 bis 22) und mehr Kartenpaare über verschiedene Startbestimmungen, damit sie Schritt für Schritt nachgibt." % [first_ok - 1, float(a["zufall"]) * 100, first_ok, float(b["gelegenheit"]) * 100]


## Ein Befund für die Nachbesserung: welches Band reißt, mit Zahlen und einer Handlung fürs Modell.
## Gemessen an den Mustern gescheiterter Erfindungen (12.10.2026, tools/lehre/curve.gd).
static func _diagnose(coarse: Callable, lo_cap: int, hi_cap: int, paare: int = 0) -> String:
	var top: Dictionary = coarse.call(hi_cap)
	var low: Dictionary = coarse.call(lo_cap)
	if float(top["zufall"]) >= ZUFALL_MAX:
		return "Zu viele Gegenbeispiele: Selbst bei der höchsten Tragfähigkeit (%d) bringt zufälliges Werfen die Lehre in %.0f %% der Partien zu Fall (erlaubt unter 35 %%). Es gibt %d Kartenpaare, gut sind 4 bis 10. Streiche Sonderfälle oder ersetze sie durch Karten, die die Lehre bestätigen: Mitglieder, die alle Startbestimmungen erfüllen, und Nichtmitglieder, die an mindestens zwei scheitern." % [hi_cap, float(top["zufall"]) * 100, paare]
	if float(low["gelegenheit"]) < GELEGENHEIT_BAND[0]:
		return "Zu wenige Gegenbeispiele: Selbst bei knapper Tragfähigkeit fällt die Lehre gegen überlegtes Spiel nur in %.0f %% der Partien (nötig 55 bis 80 %%). Mehr Kartenpaare über verschiedene Startbestimmungen." % (float(low["gelegenheit"]) * 100)
	if float(low["ausnahme"]) < AUSNAHME_MIN:
		return "Zu wenige Ausnahmen: Nur %.0f %% der Partien zwingen den Gegner zu einer Ausnahme (nötig 60 %%). Es fehlen Mitglieder, die eine Startbestimmung verletzen und bei denen keine Prisma-Bestimmung hilft: echte Sonderfälle des Begriffs." % (float(low["ausnahme"]) * 100)
	# Sprung über das Band: Wo Zufall nicht mehr reicht, liegt Gelegenheit erst über 80 %, dann unter 55 %.
	var above := {}
	var below := {}
	var hit_band := false
	for cap in range(lo_cap, hi_cap + 1):
		var m: Dictionary = coarse.call(cap)
		hit_band = hit_band or _in_bands(m)
		if float(m["zufall"]) >= ZUFALL_MAX:
			continue
		if float(m["gelegenheit"]) > GELEGENHEIT_BAND[1] and above.is_empty():
			above = m
		elif float(m["gelegenheit"]) < GELEGENHEIT_BAND[0] and below.is_empty():
			below = m
	if not above.is_empty() and not below.is_empty():
		return "Alles oder nichts: Überlegtes Spiel bringt die Lehre bei Tragfähigkeit %d in %.0f %% der Partien zu Fall, bei %d nur in %.0f %%, dazwischen nichts (nötig 55 bis 80 %%). Die Gegenbeispiele sind zu gleichförmig. Mische schwache Gegenbeispiele (Nichtmitglieder, die eine Prisma-Bestimmung schon abfängt) mit starken (Kartenpaare), und nutze alle Prisma-Merkmale auf mehreren Karten." % [int(above["cap"]), float(above["gelegenheit"]) * 100, int(below["cap"]), float(below["gelegenheit"]) * 100]
	if hit_band:
		return "Knapp vorbei: Die grobe Messung lag im Band, die Bestätigung mit 300 Partien nicht. Kleine Änderung genügt: ein Kartenpaar mehr oder weniger."
	return ""
