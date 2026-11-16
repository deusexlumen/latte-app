# Mertens-Probe: Was ein in der Karriere ausgefallener Mertens im Innenhof ändert

**Stand:** 16. November 2026 · **Bezug:** Freigabe des Nutzers vom 16.11. (isolierter Kausaltest), [Issue #27](https://github.com/deusexlumen/latte-app/issues/27), `docs/karriere-zweite-wahlzeit-2026-11.md`

Kennzeichnung: **[gerechnet]** automatisch geprüft, **[gelesen]** Ausgabe des Werkzeugs selbst gelesen. Über die Oberfläche gespielt wurde die Welt ohne Mertens nicht: Das Spiel bietet keinen Weg, sie zu betreten, und das ist Absicht.

## Ergebnis in einem Satz

**Die Kausalwirkung ist nachgewiesen, das Erfolgskriterium ist nicht erfüllt.** Ohne Mertens sind alle fünf Wege zu einem Sitzplatz für Frau Kern geschlossen, und die Ursache ist an einem Dokument und an einer Person erkennbar. Es entsteht aber keine andere Entscheidung mit Kosten oder Alternativen: Es bleibt nur „ohne Lösung“. Nach der Bedingung der Freigabe wird darauf nicht weitergebaut.

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

**Eine Setzung von mir:** Der Zettel „Bank Innenhof – erledigt“ hängt im vorhandenen Text sichtbar an der Pinnwand. Damit man ihn in der leeren Werkstatt nicht einfach nimmt, steht im neuen Text eine abgeschlossene Gittertür davor. Das schließt einen Weg, den es im Spiel bisher nicht als Handlung gab. Siehe „Offen“.

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

**3. Es entsteht keine andere Entscheidung [gerechnet].** Ohne Mertens endet jeder Weg bei „ohne Lösung“. Man kann weiter ermitteln und sogar die Widerlegung gewinnen, aber nichts davon bringt Frau Kern zum Sitzen. Das ist mehr als ein fehlender Knopf, aber es ist ein kleinerer Vorgang und kein anderer: Es gibt nichts abzuwägen.

**4. Der eigentliche Fund: BANK-01 hängt an einer einzigen Person [gerechnet].** Der Reparaturnachweis B-01 kommt nur von Mertens oder aus der Akte seiner Stelle. Der Stuhl kommt nur von ihm, am Tag wie am Abend. Das Absperrband schneidet er ab. Der Vorgang ist nur lösbar, solange der Mann im Dienst ist, den die tüchtige Karriere verbraucht. Das ist „Stabilität auf fremde Rechnung“ aus dem Gesamtwerk, hier ohne Absicht entstanden und jetzt nachzählbar.

**5. Abwesenheit hält über jeden Phasenwechsel, Nachspielen ergibt dieselbe Welt [gerechnet].**

## Entscheidung

- **Nicht weiterbauen.** Kein Einstieg im Spiel in die Welt ohne Mertens, keine Verbindung der Spielstände, keine gemeinsame Figur.
- **Beibehalten:** die Absicherung der vier Stellen in BANK-01 und die Probe samt Tests. Sie kosten das Spiel nichts und sind die Voraussetzung, falls die Verbindung später gewollt ist.
- **Stand der Frage aus Issue #27:** Wo begegnet ein späteres Handeln den Folgen eines früheren? In BANK-01, an Mertens. Die Stelle ist gefunden. Was ihr fehlt, ist ein zweiter Weg, der etwas kostet.

**Erspart:** eine gemeinsame Welt, in der die erfolgreichste Karriere den Innenhof unspielbar macht, ohne dass man etwas dagegen tun kann.

## Offen

**Produktentscheidung (Spielregel):** Soll es in BANK-01 einen Weg zum Reparaturnachweis geben, der nicht über Mertens führt und dafür etwas kostet? Erst damit würde aus der Folge eine Entscheidung. Zwei Möglichkeiten aus dem, was schon da ist:

1. **Der Zettel an der Pinnwand.** Er hängt da. Wer ihn in der leeren Werkstatt abnimmt, hat den Beleg, aber ohne Herausgabe durch die Stelle. Ein so beschaffter Beleg könnte einen Antrag tragen und später als Rückfrage wiederkommen, so wie heute der unbelegte Verdacht (T-08). Das wäre meine Gittertür, geöffnet.
2. **Die Registratur führt eine Abschrift.** Frau Seidel gibt sie heraus, mit der Aufmerksamkeit und der Umlagerung, die eine Anforderung dort ohnehin auslöst.

Beides ist neue Spielregel in einem Vorgang, dessen Spieltest noch aussteht. Deshalb nur benannt, nicht gebaut.

**Weiter offen:** die fünf unvorbereiteten Spieltests von BANK-01. Ob Menschen den Zettel an der Tür mit einer früheren Karriere verbinden, zeigt keine Rechnung.

## Geändert und geprüft

- `cases/bank_01/bank_01.gd`: `new_state(run_seed, world)`, `mertens_present`, die vier Absicherungen, Ablehnung der Reparaturakte bei unbesetzter Stelle.
- `cases/bank_01/bank_01.json`: fünf Sätze.
- `tools/mertens_probe.gd` (neu), `test/test_mertens_probe.gd` (neu, 8 Tests).

| Befehl | Ergebnis am 16.11. (Linux-Sandbox, Godot 4.7.2) |
|---|---|
| `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit` | Latte 155 bestanden (vorher 147), darin alle bisherigen BANK-01-Tests unverändert |
| `… -gdir=res://addons/lobby_loop/test/gut -gexit` | Lobby-Loop 146 bestanden |
| `godot --headless --path . --script res://tools/reentry_smoke.gd` | REENTRY_OK, keine Fehlerzeile |
| DAME (`run_all.tscn`, `flow_smoke.gd`) | 8041 Prüfungen in 22 Suiten, FLOW_OK (WebRTC-Bibliothek weggeschoben) |
| Web-Export | Job „build“ des PRs |
