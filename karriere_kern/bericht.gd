# PURPOSE: Versuch „Zwei Bücher“: was der Spieler sieht (vor Ort, in der Akte) und die beiden Fassungen am Ende. Reine Textaufbereitung.
# ARCHITECTURE: karriere_kern
# DEPENDENCIES: KarriereKern
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-11-16
class_name KarriereBericht
extends RefCounted

const Kern := preload("res://karriere_kern/kern.gd")

const ACTION_LABELS := {
	"erledigen": "Mertens anrufen, Meldung erledigen: %s",
	"antrag": "Sanierung beantragen: %s",
	"aushilfe": "Aushilfe einsetzen: %s",
	"gutachten": "Gutachten beauftragen: %s",
	"sanieren": "Sanierung anordnen: %s",
	"nachsehen": "Hingehen und nachsehen: %s",
	"zaehlweise": "Registratur: Wiederholungen je Sache ausweisen lassen",
}


static func action_label(a: Dictionary) -> String:
	var text := str(ACTION_LABELS.get(str(a["id"]), str(a["id"])))
	if text.contains("%s"):
		text = text % Kern.NAMES.get(str(a["thing"]), "")
	return "%s  (%d)" % [text, int(a["cost"])]


## Was der Spieler mit eigenen Augen sieht. Mit dem Rang wechselt der Ort: unten die Halle, oben der Schreibtisch.
static func sight(s: Dictionary) -> Array:
	var out: Array = []
	var rank := int(s["rank"][Kern.PLAYER])
	if rank == 0:
		out.append("Sie stehen in Ihrem Bezirk.")
	else:
		out.append("Sie sitzen im Rathaus. Was draußen ist, erfahren Sie aus der Akte, oder Sie gehen hin.")
	for id in Kern.THINGS:
		var t: Dictionary = s["things"][id]
		var name := str(Kern.NAMES[id])
		if rank == 0 and str(t["keeper"]) == Kern.PLAYER:
			if bool(t["fixed"]):
				out.append("%s: Das Dach ist neu. Es ist trocken." % name)
			elif bool(t["collapsed"]):
				out.append("%s: geschlossen. Bauzaun." % name)
			else:
				out.append("%s: %s." % [name, Kern.cap(Kern.damage_text(id, int(t["damage"])))])
				out.append(_carrier_line(s, id, int(t["load"]), bool(t["out"])))
		elif s["seen"].has(id):
			var seen: Dictionary = s["seen"][id]
			if not bool(seen["live"]):
				out.append("%s (Ortstermin, Periode %d): Hier ist nichts mehr zu melden." % [name, int(seen["period"])])
			else:
				out.append("%s (Ortstermin, Periode %d): %s. %s" % [name, int(seen["period"]), Kern.cap(Kern.damage_text(id, int(seen["damage"]))),
					_carrier_line(s, id, int(seen["load"]), bool(seen["out"]))])
		else:
			out.append("%s: Sie waren nicht dort." % name)
	return out


static func _carrier_line(s: Dictionary, id: String, load: int, is_out: bool) -> String:
	var limit := int(s["params"]["carrier_max"])
	var who := Kern.cap(str(Kern.CARRIERS[id]))
	if bool(s["things"][id]["aushilfe"]):
		return "%s: fällt aus. %s" % [who, "Der Vertrag der Aushilfe ist ausgelaufen." if is_out else "Eine Aushilfe erledigt die Meldungen."]
	if is_out:
		return "%s: fällt aus. Niemand erledigt die Meldungen nebenher." % who
	if load >= limit - 1 and load > 0:
		return "%s: sichtlich am Ende. Kommt trotzdem, wenn man ruft." % who
	if load > 0:
		return "%s: hat die Meldungen bisher %d-mal nebenher erledigt." % [who, load]
	return "%s: macht den regulären Dienst." % who


## Eine Zeile des Eingangs so, wie sie den Spieler erreicht. Die Meldung mit ihrer Beschreibung liest, wer die Sache betreut;
## alle anderen erfahren nur, dass etwas eingegangen ist.
static func post_line(s: Dictionary, e: Dictionary) -> String:
	if str(e["kind"]) != "case":
		return str(e["text"])
	var keeper := str(s["things"][str(e["thing"])]["keeper"])
	if keeper == Kern.PLAYER:
		return str(e["text"])
	return "Meldung eingegangen: %s. Sie geht an %s." % [Kern.NAMES[str(e["thing"])], Kern.NAMES[keeper]]


