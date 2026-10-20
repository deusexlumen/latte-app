# Docs

Seit 2026-10-20 ist latte-app die einzige Quelle. Die Dokumente der früheren Einzel-Repos liegen hier mit.

| Ort | Inhalt |
|---|---|
| `entwicklung.md` | Aufbau, Befehle, Tests (Einstieg für Entwickler) |
| `fahrplan-2026-10.md`, `e0` bis `e4`, `spieltest-bank-01.md` | Stand und Etappen der gemeinsamen Welt |
| `grundlagen/` | Spezifikation 0.1, systemisches Design, systemtheoretische Analyse |
| `gestaltung.md`, `bilder/` | Gestaltungsleitlinie, Bildschirmfotos |
| `konzept/` | Gesamtkonzept „Die Latte liegt am Boden" (aus `lobby-loop`; Geld- und Einzel-App-Teile überholt, siehe `../CLAUDE.md`) |
| `lobby-loop/` | CONTEXT (Glossar), LOBBY-LOOP, DEPLOY (GM-Proxy), plan, ADRs (`adr/`), Session-Notizen |
| `dame/` | README, Regeln (CONCEPT_DECISIONS), Online-Plan, alte Pläne und Specs, Session-Notizen |

## Alte Pfade lesen

Die Texte in `lobby-loop/` und `dame/` nennen Pfade der alten Repos. So findest du sie hier:

| Alter Pfad | In latte-app |
|---|---|
| `lobby-loop`: `scripts/…`, `content/…`, `scenes/…`, `test/…`, `data/…` | `addons/lobby_loop/…` |
| `lobby-loop`: `gm-proxy/`, `tools/*.ts`, `tools/lehre/`, `vendor/` | gleicher Pfad im Wurzelordner |
| `Dame-Card-Game`: `godot/scripts/services/…`, `godot/scripts/i18n.gd` | `addons/amt_core/…` |
| `Dame-Card-Game`: `godot/…` (Rest) | `addons/dame/…` |
| `Dame-Card-Game`: `src/` (alte React-App) | nicht übernommen, nur im archivierten Repo |

Anweisungen in `dame/AGENTS.md`, `dame/CLAUDE.md` und `lobby-loop/AGENTS.md` galten für die alten Repos. Für latte-app gilt `../CLAUDE.md`.
