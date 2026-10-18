# PURPOSE: Weltkern (Kap. 15.3, 16, 17): ein Änderungspfad (Nachspielen der Ereignisse ergibt denselben Zustand), Herkunft ohne Zyklen,
# PURPOSE: atomare Ablehnung, Befehlsform, Speichern mit Rückfall auf den vorherigen Stand und Meldung unbekannter Fassungen.
# ARCHITECTURE: test
# DEPENDENCIES: AmtWorld, AmtTransaction, AmtStore, Bank01
# PIPELINE: test
# LAST_VALIDATED: 2026-10-18
extends GutTest

const SAVE := "user://test_world_core.json"


func before_each() -> void:
	for p in [SAVE, AmtStore.prev_path(SAVE), SAVE + ".alt", SAVE + ".bak"]:
		JsonStore.remove(p)


func _play(steps: Array) -> Dictionary:
	var s := Bank01.new_state()
	for step in steps:
		var r := AmtWorld.execute(s, Bank01.command(s, step[0], step[1] if step.size() > 1 else {}), Bank01)
		assert_true(r["ok"], "%s: %s" % [step[0], r["reason"]])
		s = r["state"]
	return s


func _sample() -> Dictionary:
	return _play([
		["move", {"to": "innenhof"}], ["open_case"], ["observe"], ["request_document", {"document_id": "bench_inventory"}],
		["move", {"to": "registratur"}], ["observe"], ["compare", {"evidence": ["B-02", "D-01"]}],
		["move", {"to": "hausdienst"}], ["interview", {"actor": "mertens", "topic": "bank"}], ["request_help", {"actor": "mertens"}],
		["end_day"], ["end_evening"],
		["submit", {"antrag": "ausnahme", "findings": ["B-01", "B-02"], "conclusion": "bestand_nicht_abgeglichen", "open_questions": ["kunst"]}],
		["advance"],
	])


func test_replaying_event_ops_reproduces_the_world() -> void:
	var s := _sample()
	var replayed := AmtWorld.replay(Bank01.new_state(), s["events"])
	assert_true(AmtWorld.world_part(replayed) == AmtWorld.world_part(s), "jede Änderung steht in einem Ereignis")


func test_causes_point_backwards_only() -> void:
	var s := _sample()
	assert_eq(AmtWorld.causality_errors(s), [])
	var broken := s.duplicate(true)
	broken["events"][3]["caused_by"] = [broken["events"][10]["event_id"]]
	assert_eq(AmtWorld.causality_errors(broken).size(), 1, "Verweis auf ein späteres Ereignis fällt auf")


func test_events_are_stamped() -> void:
	var s := _sample()
	var ids := {}
	for ev in s["events"]:
		for key in ["event_id", "transaction_id", "type", "actor_id", "case_id", "turn", "caused_by", "payload"]:
			assert_true(ev.has(key), "%s hat %s" % [ev["event_id"], key])
		assert_false(ids.has(ev["event_id"]), "eindeutige Kennung")
		ids[ev["event_id"]] = true
	assert_eq(int(s["event_counter"]), ids.size())


func test_rejected_command_changes_nothing() -> void:
	var s := Bank01.new_state()
	var before := s.duplicate(true)
	var r := AmtWorld.execute(s, Bank01.command(s, "observe"), Bank01)
	assert_false(r["ok"])
	assert_eq(r["events"], [])
	assert_true(s == before, "Eingabe unverändert")
	assert_true(r["state"] == before)


func test_failure_after_events_rolls_back() -> void:
	# Ein Fall, der erst Ereignisse erzeugt und dann scheitert: nichts davon darf bleiben.
	var s := Bank01.new_state()
	var tx := AmtTransaction.new(s.duplicate(true), Bank01.command(s, "probe"))
	tx.emit("probe", "", {}, [AmtWorld.op_set(["location"], "innenhof")])
	tx.fail("abgelehnt")
	assert_eq(tx.state["location"], "innenhof", "Arbeitskopie geändert")
	assert_eq(s["location"], "vorhalle", "Original unberührt")


func test_malformed_commands() -> void:
	var s := Bank01.new_state()
	var good := Bank01.command(s, "move", {"to": "innenhof"})
	var variants := {
		"schema_version": 2, "command_id": "", "type": "", "case_id": "BANK-99", "params": "x",
	}
	for key in variants:
		var cmd := good.duplicate(true)
		cmd[key] = variants[key]
		assert_false(AmtWorld.execute(s, cmd, Bank01)["ok"], key)
	assert_false(AmtWorld.execute(s, "move", Bank01)["ok"])
	assert_false(AmtWorld.execute(s, Bank01.command(s, "fliegen"), Bank01)["ok"])


func test_store_roundtrip_and_previous_state() -> void:
	var a := _play([["move", {"to": "innenhof"}], ["open_case"]])
	var b := _play([["move", {"to": "innenhof"}], ["open_case"], ["observe"]])
	assert_true(AmtStore.save(a, SAVE))
	assert_true(AmtStore.save(b, SAVE))
	assert_true(FileAccess.file_exists(AmtStore.prev_path(SAVE)))
	var loaded := AmtStore.load_state(SAVE, Bank01.CONTENT_VERSION)
	assert_eq(loaded["error"], "")
	assert_true(loaded["state"] == b)
	# Hauptstand beschädigt: Der vorherige Stand wird angeboten, mit Meldung.
	JsonStore.write_text(SAVE, "{kaputt")
	loaded = AmtStore.load_state(SAVE, Bank01.CONTENT_VERSION)
	assert_true(loaded["from_prev"])
	assert_ne(loaded["error"], "")
	assert_true(loaded["state"] == a)


func test_unknown_content_version_is_reported_not_overwritten() -> void:
	var s := Bank01.new_state()
	s["content_version"] = "bank_01@0"
	JsonStore.write_json(SAVE, s)
	var loaded := AmtStore.load_state(SAVE, Bank01.CONTENT_VERSION)
	assert_string_contains(loaded["error"], "anderen Fassung")
	assert_true(loaded["state"].is_empty())
	assert_true(FileAccess.file_exists(SAVE), "Datei bleibt liegen")
	var moved := AmtStore.archive(SAVE)
	assert_eq(moved, SAVE + ".alt")
	assert_false(FileAccess.file_exists(SAVE))
	assert_true(FileAccess.file_exists(moved), "beiseitegelegt, nicht gelöscht")


func test_missing_save_is_not_an_error() -> void:
	var loaded := AmtStore.load_state(SAVE, Bank01.CONTENT_VERSION)
	assert_eq(loaded["error"], "")
	assert_true(loaded["state"].is_empty())


func test_normalize_turns_json_floats_back_into_ints() -> void:
	assert_eq(typeof(AmtStore.normalize(3.0)), TYPE_INT)
	assert_eq(typeof(AmtStore.normalize(2.5)), TYPE_FLOAT)
	var nested: Dictionary = AmtStore.normalize({"a": [1.0, {"b": 4.0}]})
	assert_eq(typeof(nested["a"][1]["b"]), TYPE_INT)