## Die Aktenlage: das Einzige, wonach Kämmerei, Fraktion und Ausschuss entscheiden.
static func akte(s: Dictionary) -> Array:
	var out: Array = []
	for id in Kern.THINGS:
		var t: Dictionary = s["things"][id]
		var line := "%s: %d erledigt, %d offen" % [Kern.NAMES[id], int(t["done"]), int(t["open"])]
		if bool(s["counting"]):
			line += ", %d Wiederholungen derselben Meldung" % int(t["done"])
		if str(t["report"]) != "":
			line += ", Gutachten liegt vor"
		if bool(t["fixed"]):
			line += ", saniert"
		elif int(t["due"]) > 0:
			line += ", Sanierung beschlossen"
		elif bool(t["collapsed"]):
			line += ", Schadensfall"
		out.append(line)
	var brandt := "ausgeschieden" if bool(s["gone"][Kern.RIVAL]) else "%+d (%s)" % [Kern.bilanz(s, Kern.RIVAL), Kern.RANKS[int(s["rank"][Kern.RIVAL])]]
	out.append("Bilanz: Sie %+d (%s) · Brandt %s" % [Kern.bilanz(s, Kern.PLAYER), Kern.RANKS[int(s["rank"][Kern.PLAYER])], brandt])
	var next := 0
	for c in Kern.CHECKPOINTS:
		if int(c) >= int(s["period"]) and next == 0:
			next = int(c)
	if next > 0:
		out.append("Die Fraktion entscheidet nach Periode %d: Wer die bessere Bilanz hat, rückt auf. Erledigtes zählt einfach, Offenes doppelt dagegen." % next)
	else:
		out.append("Nach Periode %d stellt die Fraktion die Liste auf. Wer im Minus steht, steht nicht darauf." % Kern.PERIODS)
	return out


## Amtliche Fassung der Wahlzeit: das, was in der Akte steht.
static func official(s: Dictionary) -> Array:
	var out: Array = []
	var done := 0
	var open := 0
	for id in Kern.THINGS:
		done += int(s["ledger"][Kern.PLAYER][id]["done"])
		open += int(s["ledger"][Kern.PLAYER][id]["open"])
	out.append("Vorgänge unter Ihrem Namen: %d fristgerecht erledigt, %d offen." % [done, open])
	out.append("Bilanz: %+d. Zuletzt: %s." % [Kern.bilanz(s, Kern.PLAYER), Kern.RANKS[int(s["rank"][Kern.PLAYER])]])
	match str(s["end"]):
		"ausschuss":
			out.append("Mandat verloren im Untersuchungsausschuss: %s." % ", ".join(PackedStringArray(s["end_reasons"])))
		"liste":
			out.append("Mandat verloren: nicht wieder aufgestellt.")
		"bleibt":
			out.append("Wieder aufgestellt.")
		"dezernent":
			out.append("Dezernent. Im Amt bestätigt.")
	return out


## Was tatsächlich ist: Bauwerke und Menschen, unabhängig von jeder Akte.
static func actual(s: Dictionary) -> Array:
	var out: Array = []
	for id in Kern.THINGS:
		var t: Dictionary = s["things"][id]
		var name := str(Kern.NAMES[id])
		if bool(t["fixed"]):
			out.append("%s: saniert, in Benutzung." % name)
		elif bool(t["collapsed"]):
			out.append("%s: eingestürzt, gesperrt." % name)
		else:
			out.append("%s: %s. Niemand hat saniert." % [name, Kern.damage_text(id, int(t["damage"]))])
		if bool(t["was_out"]):
			out.append("%s: ausgefallen.%s" % [Kern.cap(str(Kern.CARRIERS[id])), " Danach eine Aushilfe." if bool(t["aushilfe"]) else ""])
		else:
			out.append("%s: im Dienst." % Kern.cap(str(Kern.CARRIERS[id])))
	if bool(s["gone"][Kern.RIVAL]):
		out.append("Ratsherr Brandt: Mandat verloren.")
	return out
