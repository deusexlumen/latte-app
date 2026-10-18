# Latte — Session Notes

- [x] **2026-10-12 — Phase 3 (Plan in `../point and pen/plan.md`) umgesetzt, lokal, kein GitHub-Repo:**
  **M1 Spike:** Lobby-Loop im Web 39 MB, SQLite im Web nicht nötig (JSON-Fallback). **Gemeinsamer Web-Build 49 MB** (Ziel < 70 MB), läuft in Chromium, alle drei Türen geprüft.
  **M2–M4:** `tools/sync-games.mjs` baut beide Spiele per `git archive` und Pfadtabelle ein. Keine Kollisionen bei Klassen, Autoloads, user://-Dateien, UIDs. **Tests:** DAME 9574 Checks/15 Suites + FLOW_OK (identisch zur Baseline; der Plan nannte veraltet 565), Lobby-Loop 140/140, Latte 13/13.
  **Abweichung vom Plan (M3):** „DAME-Checks im alten Repo gegen die neue Quelle" hätte das alte Repo von latte abhängig gemacht. Stattdessen laufen DAMEs Checks in latte gegen `addons/amt_core` (über die Pfadtabelle).
  **M5:** Ein Spielstand: App-`SaveManager` über `JsonStore`, Migration alter App-Daten (einmalig, Marker `user://migration.json`).
  **M6/M7:** Flur (Karriere, Hörsaal, Hinterzimmer, Akte, Einstellungen), Hörsaal ohne Karriere-Effekte, `LatteAkte` mit einem Abschnitt je Spiel, Knopf/Esc „Zum Flur".
  **Gefundene Fehler:** Panels in Lobby-Loop klebten oben links (`set_anchors_preset` ohne Offsets) — in Lobby-Loop behoben (Commit d4eca27) und gesynct. DAMEs globales Theme machte den Flur-Knopf unsichtbar — eigenes Aussehen.
  **Bekannt:** DAME setzt `root.theme` app-weit, das verändert auch Lobby-Loops Schrift. DAMEs Einstellungsseite kehrt zu DAMEs Menü zurück, nicht zum Flur („Zum Flur" bleibt verfügbar).
  **Offen (LO):** installierbare Web-App auf dem Handy prüfen; GitHub-Repo anlegen nur auf Anfrage; vor eigenen Änderungen an Spiel-Code in latte `sync-manifest.json` auf `"source": "latte-app"` setzen.

- [x] **2026-10-12 — Nachprüfung Phase 3 (Rückweg, Wiedereintritt, Testspuren):**
  **Rückweg-Knopf** jetzt unten rechts (gemessen frei: Lobby-Inventar unten links, DAME-Hand unten Mitte), ausgeblendet im Flur, am DAME-Tisch und solange in Lobby-Loop ein Dialog offen ist; Esc ebenso.
  **Wiedereintritt:** Flur → Karriere → Flur → Karriere meldete `already connected` (Würfel-Signal). In Lobby-Loop behoben (Commit f48b8fc), Regressionstest dort, Fluss-Test `tools/reentry_smoke.gd` hier (jede ERROR-Zeile zählt).
  **Testspuren:** Headless läuft keine Migration mehr; Fluss-Test schreibt nur Testdateien. Vorher hatten Testläufe die echte Migration samt Marker ausgelöst und einen Spielstand angelegt; beides entfernt, `app_userdata/Latte` enthält nur Testdateien. Die echte Migration passiert beim ersten richtigen Start.
  **Quellen fest:** DAME aus Branch `feat/online-webrtc` (enthält main plus Online-Test), Lobby-Loop aus `master`.
  **Stand:** DAME 9574/15 + FLOW_OK, Latte-Fluss OK, Lobby-Loop 141/141, Latte 13/13.

- [x] **2026-10-12 — Phase 4 umgesetzt (LO: „so wie du sagst"):** Entscheidungen: Amts-Look als zusätzliche Kosmetik, Casino wählbar; Verknüpfung als eigener latte-Code, alte Repos bleiben Quelle.
  **DAME-Repo (a84f2db, Branch feat/online-webrtc):** Kategorie Raum (Casino / Amtsstube: Linoleum, graue Wände, Aktenschränke mit Ordnern statt Bar), Kartenrücken „Akte" (Aktenzeichen, Eingangsstempel), Tischfilz Amtsgrün, Signal `App.match_finished`, `I18n.de_overrides`. 9591 Checks.
  **Lobby-Loop (08f14db, bbf1766):** `MinigameContract.register_external` (ohne Gastgeber startet nichts), Item-Feld `once` (Eingeforderter Gefallen +2, einmal), Tür zum Hinterzimmer in der Aufsichtsratssitzung, Proxy kennt `dame`. 145 Tests.
  **latte (`app/hinterzimmer.gd`):** Karriere-Partie gegen 3 KI (mittel), Ergebnis nach Vertrag (Sieg: Disziplin +1 und „Notiz aus dem Hinterzimmer", Niederlage −1), danach zurück in die Karriere. Online- und freie Partien zählen nie. Chips heißen Gefälligkeiten. Amtsstube + Akte-Rücken beim ersten echten Start geschenkt. Akte: „Gefallen einfordern" für 100 Gefälligkeiten.
  **Nicht umgesetzt:** „Figuren als Beamte" bräuchte neue 3D-Kleidung/Texturen (Kunst-Assets), nicht per Code machbar.
  **Bekannt:** Führt eine verlorene Hinterzimmer-Partie zum Perma-Death, wird der Stand korrekt zurückgesetzt, der „Mandat verloren"-Schirm erscheint aber nicht (die Karriere-Szene ist während der Partie nicht geladen).
  **Tests:** DAME 9591/15 + FLOW_OK, Latte-Fluss (inkl. Karriere → DAME-Tisch → Karriere), Lobby-Loop 145, Latte 21. Headless schreibt die App nie in echte Spielstände.

- [x] **2026-10-18 — Spezifikation 0.1 „gemeinsame Spielwelt“: E0 und E1 (Cloud-Sitzung, Linux, Godot 4.7.2):**
  **E0** in `docs/e0-bestandspruefung.md`: Lobby-Loop eindeutig `deusexlumen/lobby-loop` master (lokal `../point and pen`, gleiche Historie). latte baut DAME aus `feat/online-webrtc` @ a84f2db, der Stand liegt nicht in DAME-`main`. Huhn-Port: `vendor/huhn` = Archiv bis auf eine dokumentierte Exportzeile, Golden-Test vorhanden. DAME kann Partien fortsetzen. Eine Bank-Lehre fehlt noch.
  **E1** in `docs/e1-bank-01.md`: Weltkern `world_core/` (jede Änderung als Ereignis mit Operationen; Nachspielen ergibt denselben Zustand), Vorgang `cases/bank_01/`, Klickprototyp `amt/vorgang.tscn` hinter der neuen Flur-Tür „Innenhof“. T-01 bis T-08, Pfade A/B/C, QA-01 bis QA-17 als Tests; Minispiel-Ausgänge nur über die Entwicklungsansicht. 14 neue Entwurfsentscheidungen dort aufgelistet.
  **Tests:** DAME 9495/15 (Notizen nannten 9591; unter Linux zweimal 9495) + FLOW_OK, Latte-Fluss inkl. Innenhof, Lobby-Loop 145, Latte 67 (vorher 21).
  **Offen:** E2 (Bank-Lehre, Ergebnis-Adapter), `feat/online-webrtc` nach DAME-`main`, Sync-Pfad für beide Ordnernamen.

- [x] **2026-10-18 — E2 der gemeinsamen Welt: Widerlegung im Ausschuss (`docs/e2-widerlegung.md`):**
  Bank-Lehre `cases/bank_01/lehre/bib_bank_01.json` (20 Karten, Prisma ohne die Referenz „bereitgestellt“); der Validator setzt `cap` 11 und 7 Würfe (überlegt 64,7 % Einsturz, Zufall 22,7 %, Ausnahmen 99 %). Mitglied ⇔ „bereitgestellt“ ist getestet.
  Vorgang: Jede Karte geht als `minigame_play` an den Vorgang, Ergebnisse gelten nur, wenn Seed und Kartenfolge sie erklären; Fortsetzen und Abbruch ohne neue Hand; kein Einspruch im Bank-Panel; Panel-Effekte werden nie übernommen. DAME bleibt Platzhalter bis E3.
  Parität: 200 Partien auf der Bank-Lehre, JS-Engine gegen Godot-Port, 200/200 gleich. Die Kopie in lobby-loop/vendor/huhn und das hochgeladene Archiv liefern dasselbe Golden.
  **Tests:** Latte 87 (vorher 67); DAME 9495/15 + FLOW_OK, Latte-Fluss, Lobby-Loop 145. **Offen:** E3 (echte DAME-Partie, räumlicher Übergang, Spieltest).
