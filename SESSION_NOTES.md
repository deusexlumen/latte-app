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
