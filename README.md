# Latte

**Die Latte liegt am Boden** als eine App: Flur des Amts mit drei Türen.

| Tür | Spiel | Quelle |
|-----|-------|--------|
| Karriere | Lobby-Loop (Point-and-Click-RPG mit KI-Spielleiter) | `../point and pen` |
| Hörsaal | Widerlegung einzeln, Lehre frei wählbar, ohne Karriere-Effekte | eigener Code (`hoersaal/`) |
| Hinterzimmer | DAME (Kartenspiel) | `../Dame-Card-Game/godot` |

Dazu **Akte** (ein Abschnitt je Spiel) und **Einstellungen** (DAMEs Seite, gilt app-weit).

## Aufbau

- `addons/dame/`, `addons/lobby_loop/`, `addons/amt_core/` werden von `tools/sync-games.mjs` **erzeugt**, nie von Hand ändern.
  Quelle ist jeweils der letzte Commit des Spiel-Repos; `sync-manifest.json` hält die Hashes fest.
  DAMEs Dienste (`json_store`, `save_service`, `settings_service`, …) und `i18n.gd` landen als gemeinsamer Kern in `addons/amt_core/`.
- Eigener Code: `app/` (Migration, SaveManager, Rückweg-Knopf, Akte, Hörsaal-Statistik), `flur/`, `hoersaal/`, `akte/`, `test/`.
- `SaveManager` der App ersetzt Lobby-Loops Autoload (gleiche Schnittstelle, speichert über `JsonStore`), Lobby-Loops Code bleibt unverändert.
- Beim ersten Start übernimmt `Migration` Daten der Einzel-Apps (`app_userdata/LOBBY-LOOP`, `app_userdata/Dame`). Kopiert nur, löscht nie.

## Befehle

```bash
npm run sync   # Spiele aus den Repos neu einbauen
npm test       # Werkzeug-Tests, DAME-Runner + Szenenfluss, Lobby-Loop-GUT, latte-GUT
```

Web-Export (Preset „Web", ohne Threads und ohne GDExtensions): `build/web/`, 49 MB.
