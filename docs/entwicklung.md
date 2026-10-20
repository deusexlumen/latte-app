# Latte – Entwicklung

Technische Übersicht für alle, die am Code arbeiten. Die Einstiegsseite für Spielerinnen und Tester ist die [README](../README.md).

| Tür | Spiel | Quelle |
|-----|-------|--------|
| Karriere | Lobby-Loop (Point-and-Click-RPG mit KI-Spielleiter) | `addons/lobby_loop/` |
| Hörsaal | Widerlegung einzeln, Lehre frei wählbar, ohne Karriere-Effekte | eigener Code (`hoersaal/`) |
| Hinterzimmer | DAME (Kartenspiel) | `addons/dame/` |
| Innenhof | Vorgang BANK-01 „Die gesperrte Bank“, Klickprototyp der gemeinsamen Welt (Etappen E1 bis E3: echte Widerlegung im Ausschuss, echte DAME-Partie im Hinterzimmer) | eigener Code (`world_core/`, `cases/`, `amt/`) |

Dazu **Akte** (ein Abschnitt je Spiel) und **Einstellungen** (DAMEs Seite, gilt app-weit).

Bestandsprüfung und Stand der gemeinsamen Welt: `e0-bestandspruefung.md`, `e1-bank-01.md`, `e2-widerlegung.md`, `e3-gemeinsame-erfahrung.md`, `e4-konsolidierung.md` (alle in `docs/`). Anleitung für den ersten Spieltest: `spieltest-bank-01.md`. Was als Nächstes kommt: `fahrplan-2026-10.md`.

## Aufbau

- **Eine Codebasis seit 2026-10-20.** `addons/dame/`, `addons/lobby_loop/`, `addons/amt_core/` werden direkt hier bearbeitet. Die Repos `Dame-Card-Game` und `lobby-loop` sind archiviert, `npm run sync` bricht ab.
  DAMEs Dienste (`json_store`, `save_service`, `settings_service`, …) und `i18n.gd` landen als gemeinsamer Kern in `addons/amt_core/`.
- Eigener Code: `app/` (Migration, SaveManager, Rückweg-Knopf, Akte, Hörsaal-Statistik), `flur/`, `hoersaal/`, `akte/`, `test/`.
- Weltkern: `world_core/` (ein Zustand, jede Änderung als Ereignis mit Operationen, Uhr, Aufmerksamkeit, Speichern mit Rückfall). Vorgänge unter `cases/<id>/` (Texte als JSON, Regeln als GDScript), Oberfläche unter `amt/`.
- `SaveManager` der App ersetzt Lobby-Loops Autoload (gleiche Schnittstelle, speichert über `JsonStore`).
- Fremd-Addons `addons/gut/`, `addons/godot-sqlite/`, `addons/webrtc/` sind versioniert. Nur die iOS-Abhängigkeiten von godot-sqlite fehlen (je über 100 MB, siehe `.gitignore`).
- `gm-proxy/`: Node/TypeScript-Proxy zu Gemini für Lobby-Loops Spielleiter (Port 8787, Docker über `Dockerfile`, Anleitung `docs/lobby-loop/DEPLOY.md`). Node-Werkzeuge in `tools/*.ts`, eingebettete Bibliotheken in `vendor/`.
- Doku der früheren Einzel-Repos: `docs/lobby-loop/` (CONTEXT, LOBBY-LOOP, DEPLOY, plan, ADRs), `docs/dame/`, `docs/konzept/`. Übersetzung alter Pfade: `docs/README.md`.
- Beim ersten Start übernimmt `Migration` Daten der Einzel-Apps (`app_userdata/LOBBY-LOOP`, `app_userdata/Dame`). Kopiert nur, löscht nie.

## Befehle

```bash
pnpm install
npm test              # Werkzeug-Tests, DAME-Runner + Szenenfluss, Lobby-Loop-GUT, latte-GUT
pnpm run test:node    # GM-Proxy, Node-Werkzeuge, Secret-Check
pnpm run typecheck
pnpm run proxy:dev    # GM-Proxy lokal (braucht .env, Vorlage .env.example)
pnpm tsx --test gm-proxy/tests/<datei>.test.ts   # einzelner Proxy-Test
```

`npm test` braucht `GODOT_BIN` (Godot 4.7.2). Unter Windows meldet ein `WebSocketPeer` zu einem geschlossenen Port auch nach 15 Sekunden kein „geschlossen“ (gemessen 2026-10-20). Ist der Signaling-Dienst nicht erreichbar, zeigt DAME den Fehler deshalb erst nach `JOIN_TIMEOUT_MS` (10 Sekunden); `test_signaling` wartet entsprechend.

Web-Export (Preset „Web", ohne Threads und ohne GDExtensions): `build/web/`, 49 MB.

## Veröffentlichung im Netz

`.github/workflows/pages.yml` exportiert bei jedem Push auf `main` den Web-Build und veröffentlicht ihn über GitHub Pages (Repo-Einstellung: Pages, Quelle „GitHub Actions“). In Pull Requests baut er nur und prüft, dass der Export gelingt. Fremd-Addons ohne Web-Bedeutung (GUT, godot-sqlite, webrtc) sind im Web-Export ausgeschlossen. `.github/workflows/node.yml` prüft GM-Proxy und Node-Werkzeuge.

## Rückmeldungen von Testern

Vorlage `.github/ISSUE_TEMPLATE/rueckmeldung.yml`. Für den formalen Spieltest BANK-01 gilt `spieltest-bank-01.md` (Desktop-Build, Auswertung über die Spielstand-Datei).
