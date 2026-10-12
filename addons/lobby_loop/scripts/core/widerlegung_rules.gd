# PURPOSE: Regeln der Widerlegung, 1:1-Port von huhn/engine.js: laden, urteilen, nachbessern, Gewicht, Herzschlag, Kniffe, Vorgang.
# ARCHITECTURE: core
# DEPENDENCIES: WiderlegungRng, WiderlegungLibrary
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name WiderlegungRules
extends RefCounted

const CONTENT_DIR := "res://addons/lobby_loop/content/widerlegung/"
const GAIN := {"add": 1, "repair": 1, "excl": 3, "incl": 3, "confirm": 0}


# ---------------------------------------------------------------- Daten

## Lädt _common.json und alle Lehren in der Reihenfolge "order".
## Mit `library_dir` kommen die geprüften Lehren der Bibliothek dazu und die Sperrliste
## (Einsprüche) wirkt auf alle Lehren. Eine kaputte Bibliotheks-Lehre wird übersprungen.
## Ergebnis {"instanzen", "rhetorik", "kniffe", "raenge"} oder {"error": "..."}.
static func load_data(library_dir: String = "") -> Dictionary:
	var common: Variant = _load_json(CONTENT_DIR + "_common.json")
	if not (common is Dictionary):
		return {"error": "content/widerlegung/_common.json fehlt oder ist kaputt"}
	var data := {
		"instanzen": [],
		"rhetorik": common.get("rhetorik", {}),
		"kniffe": common.get("kniffe", []),
		"raenge": common.get("raenge", []),
	}
	for id in common.get("order", []):
		var lehre: Variant = _load_json(CONTENT_DIR + str(id) + ".json")
		if not (lehre is Dictionary):
			return {"error": "Lehre %s fehlt oder ist kaputt" % str(id)}
		if not library_dir.is_empty():
			lehre = WiderlegungLibrary.apply_sperrliste(lehre, WiderlegungLibrary.sperrliste(library_dir).get(str(id), []))
		var err := prepare(lehre)
		if not err.is_empty():
			return {"error": err}
		data["instanzen"].append(lehre)
	if library_dir.is_empty():
		return data
	var gesperrt := WiderlegungLibrary.sperrliste(library_dir)
	for raw in WiderlegungLibrary.load_lehren(library_dir):
		var lehre := WiderlegungLibrary.apply_sperrliste(raw, gesperrt.get(str(raw.get("id", "")), []))
		if prepare(lehre).is_empty() and index_of(data, str(lehre.get("id", ""))) < 0:
			data["instanzen"].append(lehre)
	return data


static func index_of(data: Dictionary, lehre_id: String) -> int:
	var list: Array = data.get("instanzen", [])
	for i in list.size():
		if str(list[i].get("id", "")) == lehre_id:
			return i
	return -1


## Wie setData() in engine.js: Kartenindex, Merkmal-Sets, Literale, Plausibilitätsprüfung.
## Liefert "" bei Erfolg, sonst die Fehlermeldung.
static func prepare(D: Dictionary) -> String:
	# Godot-JSON liefert alle Zahlen als float.
	for key in ["hand", "wuerfe", "cap"]:
		D[key] = int(D.get(key, 0))
	var card_map := {}
	for c in D.get("cards", []):
		var attrs := {}
		for a in str(c.get("a", "")).split(" ", false):
			if not D["attrs"].has(a):
				return "Unbekanntes Merkmal \"%s\" bei Karte %s in %s" % [a, c["id"], D["id"]]
			attrs[a] = true
		c["attr_set"] = attrs
		c["member"] = bool(c.get("m", false))
		if card_map.has(c["id"]):
			return "Doppelte Karte %s in %s" % [c["id"], D["id"]]
		card_map[c["id"]] = c
	D["card_map"] = card_map
	D["prisma_lits"] = _parse_lits(D.get("prisma", []))
	D["start_lits"] = _parse_lits(D.get("start", []))
	for l in D["prisma_lits"] + D["start_lits"]:
		if not D["attrs"].has(l["a"]):
			return "Prisma/Start: unbekanntes Merkmal %s in %s" % [l["a"], D["id"]]
	for id in D.get("refMembers", []) + D.get("refNon", []):
		if not card_map.has(id):
			return "Referenzkarte fehlt: %s" % id
	var start := initial_lehre(D)
	for id in D["refMembers"]:
		var member: Dictionary = card_map[id]
		if not member["member"] or not satisfies(member, start):
			return "Referenzmitglied passt nicht zur Startlehre: %s" % id
	for id in D["refNon"]:
		var non: Dictionary = card_map[id]
		if non["member"] or satisfies(non, start):
			return "Referenz-Nichtmitglied passt zur Startlehre: %s" % id
	return ""


