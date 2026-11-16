# PURPOSE: Versuch „Zwei Bücher“: Regeln des Karriere-Kerns, die drei Grundverläufe, die Spur jeder Folge und die Befunde der vollständigen Auswertung.
# ARCHITECTURE: test
# DEPENDENCIES: KarriereKern, KarriereBericht, tools/karriere_kern_sweep.gd, karriere_kern/versuch.tscn
# PIPELINE: test
# LAST_VALIDATED: 2026-11-16
extends GutTest

const Kern := preload("res://karriere_kern/kern.gd")
const Bericht := preload("res://karriere_kern/bericht.gd")
const Sweep := preload("res://tools/karriere_kern_sweep.gd")


## Spielt Schritte der Form "Periode:Handlung:Sache" und verlangt, dass jeder Schritt möglich ist.
func _play(steps: Array, overrides: Dictionary = {}) -> Dictionary:
	var s := Kern.new_game(overrides)
	Kern.begin_period(s)
	while not bool(s["over"]):
		for step in steps:
			var parts: PackedStringArray = str(step).split(":")
			if int(parts[0]) == int(s["period"]):
				assert_true(Kern.act(s, parts[1], parts[2] if parts.size() > 2 else ""), "Schritt möglich: %s" % step)
		Kern.end_period(s)
		if not bool(s["over"]):
			Kern.begin_period(s)
	return s


func _texts(s: Dictionary, kind: String) -> Array:
	var out: Array = []
	for e in s["log"]:
		if str(e["kind"]) == kind:
			out.append(str(e["text"]))
	return out


