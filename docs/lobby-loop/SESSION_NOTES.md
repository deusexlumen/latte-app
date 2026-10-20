# LOBBY-LOOP — Session Notes

## Status

## Entscheidungen & Erkenntnisse

- **2026-09-19** — 10x-Session 2 (`.claude/docs/ai/lobby-loop/10x/session-2.md`) festgezogen:
  **Ship It zuerst** — gehosteter GM-Proxy (Auth, Rate-Limit, Build) als Gate für alles Weitere;
  **Plattform: Itch.io** (kostenlos, passende Satire-/Indie-Zielgruppe; kein Steam-Polishing nötig);
  danach **Registratur** (Meta-Archiv aller Karriere-Akten) + **Content-Sprint** (8–10 Knoten/Szene, ~15 Kombis inkl. Sackgassen);
  erst dann GM-Personas + Daily Scandal. **TTS bewusst verworfen** (schlechte deutsche Stimme schadet der Persona mehr).

- **2026-10-12** — Gesamtkonzept „Die Latte liegt am Boden" als Spec abgelegt (`docs/konzept/gesamtkonzept-latte.md`), Umsetzungsplan in `plan.md` (Phase 1 vollständig mit Code, Phase 2–4 als Meilensteine mit Toren).
  **Befund:** lokal `master` 1 voraus / 2 zurück gegenüber GitHub, Ship-It-Arbeit vom 19.09. noch unversioniert, `gm-proxy/src/schemas.ts` nur auf GitHub. Plan-Task 0 klärt das zuerst.
  **Offline-Lücke:** Ohne GM startet heute kein Minispiel (`FallbackDb` liefert immer `trigger_event: null`). Plan löst das über ein Knotenfeld `minigame`.
  **Offene Entscheidungen von LO:** Merge-Weg, jev-Branch mitnehmen, Belohnungsregel, Lehre je Szene (Vorschläge stehen in `plan.md`).

- [x] **2026-10-12 — Task 0 Phase 1 (Widerlegung):** Branch `feat/widerlegung`. Ship-It-Arbeit committet, `origin/master` und `origin/claude/jev-ai-model-review-b13v05` ohne Konflikt hineingemergt. Entscheidungen 3/4 nach Plan-Vorschlag (Belohnung, Lehre je Szene). **Baseline:** `pnpm test` 68 + 13 grün, Typecheck sauber, GUT 61/61.

- [x] **2026-10-12 — Tasks 1–7 Phase 1:** Renderer GL Compatibility (Sichtprüfung im Fenster steht noch aus), Huhn-Engine vendort, **Gleichheitstest 200/200 und 10/10 Vorgänge grün** (Hash/Zufall/Mischen/Regeln auf Anhieb bitgleich). Simulation Godot (Gelegenheit/Zufall): akademie 94/46, amt 70/21, erfurt 70/29, division7b 58/24, spiel 70/15 %. JS misst akademie Zufall 50 %, deshalb dort Band < 60 % statt < 42 % (nur diese Lehre).

- [x] **2026-10-12 — Tasks 8–12 Phase 1 umgesetzt (Branch `feat/widerlegung`, nicht gepusht):** Minispiel-Vertrag (`MinigameContract`), Panel, Verdrahtung in `main.gd`/`pnp_overlay.gd`, Knoten `zeugenstuhl` (amt) und `gesetzentwurf` (spiel), Akte zählt Widerlegungen, Proxy kennt `game`/`lehre` (Seed vom Modell wird verworfen). **Stand:** GUT 105/105, `pnpm test` 70 + 17 grün, Typecheck sauber, Contract-Test lokal 3/3 (Auth-Check aus). Headless-Durchlauf der echten Hauptszene (GameState -> Panel -> Akte -> Disziplin) OK.
  **Befund:** `test_failure_when_total_below_dc` (test_dice.gd) ist zufallsabhängig (W20 gegen DC 20, ~5 % rot) und war schon vorher so.
  **Offen für die Abnahme (Task 13, braucht LO):** Sichtprüfung unter GL Compatibility, Stoppuhr 3–6 Minuten, Klick-auf-Hotspot-Guard von Hand, Laterne in Akademie, danach `git push -u origin feat/widerlegung` und PR.

