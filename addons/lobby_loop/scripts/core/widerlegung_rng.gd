# PURPOSE: Deterministischer Zufall der Widerlegung, bitgleich zu huhn/engine.js (hashStr, mulberry32, shuffle).
# ARCHITECTURE: core
# DEPENDENCIES: none
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name WiderlegungRng
extends RefCounted

const MASK := 0xFFFFFFFF


## Math.imul als vorzeichenlose 32-Bit-Zahl. In 16-Bit-Hälften gerechnet,
## weil a * b mit 64-Bit-Ganzzahlen überlaufen kann.
static func imul32(a: int, b: int) -> int:
	a &= MASK
	b &= MASK
	var low := (a & 0xFFFF) * b
	var high := (((a >> 16) * b) & 0xFFFF) << 16
	return (low + high) & MASK


## hashStr aus engine.js. Seeds sind ASCII, dann sind unicode_at und charCodeAt gleich.
static func hash_str(s: String) -> int:
	var h := (1779033703 ^ s.length()) & MASK
	for i in s.length():
		h = imul32(h ^ s.unicode_at(i), 3432918353)
		h = ((h << 13) & MASK) | (h >> 19)
	h = imul32(h ^ (h >> 16), 2246822507)
	h = imul32(h ^ (h >> 13), 3266489909)
	h = h ^ (h >> 16)
	return h & MASK


## mulberry32 mit externem Zustand o["rs"], wie rnd(o) in engine.js.
static func rnd(o: Dictionary) -> float:
	o["rs"] = (int(o["rs"]) + 0x6D2B79F5) & MASK
	var t: int = o["rs"]
	t = imul32(t ^ (t >> 15), t | 1)
	t = (t ^ ((t + imul32(t ^ (t >> 7), t | 61)) & MASK)) & MASK
	return float((t ^ (t >> 14)) & MASK) / 4294967296.0


## Fisher-Yates wie shuffle(arr, o) in engine.js. Gibt eine neue Liste zurück.
static func shuffle(arr: Array, o: Dictionary) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := int(floor(rnd(o) * (i + 1)))
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t
	return a
