# PURPOSE: Issue #27: Prüft, ob eine zweite Wahlzeit in der hinterlassenen Welt eine andere Entscheidungssituation bietet als eine frische Welt.
# PURPOSE: Zwei Vorgeschichten (A tüchtig, B sichtbar), je mit Gegenprobe; dazu jede mögliche erste Wahlzeit, aus dem vollen Zustand fortgesetzt.
# ARCHITECTURE: tools
# DEPENDENCIES: KarriereKern, KarriereLauf, KarriereBericht, tools/karriere_kern_sweep.gd
# PIPELINE: untersuchung (docs/karriere-zweite-wahlzeit-2026-11.md)
# LAST_VALIDATED: 2026-11-16
extends SceneTree

# Aufruf: godot --headless --path . --script res://tools/karriere_zweite_wahlzeit.gd

const Kern := preload("res://karriere_kern/kern.gd")
const Lauf := preload("res://karriere_kern/lauf.gd")
const Bericht := preload("res://karriere_kern/bericht.gd")
const Sweep := preload("res://tools/karriere_kern_sweep.gd")

const HISTORIES := {
	"A tüchtig": ["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "5:aushilfe:halle", "5:aushilfe:bruecke"],
	"B sichtbar": ["1:antrag:halle", "2:antrag:halle"],
}
## Dieselbe Absicht in jeder Welt: die Meldung erledigen lassen und die Sanierung beantragen.
const PROBE: Array = ["erledigen", "antrag"]


func _initialize() -> void:
	print("== Zwei Vorgeschichten, je eine zweite Wahlzeit, Gegenprobe frische Welt (Grundeinstellung) ==")
	_contrast({})
	print("\n== Jede mögliche erste Wahlzeit, aus dem vollen Zustand fortgesetzt ==")
	print("(Entscheidungsperiode: eine Periode, in der außer „nachsehen“ überhaupt eine Handlung offensteht)")
	for collapse in [9, 10, 12, 16]:
		_census({"collapse": collapse})
	print("\n== Dieselben zwei Vorgeschichten, wenn Bauwerke eine Wahlzeit überdauern (Einsturzgrenze 16) ==")
	_contrast({"collapse": 16})
	print("ZWEITE_OK")
	quit(0)


## Erste Periode einer Welt: was offensteht, und was auf die Probe-Handlungen geantwortet wird.
static func first_period(s: Dictionary) -> Dictionary:
	var offered: Array = []
	for a in Kern.available(s):
		offered.append("%s:%s" % [str(a["id"]), str(a["thing"])])
	var t: Dictionary = (s as Dictionary).duplicate(true)
	var from := (t["log"] as Array).size()
	var done: Array = []
	for action in PROBE:
		done.append("%s=%s" % [action, "ja" if Kern.act(t, action, "halle") else "nicht möglich"])
	Kern.end_period(t)
	var answers: Array = []
	for i in range(from, (t["log"] as Array).size()):
		var e: Dictionary = t["log"][i]
		if ["reject", "fund", "defer", "done", "open", "carrier_out"].has(str(e["kind"])) and str(e["thing"]) == "halle":
			answers.append(str(e["text"]))
	return {"offered": offered, "done": done, "answers": answers, "sight": Bericht.sight(s), "akte": Bericht.akte(s)}


## Wie viele Perioden einer Wahlzeit bieten bei bloßem Abwarten überhaupt eine Handlung?
static func decision_periods(start: Dictionary) -> int:
	var s: Dictionary = start.duplicate(true)
	var n := 0
	while not bool(s["over"]):
		for a in Kern.available(s):
			if str(a["id"]) != "nachsehen":
				n += 1
				break
		Kern.end_period(s)
		if not bool(s["over"]):
			Kern.begin_period(s)
	return n


func _contrast(overrides: Dictionary) -> void:
	var fresh := Kern.new_game(overrides)
	Kern.begin_period(fresh)
	_show("Frische Welt", fresh)
	for name in HISTORIES:
		var run := Lauf.start(overrides)
		Lauf.play_term(run, HISTORIES[name])
		var first: Dictionary = run["state"]
		print("-- %s: erste Wahlzeit endet: %s" % [name, Kern.outcome(first)])
		Lauf.term(run)
		_show("Zweite Wahlzeit nach %s" % name, run["state"])


func _show(title: String, s: Dictionary) -> void:
	var f := first_period(s)
	print("-- %s, Periode 1 · Entscheidungsperioden bei Abwarten: %d · es liegt etwas vor: %s" % [title, decision_periods(s), Kern.has_matter(s)])
	for line in f["sight"]:
		print("   sieht: ", line)
	print("   Akte: ", f["akte"][0], " | ", f["akte"][1])
	print("   offen stehende Handlungen: ", f["offered"])
	print("   Probe: ", f["done"])
	for line in f["answers"]:
		print("   Antwort: ", line)


func _census(overrides: Dictionary) -> void:
	var first := Sweep.sweep(overrides, true)
	var paths := 0
	var continued := 0
	var kept := 0
	var kept_choice := 0
	var empty := 0
	var with_choice := 0
	var changed_offer := 0
	var second_ends := {}
	var offers := {}
	var fresh := Kern.new_game(overrides)
	Kern.begin_period(fresh)
	var fresh_offer := str(first_period(fresh)["offered"])
	for k in first["finished"]:
		var n := int(first["finished"][k][1])
		paths += n
		var prev: Dictionary = first["finished"][k][0]
		var stays := not ["ausschuss", "liste"].has(str(prev["end"]))
		var next := Kern.next_term(prev)
		continued += n
		Kern.begin_period(next)
		if stays:
			kept += n
		if decision_periods(next) == 0:
			empty += n
			continue
		if stays:
			kept_choice += n
		with_choice += n
		var offer := "%s: %s" % [Kern.RANKS[int(next["rank"][Kern.PLAYER])], str(first_period(next)["offered"])]
		if not offers.has(offer):
			offers[offer] = [0, first["finished"][k][2], next]
		offers[offer][0] = int(offers[offer][0]) + n
		if str(first_period(next)["offered"]) != fresh_offer:
			changed_offer += n
		var second := Sweep.sweep(overrides, false, next)
		for o in second["finished"]:
			second_ends[o] = true
	print("Einsturzgrenze %2d | erste Wahlzeiten %6d (Figur bleibt im Amt: %6d) | zweite Wahlzeit ohne jede Entscheidung %6d (%5.1f %%) | mit Entscheidung %6d (davon Figur im Amt geblieben %6d, neue Figur %d), andere Handlungen als in frischer Welt %6d | verschiedene Enden der zweiten Wahlzeit %d" % [
		int(overrides["collapse"]), paths, kept, empty, 100.0 * float(empty) / float(maxi(continued, 1)), with_choice, kept_choice, with_choice - kept_choice, changed_offer, second_ends.size()])
	if int(overrides["collapse"]) == 16:
		print("   Was in Periode 1 der zweiten Wahlzeit offensteht (frische Welt: %s), nach Häufigkeit:" % fresh_offer)
		var keys: Array = offers.keys()
		keys.sort_custom(func(x: String, y: String) -> bool: return int(offers[x][0]) > int(offers[y][0]))
		for o in keys.slice(0, 8):
			print("   %7d  %s" % [int(offers[o][0]), o])
			print("            Vorgeschichte z. B.: %s" % (" ".join(PackedStringArray(offers[o][1])) if not (offers[o][1] as Array).is_empty() else "(nichts tun)"))
			for line in Bericht.sight(offers[o][2]):
				print("            sieht: %s" % line)
