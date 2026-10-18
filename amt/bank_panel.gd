# PURPOSE: Widerlegungs-Panel für den Ausschuss von BANK-01: wie das Panel von Lobby-Loop, aber ohne Einspruch (kein Schreiben in Sperrlisten, Fall bleibt fest)
# PURPOSE: und mit einem Tor, das jede Karte erst vom Vorgang bestätigen lässt. So lässt sich die Partie fortsetzen und das Ergebnis nachprüfen.
# ARCHITECTURE: ui
# DEPENDENCIES: addons/lobby_loop/scripts/ui/widerlegung_panel.gd, BankWiderlegung
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-18
extends "res://addons/lobby_loop/scripts/ui/widerlegung_panel.gd"

## Callable(card_id: String) -> bool. Der Vorgang verbucht den Zug; nur bei true wird die Karte gespielt.
var gate := Callable()
## Beim Fortsetzen werden die gespeicherten Züge ohne Tor nachgespielt.
var replaying := false


func _init() -> void:
	library_dir = BankWiderlegung.LEHRE_DIR


func play_card(card_id: String) -> void:
	if not is_playing():
		return
	if not replaying and gate.is_valid() and not bool(gate.call(card_id)):
		return
	super.play_card(card_id)


## Der Fall ist fest: Karten werden hier nicht gestrichen.
func object_card(_card_id: String) -> bool:
	return false


func _refresh() -> void:
	super._refresh()
	for b in _hand_box.find_children("*", "Button", true, false):
		if (b as Button).text == "!":
			(b as Button).visible = false
			(b as Button).disabled = true
