# PURPOSE: Mertens-Probe: zwei gleiche Ausgangswelten für BANK-01, einziger Unterschied ist, ob Mertens nach einer früheren Wahlzeit im Dienst
# PURPOSE: ist oder ausgefallen. Zeigt je Welt, was offensteht, was jeder Weg kostet und wo er endet. Nur im Speicher.
# ARCHITECTURE: tools
# DEPENDENCIES: Bank01, AmtWorld, KarriereKern, KarriereLauf
# PIPELINE: untersuchung (docs/mertens-probe-2026-11.md)
# LAST_VALIDATED: 2026-11-16
extends SceneTree

# Aufruf: godot --headless --path . --script res://tools/mertens_probe.gd

const Kern := preload("res://karriere_kern/kern.gd")
const Lauf := preload("res://karriere_kern/lauf.gd")

const WORDING := "Sitzgelegenheiten müssen zugänglich sein."
const HISTORIES := {
	"B sichtbar (Mertens im Dienst)": ["1:antrag:halle", "2:antrag:halle"],
	"A tüchtig (Mertens ausgefallen)": ["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "5:aushilfe:halle", "5:aushilfe:bruecke"],
}

## Wege durch den Vorgang als Befehlsfolgen. Jeder Schritt wird versucht; eine Ablehnung wird mit ihrem Grund vermerkt.
const WAYS := {
	"Stuhl am Tag (T-06)": [["move", {"to": "innenhof"}], ["open_case", {}], ["move", {"to": "hausdienst"}],
		["request_help", {"actor": "mertens"}], ["move", {"to": "innenhof"}], ["observe", {}], ["close_case", {}], ["advance", {}]],
	"Stuhl am Abend (DAME)": [["move", {"to": "innenhof"}], ["open_case", {}], ["end_day", {}], ["start_minigame", {"game": "dame"}],
		["DEV", "won"], ["end_evening", {}], ["close_case", {}], ["advance", {}]],
	"Ausnahme (T-05)": [["move", {"to": "innenhof"}], ["open_case", {}], ["move", {"to": "hausdienst"}],
		["interview", {"actor": "mertens", "topic": "bank"}], ["request_document", {"document_id": "bench_inventory"}], ["observe", {}],
		["end_day", {}], ["end_evening", {}],
		["submit", {"antrag": "ausnahme", "findings": ["B-01", "B-02"], "conclusion": "bestand_nicht_abgeglichen", "open_questions": ["kunst"], "wording": ""}], ["advance", {}]],
	"Ausnahme über die Reparaturakte": [["move", {"to": "innenhof"}], ["open_case", {}],
		["request_document", {"document_id": "repair_record"}], ["request_document", {"document_id": "bench_inventory"}], ["observe", {}],
		["end_day", {}], ["end_evening", {}],
		["submit", {"antrag": "ausnahme", "findings": ["B-01", "B-02"], "conclusion": "bestand_nicht_abgeglichen", "open_questions": ["kunst"], "wording": ""}], ["advance", {}]],
	"Formelle Freigabe (T-04)": [["move", {"to": "innenhof"}], ["open_case", {}], ["observe", {}], ["move", {"to": "hausdienst"}],
		["interview", {"actor": "mertens", "topic": "bank"}], ["request_document", {"document_id": "bench_inventory"}],
		["move", {"to": "registratur"}], ["observe", {}], ["compare", {"evidence": ["B-02", "D-01"]}], ["interview", {"actor": "seidel", "topic": "bank"}],
		["end_day", {}], ["end_evening", {}], ["move", {"to": "ausschussraum"}], ["start_minigame", {"game": "widerlegung"}], ["DEV", "won"],
		["submit", {"antrag": "formal", "findings": ["B-01", "B-02", "B-03"], "conclusion": "zweck_gegen_einstufung", "open_questions": ["zustaendigkeit"], "wording": WORDING}], ["advance", {}]],
	"Nur Bericht, Definition gewonnen": [["move", {"to": "innenhof"}], ["open_case", {}],
		["request_document", {"document_id": "bench_inventory"}], ["move", {"to": "registratur"}], ["observe", {}], ["compare", {"evidence": ["B-02", "D-01"]}],
		["end_day", {}], ["end_evening", {}], ["move", {"to": "ausschussraum"}], ["start_minigame", {"game": "widerlegung"}], ["DEV", "won"],
		["submit", {"antrag": "keiner", "findings": ["B-02", "B-03"], "conclusion": "zweck_gegen_einstufung", "open_questions": ["zustaendigkeit"], "wording": ""}], ["advance", {}]],
	"Ohne Antrag abschließen (T-07)": [["move", {"to": "innenhof"}], ["open_case", {}], ["close_case", {}], ["advance", {}]],
}


func _initialize() -> void:
	var results := {}
	for name in HISTORIES:
		var run := Lauf.start()
		Lauf.play_term(run, HISTORIES[name])
		var world := world_from_career(run["state"])
		print("== Vorgeschichte %s -> Lage für BANK-01: %s ==" % [name, str(world)])
		_show_offers(world)
		results[name] = {}
		for way in WAYS:
			var r := walk(world, WAYS[way])
			results[name][way] = r
			print("  %-36s %s" % [way, summary(r)])
			for refusal in r["refused"]:
				print("      abgelehnt: %s" % refusal)
	print("MERTENS_OK")
	quit(0)


## Was aus der Karriere in den Vorgang hinüberreicht. Testannahmen: Der Hausmeister der Sporthalle und Mertens vom Hausdienst
## sind dieselbe Person, und die Wahlzeit liegt vor dem Tag, an dem BANK-01 beginnt.
static func world_from_career(career: Dictionary) -> Dictionary:
	return {"mertens": "ausgefallen" if bool(career["things"]["halle"]["was_out"]) else "im_dienst"}


## Geht einen Weg. Abgelehnte Schritte ändern nichts und werden vermerkt.
static func walk(world: Dictionary, steps: Array) -> Dictionary:
	var s := Bank01.new_state("BANK-01-A", world)
	var refused: Array = []
	for step in steps:
		var type := str(step[0])
		var params: Dictionary = {}
		if type == "DEV":
			if Bank01.running_session(s).is_empty():
				refused.append("kein laufendes Spiel für ein Ergebnis")
				continue
			type = "minigame_result"
			params = {"result": Bank01.dev_result(s, str(step[1]))}
		else:
			params = step[1]
		var r := AmtWorld.execute(s, Bank01.command(s, type, params), Bank01)
		if bool(r["ok"]):
			s = r["state"]
		else:
			refused.append("%s: %s" % [type, str(r["reason"])])
	var c: Dictionary = s["cases"][Bank01.CASE_ID]
	var evidence: Array = (s["evidence"] as Dictionary).keys()
	evidence.sort()
	return {
		"resolution": str(c["resolution"]), "status": str(c["status"]), "refused": refused, "evidence": evidence,
		"seat": str(s["actors"]["kern"]["seat"]), "bench": str(s["objects"]["bench"]["access"]),
		"hours_used": Bank01.HOURS - int(c["hours_remaining"]), "documents": (s["documents"] as Dictionary).keys(), "state": s,
	}


static func summary(r: Dictionary) -> String:
	var seat: String = {"bench": "sitzt auf der Bank", "chair": "sitzt auf dem Klappstuhl"}.get(str(r["seat"]), "steht")
	return "Ende: %-18s Frau Kern %s · Bank: %s · Diensthandlungen: %d · Belege: %s" % [
		str(r["resolution"]) if str(r["resolution"]) != "" else "(offen)", seat, str(r["bench"]), int(r["hours_used"]), ", ".join(PackedStringArray(r["evidence"]))]


func _show_offers(world: Dictionary) -> void:
	var s := Bank01.new_state("BANK-01-A", world)
	for step in [["move", {"to": "innenhof"}], ["open_case", {}], ["move", {"to": "hausdienst"}]]:
		s = AmtWorld.execute(s, Bank01.command(s, step[0], step[1]), Bank01)["state"]
	print("  Im Hausdienst zu sehen: %s" % Bank01.observation_text(s, "hausdienst"))
	print("  Im Hausdienst möglich: %s" % str(_labels(s)))
	s = AmtWorld.execute(s, Bank01.command(s, "end_day", {}), Bank01)["state"]
	print("  Am Abend: %s" % str(Bank01.scene(s).get("text", Bank01.scene(s))).substr(0, 260))
	print("  Am Abend möglich: %s" % str(_labels(s)))


static func _labels(s: Dictionary) -> Array:
	var out: Array = []
	for a in Bank01.available_actions(s):
		if str(a.get("group", a.get("gruppe", ""))) != "gehen" and str(a.get("type", a.get("command", ""))) != "move":
			out.append(str(a.get("label", a.get("text", a))))
	return out