func test_same_decisions_give_the_same_world() -> void:
	var steps := ["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "5:aushilfe:halle"]
	assert_eq(Kern.key(_play(steps)), Kern.key(_play(steps)), "kein Zufall im Kern")


func test_erledigen_closes_the_case_in_the_file_and_leaves_the_roof_as_it_is() -> void:
	var s := Kern.new_game()
	Kern.begin_period(s)
	var damage := int(s["things"]["halle"]["damage"])
	assert_true(Kern.act(s, "erledigen", "halle"))
	assert_eq(int(s["things"]["halle"]["done"]), 1)
	assert_eq(int(s["things"]["halle"]["open"]), 0)
	assert_eq(int(s["things"]["halle"]["damage"]), damage, "die Akte ändert sich, das Dach nicht")
	assert_eq(Kern.bilanz(s, Kern.PLAYER), 1)


func test_request_is_rejected_while_the_file_shows_nothing_open() -> void:
	var s := Kern.new_game()
	Kern.begin_period(s)
	Kern.act(s, "erledigen", "halle")
	Kern.act(s, "antrag", "halle")
	Kern.end_period(s)
	var rejects := _texts(s, "reject")
	assert_eq(rejects.size(), 1)
	assert_string_contains(rejects[0], "0 offene Vorgänge, 1 fristgerecht erledigt", "die Ablehnung nennt ihren Grund aus der Akte")
	assert_eq(int(s["things"]["halle"]["due"]), 0)


## Wer die Meldungen liegen lässt und beantragt, bekommt das Dach und verliert den Listenplatz.
func test_visible_path_repairs_the_hall_and_loses_the_list() -> void:
	var s := _play(["2:antrag:halle"])
	assert_true(bool(s["things"]["halle"]["fixed"]), "Halle saniert")
	assert_false(bool(s["things"]["halle"]["was_out"]), "Mertens ist nie eingesprungen")
	assert_eq(str(s["end"]), "liste")
	assert_eq(int(s["rank"][Kern.PLAYER]), 0)
	assert_true(bool(s["things"]["bruecke"]["collapsed"]), "an die Brücke kommt ein Ratsmitglied nicht heran")
	assert_true(bool(s["gone"][Kern.RIVAL]), "Brandt hat dort gezeichnet und war zuständig")


## Wer nichts offen lässt, hat die beste Akte, wird Dezernent und verliert im Ausschuss.
func test_diligent_path_rises_and_falls_on_its_own_signatures() -> void:
	var s := _play(["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "5:aushilfe:halle", "5:aushilfe:bruecke"])
	assert_eq(str(s["end"]), "ausschuss")
	assert_eq(int(s["rank"][Kern.PLAYER]), 2, "als Dezernent")
	assert_true((s["end_reasons"] as Array).has("zuständig als Dezernent"))
	assert_true(Kern.bilanz(s, Kern.PLAYER) >= 8, "mit einer makellosen Bilanz")
	assert_eq(int(Kern.actual(s)["fixed"]), 0, "saniert wurde nichts: Es stand nie etwas offen")
	# Die Niederlage ist aus der Spur erklärbar: Die Aushilfe hielt die Akte sauber, und die Kämmerei lehnte mit genau dieser Akte ab.
	var trace := "\n".join(PackedStringArray(Kern.trace(s, "bruecke")))
	assert_string_contains(trace, "Sie setzen eine Aushilfe ein")
	assert_string_contains(trace, "zurückgestellt. Aktenlage: 0 offene Vorgänge")
	assert_string_contains(trace, "sackt ab")


## Eine andere Entscheidung an derselben Stelle ändert das Ende: Bleibt die Brücke offen sichtbar, wird sie saniert.
func test_one_different_decision_changes_the_outcome() -> void:
	var covered := _play(["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "5:aushilfe:halle", "5:aushilfe:bruecke"])
	var shown := _play(["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "5:aushilfe:halle", "7:sanieren:halle"])
	assert_eq(str(covered["end"]), "ausschuss")
	assert_true(bool(covered["things"]["bruecke"]["collapsed"]))
	assert_eq(str(shown["end"]), "dezernent")
	assert_true(bool(shown["things"]["bruecke"]["fixed"]))
	assert_string_contains("\n".join(PackedStringArray(_texts(shown, "fund"))), "2 offene Vorgänge", "die Kämmerei nennt die offenen Vorgänge als Grund")


func test_report_repairs_and_costs_the_reporter() -> void:
	var s := _play(["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "4:gutachten:bruecke", "5:gutachten:halle"])
	assert_eq(int(Kern.actual(s)["fixed"]), 2, "beides saniert")
	assert_eq(str(s["end"]), "liste", "wer den Mangel in die Akte bringt, trägt ihn in der Bilanz")


func test_every_consequence_names_cause_actor_and_trace() -> void:
	var s := _play(["1:erledigen:halle", "2:erledigen:halle", "3:erledigen:halle", "6:aushilfe:halle"])
	for e in s["log"]:
		assert_ne(str(e["who"]), "", "jeder Eintrag hat einen Urheber")
		assert_ne(str(e["text"]), "")
	for kind in ["checkpoint", "collapse", "removed", "carrier_out"]:
		assert_gt(_texts(s, kind).size(), 0, kind)
	assert_string_contains(_texts(s, "checkpoint")[0], "Bilanz Sie 3, Brandt 3", "die Fraktion nennt die Zahlen, nach denen sie entscheidet")


func test_rank_trades_sight_for_power() -> void:
	var s := Kern.new_game()
	Kern.begin_period(s)
	assert_string_contains("\n".join(PackedStringArray(Bericht.sight(s))), "Fleck an der Decke", "unten sieht man das Dach")
	assert_false(Kern.can(s, "gutachten", "halle"), "und kann nichts entscheiden")
	for i in 3:
		Kern.act(s, "erledigen", "halle")
		Kern.end_period(s)
		Kern.begin_period(s)
	assert_eq(int(s["rank"][Kern.PLAYER]), 1)
	var sight := "\n".join(PackedStringArray(Bericht.sight(s)))
	assert_string_contains(sight, "Sporthalle: Sie waren nicht dort", "oben sieht man die Akte")
	assert_true(Kern.can(s, "gutachten", "halle"))
	assert_true(Kern.can(s, "nachsehen", "halle"), "hingehen kostet eine Diensthandlung")
	Kern.act(s, "nachsehen", "halle")
	assert_string_contains("\n".join(PackedStringArray(Bericht.sight(s))), "Ortstermin, Periode 4")


## Die Befunde aus docs/karriere-versuch-2026-11.md, gegen die vollständige Auswertung geprüft.
func test_findings_of_the_full_enumeration() -> void:
	var r := Sweep.sweep({})
	assert_eq(int(r["total"]), 14446, "Zahl der Verläufe in der Grundeinstellung")
	assert_eq(str(r["best_end"]), "ausschuss", "die beste Akte endet im Ausschuss")
	assert_eq(int(r["clean_any"]), 0, "kein Verlauf, in dem alles saniert ist und niemand ausgefallen")
	assert_gt(int(r["by_end"]["dezernent"]), 0, "die Karriere ist gewinnbar (Vermutung widerlegt)")
	for k in r["finished"]:
		var s: Dictionary = r["finished"][k][0]
		if not bool(s["things"]["halle"]["was_out"]):
			assert_true(["liste", "ausschuss"].has(str(s["end"])), "mit gesundem Hausmeister behält niemand das Mandat: %s" % k)
		if str(s["end"]) == "dezernent":
			assert_eq(int(Kern.actual(s)["carriers_out"]), 2, "jeder Sieg ist bezahlt: %s" % k)


func test_reform_makes_winning_easier_not_rarer() -> void:
	var a := Sweep.sweep({})
	var b := Sweep.sweep({"reform": true})
	var share_a := float(a["by_end"]["dezernent"]) / float(a["total"])
	var share_b := float(b["by_end"]["dezernent"]) / float(b["total"])
	assert_gt(share_b, share_a, "mit Zählweise gewinnt ein größerer Anteil der Verläufe")
	assert_eq(int(b["clean_any"]), 0)


func test_prototype_plays_from_intro_to_both_versions() -> void:
	var scene: Control = load("res://karriere_kern/versuch.tscn").instantiate()
	add_child_autofree(scene)
	assert_true(scene.press("Wahlzeit beginnen"))
	assert_has(scene.button_texts(), "Periode beenden")
	var guard := 0
	while not bool(scene.state["over"]) and guard < 20:
		scene.press("Mertens anrufen")
		scene.press("Periode beenden")
		guard += 1
	assert_true(bool(scene.state["over"]))
	var labels := []
	for l in scene.find_children("*", "Label", true, false):
		labels.append((l as Label).text)
	assert_has(labels, "Amtliche Fassung")
	assert_has(labels, "Tatsächlich")
	assert_true(scene.press("Noch einmal von unten"))
	assert_eq(int(scene.attempt), 2)
	assert_eq(int(scene.state["period"]), 1)
