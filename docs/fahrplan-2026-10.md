# Fahrplan ab 18. Oktober 2026

**Maßstab:** das Leitbild in `CLAUDE.md`. Eine App, ein Herzensprojekt, kein Geld als Ziel. Jeder Schritt wird daran gemessen, ob er die Welt, das Erleben und das, was man mitnimmt, stärkt.
**Bezug:** Spezifikation 0.1 (`grundlagen/spezifikation-0.1-gemeinsame-spielwelt.md`, E0 bis E5), Manifest „Die Latte liegt am Boden“, Gesamtkonzept vom 11.10.2026 (`../lobby-loop/docs/konzept/gesamtkonzept-latte.md`; Welt, Spielformen und Erweiterungen gelten, Geschäftsmodell und Eigenständigkeit der Einzelspiele nicht)

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

- **Erledigt (18.10.):** DAME neu gesynct. Das Hinterzimmer ist jetzt ein Ort mit vier Handlungen statt DAMEs Hauptmenü, jedes „Zurück“ führt dorthin. Online heißt „Mit Menschen spielen“, der Raumcode ist der Hauptweg, Gäste tragen ihren eigenen Namen. Der „Mandat verloren“-Schirm erscheint jetzt auch nach einer verlorenen Hinterzimmer-Partie. Im Browser sichert die App die Spielstände beim Verbergen oder Schließen des Tabs zusätzlich synchron, eine Handlung geht nicht mehr verloren (in Chromium geprüft).
- **TURN-Kontingent:** offen, braucht deine Entscheidung (siehe unten).
- **Eine Adresse im Netz:** Die eigenständige DAME-Seite auf GitHub Pages wird durch den Web-Build der Latte-App ersetzt.

**TURN, warum es hängt:** Die Verbindung im Mobilfunk läuft über einen Vermittlungsserver (TURN) von ExpressTURN, kostenlos bis 1 TB im Monat. Die Zugangsdaten sind fest; wer sie einmal abruft, kann sie behalten und weiterverwenden. Eine Begrenzung pro Abruf schützt deshalb nichts. Was bei Überschreitung passiert (Abschaltung bis Monatsende oder Rechnung), steht auf keiner Seite, die ich erreichen kann. Wirklich schützen würden nur kurzlebige Zugangsdaten, etwa bei Cloudflare; dafür verlangt Cloudflare ein Zahlungsmittel.

## 3. Die Welt vertiefen (nach dem Spieltest)

- **E5:** zweiter Vorgang aus denselben Regeln. Er zeigt, dass die Welt wächst, ohne dass jedes Mal Sonderbau nötig ist.
- **Was man mitnimmt:** Die Akte stellt heute schon amtliche Fassung und Tatsächliches nebeneinander. Am Ende einer Karriere sollte sie das über alle Spiele zusammenführen, damit sichtbar wird, wie der Apparat das eigene Handeln verarbeitet hat. Wie genau, ist eine Gestaltungsfrage für uns beide.
- **Menschen gegen Menschen auch im Denkspiel:** Huhn-Duell (einer baut eine Lehre, einer reißt sie ein) über den DAME-Netzkern. Raum, Wiedereintritt und Abwesenheit sind schon unabhängig vom Spiel.
- **Lehren-Werkstatt:** Spieler bauen eigene Lehren, die Simulation vergibt ein Prüfsiegel, Teilen per Raumcode.
- **Division 7B:** die metaphysische Abteilung mit dem Entitäten-Bestiarium als eigene Abteilung des Amts.
- **Weitere Orte aus dem Manifest:** Garbo, Köpenick, Vasa, Poyais, Erfurt 1184. Jeder wird ein eigener Mechanismus im selben Minispiel-Vertrag, jeder zeigt eine andere Seite von Kulisse gegen Fundament.
- **Für alle spielbar:** durchgehend Tastatur, große Schrift, Bildschirmleser.

## 3a. Testerreife (19.10.)

Der Spieltest wartet auf Menschen, die den Nutzer erst finden muss. Bis dahin geht die Arbeit weiter, und jeder Reibungspunkt für Tester fällt weg.

- **Erledigt (19.10.):** README als Einstieg für Tester (Link, Download, die vier Türen, Rückmeldung), Entwickler-Teil nach `docs/entwicklung.md`, Rückmelde-Vorlage, Web-Build-Workflow für GitHub Pages. Der Export wurde in einem frischen Checkout ohne die nicht versionierten Addons gebaut (11,5 MB Paket, 39,5 MB Wasm, keine Fehlerzeile). **Wirkt erst, wenn das Repo öffentlich ist und Pages auf „GitHub Actions“ steht** (Entscheidung des Nutzers).
- **Mehrsprachigkeit, Reihenfolge:** DAME hat Deutsch und Englisch (`i18n.gd`, deutscher Text als Schlüssel). Zuerst die Hülle der App über `app/latte_text.gd` (deutscher Text als Schlüssel, Sprache von DAMEs Einstellung), damit alles Neue von Anfang an übersetzbar ist. **Erledigt (19.10.):** Flur, Zum-Flur-Knopf, Hörsaal, Hinterzimmer-Raum, Rahmen der Akte. **Noch Hülle:** Bedienflächen des Innenhofs (`amt/vorgang.gd`, rund 80 Stellen) und Akte-Abschnitte (`app/akte.gd`), beides gemischt mit Inhalt; daher mit den Falltexten nach dem Spieltest. Falltexte (`cases/`) und Lobby-Loop-Inhalte erst nach dem Spieltest: Er ändert die Texte, eine Übersetzung davor wäre doppelte Arbeit.
- **Look festgelegt (19.10.):** Neobrutalismus mit Religionscharakter (gnostische Anspielung an wenigen Stellen), Assets frei als Grundlage plus Eigenfertigung auf hohem Niveau, kein 1:1-Nachbau. Ausgeführt in `gestaltung.md`. Code allein liefert keine Figuren; Modelle und Scans entstehen beim Nutzer.

## 3b. Ideen des Nutzers (19.10., noch nicht entschieden)

- **Liebe im Detail** (Vorbild LucasArts): Easter Eggs in der ganzen Welt.
- **KIMI** („Künstliche Intelligenz mit Intention“): Kunstfigur des Nutzers, auf seinem Discord als Bot und Sidekick unterwegs. Soll als eine der Nicht-Menschen in der Welt auftauchen, mal hier, mal dort, ohne mit dem Plot zu tun zu haben. Offen: Rolle, Aussehen, Stimme.
- **Division 7B, Astralwesen:** Aus den Wesen des Bestiariums könnte ein eigenes Spiel nach Art von Pokémon oder Digimon werden. Offen, ob als Tür im Amt oder als eigene Abteilung; vorerst nur Idee.

## 4. Aufräumen (wenn du willst)

Folgendes wird nicht mehr gebraucht: die React-App in `Dame-Card-Game/src/`, die Repos `dame-kartenspiel` und `Dame---Strategic-Card-Game` sowie PR Dame-Card-Game#11. Mein Vorschlag: die Repos archivieren, was sich rückgängig machen lässt, und den React-Code in einem eigenen PR entfernen. Gelöscht wird nur auf dein Wort.

## Laufende Pflichten

- Der tägliche Live-Test des Raum-Dienstes (`Dame-Card-Game/.github/workflows/online-live.yml`) hält das Supabase-Projekt wach. Schlägt er fehl, sind die Partien mit Menschen kaputt.
- DAME und Lobby-Loop werden nur in ihren eigenen Repos geändert. Latte bekommt sie danach über `sync-games.mjs`.