- [x] **2026-10-12 — Phase 2 umgesetzt (master, lokal, nicht gepusht):**
  **Modelle:** live geprüft (ai.google.dev + `GET /v1beta/models` + Testaufruf): jetzt `gemini-3.8-flash` (Primär) und `gemini-3.5-flash-lite` (Fallback), beide stabil ohne Abschaltdatum. `gemini-3-flash-preview` war nur Preview, `gemini-3.1-flash-lite` wird frühestens 7.5.2027 abgeschaltet.
  **M5 `POST /lehre/generate`:** eigener System-Prompt (`gm-proxy/prompts/lehre.md`), 16k Token-Budget, Proxy prüft Form, Referenzfälle und Kartenpaare vor (sofortiger Retry), `cap`/Seed vom Modell werden verworfen. Befund: Ohne ausdrücklichen `paarplan` baut das Modell keine Paare (0 Paare im ersten Versuch). Ein Objekt-Array im Schema löst bei Gemini 400 INVALID_ARGUMENT aus, deshalb Textliste.
  **M6–8:** `WiderlegungForge` (erfinden, im Thread prüfen, genau eine Nachbesserung), `WiderlegungLibrary` (`user://widerlegung_bibliothek/`, kaputter Index wird neu gebaut, Sperrliste), Einspruch-Knopf „!" im Panel (Referenzfälle nicht sperrbar, min. 12 Karten).
  **Entscheidung (Vorschlag, LO bestätigt?):** Mit Bibliothek ersetzt jede zweite Widerlegung (nach Seed) die Szenen-Lehre durch eine erfundene, damit die Bibliothek auch offline erreichbar ist. Der Spielleiter kann `lehre: "bibliothek"` anfordern.
  **M9 Prüfdauer:** binäre cap-Suche, Desktop nativ 0,9–1,5 s je Lehre (300 Bestätigungspartien je Strategie bleiben). Handy-Messung steht aus (LO).
  **Bugfix:** „Mandat verloren"-Schirm war bei jedem Spielstart sichtbar (auch im abgenommenen Stand). Behoben, Regressionstest `test_main_start.gd`.
  **Phase-3-Spike Web:** Web-Export (nothreads, PWA) **39 MB**, läuft in Chromium/WebGL2. SQLite-GDExtension bräuchte die dlink-Templates (nicht installiert); stattdessen liest `FallbackDb` im Web direkt aus `content/*.json`. Proxy sendet jetzt CORS (`GM_CORS_ORIGINS`), vorher hätte ein Browser-Build den Spielleiter nie erreicht.
  **Stand:** GUT 132/132, Proxy 81 + 17, Typecheck sauber.
  **Tor-Messung 12/20 (nicht erreicht):** Lauf 1: 6/20 (3.8 Flash; 10 im Proxy-Vorfilter gescheitert, deshalb Vorfilter entfernt). Lauf 2: 5/20 (3.8-Tageslimit nach ~20 Anfragen, Rest Flash-Lite). Lauf 3 und 4 nur Flash-Lite: 9/20 und 9/20 (Lauf 4: 3 direkt, 6 nach Nachbesserung). Stichprobe mit den echten Szenen-Themen des Spiels ("Szene: …", Flash-Lite): 4/6. Restliche Fehler: Kurve kippt zu abrupt / kein cap im Band, zu wenige Paare. Bänder bewusst nicht gelockert.
  **Weitere Fixes aus den Läufen:** Prüfung wählt ungültige Anker (refMembers/refNon) selbst neu; Proxy normalisiert IDs (`schüssel` → `schuessel`, `e-scooter` → `e_scooter`).
  **Option C umgesetzt (LO-Entscheidung):** Befunde nennen das gerissene Band mit Zahlen und Handlung („Zu viele Gegenbeispiele", „Zu wenige Ausnahmen", „Alles oder nichts", „Knapp vorbei"); cap-Suche 5–20; Prompt 6–10 Paare; Proxy nennt Ablehnungsgründe im Log; Nachbesserungs-Vorlage im Schema-Format. **Ergebnis (Flash-Lite):** 13, 14, 10, 10, 14 von 20; Läufe 7–10 = 48/80 = 60 %, also genau auf dem Tor. Rest-Fehler vor allem „Alles oder nichts" (Gewicht 3 je Ausnahme macht die Kurve stufig) und 0 Paare.
  **Entscheidung LO (12.10.2026): Die Prüfung setzt neben cap auch die Würfe** (`WUERFE_OPTIONS` 7, 6, 8, 5, 9). Offline an 33 gescheiterten Entwürfen: 16 bestehen. Live (Flash-Lite): **17/20 und 14/20 → Tor erreicht.** „Alles oder nichts" kommt nicht mehr vor; Rest: zu wenige Paare (4), zu wenige Gegenbeispiele (2).
  **Preis:** Prüfdauer Desktop Median 1,4–2,6 s, Ausreißer 7,3 s. Die Handy-Vorgabe (unter 3 s) ist damit fraglich; Messung auf dem Handy steht aus.
  **Entscheidung (selbst evaluiert, LO-Auftrag):** Prüfung häppchenweise statt schneller machen. `validate_async(…, pump)` und `WiderlegungSim.run_games` zerlegen die Prüfung in Pakete à 50 Partien; ohne Threads (Web) wartet die Forge nach jedem Paket einen Frame. Längstes Häppchen Desktop 50 ms (vorher 347 ms am Stück, im Web vorher mehrere Sekunden Einfrieren). Ergebnisse bitgleich (Test). Verworfen: Würfe-Suche abschalten (Tor fällt auf ~60 %), Web mit Threads (fehlende Vorlage, COOP/COEP-Header auf iOS/itch nötig).
  **Folge für das Tor „unter 3 s auf dem Handy":** Der Spieler wartet nie auf die Prüfung, sie läuft nach der Partie im Hintergrund. Gemessen werden sollte daher die Ruckel-Länge (Häppchen), nicht die Gesamtdauer.
  **Nächster Hebel:** Lauf mit `gemini-3.8-flash` nach Quota-Reset (`tools/lehre/forge_gate.gd`, Proxy mit Standard-Modellen), sonst bezahlter Schlüssel.
  **Hinweis:** Auf Port 8787 läuft noch ein alter Proxy (altes Modell, ohne `/lehre/generate`). Neu starten: `pnpm run proxy:dev`.

