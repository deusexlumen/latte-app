# PURPOSE: Übersetzung der App-Hülle (Flur, Hörsaal, Hinterzimmer, Akte-Rahmen). Deutscher Text ist der Schlüssel, wie in DAMEs i18n.gd.
# PURPOSE: Die Sprache kommt von DAME (Einstellungen, gilt app-weit). Fehlt ein Eintrag, bleibt der deutsche Text stehen.
# ARCHITECTURE: service
# DEPENDENCIES: amt_core/i18n.gd
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-19
extends RefCounted

const I18nScript := preload("res://addons/amt_core/i18n.gd")

## Nur die Hülle der App. Falltexte (cases/) und Lobby-Loop-Inhalte folgen nach dem Spieltest.
const EN := {
	# Flur
	"Flur des Amts": "The Office Corridor",
	"Vier Türen. Hinter jeder liegt eine Akte, die nicht fertig wird.": "Four doors. Behind each lies a file that never gets finished.",
	"Karriere": "Career",
	"Lobby-Loop: Kommunalpolitik bis Untersuchungsausschuss.": "Lobby-Loop: from local politics to the parliamentary inquiry.",
	"Hörsaal": "Lecture Hall",
	"Widerlegung einzeln, Lehre frei wählbar. Zählt nicht für die Karriere.": "Refutation on its own, any doctrine you like. Does not count for the career.",
	"Hinterzimmer": "Back Room",
	"Feierabend. DAME unter Kollegen.": "After hours. DAME among colleagues.",
	"Innenhof": "Courtyard",
	"Vorgang BANK-01: Die gesperrte Bank. Prototyp.": "Case BANK-01: The Blocked Bank. Prototype. (German only for now)",
	"Akte": "File",
	"Einstellungen": "Settings",
	"Übernommen aus den Einzel-Apps: %s": "Imported from the stand-alone apps: %s",
	# Zum-Flur-Knopf
	"Zum Flur": "To the corridor",
	"Zurück in den Flur des Amts (Esc). Der Spielstand bleibt erhalten.": "Back to the office corridor (Esc). Your progress is kept.",
	# Hörsaal
	"Wähle eine Lehre. Bisher %d Vorlesungen, %d Lehren eingestürzt.": "Pick a doctrine. So far %d lectures, %d doctrines collapsed.",
	"  (erfunden)": "  (invented)",
	# Hinterzimmer
	"Feierabend. Ein Tisch, ein Kartenspiel, zwei Gläser, die niemand abräumt.": "After hours. A table, a deck of cards, two glasses nobody clears away.",
	"Partie fortsetzen": "Resume game",
	"Mit den Kollegen spielen": "Play with the colleagues",
	"Mit Menschen spielen": "Play with people",
	"Am selben Tisch": "At the same table",
	"Über einen Raumcode": "Via a room code",
	"Regeln": "Rules",
	"Statistik": "Statistics",
	"Schrank": "Wardrobe",
	# Akte
	"Gefallen einfordern (%d Gefälligkeiten, Stand: %d)": "Call in a favour (%d favours, balance: %d)",
	"Einmal +2 auf den nächsten Wurf in der Karriere. Gefälligkeiten verdient man im Hinterzimmer.": "Once +2 on the next roll in the career. You earn favours in the back room.",
	"Gefallen eingefordert. Er gilt beim nächsten Wurf.": "Favour called in. It applies to the next roll.",
}


## Text in der gewählten Sprache. Deutsch (und alles Unbekannte) bleibt unverändert.
static func t(text: String) -> String:
	if I18nScript.lang == "en":
		return str(EN.get(text, text))
	return text
