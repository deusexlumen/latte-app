# Mertens-Probe: Was ein in der Karriere ausgefallener Mertens im Innenhof ändert

**Stand:** 16. November 2026 · **Bezug:** Freigabe des Nutzers vom 16.11. (isolierter Kausaltest), [Issue #27](https://github.com/deusexlumen/latte-app/issues/27), `docs/karriere-zweite-wahlzeit-2026-11.md`

Kennzeichnung: **[gerechnet]** automatisch geprüft, **[gelesen]** Ausgabe des Werkzeugs selbst gelesen. Über die Oberfläche gespielt wurde die Welt ohne Mertens nicht: Das Spiel bietet keinen Weg, sie zu betreten, und das ist Absicht.

## Ergebnis in einem Satz

**Die Kausalwirkung ist nachgewiesen.** Unter den für die Probe gesetzten Regeln enden die fünf Wege, die bisher zu einem Sitzplatz für Frau Kern führen, ohne Sitzplatz, und die Ursache ist an einem Dokument und an einer Person erkennbar.

**Ohne Sitzplatz heißt nicht ohne Unterschied** (Gegencheck nach dem Review vom 16.11., Befund 6). Die verbleibenden ungelösten Wege hinterlassen verschiedene Akten und verschiedene Folgen im Nachgang, bis hin zur Rückfrage der Registratur (T-08). Ob Spieler diese Folgen bemerken und für bedeutsam halten, ist offen. Nach der Bedingung der Freigabe wird nicht weitergebaut.

Drei Kriterien, getrennt geprüft:

| Kriterium | Befund |
|---|---|
| 1. Sitzplatz erreicht? | nein, auf keinem der fünf Wege (unter den gesetzten Regeln) **[gerechnet]** |
| 2. Folgen trotz ungelöstem Fall unterscheidbar? | ja, amtlich: 6 Wege, 6 verschiedene Akten, 4 verschiedene Folgen im Nachgang **[gerechnet]** |
| 3. Erkennt und bewertet der Spieler diese Folgen? | offen, nur im Spieltest zu klären |

Eine unterschiedliche Datenstruktur allein beweist noch keine bedeutsame Entscheidung.

**Was das nicht belegt:** dass diese Wege grundsätzlich unmöglich wären. Der Befund „kein Zugang zum Reparaturnachweis“ ruht auf zwei Setzungen der Probe (siehe „Zwei Setzungen, die den Befund tragen“). Er ist auch kein beobachtetes Spielerlebnis: Kein Mensch hat diese Welt gespielt.

> **Review des Nutzers, 16.11. (PR #29):** Forschungsstand, kein Spielnachweis und keine Integrationsfreigabe. Keine zusätzliche Regel, keine Verbindung der Welten, kein Ersatzweg. Nächster Schritt sind die fünf unvorbereiteten Spieltests des unveränderten BANK-01.

## Festgelegt vor dem Versuch

| Frage | Festlegung | Status |
|---|---|---|
| Identität | Der Hausmeister der Sporthalle im Karriere-Kern und Mertens vom Hausdienst sind dieselbe Person. | Testannahme |
| Zeitfolge | Die Wahlzeit liegt vor dem Tag, an dem BANK-01 beginnt. | Testannahme |
| Rückwirkung | Keine. Die Bank ist repariert (Juni), sein Zettel hängt an der Pinnwand. Beides bleibt. | Regel, getestet |
| Übergabe | Ein einziger Wert: Mertens im Dienst oder ausgefallen. Abgeleitet aus dem vollen Zustand der Karriere (`was_out` der Sporthalle). | getestet |
| Ersatz | Keiner. Keine Vertretung, kein neuer Weg zum Reparaturnachweis, kein neuer Schaden. | Regel |

Nicht angefasst: Spielstände (Form und Inhaltsfassung `bank_01@1` unverändert), `world_core/`, die Karriere-Oberfläche, eine gemeinsame Figur. Das Spiel selbst übergibt nichts; im Innenhof ist Mertens da wie immer.

## Was dafür in BANK-01 geändert wurde

Abwesenheit steht im vorhandenen Feld `location_id` als Ort `abwesend`. Ohne Übergabe ist der Anfangszustand derselbe wie bisher (Test), alle bisherigen Tests laufen unverändert.

Die vier Stellen, an denen BANK-01 Mertens als immer verfügbar voraussetzte, sind jetzt abgesichert:

- `_end_day` und `_end_evening` setzen ihn nicht mehr ins Hinterzimmer und zurück, wenn er nicht im Dienst ist.
- `available_actions` bietet abends Gespräch und DAME nur an, wenn er da ist.
- `_talk` und der Start der DAME-Partie prüfen seine Anwesenheit.
- Die Reparaturakte liegt bei seiner Stelle. Ist die nicht besetzt, gibt sie niemand heraus.

Fünf neue Sätze im Fall (Zettel an der Tür des Hausdienstes, Dienstschluss, Hinterzimmer am Abend, zwei Ablehnungen).

### Zwei Setzungen, die den Befund tragen

Beide sind Testannahmen der Probe und keine Folge aus vorhandenen Regeln. Ohne sie gäbe es einen Zugang zu B-01.

1. **Die Reparaturakte gibt niemand heraus.** Die Anforderung läuft im Spiel über die Stelle Hausdienst. Dass eine unbesetzte Stelle nichts herausgibt, habe ich gesetzt. Ebenso denkbar: Die Akte kommt mit Verzögerung oder über eine andere Stelle.
2. **Der Zettel hängt hinter einer abgeschlossenen Gittertür.** „Bank Innenhof – erledigt“ hängt im vorhandenen Text sichtbar an der Pinnwand. Die Gittertür steht nur im neuen Text der Probe. Sie schließt einen Weg, den es im Spiel bisher nicht als Handlung gab.

## Befunde

Aufruf: `godot --headless --path . --script res://tools/mertens_probe.gd`

Zwei Vorgeschichten aus dem Karriere-Kern, dann derselbe Vorgang, dieselben Befehle.

| Weg | nach „sichtbar“ (Mertens im Dienst) | nach „tüchtig“ (Mertens ausgefallen) |
|---|---|---|
| Stuhl am Tag (T-06) | Frau Kern sitzt auf dem Klappstuhl | steht. „Um einen Stuhl bitten Sie am besten den Hausdienst.“ |
| Stuhl am Abend (DAME) | sitzt auf dem Klappstuhl | steht. „Zu zweit kommt keine Runde zustande. Der dritte Stuhl ist der von Mertens.“ |
| Ausnahme (T-05) | sitzt auf der Bank, befristet | steht. Beleg B-01 fehlt. |
| Ausnahme über die Reparaturakte | sitzt auf der Bank, befristet | steht. „Der Hausdienst ist nicht besetzt. Niemand gibt die Akte heraus.“ |
| Formelle Freigabe (T-04) | sitzt auf der Bank, Bank offen | steht. Beleg B-01 fehlt, trotz gewonnener Widerlegung. |
| Nur Bericht | ohne Lösung | ohne Lösung |
| Ohne Antrag abschließen (T-07) | ohne Lösung | ohne Lösung |

**1. Die frühere Handlung trifft hier wirklich auf eine spätere [gerechnet].** Anders als in der zweiten Wahlzeit gibt es in BANK-01 etwas zu tun, und was man tun kann, hängt an der Vorgeschichte. Fünf Wege, die mit Mertens zu einem Sitzplatz führen, führen ohne ihn zu keinem.

**2. Die Ursache ist im Spiel erkennbar [gelesen].** An der Tür des Hausdienstes: „Hausdienst nicht besetzt. Hr. Mertens ausgefallen seit dem vierten Einsatz in der Sporthalle. Vertretung: keine.“ Am Abend Frau Seidel allein: „Seit Mertens fehlt, spielt hier keiner mehr.“ Jede Ablehnung nennt ihren Grund, kostet keine Diensthandlung und ändert nichts.

**3. Kein Weg zum Sitzplatz [gerechnet].** Unter den gesetzten Regeln endet ohne Mertens jeder der fünf Sitzplatz-Wege bei „ohne Lösung“. Man kann weiter ermitteln und sogar die Widerlegung gewinnen, aber nichts davon bringt Frau Kern zum Sitzen. Dass damit nichts mehr abzuwägen sei, folgt daraus nicht; siehe Befund 6.

**4. Der eigentliche Fund: BANK-01 hängt an einer einzigen Person [gerechnet].** Der Reparaturnachweis B-01 kommt im heutigen Spiel nur von Mertens oder aus der Akte seiner Stelle. Der Stuhl kommt nur von ihm, am Tag wie am Abend. Das Absperrband schneidet er ab. Der Vorgang ist nur lösbar, solange der Mann im Dienst ist, den die tüchtige Karriere verbraucht. Das ist „Stabilität auf fremde Rechnung“ aus dem Gesamtwerk, hier ohne Absicht entstanden und jetzt nachzählbar.

**5. Abwesenheit hält über jeden Phasenwechsel, Nachspielen ergibt dieselbe Welt [gerechnet].**

**6. Die ungelösten Wege unterscheiden sich in Akte und Nachgang [gerechnet].** Gegencheck nach dem Review vom 16.11., nur diagnostisch, ohne Regeländerung. Verglichen werden Bericht, Schlussfolgerung und ihr Status, Rückfrage, Prüfungsankündigung, Definition, Ort der Originale, Nachgangregeln, Folgeereignisse und Dokumente, nicht nur `resolution`.

| Weg (ohne Mertens) | Was im Nachgang ankommt |
|---|---|
| U1 sofort schließen | Ablagevermerk |
| U2 Registratur angefragt, dann schließen | Ablagevermerk, Aussage von Frau Seidel zur Umlagerung |
| U3 Bericht ohne Antrag, Einstufung belegt (Widerlegung gewonnen) | wie U2; zusätzlich Bericht und gewonnene Definition in der Akte |
| U4 Bericht ohne Antrag, Verdacht „Verschleierung“ (T-08) | wie U2, dazu Rückfrage der Registratur mit Verfahrensblatt als Anlage |
| U5 wie U4, Rückfrage beantwortet | wie U4, Bericht korrigiert, Schlussfolgerung belegt |
| U6 Verdacht mit Verfahrensblatt | wie U2; der Verdacht bleibt als Vermutung in der Akte, keine Rückfrage |

Alle sechs enden ungelöst, Frau Kern steht. Sechs verschiedene Akten, vier verschiedene Folgen im Nachgang. U2, U3 und U6 unterscheiden sich nur in der Akte, nicht in dem, was danach ankommt. T-08 ist auch ohne Mertens erreichbar, weil der beobachtete Umzug der Originale (B-06) und das Verfahrensblatt (B-05) über die Registratur laufen.

## Entscheidung

- **Nicht weiterbauen.** Kein Einstieg im Spiel in die Welt ohne Mertens, keine Verbindung der Spielstände, keine gemeinsame Figur.
- **Beibehalten:** die Absicherung der vier Stellen in BANK-01 und die Probe samt Tests. Sie kosten das Spiel nichts und sind die Voraussetzung, falls die Verbindung später gewollt ist.
- **Stand der Frage aus Issue #27:** Wo begegnet ein späteres Handeln den Folgen eines früheren? In BANK-01, an Mertens. Die Stelle ist gefunden. Ob ihr etwas fehlt, entscheidet sich nach dem Spieltest.

**Erspart:** eine gemeinsame Welt, in der die erfolgreichste Karriere den Innenhof unspielbar macht, ohne dass man etwas dagegen tun kann.

## Gegenhypothesen (notiert, nicht gebaut)

Ob die Welt ohne Mertens eine Sackgasse sein muss, ist offen. Zwei Gegenhypothesen aus dem, was schon da ist:

1. **Der Zettel an der Pinnwand.** Wer ihn in der leeren Werkstatt abnimmt, hat den Beleg ohne Herausgabe durch die Stelle. Ein so beschaffter Beleg könnte einen Antrag tragen und später als Rückfrage wiederkommen, so wie heute der unbelegte Verdacht (T-08).
2. **Die Registratur führt eine Abschrift.** Frau Seidel gibt sie heraus, mit der Aufmerksamkeit und der Umlagerung, die eine Anforderung dort ohnehin auslöst.

Auch die dritte Möglichkeit bleibt offen: Ein dauerhaft ungelöster Fall kann gewollt sein, wenn das eigene Handeln trotzdem unterscheidbare Folgen hat. Befund 6 zeigt, dass es diese Folgen amtlich bereits gibt.

Keine davon wird gebaut, um eine gewünschte positive Hypothese zu erzeugen.

## Nächster Nachweis (Entscheidung des Nutzers, 16.11.)

Keine neue Mechanik. Zuerst die fünf unvorbereiteten Spieltests des **unveränderten** BANK-01 aus einem Release-Build, nach `spieltest-bank-01.md`, mit dem bestehenden Beobachtungsbogen und den dort festgelegten Schwellen (unter anderem 4 von 5 selbstständiger Abschluss, 3 von 5 unaufgeforderte Folgenwahrnehmung). Die Testpersonen erfahren nichts über Karriere, Mertens oder Absicht.

Zusätzlich, ohne danach zu fragen, notieren:

- ob jemand von sich aus nach einer anderen Quelle für den Reparaturbeleg sucht (Pinnwand, Registratur);
- ob jemand einen ungelösten Abschluss als sinnvolles Ende erlebt.

Diese Notizen ergänzen den Bogen und ersetzen keines seiner Kriterien. Erst danach wird entschieden, ob die Mertens-Variante eine neue Handlungsmöglichkeit braucht oder ob eine Sackgasse genügt.

**Wer:** Der Spieltest ist Sache des Nutzers (Testpersonen). Auswertung der Spielstände: `tools/spieltest-auswertung.mjs`.

## Geändert und geprüft

- `cases/bank_01/bank_01.gd`: `new_state(run_seed, world)`, `mertens_present`, die vier Absicherungen, Ablehnung der Reparaturakte bei unbesetzter Stelle.
- `cases/bank_01/bank_01.json`: fünf Sätze.
- `tools/mertens_probe.gd` (neu, mit Gegencheck der ungelösten Wege), `test/test_mertens_probe.gd` (neu, 9 Tests).

| Befehl | Ergebnis am 16.11. (Linux-Sandbox, Godot 4.7.2) |
|---|---|
| `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit` | Latte 156 bestanden (vorher 147), darin alle bisherigen BANK-01-Tests unverändert |
| `… -gdir=res://addons/lobby_loop/test/gut -gexit` | Lobby-Loop 146 bestanden |
| `godot --headless --path . --script res://tools/reentry_smoke.gd` | REENTRY_OK, keine Fehlerzeile |
| DAME (`run_all.tscn`, `flow_smoke.gd`) | 8041 Prüfungen in 22 Suiten, FLOW_OK (WebRTC-Bibliothek weggeschoben) |
| Web-Export | Job „build“ des PRs |
