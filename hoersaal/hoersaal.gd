# PURPOSE: Hörsaal: Widerlegung einzeln spielen, Lehre frei wählbar (Grundbestand und Bibliothek). Ohne Effekte auf die Karriere.
# ARCHITECTURE: ui
# DEPENDENCIES: WiderlegungRules, WiderlegungLibrary, widerlegung_panel.gd, HoersaalStats, MinigameContract
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
extends Control

const PanelScript := preload("res://addons/lobby_loop/scripts/ui/widerlegung_panel.gd")

## Tests setzen eigene Ordner, bevor die Szene in den Baum kommt.
var library_dir := WiderlegungLibrary.DEFAULT_DIR
var stats_path := HoersaalStats.PATH
var _list: VBoxContainer
var _status: Label
var _panel: PanelContainer
var _counter := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.1)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(560, 0)
	center.add_child(column)
	var title := Label.new()
	title.text = "Hörsaal"
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	_list = VBoxContainer.new()
	column.add_child(_list)
	_panel = PanelScript.new()
	_panel.library_dir = library_dir
	add_child(_panel)
	_panel.finished.connect(_on_finished)
	refresh()


## Liste der Lehren: Grundbestand zuerst, dann die geprüften Lehren der Bibliothek.
func lehren() -> Array:
	var data := WiderlegungRules.load_data(library_dir)
	if data.has("error"):
		return []
	var out := []
	for L in data["instanzen"]:
		out.append({"id": str(L["id"]), "begriff": str(L.get("begriff", "?")), "erfunden": bool(L.get("erfunden", false))})
	return out


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var s := HoersaalStats.load_stats(stats_path)
	_status.text = "Wähle eine Lehre. Bisher %d Vorlesungen, %d Lehren eingestürzt." % [s["played"], s["collapsed"]]
	for L in lehren():
		var b := Button.new()
		b.text = "%s%s" % [L["begriff"], "  (erfunden)" if L["erfunden"] else ""]
		b.pressed.connect(start.bind(str(L["id"])))
		_list.add_child(b)


func start(lehre_id: String) -> void:
	_counter += 1
	var seed := MinigameContract.derive_seed("hoersaal#%d" % Time.get_ticks_usec(), "hoersaal", _counter)
	_panel.start({"lehre": lehre_id, "seed": seed})


func panel() -> PanelContainer:
	return _panel


## Ergebnis zählt nur im Hörsaal. Die Effekte (Disziplin, Gegenstände) werden bewusst nicht angewendet.
func _on_finished(result: Dictionary) -> void:
	HoersaalStats.record(result, stats_path)
	_status.text = str(result.get("chronik", ""))
	refresh()
