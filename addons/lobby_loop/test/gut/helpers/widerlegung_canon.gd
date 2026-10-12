# PURPOSE: Textform von Engine-Ereignissen, exakt wie canonEvent/canonStart/canonResult in tools/export-widerlegung.ts.
# ARCHITECTURE: test
# DEPENDENCIES: none
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends RefCounted

const FIELDS := [
	"type", "card", "verdict", "kind", "gain", "last", "frei", "effect",
	"rhet", "cap", "bonus", "score", "drawn", "id", "dudelsack", "uniform",
]


static func join(arr: Array, sep: String = ",") -> String:
	var parts := PackedStringArray()
	for v in arr:
		parts.append(str(v))
	return sep.join(parts)


static func _lit(l: Dictionary) -> String:
	return ("-" if l["neg"] else "+") + str(l["a"])


static func event(e: Dictionary) -> String:
	var parts := PackedStringArray()
	for k in FIELDS:
		var v: Variant = e.get(k)
		if v == null:
			parts.append("")
		elif v is bool:
			parts.append("1" if v else "0")
		else:
			parts.append(str(v))
	if e.get("lit") != null:
		parts.append(_lit(e["lit"]))
	if e.get("tg") != null:
		var tg: Dictionary = e["tg"]
		parts.append(str(tg["type"]) + ">" + (str(tg["target"]) if tg.get("target") != null else ""))
	if e.get("added") != null:
		var lits := []
		for l in e["added"]:
			lits.append(_lit(l))
		parts.append("add=" + join(lits))
	return "|".join(parts)


static func start(st: Dictionary) -> String:
	var tg_text := ""
	if st.get("telegraph") != null:
		var tg: Dictionary = st["telegraph"]
		tg_text = str(tg["type"]) + ">" + (str(tg["target"]) if tg.get("target") != null else "")
	return join([join(st["hand"]), join(st["deck"]), st["cap"], st["wuerfe"], tg_text], "/")


static func _clause(c: Dictionary) -> String:
	var key: String = str(c["a"]) if c.has("a") else str(c["id"])
	return str(c["t"]) + ":" + key + ("-" if c.get("neg", false) else "") + ("*" if c.get("painted", false) else "")


static func result(r: Dictionary) -> String:
	var clauses := []
	for c in r["lehre"]:
		clauses.append(_clause(c))
	return join([1 if r["collapsed"] else 0, r["at_wurf"], r["score"], r["exceptions"], r["last"], r["cap"], join(clauses)], "|")
