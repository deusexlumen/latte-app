# PURPOSE: Issue #27: zweite Wahlzeit in der hinterlassenen Welt. Was bleibt, was neu beginnt, Nachspielen, Einmalwirkung, keine Dateien,
# PURPOSE: und der Befund: Mit den Regeln des Versuchs bietet die zweite Wahlzeit keine Entscheidung.
# ARCHITECTURE: test
# DEPENDENCIES: KarriereKern, KarriereLauf, tools/karriere_kern_sweep.gd, tools/karriere_zweite_wahlzeit.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-11-16
extends GutTest

const Kern := preload("res://karriere_kern/kern.gd")
const Lauf := preload("res://karriere_kern/lauf.gd")
const Sweep := preload("res://tools/karriere_kern_sweep.gd")
const Zweite := preload("res://tools/karriere_zweite_wahlzeit.gd")

const A: Array = ["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "5:aushilfe:halle", "5:aushilfe:bruecke"]
const B: Array = ["1:antrag:halle", "2:antrag:halle"]


func _two_terms(steps: Array, overrides: Dictionary = {}) -> Dictionary:
	var run := Lauf.start(overrides)
	Lauf.play_term(run, steps)
	assert_true(Lauf.term(run), "nächste Wahlzeit beginnt")
	return run


func test_first_term_is_unchanged() -> void:
	var run := Lauf.start()
	Lauf.play_term(run, A)
	assert_eq(str(run["state"]["end"]), "ausschuss")
	assert_eq(Kern.bilanz(run["state"], Kern.PLAYER), 9)
	assert_eq(int(Sweep.sweep({})["total"]), 14446)


func test_world_persists_and_term_values_restart() -> void:
	var a: Dictionary = _two_terms(A)["state"]
	var b: Dictionary = _two_terms(B)["state"]
	assert_eq(int(a["term"]), 2)
	assert_eq(int(a["period"]), 1)
	assert_eq(Kern.bilanz(a, Kern.PLAYER), 0, "die Bilanz beginnt neu")
	# Was tatsächlich geschehen ist, bleibt, und es unterscheidet sich nach der Vorgeschichte.
	assert_true(bool(a["things"]["halle"]["collapsed"]), "nach A: Die Halle ist ohne die Spielfigur weiter verfallen und eingestürzt")
	assert_true(bool(a["things"]["halle"]["was_out"]), "nach A: Mertens ausgefallen")
	assert_true(bool(b["things"]["halle"]["fixed"]), "nach B: Halle saniert")
	assert_false(bool(b["things"]["halle"]["was_out"]), "nach B: Mertens im Dienst")
	assert_eq(int(b["things"]["halle"]["open"]), 2, "die Akte der Sache bleibt stehen")
	assert_ne(Kern.key(a), Kern.key(b))


func test_people_and_signatures_stay_in_the_record() -> void:
	var a: Dictionary = _two_terms(A)["state"]
	assert_eq(str(a["figure"]), "Nachrückerin (Testannahme)", "neue Figur ist als Testannahme gekennzeichnet")
	assert_eq(int(a["rank"][Kern.PLAYER]), 0)
	assert_eq(int(a["signed"][Kern.PLAYER]["halle"]), 0, "die neue Figur hat nichts gezeichnet")
	var archive: Dictionary = a["archive"]
	assert_eq(archive.size(), 1)
	assert_eq(int(archive[archive.keys()[0]]["halle"]), 5, "die Unterschriften der Vorgängerin bleiben nachprüfbar (drei Meldungen, Aushilfe, deren erste Meldung)")
	assert_true(bool(a["gone"][Kern.RIVAL]), "Brandt hat sein Mandat verloren")
	assert_eq(int(a["signed"][Kern.RIVAL]["bruecke"]), 5, "und ist mit seinen Unterschriften nicht aus der Welt")
	var trace := "\n".join(PackedStringArray(Kern.trace(a, "bruecke")))
	assert_string_contains(trace, "Wahlzeit 1, Periode 7: Die Brücke am Radweg sackt ab", "die Ursache aus der ersten Wahlzeit steht im Rückblick der zweiten")


func test_figure_in_office_continues_with_rank_and_signatures() -> void:
	var run := _two_terms(["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "5:aushilfe:halle", "7:sanieren:halle"])
	var s: Dictionary = run["state"]
	assert_eq(int(s["rank"][Kern.PLAYER]), 2)
	assert_eq(str(s["figure"]), "")
	assert_eq(int(s["signed"][Kern.PLAYER]["halle"]), 5)
	assert_true((s["archive"] as Dictionary).is_empty())


func test_decided_repair_is_carried_out_after_the_election() -> void:
	# Lage am Ende einer Wahlzeit: Sanierung in der letzten Periode beschlossen, noch nicht ausgeführt.
	var prev := Kern.new_game({"collapse": 16})
	Kern.begin_period(prev)
	prev["period"] = Kern.PERIODS
	prev["over"] = true
	prev["end"] = "bleibt"
	prev["things"]["halle"]["due"] = Kern.PERIODS + 1
	var next := Kern.next_term(prev)
	assert_false(bool(next["things"]["halle"]["fixed"]))
	Kern.begin_period(next)
	assert_true(bool(next["things"]["halle"]["fixed"]), "beschlossen vor der Wahl, ausgeführt danach")


func test_same_commands_same_world_and_replay() -> void:
	var one := _two_terms(A)
	var two := _two_terms(A)
	assert_eq(Kern.key(one["state"]), Kern.key(two["state"]), "identische Wiederholung")
	var replayed := Lauf.replay({}, one["commands"])
	assert_eq(Kern.key(replayed["state"]), Kern.key(one["state"]), "Nachspielen der Befehle ergibt dieselbe Welt")
	assert_eq(JSON.stringify(replayed["state"]["log"]), JSON.stringify(one["state"]["log"]), "und dieselbe Geschichte")


func test_command_ids_are_unique_and_a_repeated_command_acts_once() -> void:
	var run := Lauf.start()
	var cmd := {"id": Lauf.next_id(run), "type": "act", "action": "erledigen", "thing": "halle"}
	assert_true(Lauf.apply(run, cmd))
	var after := Kern.key(run["state"])
	assert_false(Lauf.apply(run, cmd), "derselbe Befehl wirkt nicht zweimal")
	assert_eq(Kern.key(run["state"]), after)
	var both := _two_terms(B)
	var seen := {}
	for c in both["commands"]:
		assert_false(seen.has(str(c["id"])), "Kennung doppelt: %s" % str(c["id"]))
		seen[str(c["id"])] = true
	assert_string_contains(str(both["commands"][both["commands"].size() - 1]["id"]), "W1-P9", "der Wechsel der Wahlzeit trägt die Kennung der alten")


func test_experiment_touches_no_save_files() -> void:
	for path in ["res://karriere_kern/kern.gd", "res://karriere_kern/lauf.gd", "res://karriere_kern/bericht.gd"]:
		var source := FileAccess.get_file_as_string(path)
		for word in ["FileAccess", "JsonStore", "AmtStore", "user://", "SaveManager"]:
			assert_false(source.contains(word), "%s greift nicht auf Dateien zu (%s)" % [path, word])
	var before := FileAccess.file_exists(AmtStore.default_path())
	_two_terms(A)
	assert_eq(FileAccess.file_exists(AmtStore.default_path()), before, "der Spielstand des Innenhofs ist unberührt")


## Befund zu Issue #27, Grundeinstellung: Nach jeder möglichen ersten Wahlzeit liegt in der zweiten nichts mehr vor.
func test_finding_second_term_offers_no_decision() -> void:
	var first := Sweep.sweep({}, true)
	var checked := 0
	for k in first["finished"]:
		var next := Kern.next_term(first["finished"][k][0])
		Kern.begin_period(next)
		checked += 1
		assert_false(Kern.has_matter(next), "kein Bauwerk überdauert die Wahlzeit")
		assert_eq(Zweite.decision_periods(next), 0, "keine Periode mit einer Handlung außer Nachsehen")
	assert_gt(checked, 100, "über alle unterscheidbaren Weltzustände am Ende der ersten Wahlzeit")


## Gegenprobe: Dieselbe Absicht trifft auf eine andere Lage, aber nur, weil nichts mehr da ist, worauf sie sich richten könnte.
func test_same_intent_meets_a_different_world_but_no_choice() -> void:
	var fresh := Kern.new_game()
	Kern.begin_period(fresh)
	assert_eq(Zweite.first_period(fresh)["done"], ["erledigen=ja", "antrag=ja"])
	for steps in [A, B]:
		var s: Dictionary = _two_terms(steps)["state"]
		assert_eq(Zweite.first_period(s)["done"], ["erledigen=nicht möglich", "antrag=nicht möglich"])
		assert_eq(Zweite.first_period(s)["offered"], [])
