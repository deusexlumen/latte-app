# PURPOSE: WiderlegungSim: Balance-Bänder der fünf Lehren (Gelegenheit trägt, Zufall nicht), deterministisch.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungSim, WiderlegungRules
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const N := 150
## Zufall trägt nicht. Ausnahme: Akademie ist die Tutorial-Lehre; die JS-Simulation misst dort selbst 50 %.
const RANDOM_MAX := {"akademie": 0.60}
const RANDOM_MAX_DEFAULT := 0.42

var data: Dictionary = {}


func before_all() -> void:
	data = WiderlegungRules.load_data()


func test_bands_per_lehre() -> void:
	for idx in (data["instanzen"] as Array).size():
		var lehre_id: String = data["instanzen"][idx]["id"]
		var gel := WiderlegungSim.simulate(data, idx, "gelegenheit", N)
		var zuf := WiderlegungSim.simulate(data, idx, "zufall", N)
		gut.p("%s: Gelegenheit %.0f %%, Zufall %.0f %%, Ausnahme in %.0f %%" % [lehre_id, gel["einsturz"] * 100, zuf["einsturz"] * 100, gel["ausnahme_quote"] * 100])
		assert_between(float(gel["einsturz"]), 0.55, 0.97, "Gelegenheit trägt in %s" % lehre_id)
		assert_lt(float(zuf["einsturz"]), float(RANDOM_MAX.get(lehre_id, RANDOM_MAX_DEFAULT)), "Zufall trägt nicht in %s" % lehre_id)


func test_gierig_not_worse_than_gelegenheit_akademie() -> void:
	var gel := WiderlegungSim.simulate(data, 0, "gelegenheit", N)
	var gier := WiderlegungSim.simulate(data, 0, "gierig", N)
	assert_true(float(gier["einsturz"]) >= float(gel["einsturz"]) - 0.10)


func test_simulation_is_deterministic() -> void:
	assert_eq(WiderlegungSim.simulate(data, 1, "zufall", 30), WiderlegungSim.simulate(data, 1, "zufall", 30))
