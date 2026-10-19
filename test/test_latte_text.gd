# PURPOSE: Übersetzung der App-Hülle: Deutsch bleibt unverändert, Englisch übersetzt, Platzhalter bleiben gleich, Flur-Türen sind übersetzt.
# ARCHITECTURE: test
# DEPENDENCIES: app/latte_text.gd, flur/flur.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-10-19
extends GutTest

const LatteText := preload("res://app/latte_text.gd")
const I18nScript := preload("res://addons/amt_core/i18n.gd")
const FlurScript := preload("res://flur/flur.gd")

var _lang := "de"


func before_each() -> void:
	_lang = I18nScript.lang


func after_each() -> void:
	I18nScript.lang = _lang


func test_deutsch_bleibt_unveraendert() -> void:
	I18nScript.lang = "de"
	assert_eq(LatteText.t("Hörsaal"), "Hörsaal")
	assert_eq(LatteText.t("Ein Text ohne Eintrag"), "Ein Text ohne Eintrag")


func test_englisch_uebersetzt_und_laesst_unbekanntes_stehen() -> void:
	I18nScript.lang = "en"
	assert_eq(LatteText.t("Hörsaal"), "Lecture Hall")
	assert_eq(LatteText.t("Ein Text ohne Eintrag"), "Ein Text ohne Eintrag")


func test_platzhalter_stimmen_ueberein() -> void:
	var rx := RegEx.create_from_string("%[sd]")
	for key in LatteText.EN:
		assert_eq(rx.search_all(str(key)).size(), rx.search_all(str(LatteText.EN[key])).size(), "Platzhalter in: %s" % key)


func test_jede_flur_tuer_hat_eine_uebersetzung() -> void:
	for door in FlurScript.DOORS:
		assert_true(LatteText.EN.has(door[0]), "Name fehlt: %s" % door[0])
		assert_true(LatteText.EN.has(door[1]), "Beschreibung fehlt: %s" % door[1])
