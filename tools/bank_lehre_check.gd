# PURPOSE: Prüft die Bank-Lehre von BANK-01 mit dem Validator der Widerlegung (Form, Kartenpaare, Simulation) und gibt cap, Würfe und Messung aus.
# PURPOSE: Mit --write schreibt es die vom Validator gesetzten Werte (cap, wuerfe, Referenzen, Messung) in die Lehren-Datei.
# ARCHITECTURE: tools
# DEPENDENCIES: WiderlegungValidator, WiderlegungRules
# PIPELINE: build, test
# LAST_VALIDATED: 2026-10-18
extends SceneTree

# Aufruf: godot --headless --path . --script res://tools/bank_lehre_check.gd -- [Pfad] [--write]
# Ohne Pfad: res://cases/bank_01/lehre/bib_bank_01.json. Ausgabe: BANK_LEHRE_OK oder BANK_LEHRE_FAIL.

const DEFAULT_PATH := "res://cases/bank_01/lehre/bib_bank_01.json"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path := DEFAULT_PATH
	var write := false
	for a in args:
		if a == "--write":
			write = true
		else:
			path = a
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (raw is Dictionary):
		print("BANK_LEHRE_FAIL Datei nicht lesbar: ", path)
		quit(1)
		return
	var base := WiderlegungRules.load_data()
	var result: Dictionary = WiderlegungValidator.validate(base, raw)
	print("befunde: ", result.get("befunde"))
	print("paare: ", result.get("paare"), " cap: ", result.get("cap"), " wuerfe: ", result.get("wuerfe"))
	print("messung: ", result.get("messung"))
	if not bool(result["ok"]):
		print("BANK_LEHRE_FAIL")
		quit(1)
		return
	if write:
		raw["cap"] = int(result["cap"])
		raw["wuerfe"] = int(result["wuerfe"])
		raw["refMembers"] = result["refMembers"]
		raw["refNon"] = result["refNon"]
		raw["pruefung"] = {"messung": result["messung"], "paare": int(result["paare"])}
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(raw, "  ", false) + "\n")
		f.close()
		print("geschrieben: ", path)
	print("BANK_LEHRE_OK")
	quit(0)