static func parse_lit(s: String) -> Dictionary:
	return {"a": s.substr(1), "neg": s.begins_with("-")}


static func _parse_lits(list: Array) -> Array:
	var out := []
	for s in list:
		out.append(parse_lit(str(s)))
	return out


static func initial_lehre(D: Dictionary) -> Array:
	var out := []
	for l in D["start_lits"]:
		out.append({"t": "req", "a": l["a"], "neg": l["neg"]})
	return out


static func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


# ---------------------------------------------------------------- Logik der Lehre

static func lit_holds(card: Dictionary, l: Dictionary) -> bool:
	var has: bool = card["attr_set"].has(l["a"])
	return not has if l["neg"] else has


static func satisfies(card: Dictionary, lehre: Array) -> bool:
	for c in lehre:
		if c["t"] == "excl" and c.get("id") == card["id"]:
			return false
	for c in lehre:
		if c["t"] == "incl" and c.get("id") == card["id"]:
			return true
	for c in lehre:
		if c["t"] == "req" and not lit_holds(card, c):
			return false
	return true


static func judge(card: Dictionary, lehre: Array) -> String:
	var sat := satisfies(card, lehre)
	if sat and not card["member"]:
		return "broad"
	if not sat and card["member"]:
		return "narrow"
	return "confirm"


## Jede Bestimmung wiegt 1, auch weggefallene (das Amt löscht nichts). Ausnahmen 3, überstrichen 1.
static func weight(lehre: Array) -> int:
	var w := 0
	for c in lehre:
		if c["t"] == "req" or c["t"] == "gone":
			w += 1
		elif c.get("painted", false):
			w += 1
		else:
			w += 3
	return w


static func incl_ids(lehre: Array) -> Dictionary:
	var s := {}
	for c in lehre:
		if c["t"] == "incl":
			s[c["id"]] = true
	return s


static func used_attrs(lehre: Array) -> Dictionary:
	var s := {}
	for c in lehre:
		if c["t"] == "req" or c["t"] == "gone":
			s[c["a"]] = true
	return s


static func _cards(D: Dictionary, ids: Array) -> Array:
	var out := []
	for id in ids:
		out.append(D["card_map"][id])
	return out


static func _all_hold(cards: Array, l: Dictionary) -> bool:
	for c in cards:
		if not lit_holds(c, l):
			return false
	return true


static func _leaks(nons: Array, lehre: Array) -> Array:
	var out := []
	for n in nons:
		if satisfies(n, lehre):
			out.append(n)
	return out


static func _active_members(D: Dictionary, member_ids: Array, lehre: Array) -> Array:
	var incl := incl_ids(lehre)
	var out := []
	for id in member_ids:
		if not incl.has(id):
			out.append(D["card_map"][id])
	return out


