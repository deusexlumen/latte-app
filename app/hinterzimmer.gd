# PURPOSE: Phase 4: DAME als Hinterzimmer der Karriere. Startet Karriere-Partien über Lobby-Loops Minispiel-Vertrag, wertet sie aus,
# PURPOSE: benennt Chips in Gefälligkeiten um und tauscht Gefälligkeiten gegen einen einmaligen Karriere-Vorteil. Online-Partien zählen nie für die Karriere.
# ARCHITECTURE: autoload
# DEPENDENCIES: App (DAME), GameState, SaveManager, MinigameContract, EventApplier (Lobby-Loop), amt_core/i18n.gd
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
extends Node

const GAME := "dame"
const KARRIERE := "res://addons/lobby_loop/scenes/main.tscn"
const DAME_MENU := "res://addons/dame/scenes/main_menu.tscn"
const REWARD_ITEM := "notiz_aus_dem_hinterzimmer"
const FAVOR_ITEM := "eingeforderter_gefallen"
## Preis eines eingeforderten Gefallens (+2 auf einen Wurf, einmal). Ein Sieg gegen die KI bringt 50.
const FAVOR_PRICE := 100
const I18nScript := preload("res://addons/amt_core/i18n.gd")

## Läuft gerade eine Karriere-Partie? Dann wird ihr Ergebnis angewendet und es geht zurück in die Karriere.
var career_match := {}
## Ergebnis angewendet, Rückkehr in die Karriere steht aus (sobald DAME den Tisch verlässt).
var return_pending := false
var last_result := {}


func _ready() -> void:
	MinigameContract.register_external(GAME, start_career_match)
	var app := get_node_or_null("/root/App")
	if app == null:
		return
	app.match_finished.connect(_on_match_finished)
	install_terms(str(app.settings.get_value("language")))
	_welcome(app)


func _process(_delta: float) -> void:
	# DAME kehrt nach der Partie in sein Menü zurück; für Karriere-Partien geht es stattdessen zurück an den Schreibtisch.
	if return_pending:
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path == DAME_MENU:
			return_pending = false
			get_tree().change_scene_to_file(KARRIERE)


## Chips heißen in der App Gefälligkeiten (deutsche Texte; Englisch bleibt wie in DAME).
static func gefaelligkeiten_overrides() -> Dictionary:
	var out := {}
	for k in I18nScript.EN:
		var key := str(k)
		if key.contains("Chips"):
			out[key] = key.replace("Sieg-Chips", "Sieg-Gefälligkeiten").replace("Chips", "Gefälligkeiten")
	return out


static func install_terms(lang: String) -> void:
	I18nScript.de_overrides = gefaelligkeiten_overrides()
	I18nScript.install(lang)


## In der App gehört die Amtsstube von Anfang an dazu (einmalig geschenkt und ausgerüstet); Casino bleibt wählbar.
## Headless (Testlauf) nicht: Ein dabei angelegtes Profil würde die Migration von DAMEs Profil verhindern.
func _welcome(app: Node) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not app.profile.owns("room_amt"):
		app.profile.grant("room_amt")
		app.profile.grant("back_akte")
		app.profile.equip("room_amt")
		app.profile.equip("back_akte")


## Starter für MinigameContract (Lobby-Loop ruft ihn mit {"scene": ...}).
func start_career_match(params: Dictionary) -> void:
	career_match = {"scene": str(params.get("scene", "")), "started_at": Time.get_datetime_string_from_system()}
	var app := get_node("/root/App")
	var name := str(app.settings.get_value("player_name"))
	app.new_match({
		"seat_count": 4,
		"ai_seats": [1, 2, 3],
		"difficulties": {1: "medium", 2: "medium", 3: "medium"},
		"names": [name if not name.is_empty() else "Sie", "Fraktionsvorsitzende", "Kämmerer", "Pressesprecherin"],
	})


## DAME-Ergebnis -> Vertrags-Ergebnis (wie die Widerlegung). Nur erlaubte Effekte: Disziplin und Gegenstände.
static func career_result(match_result: Dictionary) -> Dictionary:
	var won := bool(match_result.get("won", false))
	var score := int(match_result.get("score", 0))
	var effects: Array = []
	var chronik: String
	if won:
		effects.append({"type": EventApplier.TYPE_MODIFY_STAT, "stat": "discipline", "delta": 1})
		effects.append({"type": EventApplier.TYPE_ADD_ITEM, "item": REWARD_ITEM})
		chronik = "Partie Dame im Hinterzimmer gewonnen (%d Strafpunkte)" % score
	else:
		effects.append({"type": EventApplier.TYPE_MODIFY_STAT, "stat": "discipline", "delta": -1})
		chronik = "Partie Dame im Hinterzimmer verloren (%d Strafpunkte)" % score
	return {"game": GAME, "won": won, "score": score, "effects": effects, "chronik": chronik}


## Online-Partien zählen nur in DAMEs Statistik, nie in einer Karriere. Auch freie Partien im Hinterzimmer nicht.
func _on_match_finished(match_result: Dictionary) -> void:
	if career_match.is_empty() or bool(match_result.get("online", false)):
		return
	career_match = {}
	last_result = career_result(match_result)
	GameState.apply_minigame_result(last_result)
	SaveManager.autosave()
	return_pending = true


## Gefälligkeiten gegen einen einmaligen Vorteil tauschen. Nur erspielt, nie gekauft (DAME hat keinen Echtgeld-Weg).
func can_claim_favor() -> bool:
	var app := get_node_or_null("/root/App")
	return app != null and app.profile.chips() >= FAVOR_PRICE and not GameState.inventory.has(FAVOR_ITEM)


func claim_favor() -> bool:
	if not can_claim_favor():
		return false
	get_node("/root/App").profile.spend(FAVOR_PRICE)
	GameState.add_item(FAVOR_ITEM)
	SaveManager.autosave()
	return true
