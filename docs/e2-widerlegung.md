# E2 – Widerlegung im Ausschuss (Bank-Lehre)

**Bezug:** Spezifikation 0.1, Kap. 8.2, 9.7, 16.4, 16.5, 17.2, 19 (E2), 20.2
**Stand:** 18. Oktober 2026
**Abnahmetor E2:** Hinweise kausal korrekt; Huhn-Portierung geprüft; Verlust und Abbruch fortsetzbar.

Im Ausschussraum spielt der Vorgang jetzt die echte Widerlegung (Panel und Regeln aus Lobby-Loop) auf einer eigenen Lehre. DAME bleibt bis E3 ein Platzhalter der Entwicklungsansicht.

## Die Bank-Lehre

`cases/bank_01/lehre/bib_bank_01.json` (Inhaltskennung `bank_public_seating_v1`). Der Ordner enthält nur diese Lehre. Er ist schreibgeschützt gedacht: Das Bank-Panel führt keine Sperrliste, der Fall ändert sich zur Laufzeit nicht.

| Punkt | Wert |
|---|---|
| Startlehre | „ein bewegliches Möbel, mit Rückenlehne, nicht als Kunst inventarisiert“ (Kap. 9.7) |
| Karten | 20: 9 Mitglieder, 11 Nichtmitglieder; 4 davon Referenzkarten (nie im Deck), 16 im Deck |
| Merkmale | 10 (beweglich, Lehne, Kunst, bereitgestellt, Sitzfläche, trägt 80 kg, drinnen, gesperrt, nur zur Ansicht, gepolstert) |
| Prisma (Voss' Reihenfolge) | trägt, Sitzfläche, nicht nur zur Ansicht, drinnen, nicht gesperrt, gepolstert |
| Kartenpaare | 17 (nötig: 3) |
| `cap` / Würfe | 11 / 7, **vom Validator gesetzt**, nicht von Hand |
| Messung (Validator) | überlegtes Spiel stürzt 64,7 % ein (Band 55–80 %), Zufall 22,7 % (unter 35 %), Ausnahmen in 99 % der Partien (ab 60 %) |

Alle acht Beispielkarten aus Kap. 9.7 sind im Pool: verschraubte Wartebank, Wartehocker, BANK-01, Besucherstuhl, Stuhl im Miniaturmodell, Ausstellungsstuhl mit Berührungsverbot, Wartebank als Sitzskulptur, Transportkiste. Dazu Aktenschrank, Kühlschrank, Treppenstufe mit Geländer u. a.

### Referenz: Mitglied ⇔ „für Wartende bereitgestellt“

Kap. 9.7 verlangt, dass ein Sieg nicht von einer unausgesprochenen Definition im Kopf des Autors abhängt. Deshalb gilt für jede Karte: **Mitglied genau dann, wenn das Merkmal „bereitgestellt“ zutrifft** (der dokumentierte Nutzungsauftrag). Ein Test prüft das für alle 20 Karten. Die Einleitung im Panel nennt die Referenz. Voss' Prisma enthält sie bewusst nicht: Seine Arbeitsdefinition kennt nur formale Merkmale, und daraus entstehen die Ausnahmen, die die Definition zum Einsturz bringen.

## Aufbau

| Datei | Aufgabe |
|---|---|
| `cases/bank_01/bank_widerlegung.gd` | Lehren-Ordner, Seed je Durchlauf, **Nachspielen** einer Partie aus Seed und Kartenfolge, Umsetzung Panel-Ergebnis → Weltergebnis |
| `cases/bank_01/bank_01.gd` | neuer Befehl `minigame_play`; Prüfung des Ergebnisses durch Nachspielen |
| `amt/bank_panel.gd` | Panel von Lobby-Loop ohne Einspruch; ein Tor lässt jeden Zug erst vom Vorgang verbuchen |
| `amt/vorgang.gd` | öffnet das Panel beim Start und beim Fortsetzen, übersetzt das Panel-Ergebnis |
| `tools/bank_lehre_check.gd` | lässt den Validator laufen; mit `--write` schreibt er `cap`, Würfe, Referenzen und Messung in die Datei |
| `tools/bank-lehre-golden.mjs` | erzeugt das Golden mit der JS-Engine (200 Partien) |
| `test/golden/bank_01_widerlegung.json` | Golden (nicht im Export) |

### Ablauf einer Partie

1. `start_minigame` legt eine Session an. Der Seed ist der des Durchlaufs, nicht der der Session.
2. Das Panel startet auf diesem Seed. **Jede Karte** geht zuerst als `minigame_play` an den Vorgang. Der spielt die bisherigen Karten plus die neue auf dem Seed nach und lehnt ab, wenn die Karte nicht in der Hand liegt. Erst dann spielt das Panel sie.
3. Am Ende liefert das Panel sein Vertragsergebnis. Der Vorgang übernimmt **nur den Ausgang**; die mitgelieferte Effektliste (`modify_stat`, `add_item`) wird nie ausgeführt.
4. `minigame_result` spielt die Partie ein letztes Mal nach und verlangt, dass Ausgang und Punkte zum Verlauf passen. Erst danach ist die Definitionsfrage entschieden.

### Fortsetzen, Abbruch, Niederlage

- **Fortsetzen:** Es wird kein Panel-Zustand gespeichert. Die Session merkt sich nur die gespielten Karten; das Panel spielt sie beim Öffnen auf dem Seed nach und steht wieder genau so da (Test: gleiche Hand nach dem Neuladen).
- **Abbruch:** verbucht weder Sieg noch Niederlage (Kap. 10.2). Wer neu startet, bekommt dieselbe Hand, nicht eine neue.
- **Niederlage:** der Vorgang bleibt entscheidbar; die befristete Ausnahme steht weiter offen und Frau Kern sitzt (Test).

## Gleichheit mit dem JS-Original (Kap. 20.2)

- Lobby-Loop prüft den Port bereits mit 200 Partien auf den fünf Grund-Lehren. Für die neue Lehre gab es das nicht.
- `node tools/bank-lehre-golden.mjs` spielt 200 Partien (Seeds `BANKGOLD-0` … `-199`, die vier Kniff-Sätze von Lobby-Loop im Wechsel) auf der **JS-Engine** und schreibt Zug, Last, Herzschlag, Zufallsfolge (Hand, Nachziehstapel) und Ergebnis in das Golden. 68 von 200 Partien stürzen ein.
- `test/test_bank_widerlegung.gd` spielt dieselben Partien im Godot-Port. **200 von 200 stimmen Zeile für Zeile überein.**
- Das Golden wurde einmal mit der Kopie in `lobby-loop/vendor/huhn` und einmal mit der Engine aus deinem hochgeladenen Archiv erzeugt. **Beide Läufe sind identisch.** Die Kopie verhält sich also auf dieser Lehre wie das Original.
- Eine Mutationsprobe (Gewicht einer Ausnahme 3 → 2 im Port) wird vom Test mit der abweichenden Zeile gemeldet.

Das ist ein Vergleich für diese Lehre. Er ersetzt nicht die Prüfung des Ports auf den Grund-Lehren in Lobby-Loop.

## Tests

`test/test_bank_widerlegung.gd` (18 Tests) und zwei neue in `test_vorgang_ui.gd`:

- Lehre: Form, Referenzregel, Validator bestätigt die gespeicherten Werte (`cap`, Würfe, Bänder), Laden ohne Bibliothek unter `user://`.
- Nachspielen: deterministisch, lehnt unzulässige Züge ab.
- Vorgang: gewonnene Widerlegung öffnet den formellen Weg; verlorene führt zur Ausnahme; **manipulierte Ergebnisse** (gedrehter Ausgang, falsche Punkte, unfertige Partie, Ergebnis ohne Karten) werden abgewiesen.
- Panel: spielt über das Tor, kein Einspruch, keine Datei in den Fall-Daten, Tor kann eine Karte ablehnen.
- Oberfläche: Panel öffnet sich, Neuladen mitten in der Partie, Fortsetzen mit gleicher Hand.
- Drei Mutationsproben am Vorgang (Ausgang nicht prüfen, Zug nicht gegen die Hand prüfen, Entwicklungsergebnis ohne Schranke): jeweils mindestens ein Test schlägt an.

Insgesamt 87 Tests in `test/` (vorher 67). `npm test` ist vollständig grün.

## Neue Entwurfsentscheidungen in E2

Revidierbar, keine Nutzervorgaben.

| ID | Entscheidung | Grund |
|---|---|---|
| E2-01 | Prisma ohne das Merkmal „bereitgestellt“ | Nur so bleiben Ausnahmen möglich; ein Prisma mit der Referenz hätte die Lehre nie zum Einsturz gebracht (erste Fassung: 0 % Einsturz) |
| E2-02 | Seed der Widerlegung ist der des Durchlaufs | Ein Abbruch würfelt sonst eine neue Hand |
| E2-03 | Das Ergebnis gilt nur, wenn Seed und Kartenfolge es erklären | QA-14; schützt vor Ergebnissen, die das Panel oder ein Dritter erfindet |
| E2-04 | Ergebnis ohne gespielte Karten nur als Entwicklungsstub in Debug-Builds (`Bank01.allow_dev_results`) | E1 brauchte Platzhalter; in Release-Builds darf kein Ergebnis ohne Spiel durchgehen |
| E2-05 | Kein Einspruch im Bank-Panel | Er schreibt eine Sperrliste und ändert damit die Lehre; der Fall soll fest bleiben (Kap. 15.2) |
| E2-06 | Fortsetzen durch Nachspielen statt Panel-Zustand zu speichern | Kleinerer Speicherstand, nichts kann auseinanderlaufen |
| E2-07 | Keine Kniffe in der Bank-Partie | Kniffe gehören zur Karriere der Widerlegung, nicht zu einem einzelnen Vorgang. Die Parität deckt sie trotzdem ab |
| E2-08 | Eine Widerlegung je Vorgang, nach Abbruch neu startbar (aus E1-08) | unverändert |

## Nicht in E2 / offen

- **Echte DAME-Partie** im Hinterzimmer und der gemeinsame visuelle Übergang: E3.
- **Balance der Lehre** ist simuliert (Validator), nicht erspielt. Ob die Partie Spaß macht und ob die Referenz „bereitgestellt“ ohne Erklärung verständlich wird, zeigt erst der Spieltest (Kap. 20.4).
- Die Texte der Karten und Ausgangszeilen sind erster Entwurf.
- Das Panel ist das von Lobby-Loop, mit dessen Gestaltung. Eine Anpassung an die räumliche Darstellung (Saalmodell auf dem Ausschusstisch, Kap. 8.2) ist E3.
- Die Lehre ändern: Datei bearbeiten, dann `node tools/bank-lehre-golden.mjs` und `godot --headless --path . --script res://tools/bank_lehre_check.gd -- --write`. Die Prüfung bestätigt Bänder und `cap` neu; der Golden-Test meldet jede Abweichung zwischen Port und Original.
