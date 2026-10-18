# E0 – Bestandsprüfung

**Bezug:** Spezifikation „Die Latte liegt am Boden – gemeinsame Spielwelt“ 0.1, Kap. 19 (Etappe E0) und 21.3
**Geprüft:** 18. Oktober 2026, Cloud-Sitzung (Linux), Godot 4.7.2-stable Linux heruntergeladen
**Abnahmetor E0:** Jeder Integrationspunkt besitzt eine geprüfte Quelle; keine unklare Lobby-Loop-Arbeitskopie.

Alle Zahlen unten sind in dieser Sitzung gemessen, nicht aus älteren Notizen übernommen. Wo Notizen abweichen, steht es dabei.

## 1. Repositories

| Repository (GitHub) | Geprüfter Stand | Rolle | Status für die Welt |
|---|---|---|---|
| `deusexlumen/latte-app` | `main` @ 42dedbf (12.10.) | Gastgeber-App „Latte“: Flur, Hörsaal, Akte; baut DAME und Lobby-Loop als Addons ein | **aktiv**, Ort von E1 |
| `deusexlumen/lobby-loop` | `master` @ dac5b0b (12.10.) | Lobby-Loop (Karriere, Minispiel-Vertrag, Widerlegung als GDScript-Port) | **aktiv**, Quelle für `addons/lobby_loop` |
| `deusexlumen/Dame-Card-Game` | `main` @ 489a609 (07.10.), Branch `feat/online-webrtc` @ a84f2db (12.10.) | DAME; Hauptprojekt ist `godot/`, React-App nur Referenz | **aktiv**, Quelle für `addons/dame` und `addons/amt_core` |
| `deusexlumen/Dame---Strategic-Card-Game` | `main` @ c2b1d16 | AI-Studio-Prototyp (React, Gemini-Gegner) | nicht Teil der Integration |
| `deusexlumen/dame-kartenspiel` | `master` @ 7d77053 | DAME als Client/Server (React, Express, Socket.io, PostgreSQL) | nicht Teil der Integration |
| Das gerupfte Huhn | kein Repository; Archiv `das-gerupfte-huhn-projekt.zip` | JS-Original der Widerlegung | Referenz, eingebettet als `lobby-loop/vendor/huhn` |

### Eindeutige Lobby-Loop-Arbeitskopie

`latte-app/tools/sync-games.mjs` liest Lobby-Loop aus dem Nachbarordner `../point and pen`. Das ist der Ordnername auf dem Windows-Rechner; auf GitHub heißt das Repository `lobby-loop`. Beide sind dieselbe Historie: Der in `sync-manifest.json` festgehaltene Stand `bbf1766` ist Vorfahre von `lobby-loop/master`; danach kam nur ein Doku-Commit (`dac5b0b`). **Maßgeblich ist `deusexlumen/lobby-loop`, Branch `master`.**

Folge: In einer Umgebung, in der der Ordner `lobby-loop` heißt, läuft `npm run sync` nicht ohne Anpassung des Pfads. Für E1 war kein Sync nötig; der Pfad blieb unverändert.

### DAME: latte hängt an einem nicht gemergten Branch

latte baut DAME aus `feat/online-webrtc` @ a84f2db (Phase 4: Amtsstube, Kartenrücken „Akte“, Signal `App.match_finished`). Dieser Commit liegt **nur** auf dem Branch, nicht in `main`. `main` (489a609) kennt weder `match_finished` noch `room_amt`. Solange das so ist, ist der Branch die Quelle; ein Merge nach `main` würde die Lage eindeutig machen.

## 2. Engine und Laufzeit

| Punkt | Befund |
|---|---|
| Engine | Godot **4.7.2-stable** (Pfad in `tools/test-all.mjs`); alle drei Projekte: `config/features = ("4.7", "GL Compatibility")` |
| Renderer | `gl_compatibility` für Desktop und Mobil (latte `project.godot`) |
| Einstieg latte | `res://flur/flur.tscn`; Autoloads: Migration, App (DAME), SaveManager (latte), GameState/ApiClient/FallbackDb/DiceRoller (Lobby-Loop), FlurButton, Hinterzimmer |
| Fremd-Addons | GUT 9.6.1 und godot-sqlite aus dem Lobby-Loop-Arbeitsverzeichnis, webrtc aus DAME; nicht versioniert (`.gitignore`) |
| godot-sqlite | enthält nur Windows-Binärdateien; unter Linux Importfehler. latte läuft ohne (Lobby-Loop fällt auf JSON zurück, wie im Web-Export) |
| Testrunner | `npm test` erwartet `GODOT_BIN`; der Standardwert ist ein Windows-Pfad |

