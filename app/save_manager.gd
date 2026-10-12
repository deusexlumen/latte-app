# PURPOSE: SaveManager der App: gleiche Schnittstelle wie Lobby-Loops SaveManager, speichert aber über amt_core/JsonStore (atomar, kaputte Datei wird gesichert).
# ARCHITECTURE: autoload
# DEPENDENCIES: JsonStore (amt_core), SaveData, GameState (Lobby-Loop)
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
extends Node

## Lobby-Loop verbindet sich darauf (Perma-Death-Neustart).
signal perma_death_restarted

## Headless heißt Testlauf: nie in den echten Spielstand schreiben (sonst bliebe ein Teststand liegen
## und die Migration würde den alten Lobby-Loop-Stand beim ersten echten Start nicht übernehmen).
const HEADLESS_PATH := "user://test_headless_savegame.json"

## Tests lenken hier auf eine eigene Datei um.
var path := HEADLESS_PATH if DisplayServer.get_name() == "headless" else SaveData.SAVE_PATH


func save_game() -> Error:
	return OK if JsonStore.write_json(path, GameState.get_save_dict()) else ERR_FILE_CANT_WRITE


## Fehlt der Stand: {}. Ist er kaputt: wird er als .bak gesichert, dann {} (Lobby-Loop startet frisch).
func load_game() -> Dictionary:
	return JsonStore.read_json(path)


func has_save() -> bool:
	return FileAccess.file_exists(path)


func autosave() -> Error:
	return save_game()


## Perma-Death: irreversibel mit frischem Start-State überschreiben und Neustart signalisieren.
func perma_death() -> Dictionary:
	var fresh := SaveData.fresh_state()
	JsonStore.write_json(path, fresh)
	perma_death_restarted.emit()
	return fresh
