# PURPOSE: Mertens-Probe: BANK-01 beginnt in einer Welt, in der Mertens nach einer früheren Wahlzeit ausgefallen ist. Ohne Übergabe bleibt alles wie bisher.
# PURPOSE: Abwesenheit gilt über jeden Phasenwechsel, nichts Früheres verschwindet, und der Befund: Alle Wege zu einem Sitzplatz sind zu.
# ARCHITECTURE: test
# DEPENDENCIES: Bank01, AmtWorld, AmtStore, KarriereKern, KarriereLauf, tools/mertens_probe.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-11-16
extends GutTest

const Probe := preload("res://tools/mertens_probe.gd")
const Lauf := preload("res://karriere_kern/lauf.gd")
const GONE := {"mertens": "ausgefallen"}
const SEAT_WAYS: Array = ["Stuhl am Tag (T-06)", "Stuhl am Abend (DAME)", "Ausnahme (T-05)", "Ausnahme über die Reparaturakte", "Formelle Freigabe (T-04)"]

var s: Dictionary


func _do(type: String, params: Dictionary = {}) -> Dictionary:
	var r := AmtWorld.execute(s, Bank01.command(s, type, params), Bank01)
	s = r["state"]
	return r


func _labels() -> String:
	var out := []
	for a in Bank01.available_actions(s):
		out.append(str(a))
	return "\n".join(PackedStringArray(out))


func test_without_handover_the_case_is_exactly_as_before() -> void:
	assert_true(Bank01.new_state() == Bank01.new_state("BANK-01-A", {}), "ohne Übergabe derselbe Anfangszustand")
	assert_true(Bank01.new_state() == Bank01.new_state("BANK-01-A", {"mertens": "im_dienst"}))
	for way in Probe.WAYS:
		var r := Probe.walk({}, Probe.WAYS[way])
		assert_eq(r["refused"], [], "%s: kein Schritt abgelehnt" % way)


func test_only_difference_between_the_two_worlds_is_mertens() -> void:
	var here := Bank01.new_state()
	var gone := Bank01.new_state("BANK-01-A", GONE)
	gone["actors"]["mertens"]["location_id"] = "hausdienst"
	assert_true(here == gone, "sonst sind die Welten gleich")
	assert_true(bool(Bank01.new_state("BANK-01-A", GONE)["objects"]["bench"]["physically_usable"]), "die frühere Reparatur bleibt")


func test_career_decides_which_world_the_case_starts_in() -> void:
	for name in Probe.HISTORIES:
		var run := Lauf.start()
		Lauf.play_term(run, Probe.HISTORIES[name])
		var world := Probe.world_from_career(run["state"])
		assert_eq(str(world["mertens"]), "ausgefallen" if name.begins_with("A") else "im_dienst", name)


func test_absence_holds_through_every_phase_change() -> void:
	s = Bank01.new_state("BANK-01-A", GONE)
	_do("move", {"to": "innenhof"})
	_do("open_case")
	assert_false(Bank01.mertens_present(s))
	_do("end_day")
	assert_eq(str(s["phase"]), "abend")
	assert_false(Bank01.mertens_present(s), "abends nicht am Tisch")
	assert_eq(str(s["actors"]["seidel"]["location_id"]), "hinterzimmer", "Frau Seidel schon")
	assert_false(_labels().contains("Mertens"), "kein Gespräch, keine Partie")
	assert_false(bool(_do("talk", {"actor": "mertens", "topic": "bank"})["ok"]))
	assert_false(bool(_do("start_minigame", {"game": "dame"})["ok"]))
	_do("end_evening")
	assert_eq(str(s["phase"]), "tag2")
	assert_false(Bank01.mertens_present(s), "am zweiten Tag nicht zurück im Hausdienst")
	assert_true(AmtWorld.world_part(AmtWorld.replay(Bank01.new_state("BANK-01-A", GONE), s["events"])) == AmtWorld.world_part(s), "Nachspielen ergibt dieselbe Welt")
	assert_eq(AmtWorld.causality_errors(s), [])


func test_cause_is_visible_on_a_document_and_from_a_person() -> void:
	s = Bank01.new_state("BANK-01-A", GONE)
	assert_string_contains(Bank01.observation_text(s, "hausdienst"), "ausgefallen seit dem vierten Einsatz in der Sporthalle")
	assert_string_contains(Bank01.observation_text(s, "hausdienst"), "Bank Innenhof – erledigt", "sein Zettel hängt noch")
	_do("move", {"to": "innenhof"})
	_do("open_case")
	_do("end_day")
	assert_string_contains(str(Bank01.scene(s)), "Seit Mertens fehlt")


func test_refused_commands_cost_nothing_and_change_nothing() -> void:
	s = Bank01.new_state("BANK-01-A", GONE)
	_do("move", {"to": "innenhof"})
	_do("open_case")
	_do("move", {"to": "hausdienst"})
	for cmd in [["interview", {"actor": "mertens", "topic": "bank"}], ["request_help", {"actor": "mertens"}], ["request_document", {"document_id": "repair_record"}]]:
		var before := s.duplicate(true)
		var r := _do(cmd[0], cmd[1])
		assert_false(bool(r["ok"]), cmd[0])
		assert_true(s == before, "%s: abgelehnt, nichts geändert" % cmd[0])
	assert_string_contains(str(AmtWorld.execute(s, Bank01.command(s, "request_document", {"document_id": "repair_record"}), Bank01)["reason"]), "nicht besetzt")


## Befund: In der Welt mit Mertens führt jeder dieser Wege zu einem Sitzplatz. Ohne ihn keiner.
func test_finding_every_way_to_a_seat_is_closed() -> void:
	for way in SEAT_WAYS:
		var here := Probe.walk({}, Probe.WAYS[way])
		var gone := Probe.walk(GONE, Probe.WAYS[way])
		assert_ne(str(here["seat"]), "", "%s mit Mertens: Frau Kern sitzt" % way)
		assert_eq(str(gone["seat"]), "", "%s ohne Mertens: Frau Kern steht" % way)
		assert_eq(str(gone["bench"]), "blocked")
		assert_false((gone["evidence"] as Array).has("B-01"), "der Reparaturnachweis ist nicht zu bekommen")
		assert_gt((gone["refused"] as Array).size(), 0)
	for way in ["Nur Bericht, Definition gewonnen", "Ohne Antrag abschließen (T-07)"]:
		var gone := Probe.walk(GONE, Probe.WAYS[way])
		assert_eq(gone["refused"], [], "%s geht auch ohne Mertens" % way)
		assert_eq(str(gone["resolution"]), "unresolved")


func test_probe_writes_no_save() -> void:
	var before := FileAccess.file_exists(AmtStore.default_path())
	Probe.walk(GONE, Probe.WAYS["Formelle Freigabe (T-04)"])
	assert_eq(FileAccess.file_exists(AmtStore.default_path()), before)
	assert_eq(Bank01.CONTENT_VERSION, "bank_01@1", "Inhaltsfassung unverändert: vorhandene Spielstände laden weiter")
