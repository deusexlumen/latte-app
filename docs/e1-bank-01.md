# E1 – Fallkern BANK-01 „Die gesperrte Bank“

**Bezug:** Spezifikation 0.1, Kap. 9, 10, 15–17, 19.3, 20.1
**Stand:** 18. Oktober 2026
**Abnahmetor E1:** T-01 bis T-08 samt Speicher- und Folgeereignissen reproduzierbar.

E1 ist ein schlichter Klickprototyp. Er prüft Kausalität und Verständlichkeit, nicht Gestaltung. Erreichbar im Flur über die Tür **Innenhof**.

## Aufbau

| Ordner | Inhalt | Darf nicht |
|---|---|---|
| `world_core/amt_world.gd` | Zustandsgerüst, `execute()` (ein Befehl = eine Transaktion), `apply_ops()` als **einziger Ort jeder Änderung**, Uhr, Aufmerksamkeit, geplante Abläufe, Nachspielen, Herkunftsprüfung | Fallinhalte kennen |
| `world_core/amt_transaction.gd` | Arbeitskopie, `emit()` stempelt Ereignisse (Kennung, Zug, Phase, Ursache) und wendet ihre Operationen an | – |
| `world_core/amt_store.gd` | Speichern über `JsonStore`, vorheriger Stand als `.prev`, Prüfung von Format, Inhaltsfassung und Herkunft, `archive()` statt Überschreiben | still verwerfen |
| `cases/bank_01/bank_01.json` | alle Texte, Dokumente, Hinweise (was sie belegen und was nicht), Vergleiche, Schlussfolgerungen, offene Fragen | – |
| `cases/bank_01/bank_01.gd` | Anfangszustand, Befehle, Übergänge, Nachgangregeln, Abfragen für die Oberfläche | eigene Zeit führen, am Kern vorbei schreiben |
| `amt/vorgang.gd` | Oberfläche: Ort, Personen, höchstens vier primäre Handlungen, Menüs, Aktenkoffer (Akte, Unterlagen, Vergleichen, Verlauf), Einreichung | Weltwerte direkt ändern |

Jedes Ereignis trägt die Operationen, die es bewirkt. Wer alle Ereignisse auf den Anfangszustand anwendet, erhält denselben Weltzustand (`test_replaying_event_ops_reproduces_the_world`). Minispiele und ein späteres Sprachmodell erzeugen nie Operationen; nur die Fallsteuerung übersetzt einen geprüften Ausgang.

## Befehle

Kosten 1 Diensthandlung (nur Tag 1, nach Eröffnung): `observe`, `interview`, `request_document`, `request_help`, `wait`.
Kostenlos: `open_case`, `move`, `talk`, `compare`, `end_day`, `start_minigame`, `minigame_result`, `end_evening`, `submit`, `close_case`, `advance`, `correct_report`.

Reihenfolge innerhalb einer Diensthandlung nach Kap. 8.4: Handlung → Beobachtung → Aufmerksamkeit und Benachrichtigung → fällige Abläufe → Uhr.

## Übergänge

| Übergang | Umsetzung | Test |
|---|---|---|
| T-01 Prüfung eröffnen | `open_case` am Schild im Innenhof | `test_t01_open_case` |
| T-02 Reparatur belegen | B-01 über Mertens oder Reparaturakte; Bestand bleibt „Exponat“ | `test_t02_…` |
| T-03 Einstufung klären | B-02 + D-01 vergleichen → B-03, kostenlos | `test_t03_…` |
| T-04 Regulär freigeben | Einreichung „formal“: B-01–B-03, Widerlegung gewonnen, Wortlaut | `test_path_a_…`, `test_qa06_…` |
| T-05 Ausnahme | Einreichung „ausnahme“: B-01, B-02 | `test_path_c_…`, `test_qa09_…` |
| T-06 Ersatzstuhl | Bitte am Tag (1 Handlung) oder erste gewonnene DAME-Partie; mit T-04/T-05 kombinierbar | `test_path_b_…`, `test_t06_…`, `test_qa10_…` |
| T-07 Ohne Lösung | `close_case` vor der Einreichung | `test_t07_…`, `test_qa09_…` |
| T-08 Unbelegter Verdacht | „Verschleierung“ mit B-06, ohne B-05 → Rückfrage samt Verfahrensblatt → Korrektur | `test_t08_…` (2 Tests) |

Nachgang je Abschluss: formell → genau eine Prüfanforderung PA-12 mit dem bestätigten Wortlaut und Herkunft BANK-01; Ausnahme → Erinnerung, Eintrag „überprüfungsbedürftig“; Ersatzstuhl → Rückgabezettel; offen → Ablagevermerk. Nach einer Prüfungsankündigung zusätzlich Seidels Aussage zur Umlagerung.

## Regeltests (Kap. 20.1)

QA-01 bis QA-17 stehen als gleichnamige Tests in `test/test_bank_01.gd`. Einschränkungen in E1:

