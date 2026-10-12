# PURPOSE: REST-Client fuer den gm-proxy (4 Endpoints), asynchron, 15s-Timeout, liefert Dictionary oder null.
#   Proxy-URL und Token kommen aus user://gm_proxy.cfg ([gm], Keys url/token), Default localhost:8787 ohne Token.
# ARCHITECTURE: autoload
# DEPENDENCIES: SaveData
# PIPELINE: runtime
# LAST_VALIDATED: 2026-09-18
extends Node

const DEFAULT_URL := "http://localhost:8787"
const CONFIG_PATH := "user://gm_proxy.cfg"
const TOKEN_HEADER := "x-lobby-token"
const REQUEST_TIMEOUT := 15.0
const LEHRE_TIMEOUT := 120.0
const SESSION_FALLBACK := "anonymous"

signal request_failed(endpoint: String)

## Nur für Werkzeuge (tools/lehre/forge_gate.gd): andere Proxy-URL ohne gm_proxy.cfg anzufassen.
var url_override := ""


## POST /gm/action — GM bewertet die Absicht, legt DC fest.
func gm_action(payload: Dictionary) -> Variant:
	return await _post("/gm/action", payload, ["gm_dialogue"])


## POST /gm/result — Action-Request plus "roll"-Block, GM kommentiert Ergebnis.
func gm_result(payload: Dictionary, roll: Dictionary) -> Variant:
	var full := payload.duplicate()
	full["roll"] = roll
	return await _post("/gm/result", full, ["gm_dialogue"])


## POST /minigame/round — liefert Vorwurf + 3 PR-Phrasen.
func minigame_round(payload: Dictionary) -> Variant:
	return await _post("/minigame/round", payload, ["accusation", "phrases"])


## POST /minigame/judge — liefert correct/correct_index/commentary.
func minigame_judge(payload: Dictionary) -> Variant:
	return await _post("/minigame/judge", payload, ["correct", "correct_index"])


## Session-Kennung fuer die GM-Chronik: Savegame-Name ohne Pfad/Endung, sonst "anonymous".
static func session_id() -> String:
	if not SaveData.has_save():
		return SESSION_FALLBACK
	var name := SaveData.SAVE_PATH.get_file().get_basename()
	return name if not name.is_empty() else SESSION_FALLBACK


## Reine Aufloesung der rohen [gm]-Werte: liefert immer {url, token}.
## Leere/ungueltige url faellt auf den Default zurueck, Token bleibt leerer String.
static func resolve_proxy_config(file_values: Dictionary) -> Dictionary:
	var url := DEFAULT_URL
	var raw_url: Variant = file_values.get("url", "")
	if raw_url is String:
		var cleaned_url := (raw_url as String).strip_edges()
		if not cleaned_url.is_empty():
			url = cleaned_url
	var token := ""
	var raw_token: Variant = file_values.get("token", "")
	if raw_token is String:
		token = (raw_token as String).strip_edges()
	return {"url": url, "token": token}


## Liest user://gm_proxy.cfg (Sektion [gm]). Fehlende oder kaputte Datei -> {}.
static func _load_config_values() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return {}
	return {
		"url": cfg.get_value("gm", "url", ""),
		"token": cfg.get_value("gm", "token", ""),
	}


## POST /lehre/generate — erfundene Lehre (Phase 2). Lange Laufzeit: Modell plus Retry.
func lehre_generate(payload: Dictionary) -> Variant:
	return await _post("/lehre/generate", payload, ["id", "cards", "start"], LEHRE_TIMEOUT)


func _post(path: String, payload: Dictionary, required_keys: Array, timeout: float = REQUEST_TIMEOUT) -> Variant:
	var config := resolve_proxy_config(_load_config_values())
	var base_url: String = config["url"] if url_override.is_empty() else url_override
	var http := HTTPRequest.new()
	http.timeout = timeout
	# Auch bei pausiertem Szenenbaum muss die Antwort ankommen.
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	var request_body := payload.duplicate()
	request_body["session_id"] = session_id()
	var headers := ["Content-Type: application/json"]
	var token: String = config["token"]
	if not token.is_empty():
		headers.append("%s: %s" % [TOKEN_HEADER, token])
	var error := http.request(base_url + path, headers, HTTPClient.METHOD_POST, JSON.stringify(request_body))
	if error != OK:
		http.queue_free()
		request_failed.emit(path)
		return null
	var response: Array = await http.request_completed
	http.queue_free()
	var request_result: int = response[0]
	var response_code: int = response[1]
	var body: PackedByteArray = response[3]
	if request_result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		request_failed.emit(path)
		return null
	var parser := JSON.new()
	if parser.parse(body.get_string_from_utf8()) != OK:
		request_failed.emit(path)
		return null
	if not (parser.data is Dictionary):
		request_failed.emit(path)
		return null
	var parsed: Dictionary = parser.data
	for key in required_keys:
		if not parsed.has(key):
			request_failed.emit(path)
			return null
	return parsed
