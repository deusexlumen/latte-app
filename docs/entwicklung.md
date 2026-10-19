# Latte – Entwicklung

Technische Übersicht für alle, die am Code arbeiten. Die Einstiegsseite für Spielerinnen und Tester ist die [README](../README.md).

| Tür | Spiel | Quelle |
|-----|-------|--------|
| Karriere | Lobby-Loop (Point-and-Click-RPG mit KI-Spielleiter) | `../point and pen` oder `../lobby-loop` |
| Hörsaal | Widerlegung einzeln, Lehre frei wählbar, ohne Karriere-Effekte | eigener Code (`hoersaal/`) |
| Hinterzimmer | DAME (Kartenspiel) | `../Dame-Card-Game/godot` |
| Innenhof | Vorgang BANK-01 „Die gesperrte Bank“, Klickprototyp der gemeinsamen Welt (Etappen E1 bis E3: echte Widerlegung im Ausschuss, echte DAME-Partie im Hinterzimmer) | eigener Code (`world_core/`, `cases/`, `amt/`) |

Dazu **Akte** (ein Abschnitt je Spiel) und **Einstellungen** (DAMEs Seite, gilt app-weit).

Bestandsprüfung und Stand der gemeinsamen Welt: `e0-bestandspruefung.md`, `e1-bank-01.md`, `e2-widerlegung.md`, `e3-gemeinsame-erfahrung.md`, `e4-konsolidierung.md` (alle in `docs/`). Anleitung für den ersten Spieltest: `spieltest-bank-01.md`. Was als Nächstes kommt: `fahrplan-2026-10.md`.

## Aufbau

- `addons/dame/`, `addons/lobby_loop/`, `addons/amt_core/` werden von `tools/sync-games.mjs` **erzeugt**, nie von Hand ändern.
  Quelle ist jeweils der letzte Commit des Spiel-Repos; `sync-manifest.json` hält die Hashes fest.
  DAMEs Dienste (`json_store`, `save_service`, `settings_service`, …) und `i18n.gd` landen als gemeinsamer Kern in `addons/amt_core/`.
- Eigener Code: `app/` (Migration, SaveManager, Rückweg-Knopf, Akte, Hörsaal-Statistik), `flur/`, `hoersaal/`, `akte/`, `test/`.
- Weltkern: `world_core/` (ein Zustand, jede Änderung als Ereignis mit Operationen, Uhr, Aufmerksamkeit, Speichern mit Rückfall). Vorgänge unter `cases/<id>/` (Texte als JSON, Regeln als GDScript), Oberfläche unter `amt/`.
- `SaveManager` der App ersetzt Lobby-Loops Autoload (gleiche Schnittstelle, speichert über `JsonStore`), Lobby-Loops Code bleibt unverändert.
- Beim ersten Start übernimmt `Migration` Daten der Einzel-Apps (`app_userdata/LOBBY-LOOP`, `app_userdata/Dame`). Kopiert nur, löscht nie.

## Befehle

```bash
npm run sync   # Spiele aus den Repos neu einbauen
npm test       # Werkzeug-Tests, DAME-Runner + Szenenfluss, Lobby-Loop-GUT, latte-GUT
```

`npm test` braucht `GODOT_BIN` (Godot 4.7.2). Unter Linux fehlt godot-sqlite als Binärdatei; ohne `addons/godot-sqlite` laufen alle Tests (JSON-Rückfall wie im Web-Export).

Web-Export (Preset „Web", ohne Threads und ohne GDExtensions): `build/web/`, 49 MB.

## Veröffentlichung im Netz

`.github/workflows/pages.yml` exportiert bei jedem Push auf `main` den Web-Build und veröffentlicht ihn über GitHub Pages (Repo-Einstellung: Pages, Quelle „GitHub Actions“). In Pull Requests baut er nur und prüft, dass der Export gelingt. Fremd-Addons ohne Web-Bedeutung (GUT, godot-sqlite, webrtc) sind nicht versioniert und im Export ausgeschlossen; der Workflow braucht sie nicht.

## Rückmeldungen von Testern

Vorlage `.github/ISSUE_TEMPLATE/rueckmeldung.yml`. Für den formalen Spieltest BANK-01 gilt `spieltest-bank-01.md` (Desktop-Build, Auswertung über die Spielstand-Datei).
