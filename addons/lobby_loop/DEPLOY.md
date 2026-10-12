# DEPLOY.md — GM-Proxy Deployment-Runbook

Runbook für den "Ship It"-Stand: Der GM-Proxy ist deploybar (Auth, Rate-Limit,
Docker-Artefakt), der Godot-Client liest die Proxy-URL aus Konfiguration.
Konfigurationsnamen folgen ausschließlich dem Koordinationsvertrag.

## 1. Architektur

```
Godot-4-Client (Spieler)
        │  HTTP POST, JSON, Header x-lobby-token (bei aktivem Auth)
        ▼
GM-Proxy (Node ≥ 22, zero-dep node:http, localhost:8787 oder gehostet)
        │  REST, nur validiertes JSON in beide Richtungen
        ▼
LLM-Provider (Gemini via vendored llm-router-blueprint)
```

- Der Proxy ist die einzige Stelle, die LLM-Provider-Keys kennt. Keys liegen
  ausschließlich serverseitig (Env `GEMINI_API_KEY`), nie im Godot-Client,
  nie im Repo, nie im Client-Config-File (`token` im Client ist nur das
  Proxy-Auth-Token, kein Provider-Key).
- Der Client sendet bei jedem Request den Systemstatus (Inventar, Szene,
  Alignment, Eingabe) plus `session_id`; der Proxy antwortet mit
  maschinenlesbarem GM-Code (Dialog, Wurf, DC, Event).
- Fällt das LLM aus oder ist die Antwort ungültig, liefert der Proxy
  `503 {error, fallback: true}` und der Client schaltet auf den
  SQLite-Fallback um (kein Crash).

## 2. Konfiguration (Env-Vars)

Der Main-Block von `gm-proxy/src/server.ts` lädt optional `.env`
(`process.loadEnvFile()`, fehlende Datei ist kein Fehler) und liest echte
Env-Variablen danach — letztere gewinnen.

| Variable | Default | Semantik |
|---|---|---|
| `GM_PROXY_PORT` | `8787` | HTTP-Port des Proxys. |
| `GM_CHRONICLE_DIR` | `gm-proxy/data/chronicles` | Verzeichnis für die GM-Gedächtnis-Chronik pro Session (ADR-0004). Im Docker auf ein Volume legen. |
| `GM_PROXY_TOKEN` | _unset_ | **Unset oder leer = offener Dev-Modus ohne Auth.** Ist ein Token gesetzt, müssen alle Requests (außer `GET /health`) den Header `x-lobby-token` mit exakt diesem Wert senden; fehlt er oder ist er falsch → `401 {error}`. |
| `GM_CORS_ORIGINS` | _unset_ | Nur für den Web-Export: erlaubte Browser-Origins, komma-getrennt (z. B. `https://html.itch.zone`), oder `*`. Unset = keine CORS-Header, dann erreicht ein Browser-Build den Proxy nicht und spielt offline. |
| `GM_RATE_LIMIT_PER_MINUTE` | `30` | Request-Limit pro `session_id` aus dem JSON-Body, Fallback Client-IP. Fixfenster pro Minute. Überschreitung → `429` mit JSON-Body `{error}` und Header `Retry-After` (Sekunden bis zum nächsten Fenster). |

Zusätzlich providerseitig (`.env.example`):

| Variable | Default | Semantik |
|---|---|---|
| `GEMINI_API_KEY` | — | Einzelner Key oder komma-separiert mehrere (Key-Rotation/Quota-Arbitrage durch llm-router-blueprint). |
| `GEMINI_MODEL_PRIMARY` | `gemini-3.8-flash` | Primärmodell (stabil). |
| `GEMINI_MODEL_FALLBACK` | `gemini-3.5-flash-lite` | Fallback-Modell (stabil). |

`.env` niemals committen (steht in `.gitignore`); Vorlage ist `.env.example`.

## 3. Lokal starten

