# Spieltest BANK-01 – Anleitung

**Bezug:** Spezifikation 0.1, Kap. 20.4 (erster qualitativer Spieltest), 20.5 (Weiterbaukriterien), 20.6 (Diagnose)
**Zweck:** Prüfen, ob Menschen, die weder die Werke noch die Absicht kennen, den Vorgang selbstständig zu einem Abschluss bringen und eine eigene Handlung später wiedererkennen.

Das ist eine kleine formative Prüfung mit fünf Personen. Sie kann keine Aussage darüber belegen, wie „die meisten Menschen“ das Spiel verstehen. Vor einer öffentlichen Aussage zur Verständlichkeit folgt nach der Überarbeitung eine zweite, unabhängige Runde.

## 1. Vorbereitung

| Punkt | Vorgabe |
|---|---|
| Build | **Desktop-Export, Release** (nicht aus dem Editor). In Debug-Builds gibt es den Reiter „Entwicklung“ und Abkürzungen für die Minispiele; beides würde den Test verfälschen. Prüfen: Im Innenhof darf rechts kein Reiter „Entwicklung“ stehen. |
| Bauen | Preset „Windows Desktop“ (in `export_presets.cfg`): `godot --headless --path . --export-release "Windows Desktop" build/windows/Latte.exe`. Braucht die Export-Templates 4.7.2 und einen vorhandenen Ordner `build/windows/`. Das Ergebnis ist eine einzelne, unsignierte `Latte.exe` mit eingebettetem Paket (rund 120 MB). Windows kann beim ersten Start eine SmartScreen-Warnung zeigen. |
| Prüfung des Builds | Aus dem exportierten Paket wurde ein Linux-Release gestartet: Flur, Innenhof, Akte, Hörsaal und DAME-Menü laden ohne Fehler, alle Dateien des Vorgangs (Falldaten, Lehre, Szenen, Figuren, Ton) liegen im Paket. `Latte.exe` selbst wurde in der Build-Umgebung nicht gestartet (kein Windows). Beim ersten Test auf dem Zielrechner kurz durchklicken. |
| Warum nicht Web | Der Spielstand liegt im Browser-Speicher und lässt sich nicht als Datei auswerten. Für die Auswertung (Abschnitt 5) braucht es die Datei. |
| Gerät | Rechner mit Maus und Tastatur, Bildschirm mindestens 1280 × 720, Ton an |
| Sprache | Deutsch (Einstellungen im Flur) |
| Startzustand | Neuer Vorgang: im Innenhof „Neu beginnen“ zweimal anklicken, oder die Datei `amt_vorgang.json` löschen. DAMEs eigene Daten bleiben davon unberührt. |
| Aufnahme | Bildschirm und Ton aufzeichnen, wenn die Person zustimmt; sonst Beobachtungsbogen (Abschnitt 3) |
| Zeit | 45 Minuten einplanen. Die Schätzung der Spezifikation (20–45 Minuten) ist selbst ein Prüfpunkt. |

Die Person startet im Flur und wählt selbst die Tür „Innenhof“. Zeige oder nenne sonst nichts.

## 2. Was gesagt wird

Nur das praktische Spielziel, wörtlich:

> „Frau Kern wartet im Innenhof und möchte sich hinsetzen. Sehen Sie, ob und wie Sie das möglich machen. Es gibt kein Richtig oder Falsch, und Sie können jederzeit aufhören.“

Dazu, falls gefragt oder bei sichtbarer Ratlosigkeit nach etwa einer Minute, die Bedienung in drei Sätzen:

> „Die Knöpfe links sind Ihre Handlungen, die Menüs mit dem Pfeil klappen weitere auf. Rechts liegt der Aktenkoffer mit Ihren Unterlagen. Zahlen in Klammern sind die Kosten.“

**Nicht sagen:** Begriffe wie Systemerhalt, Verstrickung, Bürokratiekritik oder dass es um Folgen eigener Eingriffe geht. Keine Hinweise auf Hinterzimmer, Ausschuss oder Spiele.

## 3. Während des Spiels

Nicht helfen. Wartet die Person länger als zwei Minuten ohne Handlung, fragen: „Woran denken Sie gerade?“ Schweigen gilt nicht als fehlendes Verständnis.

Jede Hilfe protokollieren und einstufen:

- **Stufe 1 – Bedienung:** Wo ist etwas, wie klicke ich es an.
- **Stufe 2 – Inhalt:** Was soll ich tun, was bedeutet das.

### Beobachtungsbogen (je Person)

| Frage | Notiz (Zeitpunkt, Szene) |
|---|---|
| Wo entsteht der erste selbstständige Schritt? | |
| Wo wird Hilfe nötig? (Stufe 1 / 2) | |
| Welche Folge wird bemerkt? (laut gesagt, gezeigt, kommentiert) | |
| Welche Szene oder Unterlage wird übersprungen? | |
| Wo entstehen Lachen, Neugier, Ermüdung? | |
| Wird die Aktenhilfe benutzt? Welche Frage? | |
| Wird DAME gespielt? Wird die Widerlegung gespielt? Mit welchem Eindruck? | |
| Welcher Weg wird gewählt? (Stuhl, Ausnahme, formelle Freigabe, offen) | |
| Bricht die Person ab? Wo, warum? | |

