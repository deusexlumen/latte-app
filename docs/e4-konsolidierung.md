# E4 – Konsolidierung (vorgezogen)

**Bezug:** Spezifikation 0.1, Kap. 19 (E4), 24
**Stand:** 18. Oktober 2026

## Web-Export mit den neuen Dateien

Preset „Web“ gebaut (`godot --headless --path . --export-release "Web" build/web/index.html`, Vorlage `web_nothreads_release`), ausgeliefert über einen statischen Server und in Chromium (Playwright, Software-GL) gesteuert:

- Der Flur startet ohne Konsolenfehler. Die Autoloads `Uebergang` und `VorgangDame` laden.
- Innenhof öffnet, Falldaten und Texte (`bank_01.json`) sind im Paket; „Gehen nach“ führt in den Innenhof, Frau Kern und die Handlung „Sperrung klären“ erscheinen.
- **Speichern im Browser funktioniert:** Nach Ortswechsel und Neuladen steht der Vorgang wieder im Innenhof.
- **Befund:** Der Browser-Speicher wird asynchron geschrieben. Wer unmittelbar nach einer Handlung (unter etwa zwei Sekunden) neu lädt oder den Tab schließt, kann diese eine Handlung verlieren; nach sechs Sekunden Wartezeit blieb sie erhalten. Für den Spieltest bleibt der Desktop-Build maßgeblich.
- Nicht geprüft: Ton im Browser, eine vollständige Partie DAME im Web, Widerlegung im Web.

## Aufräumpunkte

| Punkt | Ergebnis |
|---|---|
| `sync-games.mjs` und Ordnername | `findRepo` nimmt `point and pen` oder `lobby-loop`, der erste vorhandene gewinnt; Test in `sync-games.test.mjs` |
| DAME 9495 gegen 9591 Checks | **Geklärt:** Ohne WebRTC-Erweiterung werden die Verbindungstests übersprungen (9495). Mit ihr laufen sie zusätzlich (Notizen: 9591, unter Windows). Nachgestellt: DAME-Repo mit entfernter Erweiterung ergibt 9495/15, mit Erweiterung laufen in der netzlosen Umgebung die Verbindungstests in Zeitüberschreitung. Latte hat die Erweiterung nicht im Paket (`addons/webrtc` ohne `lib`) |
| `feat/online-webrtc` nach `main` | PR #15 enthielt vier Commits nicht (Amts-Look, `match_finished`, TURN). Dame-Card-Game#17 gemergt (`a5e503d`, CI ohne Fehler). `sync-games.mjs` baut DAME jetzt aus `main`; neu synchronisiert, der Inhalt entspricht dem bisherigen Stand (a84f2db) |
| Lobby-Loop-Stand | Neu synchronisiert auf `dac5b0b` (vorher `bbf1766`); geändert ist nur `plan.md` |

## Offen
- Spieltest und dessen Überarbeitung, dann E5.