```bash
pnpm install
pnpm run proxy:dev
```

`proxy:dev` startet `tsx gm-proxy/src/server.ts`; der Proxy meldet
`[gm-proxy] LOBBY-LOOP GM-Proxy lauscht auf http://localhost:8787`.
Smoke-Test: `curl http://localhost:8787/health` → `{"ok":true}`.

Vor dem ersten Lauf mit Fallback: `pnpm run build:fallback` (compiliert
`content/`-JSON → `data/fallback.sqlite`).

## 4. Docker

Build:

```bash
docker build -t lobby-loop-gm-proxy .
```

Run (Chronik persistent, Konfiguration per Env-Datei):

```bash
docker run -d --name lobby-loop-gm-proxy \
  --env-file .env \
  -p 8787:8787 \
  -v lobby-loop-chronicles:/app/gm-proxy/data/chronicles \
  lobby-loop-gm-proxy
```

- `--env-file .env` übergibt `GM_PROXY_TOKEN`, `GM_RATE_LIMIT_PER_MINUTE`,
  `GEMINI_API_KEY` etc. ohne sie in die Shell-History zu schreiben.
- Das Volume sichert die Chronik gegen Container-Neuanlage; bei Wechsel des
  Hosts Volume mitnehmen oder `GM_CHRONICLE_DIR` entsprechend mounten.
- Produktiv: `GM_PROXY_TOKEN` zwingend setzen — ohne Token ist jede
  Installation öffentlich nutzbar, solange sie erreichbar ist.

Health-Check im Containerbetrieb: `curl http://localhost:8787/health`
(extern über den publizierten Port bzw. die Tunnel-URL).

## 5. Staging per Tunnel

Für einen vom Godot-Client erreichbaren Staging-Stand ohne eigenen Server:

```bash
# Variante A: Cloudflare Quick Tunnel (kein Account nötig)
cloudflared tunnel --url http://localhost:8787

# Variante B: ngrok (Account nötig)
ngrok http 8787
```

Beide drucken eine öffentliche HTTPS-URL; diese in `user://gm_proxy.cfg`
als `url` eintragen. Der Tunnel-Check genügt `GET /health` — die Route ist
auch mit aktivem Auth offen und liefert `{"ok":true}`, ohne dass ein Token
gesendet werden muss. Wichtig: Im Dev-Modus (Token unset) ist die
öffentliche URL von jedem nutzbar, der sie kennt — für Staging immer
`GM_PROXY_TOKEN` setzen.

## 6. Godot-Client konfigurieren

Der Client liest `user://gm_proxy.cfg`:

```ini
[gm]
url="https://deine-tunnel-oder-server-url"
token="dein-gm-proxy-token"
```

- `url`: Proxy-Basis-URL ohne trailing slash. Default (Datei fehlt oder
  Keys leer): `http://localhost:8787`.
- `token`: Wert von `GM_PROXY_TOKEN`; wird als Header `x-lobby-token`
  gesendet. Im offenen Dev-Modus leer lassen.

Auf Windows liegt `user://` unter:

```
%APPDATA%\godot\app_userdata\LOBBY-LOOP\gm_proxy.cfg
```

(`config/name` in `project.godot` ist `LOBBY-LOOP`; `Win+R` →
`shell:appdata` → `godot\app_userdata\LOBBY-LOOP`.)

## 7. Kostenbild

- **Kaskade:** Der vendored `llm-router-blueprint` rotiert über mehrere
  komma-separierte `GEMINI_API_KEY` (Free-Tier-Quota-Arbitrage) und fällt
  vom Primary- aufs Fallback-Modell zurück, bevor ein Call als
  `GmUnavailableError` durchgereicht wird. Kosten entstehen praktisch nur,
  wenn Free-Tier-Quotas erschöpft sind oder Paid-Tier-Keys eingesetzt werden.