## Zu weit: ein Nicht-Mitglied erfüllt die Lehre.
static func patch_broad(D: Dictionary, st: Dictionary, card: Dictionary, force: bool) -> Dictionary:
	var active := _active_members(D, st["members"], st["lehre"])
	if not force:
		var used := used_attrs(st["lehre"])
		for l in D["prisma_lits"]:
			if used.has(l["a"]):
				continue
			if lit_holds(card, l):
				continue
			if _all_hold(active, l):
				st["lehre"].append({"t": "req", "a": l["a"], "neg": l["neg"], "fresh": true})
				return {"kind": "add", "lit": l}
	st["lehre"].append({"t": "excl", "id": card["id"], "fresh": true})
	return {"kind": "excl"}


## Zu eng: ein Mitglied erfüllt die Lehre nicht.
static func patch_narrow(D: Dictionary, st: Dictionary, card: Dictionary, force: bool) -> Dictionary:
	if not force:
		var failing := []
		var base := []
		for c in st["lehre"]:
			if c["t"] == "req" and not lit_holds(card, c):
				failing.append(c)
				# gestrichene Bestimmungen bleiben als "weggefallen" im Text stehen
				base.append({"t": "gone", "a": c["a"], "neg": c["neg"], "fresh": true})
			else:
				base.append(c)
		var mems := _active_members(D, st["members"] + [card["id"]], base)
		var nons := _cards(D, st["non_members"])
		var def := base.duplicate()
		var added := []
		var leaks := _leaks(nons, def)
		while not leaks.is_empty():
			var used := used_attrs(def)
			var found: Variant = null
			for l in D["prisma_lits"]:
				if used.has(l["a"]):
					continue
				if not _all_hold(mems, l):
					continue
				var blocks_leak := false
				for n in leaks:
					if not lit_holds(n, l):
						blocks_leak = true
						break
				if blocks_leak:
					found = l
					break
			if found == null:
				break
			def.append({"t": "req", "a": found["a"], "neg": found["neg"], "fresh": true})
			added.append(found)
			leaks = _leaks(nons, def)
		if leaks.is_empty():
			st["lehre"] = def
			var removed := []
			for c in failing:
				removed.append({"a": c["a"], "neg": c["neg"]})
			return {"kind": "repair", "removed": removed, "added": added}
	st["lehre"].append({"t": "incl", "id": card["id"], "fresh": true})
	return {"kind": "incl"}


## Prisma-Merkmale, die der Gegner noch verwenden kann.
static func free_lits(D: Dictionary, st: Dictionary) -> Array:
	var used := used_attrs(st["lehre"])
	var mems := _active_members(D, st["members"], st["lehre"])
	var out := []
	for l in D["prisma_lits"]:
		if not used.has(l["a"]) and _all_hold(mems, l):
			out.append(l)
	return out


# ---------------------------------------------------------------- Text der Lehre

static func lit_phrase(D: Dictionary, l: Dictionary) -> String:
	var attr: Dictionary = D["attrs"][l["a"]]
	return str(attr["neg"]) if l["neg"] else str(attr["pos"])


static func lehre_view(D: Dictionary, lehre: Array) -> Dictionary:
	var reqs := []
	var excl := []
	var incl := []
	for c in lehre:
		if c["t"] == "req" or c["t"] == "gone":
			reqs.append({"text": lit_phrase(D, c), "fresh": bool(c.get("fresh", false)), "gone": c["t"] == "gone"})
		elif c["t"] == "excl":
			excl.append({"id": c["id"], "name": D["card_map"][c["id"]]["name"], "fresh": bool(c.get("fresh", false)), "painted": bool(c.get("painted", false))})
		else:
			incl.append({"id": c["id"], "name": D["card_map"][c["id"]]["name"], "fresh": bool(c.get("fresh", false)), "painted": bool(c.get("painted", false))})
	return {"reqs": reqs, "excl": excl, "incl": incl}


# ---------------------------------------------------------------- Vorgang

static func norm_az(s: String) -> String:
	return RegEx.create_from_string("\\s+").sub(s.strip_edges().to_upper(), "", true)


