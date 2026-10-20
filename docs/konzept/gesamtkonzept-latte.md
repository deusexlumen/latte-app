# Gesamtkonzept: Die Latte liegt am Boden – eine Spielewelt

Oct 11, 2026 · @Sebastian Schulte-Buxloh

> Abgelegt am 12.10.2026 als Spec für `plan.md`. Die zwei eingebetteten Diagramme (Architektur, Fahrplan) lagen nur als Einbettung vor und fehlen hier.

> **Überholt (Nutzer, 18.10.2026):** Es gibt nur eine App, die Latte-App; kein Spiel ist als eigenständige App ein Ziel. Geld, Verkauf und Veröffentlichung sind kein Ziel (Abschnitt „Geld ohne Gier“ und die Eigenständigkeitsregeln gelten nicht mehr). Verbindlich ist das Leitbild in `AGENTS.md` bzw. `latte-app/CLAUDE.md`.

## Kurzfassung

Aus Lobby-Loop, DAME und Das gerupfte Huhn wird **eine App mit einer gemeinsamen Welt: das Amt**. Die drei Spiele bleiben eigenständig spielbar und greifen über eine gemeinsame Karriere-Akte ineinander.

- **Lobby-Loop ist die Welt und die Erzählung.** Du bist Antragsteller, der Aktenkoffer ist der Spielleiter, die Szenen sind die Orte des Amts.
- **Das gerupfte Huhn ist das Denkspiel der Welt.** Es wird zur „Widerlegung": In Ausschüssen und Kommissionen reißt du Definitionen ein.
- **DAME ist das Hinterzimmer.** Dort wird gegen echte Menschen um Gefälligkeiten gespielt.
- **Technisch wird der Unterbau von DAME zur Hülle der App,** weil er der ausgereifteste ist: Profil, Speicher, Shop, Statistik, Online-Verbindung.
- **Dauerhaft trägt es durch drei Quellen von Abwechslung,** die sich nicht verbrauchen: echte Mitspieler (DAME, später Duelle), der Spielleiter, der neue Lehren erfindet, und feste Regeln, die jede erfundene Lehre auf Spielbarkeit prüfen.

Der erste Schritt ist klein und für sich nützlich: die Huhn-Regeln nach Godot übertragen und als zweites Minispiel in Lobby-Loop einbauen.

## Bestandsaufnahme

Alle drei Projekte passen technisch zusammen: Zwei laufen schon auf Godot 4.7, das dritte ist klein genug für eine Übertragung. Gelesen wurden die Repos am 11.10.2026 (Struktur, Spezifikationen, Entscheidungsdokumente, Kernskripte).

