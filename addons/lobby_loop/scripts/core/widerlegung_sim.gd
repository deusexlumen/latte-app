# PURPOSE: Balance-Simulation der Widerlegung (Zufall, Gelegenheit, Gierig); Grundlage der Spielbarkeitsprüfung in Phase 2.
# ARCHITECTURE: core
# DEPENDENCIES: WiderlegungRules, WiderlegungRng
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name WiderlegungSim
extends RefCounted

const STRATEGIES := ["zufall", "gelegenheit", "gierig"]


static func _pick(rng: Dictionary, n: int) -> int:
	return int(floor(WiderlegungRng.rnd(rng) * n))


static func choose(data: Dictionary, run: Dictionary, strategy: String, rng: Dictionary) -> String:
	var hand: Array = run["inst"]["hand"]
	if strategy == "gelegenheit":
		# liest nur das Urteil auf der Karte: Gegenbeispiele zuerst, sonst irgendwas
		var D: Dictionary = data["instanzen"][run["idx"]]
		var counter := []
		for id in hand:
			if WiderlegungRules.judge(D["card_map"][id], run["inst"]["lehre"]) != "confirm":
				counter.append(id)
		var pool: Array = counter if not counter.is_empty() else hand
		return pool[_pick(rng, pool.size())]
	if strategy == "gierig":
		# mit Laterne: nimmt den Wurf mit dem größten Lastzuwachs
		var best: String = hand[0]
		var best_value := -1e9
		for id in hand:
			var p := WiderlegungRules.preview(data, run, id)
			var value := (100.0 if p["collapse"] else 0.0) + float(p["last"]) * 3.0 + float(p["gain"]) + WiderlegungRng.rnd(rng) * 0.1
			if value > best_value:
				best_value = value
				best = id
		return best
	return hand[_pick(rng, hand.size())]


static func simulate(data: Dictionary, idx: int, strategy: String, n: int, kniffe: Array = []) -> Dictionary:
	var st := start(strategy, idx)
	run_games(data, idx, strategy, st, n, kniffe)
	return result(st)


## Zustand für eine in Pakete zerlegte Simulation (gleiche Zahlen wie simulate in einem Stück).
static func start(strategy: String, idx: int) -> Dictionary:
	return {"rng": {"rs": WiderlegungRng.hash_str("SIM#%s#%d" % [strategy, idx])}, "s": 0,
		"collapsed": 0, "any_exception": 0, "exceptions": 0, "plays_at_collapse": 0}


static func result(st: Dictionary) -> Dictionary:
	var n: int = st["s"]
	var collapsed: int = st["collapsed"]
	return {
		"einsturz": float(collapsed) / n,
		"ausnahme_quote": float(st["any_exception"]) / n,
		"avg_ausnahmen": float(st["exceptions"]) / n,
		"avg_wurf": float(st["plays_at_collapse"]) / collapsed if collapsed > 0 else 0.0,
	}


## Spielt die nächsten `count` Partien und zählt in `st` weiter.
static func run_games(data: Dictionary, idx: int, strategy: String, st: Dictionary, count: int, kniffe: Array = []) -> void:
	var rng: Dictionary = st["rng"]
	var instanz_count: int = (data["instanzen"] as Array).size()
	var collapsed: int = st["collapsed"]
	var any_exception: int = st["any_exception"]
	var exceptions: int = st["exceptions"]
	var plays_at_collapse: int = st["plays_at_collapse"]
	var first: int = st["s"]
	for s in range(first, first + count):
		var run := WiderlegungRules.new_run("SIM-%d" % s, {"kniffe": kniffe})
		run["idx"] = idx
		if idx == instanz_count - 1:
			run["alexander"] = "sonne"
		WiderlegungRules.start_instanz(data, run)
		while run["inst"]["status"] == "play":
			WiderlegungRules.play(data, run, choose(data, run, strategy, rng))
		var r: Dictionary = run["results"][0]
		if r["collapsed"]:
			collapsed += 1
			plays_at_collapse += int(r["at_wurf"])
		exceptions += int(r["exceptions"])
		if int(r["exceptions"]) > 0:
			any_exception += 1
	st["s"] = first + count
	st["collapsed"] = collapsed
	st["any_exception"] = any_exception
	st["exceptions"] = exceptions
	st["plays_at_collapse"] = plays_at_collapse