static func new_run(az: String, opts: Dictionary = {}) -> Dictionary:
	var n := norm_az(az)
	var kniffe: Array = opts.get("kniffe", [])
	return {
		"az": n,
		"daily": RegEx.create_from_string("^HUHN-\\d{8}$").search(n) != null,
		"kniffe": kniffe.duplicate(),
		"total": 0,
		"results": [],
		"alexander": null,
		"idx": 0,
		"phase": "intro",
		"streng": bool(opts.get("streng", false)),
		"inst": null,
		"offers": null,
	}


static func has_kniff(run: Dictionary, id: String) -> bool:
	return (run["kniffe"] as Array).has(id)


static func start_instanz(data: Dictionary, run: Dictionary) -> Dictionary:
	var D: Dictionary = data["instanzen"][run["idx"]]
	var o := {"rs": WiderlegungRng.hash_str(str(run["az"]) + "#" + str(D["id"]))}
	var pool := []
	for c in D["cards"]:
		if not (D["refMembers"] as Array).has(c["id"]) and not (D["refNon"] as Array).has(c["id"]):
			pool.append(c["id"])
	var deck := WiderlegungRng.shuffle(pool, o)
	var hand_n: int = D["hand"]
	# feste Startkarten (Tutorial: das Huhn liegt immer in der ersten Hand)
	if D.has("fixedHand"):
		for id in D["fixedHand"]:
			var i := deck.find(id)
			if i >= hand_n:
				var t: Variant = deck[i]
				deck[i] = deck[0]
				deck[0] = t
	var cap: int = D["cap"]
	var wuerfe: int = D["wuerfe"]
	if has_kniff(run, "inspektion"):
		cap -= 1
	if has_kniff(run, "huhn2"):
		wuerfe += 1
	if int(run["idx"]) == (data["instanzen"] as Array).size() - 1 and run["alexander"] == "gold":
		cap += 2
	var st := {
		"id": D["id"],
		"rs": o["rs"],
		"lehre": initial_lehre(D),
		"members": (D["refMembers"] as Array).duplicate(),
		"non_members": (D["refNon"] as Array).duplicate(),
		"hand": deck.slice(0, hand_n),
		"deck": deck.slice(hand_n),
		"wuerfe": wuerfe,
		"wuerfe_start": wuerfe,
		"cap": cap,
		"cap_start": cap,
		"extra": 0,
		"score": 0,
		"plays": 0,
		"beats": 0,
		"rhet_idx": 0,
		"telegraph": null,
		"status": "play",
		"seized": [],
		"used": {"fass": false, "uniform": false, "bettwaermer": false},
		"uniform_armed": false,
		"sonne_done": false,
		"first_widerlegung": true,
		"history": [],
		"exceptions": 0,
		"bonus": 0,
	}
	st["telegraph"] = make_telegraph(D, st)
	run["inst"] = st
	run["phase"] = "play"
	return st


static func make_telegraph(D: Dictionary, st: Dictionary) -> Variant:
	var seq: Array = D.get("rhetorik", [])
	if seq.is_empty():
		return null
	var rhet: String = seq[int(st["rhet_idx"]) % seq.size()]
	var tg := {"type": rhet, "target": null}
	var hand: Array = st["hand"]
	if rhet == "autoritaet" and not hand.is_empty():
		tg["target"] = hand[int(floor(WiderlegungRng.rnd(st) * hand.size()))]
	return tg


static func last(st: Dictionary) -> int:
	return weight(st["lehre"]) + int(st["extra"])


static func _draw_one(st: Dictionary) -> Variant:
	var deck: Array = st["deck"]
	if deck.is_empty():
		return null
	var id: Variant = deck.pop_front()
	st["hand"].append(id)
	return id


