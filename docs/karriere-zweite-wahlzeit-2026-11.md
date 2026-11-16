# Zweite Wahlzeit in der hinterlassenen Welt: Befund zu Issue #27

**Stand:** 16. November 2026 · **Bezug:** [Issue #27](https://github.com/deusexlumen/latte-app/issues/27), `docs/karriere-versuch-2026-11.md`, Spezifikation 0.1 G-03 bis G-06, G-10 bis G-12

Kennzeichnung: **[gerechnet]** automatisch geprüft, **[gelesen]** Ausgabe des Werkzeugs selbst gelesen. Gespielt über die Oberfläche wurde nichts Neues: Die zweite Wahlzeit hat keine Oberfläche bekommen, siehe Entscheidung.

## Ergebnis in einem Satz

**Die Hypothese ist für die vorhandenen Regeln widerlegt.** Mit den Zahlen des Versuchs bietet die zweite Wahlzeit nach jeder der 14 446 möglichen ersten Wahlzeiten keine einzige Entscheidung. Das Stop-Kriterium des Issues greift: kein Ausbau der Karriere auf dieser Grundlage.

## Was geprüft wurde

**Hypothese (Issue #27):** Ein früherer Eingriff erzeugt in einer späteren Wahlzeit unter denselben Regeln eine materiell oder sozial andere Entscheidungssituation, deren Ursache im Spiel erkennbar ist.

**Aufbau.** `KarriereKern.next_term()` setzt die Welt aus dem **vollen Zustand** fort, nicht aus `outcome()`.

| Bleibt | Beginnt neu |
|---|---|
| Bauwerke mit Schaden, Sanierung, Einsturz | Periode, Diensthandlungen |
| beschlossene, noch nicht ausgeführte Sanierungen | Bilanz und Malus |
| Ausfälle (Mertens, Bauhof), Aushilfen | Anträge der laufenden Periode |
| die Akte je Sache (erledigt, offen, Gutachten) | |
| Unterschriften, Brandts Stellung, das ganze Protokoll mit Wahlzeit und Periode | |

- **Mandatsverlust mitten in der Wahlzeit:** Die Welt läuft nach denselben Regeln ohne die Spielfigur zu Ende (`run_out`). Erst dann beginnt die neue Wahlzeit.
- **Figur bleibt im Amt:** Man spielt sie weiter, mit Rang und Unterschriften.
- **Figur hat das Mandat verloren:** Man spielt eine neue Figur im selben Bezirk. Das ist eine **Testannahme** und im Zustand so benannt (`figure`). Die alte Figur bleibt mit ihren Unterschriften in der Akte (`archive`). Wer ein Mandat verliert, verschwindet nicht.
- Nichts wird erfunden: keine neuen Schäden, Personen oder Aufgaben.
- Nur im Speicher. `karriere_kern/` greift auf keine Datei zu; der Spielstand des Innenhofs ist unberührt (Test).

`KarriereLauf` führt einen Lauf als Folge von Befehlen mit Kennung (`W2-P3-14`: Wahlzeit, Periode, laufende Nummer). Dieselben Befehle ergeben dieselbe Welt und dasselbe Protokoll. Ein doppelt eingereichter Befehl wirkt einmal.

## Befunde

Aufruf: `godot --headless --path . --script res://tools/karriere_zweite_wahlzeit.gd`

**1. Zwei Vorgeschichten gegen eine frische Welt [gelesen]**

| | Frische Welt | nach A (tüchtig) | nach B (sichtbar) |
|---|---|---|---|
| Was man sieht | Fleck an der Decke, Mertens im Dienst | „Sporthalle: geschlossen. Bauzaun.“ | „Das Dach ist neu. Es ist trocken.“ |
| Akte | 0 erledigt, 0 offen | 6 erledigt, 1 offen, Schadensfall | 0 erledigt, 2 offen, saniert |
| „Mertens anrufen“ | möglich | nicht möglich | nicht möglich |
| „Sanierung beantragen“ | möglich, wird zurückgestellt | nicht möglich | nicht möglich |
| Perioden mit einer Entscheidung | 7 | 0 | 0 |

Die Welt ist nach A und B tatsächlich eine andere, und die Ursache steht im Rückblick („Wahlzeit 1, Periode 7: Die Brücke am Radweg sackt ab“). Aber dieselbe Absicht trifft auf nichts mehr, worauf sie sich richten könnte. Das ist ein anderer Endtext mit Fortsetzung, keine andere Entscheidungssituation. Nach dem Maßstab des Issues genügt das nicht.

**2. Jede mögliche erste Wahlzeit, fortgesetzt [gerechnet]**

| Einsturzgrenze | erste Wahlzeiten | zweite Wahlzeit ohne jede Entscheidung | mit Entscheidung |
|---|---|---|---|
| 9 (Versuch) | 14 446 | 14 446 (100 %) | 0 |
| 10 | 62 478 | 62 478 (100 %) | 0 |
| 12 | 869 422 | 609 902 (70 %) | 259 520, alle mit im Amt gebliebener Figur |
| 16 | 869 422 | 247 342 (28 %) | 622 080, alle mit im Amt gebliebener Figur |

Die Zahlen zählen unterscheidbare Entscheidungsfolgen, keine Klickpfade und keine Gewinnchancen.

**3. Wo die zweite Wahlzeit Entscheidungen hat, trägt sie die Hypothese trotzdem nicht [gelesen]**

Erst wenn Bauwerke eine Wahlzeit überdauern (Grenze 12 und höher), gibt es etwas zu entscheiden. Dann gilt:

- **Eine neue Figur hat in keinem einzigen Verlauf eine Entscheidung.** Ihr Bezirk hat ein Bauwerk; ist es saniert oder eingestürzt, ist dort nichts mehr. An die Brücke kommt ein Ratsmitglied nicht heran.
- Entscheidungen haben nur Figuren, die als Vorsitz oder Dezernent im Amt geblieben sind. Sie sitzen im Rathaus: „Sporthalle: Sie waren nicht dort.“ Dass eine Aushilfe ausgelaufen ist, zeigt sich nur daran, dass „Aushilfe einsetzen“ angeboten wird. Kein Mensch, kein Gegenstand und kein Dokument macht die frühere Handlung als Ursache erkennbar.
- Mit einer so hohen Grenze stürzt in der ersten Wahlzeit nichts mehr ein. Der Versuch verliert, was ihn getragen hat.

## Welcher Mangel des Modells es verhindert

1. **Die Welt hat zwei endliche Dinge.** Jedes endet saniert oder eingestürzt. Danach liegt nichts mehr vor.
2. **Ein echter Erfolg erzeugt zu Recht nichts Neues** (G-04). Ein dichtes Dach meldet sich nicht. Fortsetzung kann also nicht aus dem Erfolg selbst kommen, und neue Schäden zu erfinden wäre der Schein-Erfolg, den das Issue ausschließt.
3. **Was bleibt, sind Menschen und Akten, und die haben hier nichts zu tun.** Mertens ist ausgefallen oder im Dienst. Im Kern gibt es außer der Halle nichts, wofür das einen Unterschied macht.
4. **Unten hat man Befugnis über genau eine Sache.** Eine neue Figur erbt einen Bezirk, in dem die Geschichte schon zu Ende ist.

Kurz: Der Kern bewahrt Folgen, aber er hat keinen Ort, an dem sie auf anderes treffen.

## Entscheidung

- **Kein Ausbau der Karriere um eine zweite Wahlzeit.** Keine Oberfläche dafür, kein Umzug auf `world_core/`, keine Speicheranbindung. Eine leere Wahlzeit zum Durchklicken wäre genau das, was das Stop-Kriterium beschreibt.
- **Beibehalten:** `next_term`, `run_out` und `KarriereLauf` als geprüfte Grundlage. Was bleibt und was neu beginnt, ist damit festgelegt und getestet, ebenso Nachspielen und Einmalwirkung.
- **Unberührt:** die bestehende Karriere, BANK-01, alle Spielstände. Die erste Wahlzeit des Versuchs ist unverändert (14 446 Verläufe, dieselben Befunde).

**Erspart:** den Umbau der Karriere-Szenen auf einen Kern, der über die erste Wahlzeit hinaus nichts hergibt, und eine Speicherschicht für Zustände, in denen nichts mehr geschieht.

## Nächster Nachweis (Vorschlag, nicht gebaut)

Das Issue nennt für diesen Fall zwei Wege. Mein Vorschlag ist der erste:

**Mertens zwischen Karriere und Innenhof.** In BANK-01 ist Mertens der, der die Bank repariert hat und den Ersatzstuhl bringt (T-02, T-06). Im Karriere-Kern ist er der, der ausfällt. Die Frage wäre: Ändert ein in der Karriere ausgefallener Mertens im Innenhof, was man tun kann und was man zur Antwort bekommt? Das wäre ein Unterschied an einem vorhandenen Menschen, in einem Vorgang, der schon Entscheidungen hat, ohne neue Figur und ohne neuen Schaden. Zuerst wieder isoliert und nur lesend: BANK-01 bekommt einen Anfangszustand mit oder ohne Mertens, und geprüft wird, welche Übergänge sich ändern. Die beiden Akteure werden dabei noch nicht verschmolzen.

Der zweite Weg, ein kleiner zweiter Vorgang (E5), wartet laut Fahrplan auf den Spieltest von BANK-01.

## Offen

- **Produktentscheidung:** ob die Mertens-Probe der nächste Schritt ist.
- **Spielerfigur über Wahlzeiten:** bleibt Testannahme. Mit diesem Befund ist die Frage nicht dringlich, weil eine neue Figur hier ohnehin nichts zu tun hätte.
- **Menschlicher Spieltest** des ersten Versuchs: hat nicht stattgefunden.

## Geändert und geprüft

- `karriere_kern/kern.gd`: `next_term`, `run_out`, `has_matter`; Protokoll trägt die Wahlzeit; die Fraktion entscheidet auch ohne Spielfigur; ein Einsturz, der die Spielfigur das Mandat kostet, bricht die Periode für die übrige Welt nicht mehr ab.
- `karriere_kern/lauf.gd` (neu): Befehle mit Kennung, Nachspielen, Einmalwirkung.
- `tools/karriere_zweite_wahlzeit.gd` (neu), `tools/karriere_kern_sweep.gd`: Enden nach vollem Zustand, Start von beliebigem Zustand.
- `test/test_karriere_wahlzeit.gd` (neu, 10 Tests): erste Wahlzeit unverändert, was bleibt und was neu beginnt, Unterschriften und Personen bleiben, Figur im Amt, beschlossene Sanierung über die Wahl, identische Wiederholung und Nachspielen, Kennungen und Einmalwirkung, keine Dateien, der Befund über alle Enden, die Gegenprobe.

Befehle und Ergebnisse am 16.11. (Linux-Sandbox, Godot 4.7.2):

| Befehl | Ergebnis |
|---|---|
| `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit` | Latte 147 bestanden (vorher 137) |
| `… -gdir=res://addons/lobby_loop/test/gut -gexit` | Lobby-Loop 146 bestanden |
| `godot --headless --path . --script res://tools/reentry_smoke.gd` | REENTRY_OK, keine Fehlerzeile |
| `godot --headless --path . --script res://tools/karriere_kern_sweep.gd -- kurz` | 14 446 und 27 926 Verläufe, wie zuvor |
| `godot --headless --path . --script res://tools/karriere_versuch_lauf.gd` | VERSUCH_OK (Klickprototyp über den Flur, unverändert) |
| DAME (`run_all.tscn`, `flow_smoke.gd`) | 8041 Prüfungen in 22 Suiten, FLOW_OK (WebRTC-Bibliothek weggeschoben); Node-Werkzeuge 10 bestanden |
| Web-Export | läuft in der CI des PRs (`pages.yml`, Job „build“) |