## 3. Testbaseline (gemessen)

| Lauf | Ergebnis vor E1 | Anmerkung |
|---|---|---|
| DAME-Runner | `ALL_TESTS_OK checks=9495 suites=15` | zweimal gleich. Die Notizen nennen 9591; die Ursache der Abweichung (Plattform?) ist nicht geklärt |
| DAME-Fluss | `FLOW_OK` | |
| Latte-Fluss | `REENTRY_OK` | streng: jede ERROR-Zeile zählt |
| Lobby-Loop GUT | 145 bestanden | enthält den Golden-Test der Widerlegung |
| Latte GUT | 21 bestanden | nach E1: 67 |
| Huhn JS (`node test/engine.test.js`) | 13 Tests grün | aus dem hochgeladenen Archiv, isoliert ausgeführt |

## 4. Integrationspunkte und ihre Quellen

| Integrationspunkt | Geprüfte Quelle | Befund |
|---|---|---|
| Minispiel-Vertrag | `lobby-loop/scripts/core/minigame_contract.gd` | `game_of()` ordnet Befehle ohne `game` dem Beleidigungsfechten zu (Kap. 16.4: Kompatibilität existiert). `register_external()` dockt Spiele einer Gastgeber-App an (latte: `dame`). |
| Ergebnisformat | dieselbe Datei, `widerlegung_result()` | Ergebnis trägt eine **Effektliste** (`add_item`, `modify_stat`). Kap. 16.5 entscheidet dagegen: Der Fall übersetzt nur den geprüften Ausgang. Für E2 braucht es einen Adapter; der Weltkern von E1 führt mitgeschickte Effekte nie aus (getestet, QA-14). |
| Widerlegung (Huhn-Port) | `lobby-loop/scripts/core/widerlegung_rules.gd`, Lehren in `content/widerlegung/*.json` | Port vorhanden; Gleichheit über `test_widerlegung_golden.gd` (200 Partien aus `vendor/huhn`). `vendor/huhn/engine.cjs` = `src/engine.js` aus dem Archiv bis auf eine dokumentierte Zeile (Export von `rnd`, `shuffle`); `data.cjs` identisch. **Eine Lehre für BANK-01 fehlt** (Kap. 9.7: 15–20 geprüfte Karten). |
| DAME-Partie | `Dame-Card-Game/godot/scripts/app.gd` (Branch `feat/online-webrtc`) | `App.new_match(config)`, Signal `App.match_finished(result)`; KI-Gegner in drei Stufen. |
| DAME fortsetzen | `scripts/services/save_service.gd`, `App.resume_match()` | `save_match`/`load_match` vorhanden. Kap. 17.1 nennt fehlende Fortsetzbarkeit als mögliches Hindernis; **sie existiert**. Ob sie im Vorgangskontext greift, ist Prüfbedarf für E3. |
| Hinterzimmer der Karriere | `latte-app/app/hinterzimmer.gd` | Karriere-Partie mit Effekten (Disziplin ±1, Gegenstand). Andere Logik als Kap. 8.3 (eine zweckgebundene Gefälligkeit); für BANK-01 nicht verwendet. |
| Speichern | `amt_core/services/json_store.gd` | atomar (tmp + rename), kaputte Datei wird als `.bak` gesichert. **Kein vorheriger Stand als Rückfall** (Kap. 17.1); den ergänzt `world_core/amt_store.gd`. |
| Akte | `latte-app/app/akte.gd` | ein Abschnitt je Spiel, reine Statistik; noch keine Vorgangsakte. |

## 5. Entscheidung für E1

E1 entsteht in **latte-app als eigener Code** (`world_core/`, `cases/bank_01/`, `amt/`). Die generierten Addons bleiben unangetastet, `sync-manifest.json` bleibt `"source": "repos"`. Begründung: Die Spezifikation verlangt, nicht vorschnell zusammenzukopieren (Kap. 15.1), und E1 braucht keine Änderung an DAME oder Lobby-Loop.

## 6. Offen für spätere Etappen

- **Vor E2:** Bank-Lehre (Kartenpool, Prisma, Startreferenzen, Tragfähigkeit, Wurfzahl) als getestetes Inhaltspaket; Adapter vom Vertragsergebnis (mit Effekten) zum Weltergebnis (ohne).
- **Vor E3:** DAME-Partie an eine Session des Vorgangs binden (Start, Fortsetzen, Ergebnis); gemeinsamer visueller Übergang; Screenreader-Befund für den Web-Export.
- **Aufräumen, unabhängig:** `feat/online-webrtc` nach `main` mergen; Pfad in `sync-games.mjs` für beide Ordnernamen; Ursache 9495 vs. 9591 DAME-Checks.