## Einspruch (Phase 2): Karte verlässt die Hand ohne Wurf, ohne Last und ohne Zufall,
## der Stapel füllt nach. Ein Herzschlag, der auf sie zielte, verliert sein Ziel.
static func withdraw_card(run: Dictionary, card_id: String) -> bool:
	var st: Variant = run.get("inst")
	if not (st is Dictionary) or run.get("phase") != "play":
		return false
	var hi: int = st["hand"].find(card_id)
	if hi < 0:
		return false
	st["hand"].remove_at(hi)
	_draw_one(st)
	var tg: Variant = st.get("telegraph")
	if tg is Dictionary and tg.get("target") == card_id:
		tg["target"] = null
	return true


## Wirft eine Karte. Liefert die Ereignisliste für die Oberfläche.
static func play(data: Dictionary, run: Dictionary, card_id: String) -> Array:
	var st: Variant = run.get("inst")
	if st == null or st["status"] != "play":
		return []
	var D: Dictionary = data["instanzen"][run["idx"]]
	var hi: int = st["hand"].find(card_id)
	if hi < 0:
		return []
	for c in st["lehre"]:
		c.erase("fresh")
	var card: Dictionary = D["card_map"][card_id]
	var ev := []
	st["hand"].remove_at(hi)
	var verdict := judge(card, st["lehre"])
	ev.append({"type": "throw", "card": card_id, "verdict": verdict})

	var res: Dictionary
	if verdict == "broad":
		var force: bool = st["uniform_armed"]
		res = patch_broad(D, st, card, force)
		st["non_members"].append(card_id)
		if force:
			st["uniform_armed"] = false
			res["uniform"] = true
	elif verdict == "narrow":
		var force: bool = st["uniform_armed"]
		res = patch_narrow(D, st, card, force)
		st["members"].append(card_id)
		if force:
			st["uniform_armed"] = false
			res["uniform"] = true
	else:
		var blocks := []
		if card["member"]:
			for l in free_lits(D, st):
				if not lit_holds(card, l):
					blocks.append(l)
		res = {"kind": "confirm", "blocks": blocks, "frei": not blocks.is_empty()}
		if card["member"]:
			st["members"].append(card_id)
		else:
			st["non_members"].append(card_id)
	res["card"] = card_id
	res["gain"] = GAIN[res["kind"]]
	if res["kind"] == "excl" or res["kind"] == "incl":
		st["exceptions"] += 1
	if verdict != "confirm" and st["first_widerlegung"]:
		st["first_widerlegung"] = false
		if has_kniff(run, "dudelsack"):
			st["extra"] += 1
			res["dudelsack"] = true
	st["score"] += res["gain"]
	res["last"] = last(st)
	var patch := {"type": "patch"}
	patch.merge(res)
	ev.append(patch)
	st["history"].append({"card": card_id, "verdict": verdict, "kind": res["kind"]})

	st["plays"] += 1
	# Beweisaufnahme: Eine Bestätigung, die dem Gegner ein freies Merkmal blockiert, kostet keinen Wurf.
	if not res.get("frei", false):
		st["wuerfe"] -= 1

	var drawn: Variant = _draw_one(st)
	if drawn != null:
		ev.append({"type": "draw", "card": drawn})

	if last(st) >= int(st["cap"]):
		_finish_instanz(data, run, true, ev)
		return ev

	if int(st["plays"]) % 3 == 0 and st["telegraph"] != null:
		_heartbeat(run, D, st, ev)

	if int(st["wuerfe"]) <= 0 or (st["hand"] as Array).is_empty():
		_finish_instanz(data, run, false, ev)
	return ev


