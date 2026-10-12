# PURPOSE: Minispiel-Vertrag: welches Spiel, welche Parameter, welcher Seed, welche Effekte zurück; gilt für alle Minispiele.
# ARCHITECTURE: core
# DEPENDENCIES: EventApplier, WiderlegungRng
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name MinigameContract
extends RefCounted

const GAME_BELEIDIGUNGSFECHTEN := "beleidigungsfechten"
const GAME_WIDERLEGUNG := "widerlegung"
const GAMES: Array = [GAME_BELEIDIGUNGSFECHTEN, GAME_WIDERLEGUNG]

## Andockpunkt für Minispiele einer einbettenden App (latte-app: "dame"). Name -> Callable(params: Dictionary).
## Das Ergebnis kommt nach dem Vertrag über GameState.apply_minigame_result zurück.
## Ohne Gastgeber ist ein solches Spiel unbekannt: das Ereignis ist ungültig und nichts startet.
static var external_games: Dictionary = {}


static func register_external(game: String, starter: Callable) -> void:
	external_games[game] = starter


static func unregister_external(game: String) -> void:
	external_games.erase(game)


## Bekannt sind die eigenen Spiele und die eines Gastgebers.
static func is_known(game: String) -> bool:
	return GAMES.has(game) or external_games.has(game)

const LEHREN: Array = ["akademie", "amt", "erfurt", "division7b", "spiel"]
const DEFAULT_LEHRE := "amt"
const LEHRE_BIBLIOTHEK := "bibliothek"
const SCENE_DEFAULT_LEHRE := {"untersuchungsausschuss": "amt", "fraktionssitzung": "spiel"}

## Ein Minispiel-Ergebnis darf nur Items geben und Werte ändern: kein Szenenwechsel, kein Minispiel im Minispiel.
const ALLOWED_EFFECTS: Array = [EventApplier.TYPE_ADD_ITEM, EventApplier.TYPE_MODIFY_STAT]
const REWARD_ITEM := "weggefallener_paragraph"
const BONUS_ITEM := "gerupftes_huhn"
const BONUS_MIN_EXCEPTIONS := 2


## Fehlt "game", ist das Beleidigungsfechten gemeint (abwärtskompatibel).
static func game_of(event: Dictionary) -> String:
	var game := str(event.get("game", ""))
	return GAME_BELEIDIGUNGSFECHTEN if game.is_empty() else game


## Lehre prüfen (unbekannt -> Szenen-Standard -> "amt"). Der Seed kommt immer vom Client.
## Mit Bibliothek (Phase 2): "bibliothek" wählt immer eine geprüfte erfundene Lehre, sonst
## ersetzt jede zweite Widerlegung (nach Seed) die angefragte Lehre durch eine aus der Bibliothek.
## So ist die Bibliothek auch offline erreichbar. Ohne Bibliothek gilt der Grundbestand.
static func widerlegung_params(raw: Dictionary, scene_id: String, az: String, library_ids: Array = []) -> Dictionary:
	var lehre := str(raw.get("lehre", ""))
	var h := WiderlegungRng.hash_str(az)
	if not library_ids.is_empty() and (lehre == LEHRE_BIBLIOTHEK or h % 2 == 1):
		return {"lehre": str(library_ids[(h >> 1) % library_ids.size()]), "seed": az}
	if not LEHREN.has(lehre):
		lehre = str(SCENE_DEFAULT_LEHRE.get(scene_id, DEFAULT_LEHRE))
	return {"lehre": lehre, "seed": az}


## Aktenzeichen aus Karriere, Szene und laufender Nummer: reproduzierbar, nie vom Sprachmodell.
static func derive_seed(material: String, scene_id: String, counter: int) -> String:
	return "LL-%08X" % WiderlegungRng.hash_str("%s#%s#%d" % [material, scene_id, counter])


static func sanitize_effects(effects: Variant) -> Array:
	var out := []
	if not (effects is Array):
		return out
	for e in effects:
		if e is Dictionary and ALLOWED_EFFECTS.has(str(e.get("type", ""))) and EventApplier.is_valid(e):
			out.append(e)
	return out


## Ergebnis einer Instanz (WiderlegungRules-Result) -> Vertrags-Ergebnis.
static func widerlegung_result(lehre: Dictionary, instanz_result: Dictionary) -> Dictionary:
	var won := bool(instanz_result.get("collapsed", false))
	var at_wurf := int(instanz_result.get("at_wurf", 0))
	var exceptions := int(instanz_result.get("exceptions", 0))
	var begriff := str(lehre.get("begriff", "?"))
	var effects: Array = []
	var chronik: String
	if won:
		effects.append({"type": EventApplier.TYPE_MODIFY_STAT, "stat": "discipline", "delta": 1})
		effects.append({"type": EventApplier.TYPE_ADD_ITEM, "item": REWARD_ITEM})
		if exceptions >= BONUS_MIN_EXCEPTIONS:
			effects.append({"type": EventApplier.TYPE_ADD_ITEM, "item": BONUS_ITEM})
		chronik = "Definition '%s' bei Wurf %d eingestürzt, %d Ausnahmen" % [begriff, at_wurf, exceptions]
	else:
		effects.append({"type": EventApplier.TYPE_MODIFY_STAT, "stat": "discipline", "delta": -1})
		chronik = "Definition '%s' hielt nach %d Würfen, %d Ausnahmen" % [begriff, at_wurf, exceptions]
	return {
		"game": GAME_WIDERLEGUNG,
		"won": won,
		"score": int(instanz_result.get("score", 0)),
		"effects": effects,
		"chronik": chronik,
		"lehre": str(lehre.get("id", "")),
	}


## Offline-Start: Hat der Spielleiter kein trigger_event geliefert, startet ein erfolgreicher Wurf
## an einem Knoten mit Feld "minigame" dieses Minispiel. So ist es ohne Netz erreichbar.
static func fallback_trigger(node_data: Dictionary, success: bool, trigger: Variant) -> Variant:
	if trigger != null or not success:
		return trigger
	var mg: Variant = node_data.get("minigame")
	if not (mg is Dictionary):
		return null
	var event := {"type": EventApplier.TYPE_START_MINIGAME, "game": str(mg.get("game", ""))}
	if mg.get("params") is Dictionary:
		event["params"] = (mg["params"] as Dictionary).duplicate()
	return event if EventApplier.is_valid(event) else null


## Erst in die Akte, dann die Effekte. Ein Effekt kann den Perma-Death auslösen,
## und die Akte muss das Ergebnis dann schon enthalten.
static func apply_result(result: Dictionary, state: Object) -> void:
	state.record_minigame(result)
	for effect in sanitize_effects(result.get("effects", [])):
		state.apply_trigger_event(effect)
