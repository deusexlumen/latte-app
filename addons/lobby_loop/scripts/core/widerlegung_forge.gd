# PURPOSE: Ablauf einer erfundenen Lehre: Spielleiter fragen, auf dem Gerät prüfen, höchstens einmal nachbessern, Bestandenes in die Bibliothek.
# ARCHITECTURE: core
# DEPENDENCIES: WiderlegungValidator, WiderlegungLibrary, WiderlegungRules
# PIPELINE: runtime, manual
# LAST_VALIDATED: 2026-10-12
class_name WiderlegungForge
extends RefCounted

## Läuft gerade eine Erfindung? Nie zwei gleichzeitig (Free-Tier-Quota, Rechenzeit).
static var busy := false


## `api` braucht lehre_generate(payload) -> Variant (ApiClient oder ein Test-Double) und hängt im Baum.
## Ergebnis: {"ok", "lehre_id", "versuche", "befunde", "pruef_ms", "raw" (letzter Entwurf)}. Nie ein Fehler nach außen:
## Ohne Netz liefert der Proxy null, und gespielt wird weiter aus Bibliothek und Grundbestand.
static func forge(api: Node, thema: String = "", dir: String = WiderlegungLibrary.DEFAULT_DIR) -> Dictionary:
	var out := {"ok": false, "lehre_id": "", "versuche": 0, "befunde": [], "pruef_ms": []}
	if busy:
		out["befunde"] = ["Es läuft schon eine Erfindung."]
		return out
	busy = true
	var base := WiderlegungRules.load_data()
	var payload := {} if thema.is_empty() else {"thema": thema}
	for attempt in 2:
		var raw: Variant = await api.lehre_generate(payload)
		out["versuche"] = attempt + 1
		if not (raw is Dictionary):
			out["befunde"] = ["Spielleiter nicht erreichbar."]
			break
		var t0 := Time.get_ticks_msec()
		var r: Dictionary = await _validate_off_thread(api, base, raw)
		out["pruef_ms"].append(Time.get_ticks_msec() - t0)
		out["befunde"] = r["befunde"]
		out["raw"] = raw
		if r["ok"]:
			out["ok"] = WiderlegungLibrary.save(raw, r, dir)
			out["lehre_id"] = str(raw.get("id", ""))
			break
		# Genau eine Nachbesserung mit dem Befund, danach greift die Bibliothek.
		payload = {"nachbesserung": {"befunde": (r["befunde"] as Array).slice(0, 5), "vorlage": raw}}
	busy = false
	return out


## Die Simulation (bis zu einigen tausend Partien) darf das Spiel nicht einfrieren.
## Web-Export ohne Threads: häppchenweise, ein Messschritt pro Frame (kein mehrsekündiges Einfrieren).
static func _validate_off_thread(api: Node, base: Dictionary, raw: Dictionary) -> Dictionary:
	if not OS.has_feature("threads"):
		var tree := api.get_tree()
		return await WiderlegungValidator.validate_async(base, raw, false, func() -> Signal: return tree.process_frame)
	var thread := Thread.new()
	if thread.start(WiderlegungValidator.validate.bind(base, raw)) != OK:
		return WiderlegungValidator.validate(base, raw)
	while thread.is_alive():
		await api.get_tree().process_frame
	var result: Variant = thread.wait_to_finish()
	return result if result is Dictionary else WiderlegungValidator.validate(base, raw)