static func _heartbeat(run: Dictionary, D: Dictionary, st: Dictionary, ev: Array) -> void:
	var tg: Dictionary = st["telegraph"]
	st["beats"] += 1
	var e := {"type": "beat", "rhet": tg["type"], "effect": "fizzle"}
	if has_kniff(run, "sonne") and not st["sonne_done"]:
		st["sonne_done"] = true
		e["effect"] = "sonne"
	elif tg["type"] == "autoritaet":
		var i: int = st["hand"].find(tg["target"]) if tg["target"] != null else -1
		if i >= 0:
			st["hand"].remove_at(i)
			st["seized"].append(tg["target"])
			e["effect"] = "seized"
			e["card"] = tg["target"]
			var d: Variant = _draw_one(st)
			if d != null:
				e["drawn"] = d
	elif tg["type"] == "knappheit":
		st["wuerfe"] = maxi(0, int(st["wuerfe"]) - 1)
		e["effect"] = "wurf"
	elif tg["type"] == "sozial":
		st["cap"] += 1
		e["effect"] = "cap"
	elif tg["type"] == "anstrich":
		var lehre: Array = st["lehre"]
		for i in range(lehre.size() - 1, -1, -1):
			var c: Dictionary = lehre[i]
			if (c["t"] == "excl" or c["t"] == "incl") and not c.get("painted", false):
				c["painted"] = true
				e["effect"] = "painted"
				e["id"] = c["id"]
				break
	e["last"] = last(st)
	e["cap"] = st["cap"]
	ev.append(e)
	st["rhet_idx"] += 1
	st["telegraph"] = make_telegraph(D, st)
	ev.append({"type": "telegraph", "tg": st["telegraph"]})


static func _finish_instanz(data: Dictionary, run: Dictionary, collapsed: bool, ev: Array) -> void:
	var st: Dictionary = run["inst"]
	st["status"] = "collapse" if collapsed else "hold"
	var bonus := 0
	if collapsed:
		bonus = 5 + 2 * maxi(0, int(st["wuerfe"]))
		var is_final := int(run["idx"]) == (data["instanzen"] as Array).size() - 1
		if is_final and run["alexander"] == "sonne":
			bonus += 15
	st["bonus"] = bonus
	st["score"] += bonus
	run["total"] += st["score"]
	var lehre_copy := []
	for c in st["lehre"]:
		var copy: Dictionary = c.duplicate()
		copy.erase("fresh")
		lehre_copy.append(copy)
	run["results"].append({
		"id": st["id"],
		"collapsed": collapsed,
		"at_wurf": st["plays"],
		"score": st["score"],
		"exceptions": st["exceptions"],
		"last": last(st),
		"cap": st["cap"],
		"lehre": lehre_copy,
	})
	run["phase"] = "result"
	ev.append({"type": "collapse" if collapsed else "hold", "bonus": bonus, "score": st["score"]})


# ---------------------------------------------------------------- Kniffe (aktiv)

static func use_kniff(run: Dictionary, id: String) -> Variant:
	var st: Variant = run.get("inst")
	if st == null or st["status"] != "play" or not has_kniff(run, id) or st["used"].get(id, false):
		return null
	if id == "fass":
		st["used"]["fass"] = true
		var old: Array = (st["hand"] as Array).duplicate()
		st["hand"] = []
		st["deck"] = st["deck"] + old
		var drawn := []
		for i in old.size():
			var d: Variant = _draw_one(st)
			if d != null:
				drawn.append(d)
		# Autorität zielt auf eine Karte, die nicht mehr in der Hand ist? Dann neu zielen.
		var tg: Variant = st["telegraph"]
		var hand: Array = st["hand"]
		if tg != null and tg["type"] == "autoritaet" and not hand.has(tg["target"]) and not hand.is_empty():
			tg["target"] = hand[int(floor(WiderlegungRng.rnd(st) * hand.size()))]
		return {"type": "fass", "old": old, "drawn": drawn}
	if id == "uniform":
		st["used"]["uniform"] = true
		st["uniform_armed"] = true
		return {"type": "uniform"}
	if id == "bettwaermer":
		st["used"]["bettwaermer"] = true
		var drawn := []
		for i in 2:
			var d: Variant = _draw_one(st)
			if d != null:
				drawn.append(d)
		return {"type": "bettwaermer", "drawn": drawn}
	return null


