# Fahrplan ab 18. Oktober 2026

**Maßstab:** das Leitbild in `CLAUDE.md`. Eine App, ein Herzensprojekt, kein Geld als Ziel. Jeder Schritt wird daran gemessen, ob er die Welt, das Erleben und das, was man mitnimmt, stärkt.
**Bezug:** Spezifikation 0.1 (E0 bis E5), Manifest „Die Latte liegt am Boden“, Gesamtkonzept vom 11.10.2026 (`../lobby-loop/docs/konzept/gesamtkonzept-latte.md`; Welt, Spielformen und Erweiterungen gelten, Geschäftsmodell und Eigenständigkeit der Einzelspiele nicht)

## Wo wir stehen

| Teil | Stand | Was fehlt |
|---|---|---|
| Gemeinsame Welt | E0 bis E4: Innenhof mit BANK-01, Widerlegung im Ausschuss, echte DAME-Partie am Abend, Akte mit amtlicher Fassung neben dem Tatsächlichen | **Spieltest nicht gemacht**, danach Überarbeitung und E5 |
| Karriere (Lobby-Loop) | Szenen, Würfel, Perma-Death, Karriere-Akte, Widerlegung, Spielleiter erfindet Lehren | – |
| Hinterzimmer (DAME) | in Latte auf Stand `a5e503d` | Online-Ausbau vom 18.10. (Raum, mehrere Gäste, Wiedereintritt, Abwesenheit) nicht übernommen; ob Online in Latte läuft, ist ungeprüft |
| Eine App | Flur mit vier Türen, ein Spielstand, eine Einstellungsseite | DAME hat in Latte noch sein eigenes Hauptmenü; DAME läuft zusätzlich als eigene Seite auf GitHub Pages |

## 1. Prüfen, ob es trägt

Der Spieltest misst genau das Leitbild: ob Menschen eine eigene Handlung später in ihren Folgen wiedererkennen (Weiterbaukriterien in `spieltest-bank-01.md`). Ohne ihn baue ich die Welt auf Vermutungen weiter.

- **Du:** Spieltest BANK-01 mit fünf Personen, die das Spiel nicht kennen.
- **Ich:** Auswertung (`tools/spieltest-auswertung.mjs`), Überarbeitung nach der Diagnosetabelle.

## 2. Eine App, wirklich eine

- **DAME vollständig ins Hinterzimmer:** neu syncen (heute 5 PRs zurück), DAMEs eigenes Hauptmenü in Latte durch den Flur ersetzen, sodass es nur noch einen Einstieg gibt.
- **Menschen am Tisch:** Online-Partien im Hinterzimmer prüfen und fertig machen. Dazu gehören der aufgeräumte Raum-Bildschirm, Namen statt „Gast 2“ und das abgesicherte TURN-Kontingent, damit Verbindungen im Mobilfunk halten. Online zählt weiter nie in der Karriere.
- **Eine Adresse im Netz:** Die eigenständige DAME-Seite auf GitHub Pages wird durch den Web-Build der Latte-App ersetzt.
- **Zwei bekannte Fehler:** Im Browser geht eine Handlung verloren, wenn der Tab schnell geschlossen wird. Nach einer verlorenen Hinterzimmer-Partie fehlt der „Mandat verloren“-Schirm.

## 3. Die Welt vertiefen (nach dem Spieltest)

- **E5:** zweiter Vorgang aus denselben Regeln. Er zeigt, dass die Welt wächst, ohne dass jedes Mal Sonderbau nötig ist.
- **Was man mitnimmt:** Die Akte stellt heute schon amtliche Fassung und Tatsächliches nebeneinander. Am Ende einer Karriere sollte sie das über alle Spiele zusammenführen, damit sichtbar wird, wie der Apparat das eigene Handeln verarbeitet hat. Wie genau, ist eine Gestaltungsfrage für uns beide.
- **Menschen gegen Menschen auch im Denkspiel:** Huhn-Duell (einer baut eine Lehre, einer reißt sie ein) über den DAME-Netzkern. Raum, Wiedereintritt und Abwesenheit sind schon unabhängig vom Spiel.
- **Lehren-Werkstatt:** Spieler bauen eigene Lehren, die Simulation vergibt ein Prüfsiegel, Teilen per Raumcode.
- **Division 7B:** die metaphysische Abteilung mit dem Entitäten-Bestiarium als eigene Abteilung des Amts.
- **Weitere Orte aus dem Manifest:** Garbo, Köpenick, Vasa, Poyais, Erfurt 1184. Jeder wird ein eigener Mechanismus im selben Minispiel-Vertrag, jeder zeigt eine andere Seite von Kulisse gegen Fundament.
- **Für alle spielbar:** durchgehend Tastatur, große Schrift, Bildschirmleser.

## 4. Aufräumen (wenn du willst)

Folgendes wird nicht mehr gebraucht: die React-App in `Dame-Card-Game/src/`, die Repos `dame-kartenspiel` und `Dame---Strategic-Card-Game` sowie PR Dame-Card-Game#11. Mein Vorschlag: die Repos archivieren, was sich rückgängig machen lässt, und den React-Code in einem eigenen PR entfernen. Gelöscht wird nur auf dein Wort.

## Laufende Pflichten

- Der tägliche Live-Test des Raum-Dienstes (`Dame-Card-Game/.github/workflows/online-live.yml`) hält das Supabase-Projekt wach. Schlägt er fehl, sind die Partien mit Menschen kaputt.
- DAME und Lobby-Loop werden nur in ihren eigenen Repos geändert. Latte bekommt sie danach über `sync-games.mjs`.