- **Calls pro Spielaktion:** 2 Roundtrips — `POST /gm/action` (GM bewertet,
  legt DC fest) und `POST /gm/result` (GM kommentiert den Wurf). Das
  Beleidigungsfechten kostet pro Runde 1 Call (`/minigame/round`),
  `/minigame/judge` kann clientseitig deterministisch fallen, wenn die
  Fallback-Runde gespielt wird.
- **Größenordnung:** Eine typische Interaktion ≈ 2 LLM-Calls; eine
  Minigame-Runde ≈ 1 LLM-Call. Bei Flash-Modellen und Free Tier ist das
  vernachlässigbar, skaliert aber mit Spielerzahl × Aktionen/Minute.
- **Empfehlung:** `GM_RATE_LIMIT_PER_MINUTE` ist die zentrale Kostenbremse,
  weil das Limit pro `session_id` greift — ein einzelner Client oder ein
  wildgewordener Bot kann die Quota nicht alleine plätten. Für öffentliche
  Instanzen eher knapp (z. B. 30) statt großzügig konfigurieren.
- **Achtung Free-Tier-Realität (beobachtet 2026-09-19):** Geminis Free Tier
  liegt bei ~5 Requests/Minute und Projekt/Modell (`gemini-2.5-flash`) bzw.
  ~20/Tag (`gemini-2.5-flash-lite`). Ein `GM_RATE_LIMIT_PER_MINUTE=30`
  übersteigt die Provider-Quota, sobald mehr als eine Session aktiv ist —
  der Proxy fängt das als `503 {error, fallback: true}` sauber ab (Client
  spielt dann den SQLite-Fallback), aber der GM ist dann nicht lebendig.
  **Gemessen 2026-10-12:** `gemini-3.8-flash` hat im Free Tier nur
  **20 Anfragen pro Tag** und Projekt (`GenerateRequestsPerDayPerProjectPerModel-FreeTier`).
  Danach meldet der Router das Modell bis zum nächsten Tag als erschöpft und
  nimmt `gemini-3.5-flash-lite`. Für ein öffentliches Spiel heißt das: Free
  Tier reicht nur zum Testen, produktiv braucht es einen bezahlten Schlüssel
  oder `GEMINI_MODEL_PRIMARY=gemini-3.5-flash-lite`.
  Für Free-Tier-Deployments das Limit klein wählen (z. B. 5–10) und/oder
  mehrere `GEMINI_API_KEY` komma-separiert setzen (Key-Rotation über den
  llm-router-blueprint).

## 8. Release-Checkliste

Vor jedem Deploy abhaken:

- [ ] `pnpm test` — Proxy-Suites (`gm-proxy/tests/`) + Tools-Suites grün.
- [ ] `pnpm run typecheck` — `tsc` ohne Fehler.
- [ ] GUT-Suite: `<godot-binary> --headless -s addons/gut/gut_cmdln.gd -gdir=res://addons/lobby_loop/test/gut -gexit` — Unit-Tests für reine Logik (Wurf, Stats, Kombinationen, Shuffle, Run-Stats, Epitaph). Lokal nur lauffähig mit installiertem Godot-Binary; in CI einen Godot-Step einplanen.
- [ ] `pnpm run check:secrets` — Secret-Scan; bestätigt, dass weder `.env` noch Keys im Git landen.
- [ ] Contract-Test gegen die Staging-URL: `POST /gm/action` mit
  `session_id` + Systemstatus gegen die Tunnel-/Server-URL, inkl.
  Auth-Header; Erwartung `200` mit `gm_dialogue`. Danach `401` ohne Header
  (Token gesetzt) und `429` bei Limit-Überschreitung verifizieren.
- [ ] `/health` ohne Token prüfen (muss immer `{"ok":true}` liefern).
- [ ] Chronik-Verzeichnis/Volume beschreibbar; nach Testlauf liegt eine
  Chronik-Datei pro `session_id` darin.