## Laterne: was würde der Gegner tun? Ändert nichts.
static func preview(data: Dictionary, run: Dictionary, card_id: String) -> Dictionary:
	var st: Dictionary = run["inst"]
	var D: Dictionary = data["instanzen"][run["idx"]]
	var card: Dictionary = D["card_map"][card_id]
	var lehre_copy := []
	for c in st["lehre"]:
		lehre_copy.append(c.duplicate())
	var tmp := {
		"lehre": lehre_copy,
		"members": (st["members"] as Array).duplicate(),
		"non_members": (st["non_members"] as Array).duplicate(),
	}
	var verdict := judge(card, tmp["lehre"])
	var res: Dictionary
	if verdict == "broad":
		res = patch_broad(D, tmp, card, st["uniform_armed"])
	elif verdict == "narrow":
		res = patch_narrow(D, tmp, card, st["uniform_armed"])
	else:
		var blocks := []
		if card["member"]:
			for l in free_lits(D, tmp):
				if not lit_holds(card, l):
					blocks.append(l)
		res = {"kind": "confirm", "blocks": blocks}
	res["verdict"] = verdict
	res["frei"] = res["kind"] == "confirm" and not (res["blocks"] as Array).is_empty()
	res["gain"] = GAIN[res["kind"]]
	var extra: int = st["extra"]
	if verdict != "confirm" and st["first_widerlegung"] and has_kniff(run, "dudelsack"):
		extra += 1
	res["last"] = weight(tmp["lehre"]) + extra
	res["collapse"] = int(res["last"]) >= int(st["cap"])
	return res


# ---------------------------------------------------------------- Zwischen den Instanzen

static func next_phase(data: Dictionary, run: Dictionary) -> String:
	var n: int = (data["instanzen"] as Array).size()
	if run["phase"] != "result":
		return run["phase"]
	if int(run["idx"]) >= n - 1:
		run["phase"] = "end"
		return "end"
	run["phase"] = "tonne"
	run["offers"] = kniff_offers(data, run)
	return "tonne"


static func kniff_offers(data: Dictionary, run: Dictionary) -> Array:
	var o := {"rs": WiderlegungRng.hash_str(str(run["az"]) + "#tonne" + str(run["idx"]))}
	var avail := []
	for k in data["kniffe"]:
		if not has_kniff(run, k["id"]):
			avail.append(k["id"])
	return WiderlegungRng.shuffle(avail, o).slice(0, 3)


static func choose_kniff(data: Dictionary, run: Dictionary, id: String) -> void:
	if run["phase"] != "tonne":
		return
	if not id.is_empty() and (run["offers"] as Array).has(id) and not has_kniff(run, id):
		run["kniffe"].append(id)
	run["offers"] = null
	run["idx"] = int(run["idx"]) + 1
	if int(run["idx"]) == (data["instanzen"] as Array).size() - 1 and run["alexander"] == null:
		run["phase"] = "alexander"
	else:
		run["phase"] = "intro"


static func choose_alexander(run: Dictionary, choice: String) -> void:
	if run["phase"] != "alexander":
		return
	run["alexander"] = "gold" if choice == "gold" else "sonne"
	if run["alexander"] == "gold":
		run["total"] += 8
	run["phase"] = "intro"


# ---------------------------------------------------------------- Wertung

static func rank(data: Dictionary, total: int) -> Dictionary:
	var raenge: Array = data["raenge"]
	var best: Dictionary = raenge[0]
	for x in raenge:
		if total >= int(x["min"]):
			best = x
	return best


static func pruefcode(run: Dictionary) -> String:
	var parts := PackedStringArray()
	for r in run["results"]:
		parts.append(("E%d" % int(r["at_wurf"]) if r["collapsed"] else "H") + str(r["score"]))
	var s := str(run["az"]) + ("|S" if run["streng"] else "") + "|" + str(run["total"]) + "|" + ",".join(parts) + "|" + (str(run["alexander"]) if run["alexander"] != null else "-")
	return ("%08X" % WiderlegungRng.hash_str(s)).substr(0, 4)
