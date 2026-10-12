# PURPOSE: WiderlegungRng: 32-Bit-Multiplikation, Hash, mulberry32 und Mischen bitgleich zur JS-Engine.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungRng, test/golden/widerlegung.json
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const GOLDEN_PATH := "res://addons/lobby_loop/test/golden/widerlegung.json"

var golden: Dictionary = {}


func before_all() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	if parsed is Dictionary:
		golden = parsed


func test_golden_file_present() -> void:
	assert_false(golden.is_empty(), "test/golden/widerlegung.json fehlt: pnpm run build:widerlegung")


func test_imul32_matches_math_imul() -> void:
	# Werte von Math.imul, als vorzeichenlose 32-Bit-Zahl gelesen.
	assert_eq(WiderlegungRng.imul32(0xFFFFFFFF, 0xFFFFFFFF), 1)
	assert_eq(WiderlegungRng.imul32(2, 0x80000000), 0)
	assert_eq(WiderlegungRng.imul32(0x7FFFFFFF, 0x7FFFFFFF), 1)
	assert_eq(WiderlegungRng.imul32(3, 5), 15)


func test_hash_matches_js() -> void:
	var entries: Array = golden.get("hash", [])
	assert_gt(entries.size(), 0)
	for entry in entries:
		assert_eq(WiderlegungRng.hash_str(str(entry["s"])), int(entry["h"]), "hashStr('%s')" % entry["s"])


func test_rnd_sequence_matches_js() -> void:
	var spec: Dictionary = golden.get("rnd", {})
	var o := {"rs": WiderlegungRng.hash_str(str(spec.get("seed", "")))}
	var values: Array = spec.get("values", [])
	assert_eq(values.size(), 20)
	for i in values.size():
		var got := int(floor(WiderlegungRng.rnd(o) * 4294967296.0))
		assert_eq(got, int(values[i]), "rnd Nr. %d" % i)


func test_shuffle_matches_js() -> void:
	var spec: Dictionary = golden.get("shuffle", {})
	var o := {"rs": WiderlegungRng.hash_str(str(spec.get("seed", "")))}
	var got := WiderlegungRng.shuffle(spec.get("input", []), o)
	assert_eq(got, spec.get("output", []))


func test_shuffle_keeps_input_untouched() -> void:
	var input := ["a", "b", "c"]
	WiderlegungRng.shuffle(input, {"rs": 1})
	assert_eq(input, ["a", "b", "c"])