| Projekt | Was es ist | Stand | Stärke für das Ganze | Lücke |
| --- | --- | --- | --- | --- |
| [DAME](https://github.com/deusexlumen/Dame-Card-Game) | Gedächtnis- und Bluff-Kartenspiel, 2–6 Spieler, 3D-Casinotisch | 155 Commits, live im Browser, Godot 4.7 (GL Compatibility), Online über WebRTC im Aufbau | Ausgereifter Unterbau: Profil, Speicher, Shop nur für Kosmetik, Kaufschnittstelle `PurchaseProvider`, Statistik, Netz-Kern | Eigene Welt (Casino), keine Verbindung zur Satire |
| [Lobby-Loop](https://github.com/deusexlumen/lobby-loop) | Satirisches Point-&-Click-Rollenspiel, Sprachmodell als Spielleiter (Aktenkoffer), W20-Würfe, Perma-Death | 7 Commits, Godot 4.7 (Forward Plus), Spiellogik + erste Oberfläche (Raum, Inventar, Overlay, Minispiel-Panel), GM-Proxy in Node, Offline-Modus über SQLite | Die Welt: Szenen, Konzept-Inventar, Karriere-Akte als teilbares Ende, sauberer Befehls-Vertrag zwischen Spielleiter und Engine | Wenig Spielmechanik jenseits des Würfels; Minispiel-Befehl kennt nur ein Minispiel |
| Das gerupfte Huhn | Widerlegungs-Denkspiel: Definitionen mit Gegenbeispielen zum Einsturz bringen | v2, eine HTML-Datei, 13 Regeltests, Balance per Simulation, läuft im Browser | Eine Mechanik, die Können belohnt (gemessen) und jede Begriffsdebatte spielbar macht | Inhalt verbraucht sich (5 Lehren, 85 Karten); kein Godot |

Zwei Korrekturen zu meiner letzten Antwort: Lobby-Loop hat bereits eine erste Oberfläche (`scripts/main.gd`, fünf UI-Panels). Und die Minispiel-Andockstelle existiert, ist aber fest auf das Beleidigungsfechten verdrahtet: `start_minigame` trägt keine Angabe, welches Spiel starten soll.

## Die Idee: eine Welt, drei Spielformen

Die Welt ist das **Amt** aus „Die Latte liegt am Boden": ein Apparat, der nur seine eigenen Akten kennt. Das Leitmotiv aller drei Spiele ist **Kulisse gegen Fundament**. Jedes Spiel lässt dich eine andere Fähigkeit gegen diesen Apparat einsetzen.

| Spielform | Spiel | Was du tust | Fähigkeit | Vorbild aus dem Manifest |
| --- | --- | --- | --- | --- |
| Erzählen | Lobby-Loop | Absichten formulieren, würfeln, Konzepte kombinieren | Auftreten | Köpenick: Autorität ist Aufführung |
| Denken | Widerlegung (das gerupfte Huhn) | Definitionen mit Gegenbeispielen einreißen | Substanz | Diogenes und das gerupfte Huhn |
| Bluffen | Hinterzimmer (DAME) | sich Karten merken, täuschen, im richtigen Moment „Dame" rufen | Gedächtnis und Täuschung | Garbo: Wer die Aktenlage beherrscht, gewinnt |

Der Ton ist überall derselbe: trocken, amtlich, ohne zu zwinkern. DAME braucht dafür keine Regeländerung, nur eine neue Rahmung. Das Casino-Hinterzimmer wird das Hinterzimmer des Amts, die Chips werden Gefälligkeiten.

**Arbeitstitel der App: „Die Latte liegt am Boden".** Der Name existiert bereits als Manifest und als Werk (Boden-Inspektion), die App wäre der dritte Teil derselben Marke.

## Spielerfahrung: wie die Spiele ineinandergreifen

Du spielst eine **Karriere** im Amt (Lobby-Loop). Die beiden anderen Spiele sind die Momente, in denen es ernst wird. Ihr Ergebnis wirkt in die Karriere zurück. Jedes Spiel ist außerdem einzeln aus dem Hauptmenü startbar, ohne Karriere.

Ein typischer Abend:

1. Du betrittst eine Szene, etwa die Fraktionssitzung, und handelst über Absichten und W20-Würfe. Das ist Lobby-Loop wie bisher.
2. Ein Gesetzentwurf liegt auf dem Tisch: „Lobbyist im Sinne dieses Gesetzes ist, wer …". Der Spielleiter startet eine **Widerlegung**. Reißt du die Definition ein, gewinnt deine Fraktion die Abstimmung.
3. Das Ergebnis fließt zurück: Einsturz bringt Fraktionsdisziplin und ein Konzept-Item (zum Beispiel „Gerupftes Huhn" oder „Weggefallener Paragraph"). Eine gehaltene Lehre kostet Disziplin.
4. Abends lockt das **Hinterzimmer**: eine Runde DAME gegen Kollegen. Gewinne sind Gefälligkeiten, mit denen du in der Karriere einmalige Vorteile kaufst, etwa +2 auf einen Würfelwurf.
5. Endet die Karriere (Perma-Death oder Ruhestand), schreibt die Registratur die **Karriere-Akte**: alle Widerlegungen, Bluffs und Würfe in einem amtlichen Dokument.

Drei Regeln halten das sauber:

- **Kein Spiel hängt vom anderen ab.** Wer nur DAME spielen will, spielt nur DAME.
- **Vorteile aus einem Spiel sind im anderen klein und einmalig.** Sonst wird ein Spiel zum Pflichtprogramm für das andere.
- **Die Karriere-Akte ist das gemeinsame Gedächtnis.** Lobby-Loop hat sie schon (ADR 0005). Sie wird so erweitert, dass sie Ergebnisse aller drei Spiele aufnimmt.

## Warum es dauerhaft trägt

Spiele, die Jahrzehnte überleben (Schach, Skat, Poker, Tetris), holen ihre Abwechslung aus dem Gegner oder aus den Regeln, nicht aus vorgefertigtem Inhalt. Die App bekommt drei solche Quellen, und jede gleicht die Schwäche einer anderen aus.

| Quelle | Woher die Abwechslung kommt | Welche Schwäche sie behebt |
| --- | --- | --- |
| **Echte Mitspieler** | DAME online und am selben Gerät; später Huhn-Duelle (einer baut die Lehre, einer reißt sie ein) | Ein Computergegner ist irgendwann durchschaut |
| **Der Spielleiter** | Erfindet neue Szenen, Vorwürfe und vor allem neue Lehren zu jedem Begriff | Handgeschriebene Inhalte (5 Lehren) sind nach Wochen verbraucht |
| **Feste Regeln als Prüfer** | Die Huhn-Regeln sind berechenbar. Sie spielen jede erfundene Lehre hunderte Male durch und lassen nur spielbare zu | Ein Sprachmodell erfindet auch Unspielbares und Falsches |

Der entscheidende Punkt ist die Verbindung der zweiten und dritten Quelle. Der Spielleiter allein wäre beliebig, die Regeln allein wären endlich. Zusammen ergeben sie **unbegrenzten Inhalt mit geprüfter Qualität**, und das ohne Server, weil die Prüfung auf dem Gerät läuft.

Dazu kommt Perma-Death aus Lobby-Loop: Jede Karriere ist anders, weil sie enden kann. Das ist der Mechanismus, mit dem Roguelikes seit Jahren tragen.

## Architektur

Eine Godot-App (4.7, GL Compatibility), drei Spiele als Module, ein gemeinsamer Kern darunter. Die Spiele sprechen nie direkt miteinander, sondern nur über den Minispiel-Vertrag und die Karriere-Akte.

[eingebettetes Diagramm: Architektur · Hülle, drei Spiele, Vertrag, gemeinsamer Kern]

Der Spielleiter ist optional: Ohne ihn läuft alles aus dem Grundbestand und der lokalen Bibliothek. Mit ihm erfindet er Szenen für die Karriere und neue Lehren, die die Widerlegung vor der Ausgabe per Simulation prüft.

## Spec Phase 1: Widerlegung als Minispiel in Lobby-Loop

**Ergebnis der Phase:** Im Untersuchungsausschuss und in der Fraktionssitzung startet der Spielleiter eine Widerlegung. Sie läuft vollständig offline, nutzt die fünf vorhandenen Lehren und wirkt auf Fraktionsdisziplin und Inventar zurück.

**Was entsteht und was angefasst wird**

```
content/widerlegung/            NEU  die 5 Lehren als JSON (aus data.js übertragen)
scripts/core/widerlegung_rules.gd  NEU  reine Regeln: urteilen, nachbessern, Gewicht, Herzschlag
scripts/core/widerlegung_sim.gd    NEU  Simulation für Balance und später für die Prüfung erfundener Lehren
scripts/ui/widerlegung_panel.gd    NEU  Saal, Lehre, Hand, Prisma, Protokoll
scripts/core/event_applier.gd      EDIT start_minigame bekommt das Feld "game"
scripts/autoload/GameState.gd      EDIT start_minigame(game, params) statt ohne Angabe
gm-proxy/src/schemas.ts            EDIT Enum um "widerlegung" erweitern
test/gut/test_widerlegung.gd       NEU  Regeltests
test/golden/widerlegung.json       NEU  200 Partien aus der JS-Fassung als Vergleich
```

**Der Minispiel-Vertrag** gilt ab jetzt für jedes Minispiel, auch für das Beleidigungsfechten und später für DAME:

```
Befehl vom Spielleiter:
{ "type": "start_minigame", "game": "widerlegung", "params": { "lehre": "amt", "seed": "..." } }
fehlt "game"  -> "beleidigungsfechten" (abwärtskompatibel)

Ergebnis an die Engine:
{ "game": "widerlegung", "won": true, "score": 14,
  "effects": [ { "type": "modify_stat", "stat": "discipline", "delta": 1 },
               { "type": "add_item", "item": "weggefallener_paragraph" } ],
  "chronik": "Definition 'Lobbyist' bei Wurf 5 eingestürzt, 2 Ausnahmen" }
```

Die Effekte nutzen das vorhandene Befehls-Enum. Das Minispiel ändert den Spielstand also nie direkt, sondern nur über den `EventApplier`. Das hält die Regel aus der Spezifikation ein, dass Fraktionsdisziplin nur über Spielmechanik verändert wird.

**Tests**

- Die 13 vorhandenen Regeltests werden als GUT-Tests übertragen, inklusive der Invariante mit 10.000 Zufallszügen.
- **Gleichheitstest:** 200 Partien mit festen Seeds liefern in Godot exakt dieselben Züge, Lasten und Punkte wie in der JS-Fassung. Das fängt jeden Übertragungsfehler.
- Der alte `start_minigame` ohne `game` startet weiterhin das Beleidigungsfechten.
- Offline-Modus: Die Widerlegung braucht keinen Spielleiter-Aufruf, um gespielt zu werden.

**Abnahme**

- [ ] Alle GUT-Tests grün, Gleichheitstest 200/200
- [ ] Widerlegung aus einer Szene startbar, Ergebnis ändert Disziplin und Inventar über den `EventApplier`
- [ ] Ohne Netz vollständig spielbar
- [ ] Ein Durchgang dauert 3–6 Minuten (eine Lehre)

## Spec Phase 2: Der Spielleiter erfindet Lehren

**Ergebnis der Phase:** Zu jeder Szene kann der Spielleiter eine neue Lehre erfinden. Die App spielt sie vor der Ausgabe auf dem Gerät durch und lässt nur spielbare zu. Was nicht besteht, wird ersetzt, nie ausgeliefert.

**Der Ablauf einer neuen Lehre**

1. Der Proxy ruft einen neuen Endpunkt `POST /lehre/generate` auf, mit Szene, Gegner und Karriere-Stand. Strukturierte Ausgabe nach festem Schema, wie die anderen Spielleiter-Aufrufe (ADR 0007).
2. **Formprüfung:** Das Schema stimmt, 8–12 Merkmale, Startlehre mit 2–3 Bestimmungen, Prisma mit 5–7 Merkmalen, 15–22 Karten, jede mit Begründungssatz.
3. **Logikprüfung:** Die Referenzfälle passen zur Startlehre, keine doppelten Karten, keine unbekannten Merkmale. Die Engine prüft das schon heute beim Laden.
4. **Spielbarkeitsprüfung:** 300 simulierte Partien. Zugelassen wird nur, was in diesen Bändern liegt:
   - Gelegenheitsspieler 55–80 % Einsturz, Zufallsspieler unter 35 %
   - In mindestens 60 % der Partien entsteht eine Ausnahme
   - Mindestens 3 Kartenpaare (Ding scheitert an genau einem Merkmal, Mitglied ohne dieses Merkmal)
   - Die Tragfähigkeit wird von der Simulation gesetzt, nie vom Sprachmodell
5. Besteht die Lehre nicht, bekommt der Spielleiter einmal den Befund zurück („zu leicht, keine Paare") und bessert nach. Danach greift die Bibliothek bereits geprüfter Lehren.
6. **Bestandene Lehren werden lokal archiviert** und wachsen zu einer persönlichen Bibliothek. Offline spielt man aus dieser Bibliothek.

**Das Wahrheitsproblem:** Ein Sprachmodell kann behaupten, ein Hai lege Eier. Drei Schutzschichten:

- Jede Karte trägt ihren Begründungssatz. Die Wahrheit steht als „laut Akte" auf der Karte, und das passt zur Satire: Das Amt kennt nur seine Akten.
- Ein Knopf **„Einspruch"** markiert eine Karte als falsch. Sie wird aus dieser Lehre entfernt und nie wieder verwendet.
- Begriffe mit eindeutiger Wahrheit (Biologie, Gegenstände) bevorzugt der Spielleiter. Strittige Begriffe („Kunst", „Spiel") laufen als ausgewiesene Sonderlehren.

**Abnahme**

- [ ] Von 20 erfundenen Lehren bestehen mindestens 12 die Prüfung direkt oder nach einer Nachbesserung
- [ ] Die Prüfung dauert auf einem Mittelklasse-Handy unter 3 Sekunden
- [ ] Ohne Netz spielt man aus Bibliothek und Grundbestand, ohne Fehlermeldung

## Spec Phase 3 und 4: das Zentrum und das Hinterzimmer

**Phase 3: eine App, ein Hauptmenü.** Ergebnis: Eine Godot-App startet in den Flur des Amts. Von dort führen drei Türen in die Karriere, den Hörsaal (Widerlegung einzeln) und das Hinterzimmer.

- **Neues gemeinsames Projekt** statt Zusammenkopieren: ein Repo `latte-app`, in das Lobby-Loop und DAME als Godot-Addons einziehen (`addons/lobby_loop/`, `addons/dame/`). So bleiben beide Repos für sich lauffähig, bis der Umzug fertig ist.
- **Gemeinsamer Kern aus DAME:** `profile_service`, `save_service`, `settings_service`, `stats_service`, `audio_service`, `purchase_provider`, `i18n` wandern in `addons/amt_core/`. DAME nutzt sie dann von dort, Lobby-Loop ersetzt damit sein eigenes `SaveManager`.
- **Renderer vereinheitlichen:** Lobby-Loop läuft heute mit Forward Plus, DAME mit GL Compatibility. Die App nimmt GL Compatibility, weil nur das im Browser und als installierbare Web-App läuft. Lobby-Loop ist 2D, der Wechsel kostet dort fast nichts.
- **Eine Karriere-Akte für alles:** Das Format aus ADR 0005 bekommt je Spiel einen Abschnitt. Die Registratur schreibt am Ende über alle drei Spiele.

**Phase 4: DAME als Hinterzimmer.** Ergebnis: DAME läuft unverändert in seinen Regeln, aber in der Welt des Amts.

- **Neue Kosmetik statt neuer Regeln:** ein Hinterzimmer-Tisch (Aktenschränke statt Bar), Kartenrücken mit Aktenzeichen, Figuren als Beamte. Das Casino bleibt als wählbarer Tisch erhalten.
- **Chips werden Gefälligkeiten.** Gleiche Regel wie heute: nur erspielt, nie gekauft, nur für Kosmetik und kleine einmalige Karriere-Vorteile.
- **Minispiel-Vertrag:** Aus der Karriere gestartet, läuft eine Partie gegen die Computergegner und meldet `won`, `score` und Effekte zurück wie die Widerlegung.
- **Online bleibt eigenständig:** Partien gegen echte Menschen zählen in der Statistik, aber nie in einer Karriere. Sonst würden Verbindungsabbrüche Karrieren beenden.

**Abnahme Phase 3 und 4**

- [ ] Alle Tests beider Projekte laufen im gemeinsamen Repo grün (DAME: 565 Checks)
- [ ] Ein Spielstand, ein Profil, eine Einstellungsseite für alle drei Spiele
- [ ] Web-Build unter 70 MB, läuft als installierbare Web-App
- [ ] DAME aus der Karriere spielbar, Online-Partien zählen nicht in Karrieren

## Geld ohne Gier: das Geschäftsmodell

**Empfehlung: einmal kaufen, nie zahlen müssen.** Ein Spiel, das „für immer" da sein soll, darf seine Spieler nicht melken. Dauerhafte Spiele verdienen über Vertrauen und Weiterempfehlung.

| Baustein | Was | Warum |
| --- | --- | --- |
| Kostenlose Web-Fassung | Akademie (erste Widerlegung) und DAME gegen den Computer | Wer es spielt, versteht es. Das ist die einzige Werbung, die bei diesem Spiel funktioniert |
| Vollversion, einmal kaufen | Karriere, alle Lehren, Hinterzimmer, Online | Ein Preis, kein Abo. Veröffentlichung auf itch.io und Steam (Windows), die Web-App für Käufer |
| Kosmetik, freiwillig | Tische, Kartenrücken, Siegel | Die Kaufschnittstelle aus DAME existiert schon. Nie kaufbare Spielvorteile, nie kaufbare Gefälligkeiten |
| Gedruckte Fassung | Widerlegung und DAME als echte Kartenspiele | Kartenspiele am Tisch sind die langlebigste Form. Gleiche Regeln, gleiche Marke |

**Das Kostenproblem des Spielleiters:** Lobby-Loop nutzt heute das kostenlose Kontingent von Gemini mit deinen Schlüsseln. Das trägt keine öffentliche Veröffentlichung, weil jeder Spieler Aufrufe auf deine Rechnung erzeugen würde. Deshalb:

- **Offline zuerst:** Die Vollversion ist ohne Spielleiter komplett spielbar (Grundbestand, Bibliothek, feste Dialoge). Das ist in Lobby-Loop schon so angelegt.
- **Spielleiter mit eigenem Schlüssel:** Wer will, trägt einen eigenen API-Schlüssel ein. Kosten und Datenschutz liegen dann beim Spieler.
- **Später prüfen:** ein kleines Spielleiter-Abo, erst wenn klar ist, wie viele Aufrufe ein Abend wirklich braucht.

## Erweiterungen darüber hinaus

Nach Phase 4, ungefähr nach Hebelwirkung geordnet. Jede passt in den Minispiel-Vertrag oder nutzt die vorhandene Welt.

**Mehr Spiel aus vorhandenen Regeln**

- **Huhn-Duell:** Einer spielt Platon und bessert selbst nach, der andere wirft. Gleicher Netz-Kern wie DAME online. Die stärkste Quelle für Langzeitspaß.
- **Lehren-Werkstatt:** Spieler bauen eigene Lehren, die Simulation vergibt ein Prüfsiegel. Teilen per Code.
- **Wochenlehre:** eine vom Spielleiter erfundene Lehre pro Woche, für alle gleich, mit Rangliste. Erst sinnvoll, wenn es Spieler gibt.

**Neue Minispiele aus dem Manifest** (jedes ein eigener Mechanismus, alle im selben Vertrag)

- **Garbo, der Bericht:** Erfinde Agentenberichte, die in sich stimmig sind und zu dem passen, was die Zentrale glauben will. Die Zentrale prüft Fahrpläne und Zeitungen.
- **Köpenick, die Uniform:** Auftreten unter Zeitdruck. Wer zögert oder das falsche Abzeichen zeigt, wird nach Papieren gefragt.
- **Vasa, der Stapel:** Prunk auf ein Schiff laden, das bei Windstärke null kentert. Ein Physikspiel über Gier.
- **Poyais, das Land:** Ein Land verkaufen, das es nicht gibt. Je detaillierter die Bürokratie, desto höher der Kurs der Anleihe, bis die ersten Siedler ankommen.

**Welt und Marke**

- **Historische Kapitel:** Erfurt 1184, Stockholm 1628, Boston 1919 als Karriere-Szenarien mit eigenem Ende.
- **Division 7B als Erweiterung:** die metaphysische Abteilung mit dem Entitäten-Bestiarium als eigene Abteilung des Amts.
- **Karriere-Akte als echtes Dokument:** am Ende als PDF im Stil der Freistellungsurkunde aus der Boden-Inspektion.
- **Gedruckte Spiele:** Widerlegung und DAME als Kartenspiele, die Boden-Inspektion als Verkaufskanal.

**Zugänglichkeit**

- Englische Fassung (DAME ist schon zweisprachig), Bildschirmleser, Steuerung nur mit Tastatur, große Schrift.

## Fahrplan

Vier Phasen, jede endet an einem messbaren Tor. Erst wenn das Tor erreicht ist, beginnt die nächste. Jede Phase hinterlässt etwas Spielbares.

[eingebettetes Diagramm: Fahrplan · 4 Phasen, je ein Tor, danach Erweiterungen]

Die Reihenfolge schützt DAME: Es zieht erst in Phase 3 um, wenn die Widerlegung in Lobby-Loop läuft und der Vertrag erprobt ist. Bis dahin bleibt jedes Repo für sich lauffähig.

## Konfidenz- und Lückenreport

**Konfidenz**

- **Hoch:** Widerlegung und Lobby-Loop passen thematisch und technisch zusammen. Beide sind Godot-tauglich, der Minispiel-Vertrag baut auf dem vorhandenen Befehls-Enum auf.
- **Hoch:** Die Simulation als Prüfer für erfundene Lehren funktioniert. Die Balance der fünf Lehren wurde genau so eingestellt.
- **Mittel:** DAME als Hinterzimmer. Die Regeln bleiben, aber Ton und Look ändern sich. Das ist eine Geschmacksfrage, die nur du entscheiden kannst.
- **Mittel:** Wie oft ein Sprachmodell spielbare Lehren erfindet. Geschätzt, nicht gemessen.

**Risiken**

| Stufe | Risiko | Gegenmittel |
| --- | --- | --- |
| P1 | DAME wird beim Zusammenlegen beschädigt, obwohl es live und fertig ist | Umzug erst in Phase 3, als Addon, alle 565 DAME-Checks müssen im neuen Repo grün sein, das alte Repo bleibt bis dahin die Quelle |
| P1 | Spielleiter-Kosten bei öffentlicher Veröffentlichung | Offline zuerst, Spielleiter nur mit eigenem Schlüssel |
| P2 | Erfundene Karten sind sachlich falsch | Begründungssatz auf jeder Karte, Einspruch-Knopf, eindeutige Begriffe bevorzugt |
| P2 | Alles hängt am Tempo von Lobby-Loop, dem jüngsten Projekt | Phase 1 ist klein und für sich nützlich; die Widerlegung bleibt auch einzeln spielbar |
| P2 | Renderer-Wechsel in Lobby-Loop (Forward Plus → GL Compatibility) | 2D-Spiel, geringer Aufwand; früh in Phase 1 prüfen |
| P3 | Vorteile aus einem Spiel machen das andere zur Pflicht | Vorteile klein und einmalig halten |

**Lücken und offene Fragen**

- Ich habe den Code nicht vollständig gelesen, nur Struktur, Spezifikationen, Entscheidungen und Kernskripte. Vor Phase 1 nachzusehen: `scripts/ui/minigame_panel.gd` und `GameState.start_minigame()` in Lobby-Loop.
- Lobby-Loop setzt in Entscheidung ADR 0007 noch nicht geprüfte Modellnamen voraus (geprüft 12.10.2026: korrekt ist `gemini-3-flash-preview`, behoben; danach umgestellt auf die stabilen `gemini-3.8-flash` / `gemini-3.5-flash-lite`).
- **Deine Entscheidungen:** der App-Name, ob DAME den Amts-Look bekommen soll, und ob eine gedruckte Fassung ein echtes Ziel ist.