## 4. Fragen danach

In dieser Reihenfolge, wörtlich. Nachfragen dürfen Quellen klären („Woran haben Sie das gemerkt?“), aber keine gewünschte Antwort hineinlegen.

1. „Was wolltest du erreichen, und was ist daraus geworden?“
2. „Was hat sich durch deine Entscheidungen verändert?“
3. „Gab es eine spätere Situation, die mit einer früheren Handlung zusammenhing?“
4. „Wo war dir unklar, was du tun konntest oder warum etwas passiert ist?“
5. „Welche Person oder Szene ist dir geblieben? Würdest du weiterspielen wollen?“

Antworten möglichst wörtlich notieren. Bei Frage 3 festhalten, **ob die Person es ohne Hinweis nennt** und woran sie es erkannt hat (Fallnummer, Formulierung, Gegenstand, Figur).

## 5. Auswertung

Nach der Sitzung den Spielstand sichern und auswerten:

```bash
node tools/spieltest-auswertung.mjs <Pfad>/amt_vorgang.json
```

| System | Ordner |
|---|---|
| Windows | `%APPDATA%\Godot\app_userdata\Latte\` |
| Linux | `~/.local/share/godot/app_userdata/Latte/` |
| macOS | `~/Library/Application Support/Godot/app_userdata/Latte/` |

Die Datei vor dem nächsten Durchlauf kopieren und mit der Personennummer benennen. Die Ausgabe zeigt Abschluss (amtlich und tatsächlich), Aufwand, erworbene Belege, Minispiele, Bericht und die Folgen, die im Nachgang zu sehen waren. `--json` gibt dasselbe maschinenlesbar aus. Das Skript fasst nur das Protokoll zusammen. Es bewertet weder Verständnis noch Spielspaß.

Ein Beispiel für einen vollständigen Durchlauf liegt in `tools/fixtures/bank01-pfad-a.json`.

## 6. Weiterbaukriterien (vorläufig, Kap. 20.5)

| Kriterium | Schwelle | Quelle |
|---|---|---|
| Selbstständig zu einem Abschluss gefunden (nach kurzer Bedienungseinführung) | mindestens 4 von 5 | Beobachtung, Spielstand |
| Konkreten eigenen Eingriff und eine spätere Verarbeitung ohne thematischen Hinweis genannt | mindestens 3 von 5 | Frage 3 |
| Abschlusswege werden als unterschiedlich wirksam wahrgenommen; Eindruck „am Ende passiert sowieso dasselbe“ löst eine Überarbeitung aus | – | Frage 2 und 4 |
| Kein wiederkehrender technischer oder sprachlicher Blocker, der mehr als eine Person ohne Hilfe festhält | 0 | Beobachtungsbogen |
| Humor und Interesse | qualitativ dokumentiert | Beobachtung, Frage 5 |

Das Bestehen der Zahlen beweist noch keinen Spielspaß.

## 7. Diagnose bei Problemen (Kap. 20.6)

| Befund | Zuerst ändern |
|---|---|
| Handlungsmöglichkeiten unklar | Verben, Voraussetzungen, sichtbare Kosten |
| Eigene Folge nicht erkannt | Wiederkehrende Formulierung, Zeitpunkt, Fallnummer, räumliche Begegnung |
| Alles wirkt vorherbestimmt | Unterschiedliche Zustandsänderungen und Wegbedingungen |
| Welt wirkt wie eine Minispielsammlung | Anlass, gemeinsame Personen, Rückkehr in denselben Vorgang |
| Text wirkt belehrend | Erklärsätze entfernen; Folge in Handlung oder Gegenstand zeigen |
| Zu wenig Interesse | Anliegen und Figuren konkretisieren; Routinetätigkeiten verkürzen |
| Jede Szene wirkt wie eine Pointe | Mehr gewöhnlichen Alltag und unbeachtete Nebenhandlungen zulassen |

## 8. Bekannte Grenzen des Prototyps

Diese Punkte sind bekannt und sollten nicht als Testergebnis gewertet werden, aber im Bogen vermerkt bleiben, wenn sie stören:

- Die Oberfläche ist ein Klickprototyp ohne Raumdarstellung. Orte und Personen sind Text.
- Das Widerlegungs-Panel ist das von Lobby-Loop und gehört optisch nicht zum Innenhof.
- Die Balance der Widerlegung ist simuliert, nicht erspielt.
- Screenreader und schmale Darstellung sind nicht geprüft.
- Der Ton im Innenhof fehlt; im Hinterzimmer läuft DAMEs Ton.