- **QA-09, QA-10, QA-14** prüfen den Weltkern mit Platzhalter-Ergebnissen (`Bank01.dev_result`), nicht mit echtem DAME oder echter Widerlegung (Kap. 19.1).
- **QA-13** speichert und lädt nach jedem Phasenwechsel; der geladene Stand ist identisch.
- Zwei Mutationsproben während der Entwicklung: „Befragen zählt als Augenzeugenschaft“ und „Nachgangregel ohne Einmal-Sperre“ werden jeweils von einem Test erkannt.

Insgesamt: `test_bank_01.gd` 30, `test_world_core.gd` 10, `test_vorgang_ui.gd` 6 Tests; mit den bisherigen 21 sind es 67. Der Fluss-Test (`tools/reentry_smoke.gd`) geht zusätzlich Flur → Innenhof → Flur → Innenhof und prüft, dass der Stand erhalten bleibt.

## Neue Entwurfsentscheidungen in E1

Die Spezifikation ließ diese Punkte offen. Sie sind **Entwurfsentscheidungen**, revidierbar, keine Nutzervorgaben.

| ID | Entscheidung | Grund |
|---|---|---|
| E1-01 | Ereignisse tragen primitive Operationen; nur `apply_ops` ändert den Zustand | Kap. 15.3 „einziger Änderungspfad“ wird prüfbar (Nachspielen) |
| E1-02 | Augenzeuge der Umlagerung ist nur, wer am Ort **umsieht** oder **Zeit verstreichen lässt**; wer dort befragt oder anfordert, nicht | Kap. 9.5 sagt „beobachtet“; Befragen bindet die Aufmerksamkeit |
| E1-03 | Benachrichtigung ab Stufe 2: Hausdienst → Registratur, Registratur → Hausdienst, Ausschuss → Registratur | passt zum „gemeinsamen Vermerk“ von Registratur und Hausdienst; macht QA-11 prüfbar |
| E1-04 | Gespräche mit Frau Kern und abends mit Mertens kosten keine Diensthandlung | kein Dienstcharakter; Kap. 6.1 „Abend verbraucht keine Handlung“ |
| E1-05 | Bitte um einen Stuhl: 1 Handlung, keine Aufmerksamkeit, Stuhl nach der nächsten Handlung | Kap. 8.3: „über eine zusätzliche Diensthandlung“; keine Untersuchung |
| E1-06 | B-05 über Befragung Seidels nach der Ankündigung, über Anforderung des Verfahrensblatts oder als Anlage der Rückfrage (T-08) | Kap. 9.4: zwei Wege; T-08 verlangt eine Korrekturmöglichkeit |
| E1-07 | Zusätzliche Vergleiche: B-01 + B-02 → F-01 „Freigabe und Bestand widersprechen sich“; B-05 + B-06 (oder S-02) → F-02 „Umlagerung folgte der eigenen Anforderung“ | Kap. 9.5: „Ein Vergleich von Zeitpunkt und Anweisung zeigt den eigenen Anteil“ |
| E1-08 | Eine Widerlegung je Vorgang (nach Abbruch neu startbar); bei DAME zählt nur die erste beendete Partie | sonst ließe sich bis zum Sieg wiederholen; Kap. 8.3 „keine unbegrenzten Vorteile“ |
| E1-09 | Bericht und Antrag bilden eine verbindliche Einreichung am Tag 2 | Kap. 10.2: verbindlich erst nach Bestätigung |
| E1-10 | Schlussfolgerung gilt als „belegt“, wenn die zitierten Feststellungen alle nötigen Behauptungen tragen; „Verschleierung“ ist nie belegbar | Kap. 9.4: B-06 belegt keine Absicht |
| E1-11 | Ohne Entwicklungsansicht werden keine Minispiele angeboten; eine laufende Partie lässt sich immer abbrechen | E1 hat keine echten Minispiele; Abbruch ist regelkonform |
| E1-12 | Frau Kern ist im Nachgang („einige Wochen später“) nicht mehr im Hof | ihr Termin ist vorbei; der Hof zeigt Schild und neuen Stuhl |
| E1-13 | Antragsformulierung: drei Vorlagen oder eigene, höchstens 160 Zeichen, Zeilenumbrüche entfernt; wörtlich übernommen | Kap. 9.8 und QA-12 |
| E1-14 | Der Spatz erscheint nach fester Regel aus Zug und Phase | Kap. 3.5 ohne Zufall; QA-01 bleibt deterministisch |

## Nicht in E1

- Echte Widerlegung im Ausschuss (braucht die Bank-Lehre) und echte DAME-Partie: E2/E3.
- Räumliche Gestaltung, Ton, Übergänge: E3.
- Schmale Darstellung: Das Projekt skaliert 1280 × 720 logisch (`canvas_items`, `keep`); eine eigene Ansicht ab 360 logischen Pixeln ist ungeprüft.
- Screenreader: nicht geprüft (Kap. 12.3 verlangt einen eigenen Befund).
- Kein Sprachmodell, kein Netz, keine Telemetrie.