## Offen / TODO

- [ ] Ship-It-Skizze: gehosteter Proxy (Auth-Modell, Session-Rate-Limit, Kosten/Run) — blockiert von Zielplattform-Frage, jetzt beantwortet: Itch.io
- [x] **2026-09-19 — Ship It umgesetzt** (Goal-Lauf, Swarm aus 5 Agenten + Integration):
  Proxy-Härtung (`gm-proxy/src/middleware.ts`: `x-lobby-token`-Auth via `GM_PROXY_TOKEN`, Fixfenster-Rate-Limit `GM_RATE_LIMIT_PER_MINUTE` Default 30, 429+Retry-After), Dockerfile gebaut+gesmoket,
  `tools/check-no-secrets.ts` (respektiert `git check-ignore` — Fund: `gm-proxy/router-state.json` enthält Key, liegt aber in .gitignore, nie im Git),
  `tools/contract-test.ts` (+`GM_CONTRACT_TEST_TOKEN`/`GM_CONTRACT_TEST_AUTH`), `ApiClient.gd` liest `user://gm_proxy.cfg` ([gm] url/token),
  `DEPLOY.md` (8 Abschnitte). **Beweise:** Contract-Test 4/4 grün über localhost.run-Tunnel mit echter Gemini-Antwort; 429-Burst live; GUT 61/61 unter Godot 4.7.2 (Binary lag nicht vor, wurde nachgeladen).
  **Befund Free-Tier:** Gemini ~5 RPM/Modell → `GM_RATE_LIMIT_PER_MINUTE=30` übersteigt Provider-Quota bei Multi-Session; DEPLOY.md empfiehlt 5–10 oder Key-Rotation.
  **Verbleibend (LO-Entscheidungen):** Hoster + Domain für den Produktiv-Endpunkt; Godot-Export-Preset für Itch-Build noch nicht definiert.

- [x] **2026-10-12 — Task 13 Abnahme Widerlegung:** Sichtprüfung von LO bestanden (manuell). Offen aus dem Plan: Stoppuhr-Zeiten sind nicht eingetragen. Noch nicht gepusht; Push und PR nur auf Anfrage.
