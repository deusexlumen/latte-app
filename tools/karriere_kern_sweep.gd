# PURPOSE: Rechnet den Versuch „Zwei Bücher“ vollständig durch: jede mögliche Folge von Entscheidungen des Spielers, gruppiert nach Ausgang.
# PURPOSE: Beantwortet, ob es einen Gewinnweg gibt, wie viele, was er kostet, und ob die Befunde an den Stellschrauben hängen.
# ARCHITECTURE: tools
# DEPENDENCIES: KarriereKern
# PIPELINE: untersuchung (docs/karriere-versuch-2026-11.md)
# LAST_VALIDATED: 2026-11-16
extends SceneTree

# Aufruf: godot --headless --path . --script res://tools/karriere_kern_sweep.gd
# Mit „-- kurz“ nur die Grundeinstellung, ohne Empfindlichkeitsprüfung.

const Kern := preload("res://karriere_kern/kern.gd")


## Feste Folgen von Handlungen ("Periode:Handlung:Sache"). Was nicht (mehr) möglich ist, entfällt.
const RECIPES := {
	"Tüchtig (nichts bleibt offen)": ["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "4:aushilfe:halle", "4:aushilfe:bruecke", "5:aushilfe:halle", "5:aushilfe:bruecke", "6:aushilfe:halle", "6:aushilfe:bruecke", "7:aushilfe:halle", "7:aushilfe:bruecke", "8:aushilfe:halle", "8:aushilfe:bruecke"],
	"Auswahl (eigenes decken, fremdes zeigen)": ["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "5:aushilfe:halle", "6:aushilfe:halle", "7:sanieren:halle", "8:sanieren:bruecke"],
	"Sichtbar (liegen lassen, beantragen)": ["2:antrag:halle", "3:antrag:halle", "4:antrag:halle"],
	"Aufsteigen, dann Gutachten": ["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "4:gutachten:bruecke", "5:gutachten:halle", "6:gutachten:halle"],
}


## Spielt eine feste Folge und gibt das Ende zurück.
static func run_recipe(overrides: Dictionary, steps: Array) -> String:
	var s := Kern.new_game(overrides)
	Kern.begin_period(s)
	while not bool(s["over"]):
		for step in steps:
			var parts: PackedStringArray = str(step).split(":")
			if int(parts[0]) == int(s["period"]):
				Kern.act(s, parts[1], parts[2])
		Kern.end_period(s)
		if not bool(s["over"]):
			Kern.begin_period(s)
	var a := Kern.actual(s)
	return "%s %d/%d/%d" % [str(s["end"]).substr(0, 4), int(a["fixed"]), int(a["collapsed"]), int(a["carriers_out"])]


func _initialize() -> void:
	var short := OS.get_cmdline_user_args().has("kurz")
	print("== A: Grundeinstellung ==")
	_report(sweep({}), true)
	print("\n== B: mit Zählweise (die Registratur kann Wiederholungen ausweisen) ==")
	_report(sweep({"reform": true}), true)
	if not short:
		print("\n== Empfindlichkeit: Einsturzgrenze x Belastbarkeit, je Variante ==")
		for reform in [false, true]:
			for collapse in [8, 9, 10]:
				for carrier in [3, 4, 5]:
					var r := sweep({"collapse": collapse, "carrier_max": carrier, "reform": reform})
					print("%s Einsturz %2d Belastbarkeit %d | Wege %7d | Dezernent %6d (%4.1f %%), davon niemand ausgefallen und nichts eingestürzt %5d | alles saniert und niemand ausgefallen (egal welcher Rang) %5d | bestes Aktenergebnis %+d endet: %s" % [
						"B" if reform else "A", collapse, carrier, r["total"], r["by_end"].get("dezernent", 0),
						100.0 * float(r["by_end"].get("dezernent", 0)) / float(r["total"]), r["clean_wins"], r["clean_any"], r["best_bilanz"], r["best_end"]])
	if not short:
		print("\n== Rezeptprobe: dieselbe Folge von Handlungen in veränderten Welten ==")
		for name in RECIPES:
			var line := "%-38s" % name
			for collapse in [8, 9, 10]:
				for carrier in [3, 4, 5]:
					line += " | %d/%d %s" % [collapse, carrier, run_recipe({"collapse": collapse, "carrier_max": carrier}, RECIPES[name])]
			print(line)
	print("SWEEP_OK")
	quit(0)


## Alle Zustände, die der Spieler in einer Periode durch Handlungen erreichen kann (ohne „nachsehen“: es ändert nur sein Wissen).
static func period_choices(state: Dictionary, path: Array) -> Dictionary:
	var out := {}
	var stack: Array = [[state, path]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var s: Dictionary = item[0]
		var k := Kern.key(s)
		if out.has(k):
			continue
		out[k] = item
		for a in Kern.available(s):
			if str(a["id"]) == "nachsehen":
				continue
			var n: Dictionary = s.duplicate(true)
			Kern.act(n, str(a["id"]), str(a["thing"]))
			var step := "%d:%s%s" % [int(s["period"]), str(a["id"]), ("(%s)" % str(a["thing"])) if str(a["thing"]) != "" else ""]
			stack.append([n, (item[1] as Array) + [step]])
	return out


## Breitensuche über die Perioden. Gleiche Weltzustände werden zusammengelegt, ihre Wege gezählt.
## full: Enden nach vollem Weltzustand getrennt halten statt nach Kurzform (nötig, wenn danach weitergespielt wird).
## start: von diesem Zustand aus statt von einer frischen Welt.
static func sweep(overrides: Dictionary, full: bool = false, start: Dictionary = {}) -> Dictionary:
	if start.is_empty():
		start = Kern.new_game(overrides)
		Kern.begin_period(start)
	# Schlüssel -> [Zustand, Anzahl Wege, Beispielweg]
	var frontier := {Kern.key(start): [start, 1, []]}
	var finished := {}
	while not frontier.is_empty():
		var next := {}
		for fk in frontier:
			var entry: Array = frontier[fk]
			var choices := period_choices(entry[0], entry[2])
			for ck in choices:
				var s: Dictionary = (choices[ck][0] as Dictionary).duplicate(true)
				var path: Array = choices[ck][1]
				Kern.end_period(s)
				if not bool(s["over"]):
					Kern.begin_period(s)
				var target: Dictionary = finished if bool(s["over"]) else next
				var k := (Kern.key(s) if full else Kern.outcome(s)) if bool(s["over"]) else Kern.key(s)
				if target.has(k):
					target[k][1] = int(target[k][1]) + int(entry[1])
					# Als Beispiel den Weg mit den wenigsten Handlungen behalten.
					if path.size() < (target[k][2] as Array).size():
						target[k][0] = s
						target[k][2] = path
				else:
					target[k] = [s, int(entry[1]), path]
		frontier = next
	var total := 0
	var by_end := {}
	var clean := 0
	var clean_any := 0
	var best_bilanz := -999
	var best_end := ""
	for k in finished:
		var n := int(finished[k][1])
		var s: Dictionary = finished[k][0]
		total += n
		by_end[str(s["end"])] = int(by_end.get(str(s["end"]), 0)) + n
		var a := Kern.actual(s)
		if str(s["end"]) == "dezernent" and int(a["carriers_out"]) == 0 and int(a["collapsed"]) == 0:
			clean += n
		if int(a["fixed"]) == Kern.THINGS.size() and int(a["carriers_out"]) == 0:
			clean_any += n
		var b := Kern.bilanz(s, Kern.PLAYER)
		if b > best_bilanz:
			best_bilanz = b
			best_end = str(s["end"])
		elif b == best_bilanz and not best_end.contains(str(s["end"])):
			best_end += "/" + str(s["end"])
	return {"finished": finished, "total": total, "by_end": by_end, "clean_wins": clean, "clean_any": clean_any, "best_bilanz": best_bilanz, "best_end": best_end}


func _report(r: Dictionary, examples: bool) -> void:
	print("Wege insgesamt: %d | nach Ende: %s | Dezernent, niemand ausgefallen, nichts eingestürzt: %d | alles saniert, niemand ausgefallen: %d | bestes Aktenergebnis %+d endet: %s" % [r["total"], str(r["by_end"]), r["clean_wins"], r["clean_any"], r["best_bilanz"], r["best_end"]])
	var keys: Array = (r["finished"] as Dictionary).keys()
	keys.sort_custom(func(x: String, y: String) -> bool: return int(r["finished"][x][1]) > int(r["finished"][y][1]))
	for k in keys:
		var e: Array = r["finished"][k]
		print("%7d  %s" % [int(e[1]), k])
		if examples:
			print("         z. B.: %s" % (" ".join(PackedStringArray(e[2])) if not (e[2] as Array).is_empty() else "(nichts tun)"))
