# Widerlegung in Lobby-Loop — Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die Regeln von „Das gerupfte Huhn" laufen bitgleich in Godot und sind in Lobby-Loop als zweites Minispiel („Widerlegung") spielbar, auch ohne Netz. Danach folgen Phase 2 bis 4 des Gesamtkonzepts an messbaren Toren.

**Architecture:** Die JS-Engine wird nach `vendor/huhn/` übernommen. Ein Node-Tool erzeugt daraus die Lehren als JSON und eine Golden-Datei. Die GDScript-Portierung (`WiderlegungRng`, `WiderlegungRules`) muss diese Golden-Datei Zug für Zug treffen. Ein neuer Minispiel-Vertrag (`MinigameContract`) verbindet Spielleiter, `EventApplier`, `GameState` und das neue `widerlegung_panel.gd`. Ergebnisse wirken nur über erlaubte Effekte (`add_item`, `modify_stat`) zurück.

**Tech Stack:** Godot 4.7.2 (GDScript, GUT), Node ≥ 22 mit `tsx` und `node:test`, TypeScript 5.7, Gemini-Proxy (vorhanden).

**Spec:** `docs/konzept/gesamtkonzept-latte.md`

---

## Wo wir stehen (Befund vom 12.10.2026)

1. **Repo:** `C:\Users\Buxe\Projects\point and pen` ist der lokale Klon von `deusexlumen/lobby-loop`, Branch `master`.
2. **Lokal und GitHub sind auseinandergelaufen:** lokal 1 Commit voraus (`8beb7c2` Aktenkoffer-Textur), 2 Commits zurück (`159f8d7` strukturierte GM-Calls + Merge `62c2f10`). Dazu liegt die komplette Ship-It-Arbeit vom 19.09. **unversioniert** im Arbeitsverzeichnis (Middleware, Dockerfile, DEPLOY.md, Contract-Test, Secrets-Check, `test_api_client_config.gd`, Änderungen an `server.ts`, `package.json`, `ApiClient.gd`).
3. **`gm-proxy/src/schemas.ts` existiert nur auf GitHub**, nicht lokal. Die Spec nennt sie als Datei, die geändert wird.
4. Branch `origin/claude/jev-ai-model-review-b13v05` hat 3 weitere Commits (CI-Workflow, Windows-Export-Preset, Skill godot-export), die nicht in `master` sind.
5. **Offline kann heute kein Minispiel starten:** `FallbackDb` liefert immer `trigger_event: null`. Das gilt schon für das Beleidigungsfechten.
6. `start_minigame` verliert unterwegs jede Angabe: `validate.ts` baut `{type: 'start_minigame'}` neu, `EventApplier.apply` ruft `state.start_minigame()` ohne Argumente.
7. Godot-Binary: `C:\Users\Buxe\tools\Godot\Godot_v4.7.2-stable_win64_console.exe`. Letzter bekannter Stand: GUT 61/61 grün.
8. Huhn-Quelle: `C:\Users\Buxe\Projects\huhn` (kein Git). Engine 531 Zeilen, Daten 372 Zeilen, 13 Regeltests, Simulation.
9. DAME (für Phase 3/4 geprüft): Godot-Projekt liegt in `Dame-Card-Game/godot/`, ein Autoload `App`, eigener Test-Runner (`pnpm test:godot` → `node scripts/godot-test.mjs`, 565 Checks), kein GUT. Dienste unter `godot/scripts/services/`: `audio_service`, `catalog`, `json_store`, `profile_service`, `purchase_provider`, `save_service`, `settings_service`, `stats_service`. `i18n.gd` liegt in `godot/scripts/`, nicht bei den Diensten. Web-Build heute 49 MB.
10. Ein überflüssiger Klon liegt unter `C:\Users\Buxe\Projects\lobby-loop` (von mir angelegt, Löschen wurde abgelehnt). Er wird von diesem Plan nicht benutzt.

## Global Constraints

- Godot **4.7.2**, Ziel-Renderer **GL Compatibility** (Spec: „Die App nimmt GL Compatibility").
- Node **≥ 22** (`package.json` engines).
- Bezeichner in Code englisch, Spieltexte und Doku deutsch (Lobby-Loop `AGENTS.md`).
- Kein String-Parsing an API-Grenzen, nur validiertes JSON. Ungültiges schaltet auf Fallback, nie Crash.
- **Fraktionsdisziplin ändert sich nur über Spielmechanik**, also nur über `EventApplier`.
- Fehlt `"game"` in `start_minigame`, startet `"beleidigungsfechten"` (abwärtskompatibel).
- Effekte eines Minispiel-Ergebnisses: nur `add_item` und `modify_stat`.
- Der Seed einer Widerlegung kommt immer vom Client, nie vom Sprachmodell.
- Gleichheitstest: **200/200** Partien identisch mit der JS-Fassung.
- Ein Durchgang dauert **3–6 Minuten** (eine Lehre).
- Die Widerlegung ist **ohne Netz vollständig spielbar**.
- Mehr als 5 Dateien in einem Schritt: vorher Bescheid sagen (globales `AGENTS.md`).
- Nach jeder wichtigen Entscheidung: Eintrag in `SESSION_NOTES.md`.

## Review Focus

1. **Zahlen aus Godot-JSON sind float.** Wer `cap`, `hand`, `wuerfe` nicht castet, bekommt `"9.0"` statt `"9"` und falsche Ganzzahl-Logik. Erwartung: `prepare()` castet, der Golden-Test vergleicht Texte und fällt sofort auf. Abgedeckt in Task 4 und Task 6.
2. **Der Spielleiter schickt eine unbekannte Lehre, einen eigenen Seed oder ein unbekanntes Spiel.** Erwartung: Lehre fällt auf den Szenen-Standard zurück, Seed wird ignoriert, unbekanntes Spiel wird verworfen und nichts startet. Abgedeckt in Task 8 (Godot) und Task 11 (Proxy).
3. **Niederlage bei Fraktionsdisziplin 1.** Erwartung: Das Ergebnis steht in der Akte, bevor der Effekt den Perma-Death auslöst. Das Panel ist dann schon zu. Abgedeckt in Task 8 (Reihenfolge in `apply_result`) und Task 9 (Panel sendet erst beim Schließen).
4. **Abbruch mitten in der Partie** (Perma-Death von außen, Szenenwechsel). Erwartung: Das Panel sendet kein Ergebnis, es wirkt kein Effekt. Abgedeckt in Task 9.
5. **Klick auf einen Hotspot, während die Widerlegung offen ist.** Erwartung: Nichts passiert. Abgedeckt in Task 10 (Guard in `main.gd`) und als Punkt im manuellen Test in Task 13.

## Deine Entscheidungen vor dem Start

1. **Git-Abgleich (Task 0):** Empfehlung: Ship-It-Arbeit auf einen Branch committen, dann `origin/master` hineinmergen. Das ist der einzige Weg, der nichts verwirft.
2. **Den jev-Branch mitnehmen?** Empfehlung: ja. Er bringt CI (GUT headless) und das Windows-Export-Preset, beides brauchst du für Itch.io.
3. **Belohnungsregel:** Vorschlag: Einsturz bringt Disziplin +1 und „Weggefallener Paragraph". Ab 2 Ausnahmen zusätzlich „Gerupftes Huhn". Gehaltene Lehre kostet Disziplin −1.
4. **Welche Lehre in welcher Szene:** Vorschlag: Untersuchungsausschuss → „amt" (Sitzgelegenheit) am neuen Knoten „Zeugenstuhl". Fraktionssitzung → „spiel" (Spielgesetz) am neuen Knoten „Gesetzentwurf".

---

## Dateien in Phase 1

```
vendor/huhn/engine.cjs                 NEU   Kopie von huhn/src/engine.js, exportiert zusätzlich rnd + shuffle
vendor/huhn/data.cjs                   NEU   Kopie von huhn/src/data.js
vendor/huhn/README.md                  NEU   Herkunft, Datum, einzige Änderung
tools/export-widerlegung.ts            NEU   Lehren -> content/widerlegung/*.json, Golden -> test/golden/widerlegung.json
tools/tests/export-widerlegung.test.ts NEU   Export vollständig, Golden deterministisch und aktuell
content/widerlegung/*.json             NEU   generiert: 5 Lehren + _common.json
test/golden/widerlegung.json           NEU   generiert: Hash, Zufall, Mischen, 200 Partien, 10 Vorgänge
scripts/core/widerlegung_rng.gd        NEU   32-Bit-Hash, mulberry32, Mischen (bitgleich zu JS)
scripts/core/widerlegung_rules.gd      NEU   Regeln: laden, urteilen, nachbessern, Gewicht, Herzschlag, Kniffe, Vorgang
scripts/core/widerlegung_sim.gd        NEU   Simulation (Zufall, Gelegenheit, Gierig)
scripts/core/minigame_contract.gd      NEU   Minispiel-Vertrag: Spiele, Parameter, Seed, Effekte, Ergebnis, Offline-Start
scripts/ui/widerlegung_panel.gd        NEU   Saal, Lehre, Last, Hand, Herzschlag, Protokoll
test/gut/helpers/widerlegung_canon.gd  NEU   Textform von Ereignissen für Golden- und Determinismus-Tests
test/gut/test_widerlegung_rng.gd       NEU
test/gut/test_widerlegung_rules.gd     NEU   die 13 Huhn-Regeltests
test/gut/test_widerlegung_golden.gd    NEU   Gleichheitstest 200/200
test/gut/test_widerlegung_sim.gd       NEU
test/gut/test_minigame_contract.gd     NEU
test/gut/test_widerlegung_panel.gd     NEU
scripts/core/event_applier.gd          EDIT  start_minigame(game, params), unbekanntes Spiel ungültig
scripts/autoload/GameState.gd          EDIT  Signal mit game/params, record_minigame, apply_minigame_result
scripts/core/run_stats.gd              EDIT  Liste minigames
scripts/core/epitaph_generator.gd      EDIT  Widerlegungen in der Akte
scripts/ui/pnp_overlay.gd              EDIT  Offline-Start über Knotenfeld "minigame"
scripts/main.gd                        EDIT  Panel einhängen, Routing, Guard, Perma-Death
test/gut/test_events.gd                EDIT  Stub mit Argumenten, neue Fälle
test/gut/test_run_stats.gd             EDIT  minigames + Akte
content/items.json                     EDIT  2 neue Items
content/scenes/untersuchungsausschuss.json  EDIT  Knoten zeugenstuhl
content/scenes/fraktionssitzung.json        EDIT  Knoten gesetzentwurf
tools/compile-fallback.ts              EDIT  optionales Feld minigame prüfen
tools/tests/compile-fallback.test.ts   EDIT
gm-proxy/src/types.ts                  EDIT  TriggerEvent start_minigame mit game/params, RunStats.minigames
gm-proxy/src/validate.ts               EDIT  game/params prüfen, Seed verwerfen, minigames durchreichen
gm-proxy/src/schemas.ts                EDIT  (nach Task 0 vorhanden) Schema für start_minigame
gm-proxy/tests/validate.test.ts        EDIT
gm-proxy/prompts/gm-system.md          EDIT  Widerlegung im Befehls-Enum
gm-proxy/prompts/epitaph.md            EDIT  Widerlegungen erwähnen
project.godot                          EDIT  GL Compatibility
package.json                           EDIT  Skript build:widerlegung
```

## Befehle, die jeder Task benutzt

```bash
cd "/c/Users/Buxe/Projects/point and pen"
GODOT="/c/Users/Buxe/tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
# Neue class_name-Dateien registrieren (nach jedem Task, der eine anlegt):
"$GODOT" --headless --path . --import
# Alle GUT-Tests:
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://addons/lobby_loop/test/gut -gexit
# Eine Datei:
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_rng.gd -gexit
# Proxy und Tools:
pnpm test
pnpm run typecheck
```

---

## Phase 1: Widerlegung als Minispiel in Lobby-Loop

### Task 0: Git-Abgleich und Baseline

**Files:** keine neuen. Betrifft den ganzen Arbeitsstand.

**Interfaces:**
- Produces: Branch `feat/widerlegung` auf Basis von `origin/master` plus Ship-It-Arbeit plus `8beb7c2`. `gm-proxy/src/schemas.ts` ist danach vorhanden.

- [ ] **Step 1: Arbeitsstand sichern**

```bash
git status --short
git switch -c feat/widerlegung
git add plan.md docs/konzept SESSION_NOTES.md
git commit -m "docs: Gesamtkonzept und Umsetzungsplan Phase 1–4"
git add -A
git status --short   # prüfen: keine Schlüssel, kein router-state.json, kein kimi-debug-*.zip
git commit -m "feat: Ship-It — Proxy-Härtung, Docker, Contract-Test, Secrets-Check (Stand 19.09.)"
```

Wenn `git status` nach `git add -A` ein `.zip` oder eine Datei mit Schlüssel zeigt: `git reset <datei>`, in `.gitignore` aufnehmen, dann committen.

- [ ] **Step 2: GitHub-Stand hineinmergen**

```bash
git fetch origin
git merge origin/master -m "merge: origin/master (strukturierte GM-Calls, ADR 0007)"
```

Erwartung: Der Merge läuft ohne Konflikt durch. `origin/master` ändert `gm-system.md`, `gemini.ts`, `llm-handlers.ts`, `prompt.ts`, `schemas.ts`, `.env.example`, `AGENTS.md`, aber nicht `server.ts`, `package.json` oder `ApiClient.gd`. Wenn doch ein Konflikt auftaucht: beide Seiten behalten, dann `pnpm test`.

- [ ] **Step 3: jev-Branch hineinmergen (nur wenn du Entscheidung 2 mit Ja beantwortet hast)**

```bash
git merge origin/claude/jev-ai-model-review-b13v05 -m "merge: CI, Windows-Export-Preset, Skill godot-export"
```

- [ ] **Step 4: Baseline messen**

```bash
pnpm install
pnpm test
pnpm run typecheck
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://addons/lobby_loop/test/gut -gexit
```

Erwartung: `pnpm test` grün, Typecheck ohne Fehler, GUT mindestens 61 Tests grün. Die genaue Zahl in `SESSION_NOTES.md` notieren. **Wenn hier etwas rot ist, stopp. Erst reparieren, dann Phase 1.**

- [ ] **Step 5: Notiz**

In `SESSION_NOTES.md` unter „Entscheidungen & Erkenntnisse" eintragen: Datum, Merge-Weg, GUT-Zahl, Testzahl `pnpm test`. Commit:

```bash
git add SESSION_NOTES.md
git commit -m "docs: Baseline vor Phase 1 Widerlegung"
```

---

### Task 1: Renderer auf GL Compatibility

Die Spec sagt: früh in Phase 1 prüfen. Der Wechsel ist eine Zeile, das Risiko liegt in Shadern oder Texturen, die unter Compatibility anders aussehen.

**Files:**
- Modify: `project.godot` (Abschnitte `[application]` und `[rendering]`)

- [ ] **Step 1: Umstellen**

In `project.godot`:

```ini
config/features=PackedStringArray("4.7", "GL Compatibility")
```

Und im Abschnitt `[rendering]` ergänzen:

```ini
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

- [ ] **Step 2: Tests**

```bash
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://addons/lobby_loop/test/gut -gexit
```

Erwartung: dieselbe Zahl grüner Tests wie in Task 0.

- [ ] **Step 3: Sichtprüfung (manuell, 2 Minuten)**

```bash
"/c/Users/Buxe/tools/Godot/Godot_v4.7.2-stable_win64.exe" --path .
```

Prüfen: Startszene erscheint, Aktenkoffer-Textur sichtbar, Hotspot-Farben stimmen, Overlay öffnet. Wenn etwas kaputt aussieht: Screenshot, Datei in `SESSION_NOTES.md` notieren, Änderung zurücknehmen (`git checkout project.godot`) und mir Bescheid geben. Der Rest von Phase 1 hängt nicht am Renderer.

- [ ] **Step 4: Commit**

```bash
git add project.godot
git commit -m "chore: Renderer GL Compatibility (Web-tauglich, Vorbereitung gemeinsame App)"
```

---

### Task 2: Huhn-Engine vendoren, Lehren und Golden erzeugen

**Files:**
- Create: `vendor/huhn/engine.cjs`, `vendor/huhn/data.cjs`, `vendor/huhn/README.md`
- Create: `tools/export-widerlegung.ts`
- Create: `tools/tests/export-widerlegung.test.ts`
- Modify: `package.json` (scripts)
- Generated: `content/widerlegung/{akademie,amt,erfurt,division7b,spiel,_common}.json`, `test/golden/widerlegung.json`

**Interfaces:**
- Produces (Dateiformat `content/widerlegung/<id>.json`): genau das Objekt aus `data.js` `INSTANZEN[i]`, Felder unverändert (`id`, `nr`, `begriff`, `gegner`, `lehreHead`, `startSatz`, `intro`, `ort`, `hand`, `wuerfe`, `cap`, `laterneLeihgabe?`, `fixedHand?`, `rhetorik`, `attrs`, `start`, `prisma`, `refMembers`, `refNon`, `cards[]` mit `id`, `name`, `icon`, `m`, `a`, `note`).
- Produces (`_common.json`): `{order: string[], rhetorik: {...}, kniffe: [...], raenge: [...]}`.
- Produces (`test/golden/widerlegung.json`): `{version, hash: [{s, h}], rnd: {seed, values: int[]}, shuffle: {seed, input, output}, games: [{g, az, idx, kniffe, alexander, start, lines: string[], result}], full: string[]}`. Die Textformen sind in Step 4 definiert und in Task 6 exakt nachgebaut.

- [ ] **Step 1: Engine und Daten kopieren**

```bash
mkdir -p vendor/huhn
cp "/c/Users/Buxe/Projects/huhn/src/engine.js" vendor/huhn/engine.cjs
cp "/c/Users/Buxe/Projects/huhn/src/data.js" vendor/huhn/data.cjs
```

Dann in `vendor/huhn/engine.cjs` im `API`-Objekt (Zeile 522–528) die zwei internen Funktionen mit exportieren. Aus

```js
  const API = {
    setData, hashStr, satisfies, judge, weight, litHolds, parseLit, litKey,
```

wird

```js
  const API = {
    setData, hashStr, rnd, shuffle, satisfies, judge, weight, litHolds, parseLit, litKey,
```

- [ ] **Step 2: Herkunft dokumentieren**

`vendor/huhn/README.md`:

```markdown
# vendor/huhn

Kopie der Spiel-Engine aus „Das gerupfte Huhn" (lokal `C:\Users\Buxe\Projects\huhn\src\`, Stand 12.10.2026, v2).

- `engine.cjs` = `src/engine.js`. Einzige Änderung: `rnd` und `shuffle` stehen zusätzlich im exportierten `API`-Objekt, damit der Golden-Test Zufall und Mischen direkt vergleichen kann.
- `data.cjs` = `src/data.js`, unverändert.

Die Dateien sind die Referenz für die GDScript-Portierung. Wer sie ändert, muss danach `pnpm run build:widerlegung` laufen lassen und den neuen Golden-Stand committen. Der Test `tools/tests/export-widerlegung.test.ts` schlägt sonst fehl.
```

- [ ] **Step 3: Den fehlschlagenden Test schreiben**

`tools/tests/export-widerlegung.test.ts`:

```ts
/*
 * PURPOSE: Export der Huhn-Lehren und Golden-Datei: vollständig, deterministisch, eingecheckter Stand aktuell
 * ARCHITECTURE: tools/tests
 * DEPENDENCIES: node:test, node:assert/strict, node:fs, node:url, ../export-widerlegung.js
 * PIPELINE: test
 * LAST_VALIDATED: 2026-10-12
 */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { GOLDEN_GAMES, buildGolden, exportContent, loadHuhn } from '../export-widerlegung.js';

const GOLDEN_FILE = fileURLToPath(new URL('../../test/golden/widerlegung.json', import.meta.url));

test('exportiert fünf Lehren plus _common.json in fester Reihenfolge', () => {
  const { raw } = loadHuhn();
  const files = exportContent(raw);
  assert.deepEqual(Object.keys(files).sort(), [
    '_common.json',
    'akademie.json',
    'amt.json',
    'division7b.json',
    'erfurt.json',
    'spiel.json',
  ]);
  const common = JSON.parse(files['_common.json']);
  assert.deepEqual(common.order, ['akademie', 'amt', 'erfurt', 'division7b', 'spiel']);
  assert.equal(common.kniffe.length, 8);
  const akademie = JSON.parse(files['akademie.json']);
  assert.equal(akademie.cardMap, undefined, 'keine Laufzeitfelder aus setData im Export');
  assert.equal(akademie.cards.length, raw.instanzen[0].cards.length);
  assert.equal(akademie.cap, 9);
});

test('Golden ist deterministisch und enthält 200 Partien', () => {
  const a = loadHuhn();
  const first = JSON.stringify(buildGolden(a.E, a.DATA));
  const b = loadHuhn();
  assert.equal(JSON.stringify(buildGolden(b.E, b.DATA)), first);
  const golden = JSON.parse(first);
  assert.equal(golden.games.length, GOLDEN_GAMES);
  assert.ok(golden.games.every((g: { lines: string[] }) => g.lines.length > 0));
  assert.equal(golden.full.length, 10);
});

test('eingecheckter Golden entspricht der vendorten Engine', () => {
  const { E, DATA } = loadHuhn();
  const committed = readFileSync(GOLDEN_FILE, 'utf8').replace(/\r\n/g, '\n');
  assert.equal(committed, JSON.stringify(buildGolden(E, DATA)) + '\n');
});
```

- [ ] **Step 4: Test laufen lassen, er muss scheitern**

```bash
pnpm run test:tools
```

Erwartung: FAIL, „Cannot find module '../export-widerlegung.js'".

- [ ] **Step 5: Das Export-Tool schreiben**

`tools/export-widerlegung.ts`:

```ts
/*
 * PURPOSE: Exportiert die Huhn-Lehren als Godot-Content und schreibt die Golden-Datei für den Gleichheitstest
 * ARCHITECTURE: tools
 * DEPENDENCIES: node:fs, node:module, node:path, node:url, vendor/huhn
 * PIPELINE: build, test
 * LAST_VALIDATED: 2026-10-12
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);

export const GOLDEN_GAMES = 200;
/** Kniff-Sätze für den Golden: decken jede Kniff-Verzweigung der Engine mindestens einmal ab. */
export const GOLDEN_KNIFFE: string[][] = [
  [],
  ['inspektion', 'huhn2'],
  ['dudelsack', 'sonne'],
  ['uniform', 'fass', 'bettwaermer'],
];
/** Aktive Kniffe werden vor dem zweiten Wurf in dieser Reihenfolge eingesetzt. */
export const KNIFF_USE_ORDER = ['fass', 'bettwaermer', 'uniform'];
const HASH_INPUTS = ['', 'a', 'HUHN-20261011', 'GOLD-0#akademie', 'LL-session#amt#3', 'HUHN-20261011#tonne0'];
const CANON_FIELDS = [
  'type', 'card', 'verdict', 'kind', 'gain', 'last', 'frei', 'effect',
  'rhet', 'cap', 'bonus', 'score', 'drawn', 'id', 'dudelsack', 'uniform',
];

// Die Engine ist untypisiertes JS; die Form prüft der Golden-Test, nicht der Compiler.
type Any = any; // eslint-disable-line @typescript-eslint/no-explicit-any

/** Frisch laden: setData() verändert DATA (Sets, cardMap), deshalb Require-Cache leeren. */
export function loadHuhn(): { E: Any; DATA: Any; raw: Any } {
  const dataPath = join(ROOT, 'vendor/huhn/data.cjs');
  const enginePath = join(ROOT, 'vendor/huhn/engine.cjs');
  delete require.cache[require.resolve(dataPath)];
  delete require.cache[require.resolve(enginePath)];
  const DATA = require(dataPath);
  const raw = JSON.parse(JSON.stringify(DATA));
  const E = require(enginePath);
  E.setData(DATA);
  return { E, DATA, raw };
}

export function exportContent(raw: Any): Record<string, string> {
  const files: Record<string, string> = {};
  for (const D of raw.instanzen) files[`${D.id}.json`] = JSON.stringify(D, null, 2) + '\n';
  files['_common.json'] =
    JSON.stringify(
      {
        order: raw.instanzen.map((D: Any) => D.id),
        rhetorik: raw.rhetorik,
        kniffe: raw.kniffe,
        raenge: raw.raenge,
      },
      null,
      2,
    ) + '\n';
  return files;
}

const litStr = (l: Any): string => (l.neg ? '-' : '+') + l.a;

/** Textform eines Engine-Ereignisses. GDScript baut exakt dieselbe (test/gut/helpers/widerlegung_canon.gd). */
export function canonEvent(e: Any): string {
  const parts = CANON_FIELDS.map((k) => {
    const v = e[k];
    if (v === undefined || v === null) return '';
    if (typeof v === 'boolean') return v ? '1' : '0';
    return String(v);
  });
  if (e.lit) parts.push(litStr(e.lit));
  if (e.tg) parts.push(e.tg.type + '>' + (e.tg.target ?? ''));
  if (e.added) parts.push('add=' + e.added.map(litStr).join(','));
  return parts.join('|');
}

export function canonStart(st: Any): string {
  const tg = st.telegraph ? st.telegraph.type + '>' + (st.telegraph.target ?? '') : '';
  return [st.hand.join(','), st.deck.join(','), st.cap, st.wuerfe, tg].join('/');
}

const canonClause = (c: Any): string =>
  c.t + ':' + (c.a ?? c.id) + (c.neg ? '-' : '') + (c.painted ? '*' : '');

export function canonResult(r: Any): string {
  return [r.collapsed ? 1 : 0, r.atWurf, r.score, r.exceptions, r.last, r.cap, r.lehre.map(canonClause).join(',')].join('|');
}

export function playGame(E: Any, DATA: Any, g: number): Any {
  const n = DATA.instanzen.length;
  const idx = g % n;
  const kniffe = GOLDEN_KNIFFE[Math.floor(g / n) % GOLDEN_KNIFFE.length];
  const az = 'GOLD-' + g;
  const run = E.newRun(az, { kniffe });
  run.idx = idx;
  if (idx === n - 1) run.alexander = g % 2 === 0 ? 'sonne' : 'gold';
  const st = E.startInstanz(run);
  const start = canonStart(st);
  const lines: string[] = [];
  while (run.inst.status === 'play') {
    if (run.inst.plays === 1) {
      for (const k of KNIFF_USE_ORDER) {
        if (E.useKniff(run, k)) lines.push('K|' + k + '|' + run.inst.hand.join(','));
      }
    }
    const hand = run.inst.hand;
    const card = hand[(run.inst.plays * 7 + g) % hand.length];
    lines.push('P|' + card);
    for (const e of E.play(run, card)) lines.push(canonEvent(e));
  }
  return { g, az, idx, kniffe, alexander: run.alexander, start, lines, result: canonResult(run.results[0]) };
}

export function runFull(E: Any, i: number): string {
  const run = E.newRun('FULL-' + i);
  while (run.phase !== 'end') {
    if (run.phase === 'intro') E.startInstanz(run);
    else if (run.phase === 'play') E.play(run, run.inst.hand[0]);
    else if (run.phase === 'result') E.nextPhase(run);
    else if (run.phase === 'tonne') E.chooseKniff(run, run.offers[0]);
    else if (run.phase === 'alexander') E.chooseAlexander(run, i % 2 === 0 ? 'gold' : 'sonne');
  }
  return [run.total, E.pruefcode(run), run.kniffe.join(','), run.results.map(canonResult).join(';')].join('|');
}

export function buildGolden(E: Any, DATA: Any): Any {
  const o = { rs: E.hashStr('RNG-GOLD') };
  const values = Array.from({ length: 20 }, () => Math.floor(E.rnd(o) * 4294967296));
  const input = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];
  return {
    version: 1,
    hash: HASH_INPUTS.map((s) => ({ s, h: E.hashStr(s) })),
    rnd: { seed: 'RNG-GOLD', values },
    shuffle: { seed: 'SHUF', input, output: E.shuffle(input, { rs: E.hashStr('SHUF') }) },
    games: Array.from({ length: GOLDEN_GAMES }, (_, g) => playGame(E, DATA, g)),
    full: Array.from({ length: 10 }, (_, i) => runFull(E, i)),
  };
}

function main(): void {
  const { E, DATA, raw } = loadHuhn();
  const contentDir = join(ROOT, 'content/widerlegung');
  mkdirSync(contentDir, { recursive: true });
  for (const [name, text] of Object.entries(exportContent(raw))) writeFileSync(join(contentDir, name), text);
  const goldenDir = join(ROOT, 'test/golden');
  mkdirSync(goldenDir, { recursive: true });
  writeFileSync(join(goldenDir, 'widerlegung.json'), JSON.stringify(buildGolden(E, DATA)) + '\n');
  console.log('content/widerlegung/ und test/golden/widerlegung.json geschrieben');
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) main();
```

In `package.json` unter `scripts` ergänzen:

```json
    "build:widerlegung": "tsx tools/export-widerlegung.ts",
```

- [ ] **Step 6: Erzeugen und testen**

```bash
pnpm run build:widerlegung
pnpm run test:tools
pnpm run typecheck
```

Erwartung: 6 Dateien unter `content/widerlegung/`, `test/golden/widerlegung.json` (rund 0,5 MB), alle Tool-Tests grün, Typecheck ohne Fehler. Wenn der Typecheck an `require.cache` scheitert: `import type {} from 'node:module'` ist nicht nötig, `@types/node` ist installiert; Fehlermeldung vollständig an mich.

- [ ] **Step 7: Commit**

```bash
git add vendor/huhn tools/export-widerlegung.ts tools/tests/export-widerlegung.test.ts package.json content/widerlegung test/golden
git commit -m "feat(widerlegung): Huhn-Engine vendort, Lehren als JSON, Golden aus der JS-Fassung"
```

---

### Task 3: Zufall bitgleich zu JS (`WiderlegungRng`)

JS rechnet hier mit 32-Bit-Ganzzahlen (`Math.imul`, `>>>`). GDScript hat 64-Bit-Ganzzahlen. **Ein direktes `a * b` kann über 2^63 laufen**, deshalb wird die Multiplikation in 16-Bit-Hälften zerlegt und nach jeder Operation auf 32 Bit maskiert.

**Files:**
- Create: `scripts/core/widerlegung_rng.gd`
- Test: `test/gut/test_widerlegung_rng.gd`

**Interfaces:**
- Produces: `WiderlegungRng.imul32(a: int, b: int) -> int`, `WiderlegungRng.hash_str(s: String) -> int` (0 … 2^32−1), `WiderlegungRng.rnd(o: Dictionary) -> float` (verändert `o["rs"]`), `WiderlegungRng.shuffle(arr: Array, o: Dictionary) -> Array` (neue Liste).

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`test/gut/test_widerlegung_rng.gd`:

```gdscript
# PURPOSE: WiderlegungRng: 32-Bit-Multiplikation, Hash, mulberry32 und Mischen bitgleich zur JS-Engine.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungRng, test/golden/widerlegung.json
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const GOLDEN_PATH := "res://addons/lobby_loop/test/golden/widerlegung.json"

var golden: Dictionary = {}


func before_all() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	if parsed is Dictionary:
		golden = parsed


func test_golden_file_present() -> void:
	assert_false(golden.is_empty(), "test/golden/widerlegung.json fehlt: pnpm run build:widerlegung")


func test_imul32_matches_math_imul() -> void:
	# Werte von Math.imul, als vorzeichenlose 32-Bit-Zahl gelesen.
	assert_eq(WiderlegungRng.imul32(0xFFFFFFFF, 0xFFFFFFFF), 1)
	assert_eq(WiderlegungRng.imul32(2, 0x80000000), 0)
	assert_eq(WiderlegungRng.imul32(0x7FFFFFFF, 0x7FFFFFFF), 1)
	assert_eq(WiderlegungRng.imul32(3, 5), 15)


func test_hash_matches_js() -> void:
	var entries: Array = golden.get("hash", [])
	assert_gt(entries.size(), 0)
	for entry in entries:
		assert_eq(WiderlegungRng.hash_str(str(entry["s"])), int(entry["h"]), "hashStr('%s')" % entry["s"])


func test_rnd_sequence_matches_js() -> void:
	var spec: Dictionary = golden.get("rnd", {})
	var o := {"rs": WiderlegungRng.hash_str(str(spec.get("seed", "")))}
	var values: Array = spec.get("values", [])
	assert_eq(values.size(), 20)
	for i in values.size():
		var got := int(floor(WiderlegungRng.rnd(o) * 4294967296.0))
		assert_eq(got, int(values[i]), "rnd Nr. %d" % i)


func test_shuffle_matches_js() -> void:
	var spec: Dictionary = golden.get("shuffle", {})
	var o := {"rs": WiderlegungRng.hash_str(str(spec.get("seed", "")))}
	var got := WiderlegungRng.shuffle(spec.get("input", []), o)
	assert_eq(got, spec.get("output", []))


func test_shuffle_keeps_input_untouched() -> void:
	var input := ["a", "b", "c"]
	WiderlegungRng.shuffle(input, {"rs": 1})
	assert_eq(input, ["a", "b", "c"])
```

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_rng.gd -gexit
```

Erwartung: FAIL, Parser-Fehler „Identifier WiderlegungRng not declared".

- [ ] **Step 3: Implementieren**

`scripts/core/widerlegung_rng.gd`:

```gdscript
# PURPOSE: Deterministischer Zufall der Widerlegung, bitgleich zu huhn/engine.js (hashStr, mulberry32, shuffle).
# ARCHITECTURE: core
# DEPENDENCIES: none
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name WiderlegungRng
extends RefCounted

const MASK := 0xFFFFFFFF


## Math.imul als vorzeichenlose 32-Bit-Zahl. In 16-Bit-Hälften gerechnet,
## weil a * b mit 64-Bit-Ganzzahlen überlaufen kann.
static func imul32(a: int, b: int) -> int:
	a &= MASK
	b &= MASK
	var low := (a & 0xFFFF) * b
	var high := (((a >> 16) * b) & 0xFFFF) << 16
	return (low + high) & MASK


## hashStr aus engine.js. Seeds sind ASCII, dann sind unicode_at und charCodeAt gleich.
static func hash_str(s: String) -> int:
	var h := (1779033703 ^ s.length()) & MASK
	for i in s.length():
		h = imul32(h ^ s.unicode_at(i), 3432918353)
		h = ((h << 13) & MASK) | (h >> 19)
	h = imul32(h ^ (h >> 16), 2246822507)
	h = imul32(h ^ (h >> 13), 3266489909)
	h = h ^ (h >> 16)
	return h & MASK


## mulberry32 mit externem Zustand o["rs"], wie rnd(o) in engine.js.
static func rnd(o: Dictionary) -> float:
	o["rs"] = (int(o["rs"]) + 0x6D2B79F5) & MASK
	var t: int = o["rs"]
	t = imul32(t ^ (t >> 15), t | 1)
	t = (t ^ ((t + imul32(t ^ (t >> 7), t | 61)) & MASK)) & MASK
	return float((t ^ (t >> 14)) & MASK) / 4294967296.0


## Fisher-Yates wie shuffle(arr, o) in engine.js. Gibt eine neue Liste zurück.
static func shuffle(arr: Array, o: Dictionary) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := int(floor(rnd(o) * (i + 1)))
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t
	return a
```

- [ ] **Step 4: Tests laufen lassen**

```bash
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_rng.gd -gexit
```

Erwartung: 6/6 grün. **Wenn `test_hash_matches_js` scheitert, nicht weiter.** Fehlerbild an mich, denn alles Spätere baut auf diesem Hash auf.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/widerlegung_rng.gd test/gut/test_widerlegung_rng.gd
git commit -m "feat(widerlegung): Zufall bitgleich zur JS-Engine (imul32, hashStr, mulberry32, shuffle)"
```

---

### Task 4: Regeln laden und urteilen

**Files:**
- Create: `scripts/core/widerlegung_rules.gd` (erster Teil: Laden, Logik der Lehre, Nachbessern)
- Test: `test/gut/test_widerlegung_rules.gd` (erster Teil: Tests 1–6 der Huhn-Suite)

**Interfaces:**
- Consumes: `WiderlegungRng` aus Task 3.
- Produces:
  - `WiderlegungRules.load_data() -> Dictionary` mit `instanzen: Array[Dictionary]`, `rhetorik`, `kniffe`, `raenge`, bei Fehler `{"error": String}`.
  - `WiderlegungRules.index_of(data: Dictionary, lehre_id: String) -> int`
  - `WiderlegungRules.prepare(D: Dictionary) -> String` (leer = ok). Legt an: `D["card_map"]`, je Karte `attr_set: Dictionary` und `member: bool`, `D["prisma_lits"]`, `D["start_lits"]`.
  - Literal: `{"a": String, "neg": bool}`. Klausel der Lehre: `{"t": "req"|"gone"|"excl"|"incl", "a"?, "neg"?, "id"?, "fresh"?, "painted"?}`.
  - `initial_lehre(D) -> Array`, `lit_holds(card, l) -> bool`, `satisfies(card, lehre) -> bool`, `judge(card, lehre) -> String` (`"broad"`, `"narrow"`, `"confirm"`), `weight(lehre) -> int`, `patch_broad(D, st, card, force) -> Dictionary`, `patch_narrow(D, st, card, force) -> Dictionary`, `free_lits(D, st) -> Array`, `lit_phrase(D, l) -> String`, `lehre_view(D, lehre) -> Dictionary`.
  - Zustand einer Instanz (`st`) nutzt die Schlüssel `lehre`, `members`, `non_members` (JS: `nonMembers`).

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`test/gut/test_widerlegung_rules.gd`:

```gdscript
# PURPOSE: Die 13 Regeltests aus huhn/test/engine.test.js, übertragen auf WiderlegungRules.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungRules, test/gut/helpers/widerlegung_canon.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

var data: Dictionary = {}


func before_all() -> void:
	data = WiderlegungRules.load_data()


func _inst(lehre_id: String) -> Dictionary:
	return data["instanzen"][WiderlegungRules.index_of(data, lehre_id)]


func test_data_loads_without_error() -> void:
	assert_false(data.has("error"), str(data.get("error", "")))
	assert_eq((data["instanzen"] as Array).size(), 5)


func test_startlehre_platon() -> void:
	var D := _inst("akademie")
	var lehre := WiderlegungRules.initial_lehre(D)
	assert_eq(WiderlegungRules.judge(D["card_map"]["huhn"], lehre), "broad")
	assert_eq(WiderlegungRules.judge(D["card_map"]["saeugling"], lehre), "narrow")
	assert_eq(WiderlegungRules.judge(D["card_map"]["pferd"], lehre), "confirm")
```

Nur diese zwei Tests in Task 4. Godot prüft statische Aufrufe auf eine `class_name` schon beim Parsen: Ein Test, der `new_run` oder `play` aufruft, bevor es sie gibt, lässt die ganze Datei scheitern. Die Spiel-Tests kommen deshalb erst in Task 5.

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_rules.gd -gexit
```

Erwartung: FAIL, „Identifier WiderlegungRules not declared".

- [ ] **Step 3: Ersten Teil implementieren**

`scripts/core/widerlegung_rules.gd`:

```gdscript
# PURPOSE: Regeln der Widerlegung, 1:1-Port von huhn/engine.js: laden, urteilen, nachbessern, Gewicht, Herzschlag, Kniffe, Vorgang.
# ARCHITECTURE: core
# DEPENDENCIES: WiderlegungRng
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name WiderlegungRules
extends RefCounted

const CONTENT_DIR := "res://addons/lobby_loop/content/widerlegung/"
const GAIN := {"add": 1, "repair": 1, "excl": 3, "incl": 3, "confirm": 0}


# ---------------------------------------------------------------- Daten

## Lädt _common.json und alle Lehren in der Reihenfolge "order".
## Ergebnis {"instanzen", "rhetorik", "kniffe", "raenge"} oder {"error": "..."}.
static func load_data() -> Dictionary:
	var common: Variant = _load_json(CONTENT_DIR + "_common.json")
	if not (common is Dictionary):
		return {"error": "content/widerlegung/_common.json fehlt oder ist kaputt"}
	var data := {
		"instanzen": [],
		"rhetorik": common.get("rhetorik", {}),
		"kniffe": common.get("kniffe", []),
		"raenge": common.get("raenge", []),
	}
	for id in common.get("order", []):
		var lehre: Variant = _load_json(CONTENT_DIR + str(id) + ".json")
		if not (lehre is Dictionary):
			return {"error": "Lehre %s fehlt oder ist kaputt" % str(id)}
		var err := prepare(lehre)
		if not err.is_empty():
			return {"error": err}
		data["instanzen"].append(lehre)
	return data


static func index_of(data: Dictionary, lehre_id: String) -> int:
	var list: Array = data.get("instanzen", [])
	for i in list.size():
		if str(list[i].get("id", "")) == lehre_id:
			return i
	return -1


## Wie setData() in engine.js: Kartenindex, Merkmal-Sets, Literale, Plausibilitätsprüfung.
## Liefert "" bei Erfolg, sonst die Fehlermeldung.
static func prepare(D: Dictionary) -> String:
	# Godot-JSON liefert alle Zahlen als float.
	for key in ["hand", "wuerfe", "cap"]:
		D[key] = int(D.get(key, 0))
	var card_map := {}
	for c in D.get("cards", []):
		var attrs := {}
		for a in str(c.get("a", "")).split(" ", false):
			if not D["attrs"].has(a):
				return "Unbekanntes Merkmal \"%s\" bei Karte %s in %s" % [a, c["id"], D["id"]]
			attrs[a] = true
		c["attr_set"] = attrs
		c["member"] = bool(c.get("m", false))
		if card_map.has(c["id"]):
			return "Doppelte Karte %s in %s" % [c["id"], D["id"]]
		card_map[c["id"]] = c
	D["card_map"] = card_map
	D["prisma_lits"] = _parse_lits(D.get("prisma", []))
	D["start_lits"] = _parse_lits(D.get("start", []))
	for l in D["prisma_lits"] + D["start_lits"]:
		if not D["attrs"].has(l["a"]):
			return "Prisma/Start: unbekanntes Merkmal %s in %s" % [l["a"], D["id"]]
	for id in D.get("refMembers", []) + D.get("refNon", []):
		if not card_map.has(id):
			return "Referenzkarte fehlt: %s" % id
	var start := initial_lehre(D)
	for id in D["refMembers"]:
		var member: Dictionary = card_map[id]
		if not member["member"] or not satisfies(member, start):
			return "Referenzmitglied passt nicht zur Startlehre: %s" % id
	for id in D["refNon"]:
		var non: Dictionary = card_map[id]
		if non["member"] or satisfies(non, start):
			return "Referenz-Nichtmitglied passt zur Startlehre: %s" % id
	return ""


static func parse_lit(s: String) -> Dictionary:
	return {"a": s.substr(1), "neg": s.begins_with("-")}


static func _parse_lits(list: Array) -> Array:
	var out := []
	for s in list:
		out.append(parse_lit(str(s)))
	return out


static func initial_lehre(D: Dictionary) -> Array:
	var out := []
	for l in D["start_lits"]:
		out.append({"t": "req", "a": l["a"], "neg": l["neg"]})
	return out


static func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


# ---------------------------------------------------------------- Logik der Lehre

static func lit_holds(card: Dictionary, l: Dictionary) -> bool:
	var has: bool = card["attr_set"].has(l["a"])
	return not has if l["neg"] else has


static func satisfies(card: Dictionary, lehre: Array) -> bool:
	for c in lehre:
		if c["t"] == "excl" and c.get("id") == card["id"]:
			return false
	for c in lehre:
		if c["t"] == "incl" and c.get("id") == card["id"]:
			return true
	for c in lehre:
		if c["t"] == "req" and not lit_holds(card, c):
			return false
	return true


static func judge(card: Dictionary, lehre: Array) -> String:
	var sat := satisfies(card, lehre)
	if sat and not card["member"]:
		return "broad"
	if not sat and card["member"]:
		return "narrow"
	return "confirm"


## Jede Bestimmung wiegt 1, auch weggefallene (das Amt löscht nichts). Ausnahmen 3, überstrichen 1.
static func weight(lehre: Array) -> int:
	var w := 0
	for c in lehre:
		if c["t"] == "req" or c["t"] == "gone":
			w += 1
		elif c.get("painted", false):
			w += 1
		else:
			w += 3
	return w


static func incl_ids(lehre: Array) -> Dictionary:
	var s := {}
	for c in lehre:
		if c["t"] == "incl":
			s[c["id"]] = true
	return s


static func used_attrs(lehre: Array) -> Dictionary:
	var s := {}
	for c in lehre:
		if c["t"] == "req" or c["t"] == "gone":
			s[c["a"]] = true
	return s


static func _cards(D: Dictionary, ids: Array) -> Array:
	var out := []
	for id in ids:
		out.append(D["card_map"][id])
	return out


static func _all_hold(cards: Array, l: Dictionary) -> bool:
	for c in cards:
		if not lit_holds(c, l):
			return false
	return true


static func _leaks(nons: Array, lehre: Array) -> Array:
	var out := []
	for n in nons:
		if satisfies(n, lehre):
			out.append(n)
	return out


static func _active_members(D: Dictionary, member_ids: Array, lehre: Array) -> Array:
	var incl := incl_ids(lehre)
	var out := []
	for id in member_ids:
		if not incl.has(id):
			out.append(D["card_map"][id])
	return out


## Zu weit: ein Nicht-Mitglied erfüllt die Lehre.
static func patch_broad(D: Dictionary, st: Dictionary, card: Dictionary, force: bool) -> Dictionary:
	var active := _active_members(D, st["members"], st["lehre"])
	if not force:
		var used := used_attrs(st["lehre"])
		for l in D["prisma_lits"]:
			if used.has(l["a"]):
				continue
			if lit_holds(card, l):
				continue
			if _all_hold(active, l):
				st["lehre"].append({"t": "req", "a": l["a"], "neg": l["neg"], "fresh": true})
				return {"kind": "add", "lit": l}
	st["lehre"].append({"t": "excl", "id": card["id"], "fresh": true})
	return {"kind": "excl"}


## Zu eng: ein Mitglied erfüllt die Lehre nicht.
static func patch_narrow(D: Dictionary, st: Dictionary, card: Dictionary, force: bool) -> Dictionary:
	if not force:
		var failing := []
		var base := []
		for c in st["lehre"]:
			if c["t"] == "req" and not lit_holds(card, c):
				failing.append(c)
				# gestrichene Bestimmungen bleiben als "weggefallen" im Text stehen
				base.append({"t": "gone", "a": c["a"], "neg": c["neg"], "fresh": true})
			else:
				base.append(c)
		var mems := _active_members(D, st["members"] + [card["id"]], base)
		var nons := _cards(D, st["non_members"])
		var def := base.duplicate()
		var added := []
		var leaks := _leaks(nons, def)
		while not leaks.is_empty():
			var used := used_attrs(def)
			var found: Variant = null
			for l in D["prisma_lits"]:
				if used.has(l["a"]):
					continue
				if not _all_hold(mems, l):
					continue
				var blocks_leak := false
				for n in leaks:
					if not lit_holds(n, l):
						blocks_leak = true
						break
				if blocks_leak:
					found = l
					break
			if found == null:
				break
			def.append({"t": "req", "a": found["a"], "neg": found["neg"], "fresh": true})
			added.append(found)
			leaks = _leaks(nons, def)
		if leaks.is_empty():
			st["lehre"] = def
			var removed := []
			for c in failing:
				removed.append({"a": c["a"], "neg": c["neg"]})
			return {"kind": "repair", "removed": removed, "added": added}
	st["lehre"].append({"t": "incl", "id": card["id"], "fresh": true})
	return {"kind": "incl"}


## Prisma-Merkmale, die der Gegner noch verwenden kann.
static func free_lits(D: Dictionary, st: Dictionary) -> Array:
	var used := used_attrs(st["lehre"])
	var mems := _active_members(D, st["members"], st["lehre"])
	var out := []
	for l in D["prisma_lits"]:
		if not used.has(l["a"]) and _all_hold(mems, l):
			out.append(l)
	return out


# ---------------------------------------------------------------- Text der Lehre

static func lit_phrase(D: Dictionary, l: Dictionary) -> String:
	var attr: Dictionary = D["attrs"][l["a"]]
	return str(attr["neg"]) if l["neg"] else str(attr["pos"])


static func lehre_view(D: Dictionary, lehre: Array) -> Dictionary:
	var reqs := []
	var excl := []
	var incl := []
	for c in lehre:
		if c["t"] == "req" or c["t"] == "gone":
			reqs.append({"text": lit_phrase(D, c), "fresh": bool(c.get("fresh", false)), "gone": c["t"] == "gone"})
		elif c["t"] == "excl":
			excl.append({"id": c["id"], "name": D["card_map"][c["id"]]["name"], "fresh": bool(c.get("fresh", false)), "painted": bool(c.get("painted", false))})
		else:
			incl.append({"id": c["id"], "name": D["card_map"][c["id"]]["name"], "fresh": bool(c.get("fresh", false)), "painted": bool(c.get("painted", false))})
	return {"reqs": reqs, "excl": excl, "incl": incl}
```

- [ ] **Step 4: Tests laufen lassen**

```bash
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_rules.gd -gexit
```

Erwartung: 2/2 grün (`test_data_loads_without_error`, `test_startlehre_platon`).

- [ ] **Step 5: Commit**

```bash
git add scripts/core/widerlegung_rules.gd test/gut/test_widerlegung_rules.gd
git commit -m "feat(widerlegung): Lehren laden, urteilen, Gewicht, nachbessern (Port engine.js)"
```

---

### Task 5: Eine Instanz spielen (Wurf, Herzschlag, Kniffe, Laterne)

**Files:**
- Modify: `scripts/core/widerlegung_rules.gd` (anhängen)
- Create: `test/gut/helpers/widerlegung_canon.gd`
- Modify: `test/gut/test_widerlegung_rules.gd` (Tests 7–13 anhängen)

**Interfaces:**
- Consumes: alles aus Task 4.
- Produces:
  - `new_run(az: String, opts: Dictionary = {}) -> Dictionary` mit Schlüsseln `az`, `daily`, `kniffe`, `total`, `results`, `alexander`, `idx`, `phase`, `streng`, `inst`, `offers`.
  - `start_instanz(data, run) -> Dictionary` (setzt `run["inst"]`, `run["phase"] = "play"`).
  - Instanz `st`: `id`, `rs`, `lehre`, `members`, `non_members`, `hand`, `deck`, `wuerfe`, `wuerfe_start`, `cap`, `cap_start`, `extra`, `score`, `plays`, `beats`, `rhet_idx`, `telegraph`, `status` (`"play"`, `"collapse"`, `"hold"`), `seized`, `used`, `uniform_armed`, `sonne_done`, `first_widerlegung`, `history`, `exceptions`, `bonus`.
  - `play(data, run, card_id) -> Array` von Ereignissen mit `type` in `throw`, `patch`, `draw`, `beat`, `telegraph`, `collapse`, `hold`.
  - `last(st) -> int`, `use_kniff(run, id) -> Variant`, `preview(data, run, card_id) -> Dictionary` (`kind`, `verdict`, `frei`, `gain`, `last`, `collapse`, …), `has_kniff(run, id) -> bool`.
  - `run["results"]`-Eintrag: `id`, `collapsed`, `at_wurf`, `score`, `exceptions`, `last`, `cap`, `lehre`.
  - Hilfsskript `widerlegung_canon.gd`: `event(e) -> String`, `start(st) -> String`, `result(r) -> String`, `join(arr) -> String`. Textform exakt wie `canonEvent`, `canonStart`, `canonResult` in `tools/export-widerlegung.ts`.

- [ ] **Step 1: Hilfsskript für die Textform**

`test/gut/helpers/widerlegung_canon.gd` (kein `test_`-Präfix, GUT sammelt es nicht ein):

```gdscript
# PURPOSE: Textform von Engine-Ereignissen, exakt wie canonEvent/canonStart/canonResult in tools/export-widerlegung.ts.
# ARCHITECTURE: test
# DEPENDENCIES: none
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends RefCounted

const FIELDS := [
	"type", "card", "verdict", "kind", "gain", "last", "frei", "effect",
	"rhet", "cap", "bonus", "score", "drawn", "id", "dudelsack", "uniform",
]


static func join(arr: Array, sep: String = ",") -> String:
	var parts := PackedStringArray()
	for v in arr:
		parts.append(str(v))
	return sep.join(parts)


static func _lit(l: Dictionary) -> String:
	return ("-" if l["neg"] else "+") + str(l["a"])


static func event(e: Dictionary) -> String:
	var parts := PackedStringArray()
	for k in FIELDS:
		var v: Variant = e.get(k)
		if v == null:
			parts.append("")
		elif v is bool:
			parts.append("1" if v else "0")
		else:
			parts.append(str(v))
	if e.get("lit") != null:
		parts.append(_lit(e["lit"]))
	if e.get("tg") != null:
		var tg: Dictionary = e["tg"]
		parts.append(str(tg["type"]) + ">" + (str(tg["target"]) if tg.get("target") != null else ""))
	if e.get("added") != null:
		var lits := []
		for l in e["added"]:
			lits.append(_lit(l))
		parts.append("add=" + join(lits))
	return "|".join(parts)


static func start(st: Dictionary) -> String:
	var tg_text := ""
	if st.get("telegraph") != null:
		var tg: Dictionary = st["telegraph"]
		tg_text = str(tg["type"]) + ">" + (str(tg["target"]) if tg.get("target") != null else "")
	return join([join(st["hand"]), join(st["deck"]), st["cap"], st["wuerfe"], tg_text], "/")


static func _clause(c: Dictionary) -> String:
	var key: String = str(c["a"]) if c.has("a") else str(c["id"])
	return str(c["t"]) + ":" + key + ("-" if c.get("neg", false) else "") + ("*" if c.get("painted", false) else "")


static func result(r: Dictionary) -> String:
	var clauses := []
	for c in r["lehre"]:
		clauses.append(_clause(c))
	return join([1 if r["collapsed"] else 0, r["at_wurf"], r["score"], r["exceptions"], r["last"], r["cap"], join(clauses)], "|")
```

- [ ] **Step 2: Die Spiel-Tests 2–13 anhängen**

Oben in `test/gut/test_widerlegung_rules.gd` unter `extends GutTest` ergänzen:

```gdscript
const Canon := preload("res://addons/lobby_loop/test/gut/helpers/widerlegung_canon.gd")
```

Am Ende der Datei anhängen, zuerst Hilfsfunktionen und die Tests 2–6 der JS-Suite:

```gdscript
func _start_at(idx: int, az: String = "TEST-1") -> Dictionary:
	var run := WiderlegungRules.new_run(az)
	run["idx"] = idx
	WiderlegungRules.start_instanz(data, run)
	return run


func _patch(events: Array) -> Dictionary:
	for e in events:
		if e["type"] == "patch":
			return e
	return {}


func test_patch_broad_takes_first_prisma_lit() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["huhn"]
	var p := _patch(WiderlegungRules.play(data, r, "huhn"))
	assert_eq(p["kind"], "add")
	assert_eq(p["lit"]["a"], "naegel")
	assert_eq(WiderlegungRules.last(r["inst"]), 4)


func test_patch_broad_without_free_lit_makes_exception() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["hermes"]
	var p := _patch(WiderlegungRules.play(data, r, "hermes"))
	assert_eq(p["kind"], "excl")
	assert_eq(WiderlegungRules.last(r["inst"]), 6)


func test_blockade_then_exception() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["pythagoreer", "kyklop", "huhn"]
	r["inst"]["deck"] = []
	assert_eq(_patch(WiderlegungRules.play(data, r, "pythagoreer"))["kind"], "confirm")
	assert_eq(_patch(WiderlegungRules.play(data, r, "kyklop"))["kind"], "excl")


func test_patch_narrow_keeps_gone_clause() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["veteran"]
	var before := WiderlegungRules.last(r["inst"])
	var p := _patch(WiderlegungRules.play(data, r, "veteran"))
	assert_eq(p["kind"], "repair")
	var has_gone := false
	for c in r["inst"]["lehre"]:
		if c["t"] == "gone" and c["a"] == "zweibeinig":
			has_gone = true
	assert_true(has_gone, "gestrichene Bestimmung bleibt als weggefallen stehen")
	assert_true(WiderlegungRules.last(r["inst"]) >= before)


func test_patch_narrow_with_leak_makes_inclusion() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["kyklop", "pythagoreer"]
	r["inst"]["deck"] = []
	assert_eq(_patch(WiderlegungRules.play(data, r, "kyklop"))["lit"]["a"], "lacht")
	assert_eq(_patch(WiderlegungRules.play(data, r, "pythagoreer"))["kind"], "incl")
```

Dann die Tests 7–13:

```gdscript
func test_invariant_10000_random_moves() -> void:
	var violations := []
	var moves := 0
	var s := 0
	while moves < 10000:
		for idx in (data["instanzen"] as Array).size():
			var r := _start_at(idx, "INV-%d" % s)
			var D: Dictionary = data["instanzen"][idx]
			while r["inst"]["status"] == "play":
				var hand: Array = r["inst"]["hand"]
				WiderlegungRules.play(data, r, hand[(s * 7 + moves) % hand.size()])
				moves += 1
				for id in r["inst"]["members"]:
					if not WiderlegungRules.satisfies(D["card_map"][id], r["inst"]["lehre"]):
						violations.append("Mitglied ausgeschlossen: %s in %s" % [id, D["id"]])
				for id in r["inst"]["non_members"]:
					if WiderlegungRules.satisfies(D["card_map"][id], r["inst"]["lehre"]):
						violations.append("Nicht-Mitglied eingeschlossen: %s in %s" % [id, D["id"]])
		s += 1
	assert_eq(violations, [], "Lehre ordnet nach jedem Zug alle Fallakten richtig ein")


func _play_log(az: String) -> String:
	var r := WiderlegungRules.new_run(az)
	var log := []
	while r["phase"] != "end":
		match r["phase"]:
			"intro":
				WiderlegungRules.start_instanz(data, r)
				log.append(Canon.join(r["inst"]["hand"]))
				log.append(Canon.join(r["inst"]["deck"]))
			"play":
				for e in WiderlegungRules.play(data, r, r["inst"]["hand"][0]):
					log.append(Canon.event(e))
			"result":
				WiderlegungRules.next_phase(data, r)
			"tonne":
				log.append(Canon.join(r["offers"]))
				WiderlegungRules.choose_kniff(data, r, r["offers"][0])
			"alexander":
				WiderlegungRules.choose_alexander(r, "sonne")
	log.append(str(r["total"]))
	log.append(WiderlegungRules.pruefcode(r))
	return Canon.join(log, "|")


func test_determinism_same_az_same_game() -> void:
	assert_eq(_play_log("HUHN-20261011"), _play_log("HUHN-20261011"))
	assert_ne(_play_log("HUHN-20261011"), _play_log("HUHN-20261012"))


func test_preview_changes_nothing_and_predicts() -> void:
	var mismatches := []
	for s in 200:
		var r := _start_at(s % 5, "PV-%d" % s)
		while r["inst"]["status"] == "play":
			var id: String = r["inst"]["hand"][0]
			var snap := JSON.stringify(r["inst"])
			var p := WiderlegungRules.preview(data, r, id)
			if JSON.stringify(r["inst"]) != snap:
				mismatches.append("Laterne veränderte Zustand (PV-%d)" % s)
			var pe := _patch(WiderlegungRules.play(data, r, id))
			if pe["kind"] != p["kind"] or pe["last"] != p["last"]:
				mismatches.append("Laterne lag falsch bei %s (PV-%d)" % [id, s])
	assert_eq(mismatches, [])


func test_kniffe_inspektion_huhn2_uniform() -> void:
	var r := WiderlegungRules.new_run("K-1", {"kniffe": ["inspektion", "huhn2", "uniform"]})
	WiderlegungRules.start_instanz(data, r)
	assert_eq(r["inst"]["cap"], int(data["instanzen"][0]["cap"]) - 1)
	assert_eq(r["inst"]["wuerfe"], int(data["instanzen"][0]["wuerfe"]) + 1)
	r["inst"]["hand"] = ["huhn", "kaenguru"]
	WiderlegungRules.use_kniff(r, "uniform")
	assert_eq(_patch(WiderlegungRules.play(data, r, "huhn"))["kind"], "excl")
	assert_null(WiderlegungRules.use_kniff(r, "uniform"), "nur einmal je Instanz")


func test_heartbeat_autoritaet_seizes_marked_card() -> void:
	var r := _start_at(0, "HB-3")
	var tg: Dictionary = r["inst"]["telegraph"]
	assert_eq(tg["type"], "autoritaet")
	var target: String = tg["target"]
	var beat: Dictionary = {}
	for i in 3:
		if r["inst"]["status"] != "play":
			break
		var id: String = ""
		for h in r["inst"]["hand"]:
			if h != target:
				id = h
				break
		for e in WiderlegungRules.play(data, r, id):
			if e["type"] == "beat":
				beat = e
	if r["inst"]["status"] == "play":
		assert_false(beat.is_empty(), "Herzschlag nach dem dritten Wurf")
		assert_eq(beat["effect"], "seized")
		assert_false((r["inst"]["hand"] as Array).has(target))


func test_pruefcode_is_four_hex_chars() -> void:
	var r := WiderlegungRules.new_run("HUHN-20261011")
	while r["phase"] != "end":
		match r["phase"]:
			"intro": WiderlegungRules.start_instanz(data, r)
			"play": WiderlegungRules.play(data, r, r["inst"]["hand"][0])
			"result": WiderlegungRules.next_phase(data, r)
			"tonne": WiderlegungRules.choose_kniff(data, r, r["offers"][0])
			"alexander": WiderlegungRules.choose_alexander(r, "gold")
	var code := WiderlegungRules.pruefcode(r)
	assert_true(RegEx.create_from_string("^[0-9A-F]{4}$").search(code) != null, code)


func test_beweisaufnahme_blocking_confirm_is_free() -> void:
	var r := _start_at(0)
	r["inst"]["hand"] = ["pythagoreer", "kyklop", "huhn"]
	r["inst"]["deck"] = []
	var w: int = r["inst"]["wuerfe"]
	var pv := WiderlegungRules.preview(data, r, "pythagoreer")
	assert_true(pv["frei"] and (pv["blocks"] as Array).size() >= 1)
	var p := _patch(WiderlegungRules.play(data, r, "pythagoreer"))
	assert_true(p["frei"])
	assert_eq(r["inst"]["wuerfe"], w)
	assert_eq(r["inst"]["plays"], 1)
	# nicht blockierende Bestätigung kostet einen Wurf
	var r2 := _start_at(1)
	var D: Dictionary = data["instanzen"][1]
	var id := ""
	for c in D["cards"]:
		if not c["member"] and not WiderlegungRules.satisfies(c, r2["inst"]["lehre"]) and not (D["refNon"] as Array).has(c["id"]):
			id = c["id"]
			break
	r2["inst"]["hand"] = [id]
	r2["inst"]["deck"] = ["bett"]
	var w2: int = r2["inst"]["wuerfe"]
	WiderlegungRules.play(data, r2, id)
	assert_eq(r2["inst"]["wuerfe"], w2 - 1)
```

Hinweis zu Test 12 der JS-Suite („Teilen-Text"): Lobby-Loop braucht keinen Teilen-Text. Der Test wird durch `test_pruefcode_is_four_hex_chars` ersetzt. Dass der Prüfcode exakt der JS-Fassung entspricht, prüft der Golden-Test in Task 6 über die 10 vollständigen Vorgänge.

- [ ] **Step 3: Tests laufen lassen, sie müssen scheitern**

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_rules.gd -gexit
```

Erwartung: FAIL, Parser-Fehler „Static function "new_run()" not found in base WiderlegungRules". Die ganze Datei lädt nicht, bis Step 4 die Funktionen liefert.

- [ ] **Step 4: Instanz und Vorgang implementieren**

An `scripts/core/widerlegung_rules.gd` anhängen:

```gdscript
# ---------------------------------------------------------------- Vorgang

static func norm_az(s: String) -> String:
	return RegEx.create_from_string("\\s+").sub(s.strip_edges().to_upper(), "", true)


static func new_run(az: String, opts: Dictionary = {}) -> Dictionary:
	var n := norm_az(az)
	var kniffe: Array = opts.get("kniffe", [])
	return {
		"az": n,
		"daily": RegEx.create_from_string("^HUHN-\\d{8}$").search(n) != null,
		"kniffe": kniffe.duplicate(),
		"total": 0,
		"results": [],
		"alexander": null,
		"idx": 0,
		"phase": "intro",
		"streng": bool(opts.get("streng", false)),
		"inst": null,
		"offers": null,
	}


static func has_kniff(run: Dictionary, id: String) -> bool:
	return (run["kniffe"] as Array).has(id)


static func start_instanz(data: Dictionary, run: Dictionary) -> Dictionary:
	var D: Dictionary = data["instanzen"][run["idx"]]
	var o := {"rs": WiderlegungRng.hash_str(str(run["az"]) + "#" + str(D["id"]))}
	var pool := []
	for c in D["cards"]:
		if not (D["refMembers"] as Array).has(c["id"]) and not (D["refNon"] as Array).has(c["id"]):
			pool.append(c["id"])
	var deck := WiderlegungRng.shuffle(pool, o)
	var hand_n: int = D["hand"]
	# feste Startkarten (Tutorial: das Huhn liegt immer in der ersten Hand)
	if D.has("fixedHand"):
		for id in D["fixedHand"]:
			var i := deck.find(id)
			if i >= hand_n:
				var t: Variant = deck[i]
				deck[i] = deck[0]
				deck[0] = t
	var cap: int = D["cap"]
	var wuerfe: int = D["wuerfe"]
	if has_kniff(run, "inspektion"):
		cap -= 1
	if has_kniff(run, "huhn2"):
		wuerfe += 1
	if int(run["idx"]) == (data["instanzen"] as Array).size() - 1 and run["alexander"] == "gold":
		cap += 2
	var st := {
		"id": D["id"],
		"rs": o["rs"],
		"lehre": initial_lehre(D),
		"members": (D["refMembers"] as Array).duplicate(),
		"non_members": (D["refNon"] as Array).duplicate(),
		"hand": deck.slice(0, hand_n),
		"deck": deck.slice(hand_n),
		"wuerfe": wuerfe,
		"wuerfe_start": wuerfe,
		"cap": cap,
		"cap_start": cap,
		"extra": 0,
		"score": 0,
		"plays": 0,
		"beats": 0,
		"rhet_idx": 0,
		"telegraph": null,
		"status": "play",
		"seized": [],
		"used": {"fass": false, "uniform": false, "bettwaermer": false},
		"uniform_armed": false,
		"sonne_done": false,
		"first_widerlegung": true,
		"history": [],
		"exceptions": 0,
		"bonus": 0,
	}
	st["telegraph"] = make_telegraph(D, st)
	run["inst"] = st
	run["phase"] = "play"
	return st


static func make_telegraph(D: Dictionary, st: Dictionary) -> Variant:
	var seq: Array = D.get("rhetorik", [])
	if seq.is_empty():
		return null
	var rhet: String = seq[int(st["rhet_idx"]) % seq.size()]
	var tg := {"type": rhet, "target": null}
	var hand: Array = st["hand"]
	if rhet == "autoritaet" and not hand.is_empty():
		tg["target"] = hand[int(floor(WiderlegungRng.rnd(st) * hand.size()))]
	return tg


static func last(st: Dictionary) -> int:
	return weight(st["lehre"]) + int(st["extra"])


static func _draw_one(st: Dictionary) -> Variant:
	var deck: Array = st["deck"]
	if deck.is_empty():
		return null
	var id: Variant = deck.pop_front()
	st["hand"].append(id)
	return id


## Wirft eine Karte. Liefert die Ereignisliste für die Oberfläche.
static func play(data: Dictionary, run: Dictionary, card_id: String) -> Array:
	var st: Variant = run.get("inst")
	if st == null or st["status"] != "play":
		return []
	var D: Dictionary = data["instanzen"][run["idx"]]
	var hi: int = st["hand"].find(card_id)
	if hi < 0:
		return []
	for c in st["lehre"]:
		c.erase("fresh")
	var card: Dictionary = D["card_map"][card_id]
	var ev := []
	st["hand"].remove_at(hi)
	var verdict := judge(card, st["lehre"])
	ev.append({"type": "throw", "card": card_id, "verdict": verdict})

	var res: Dictionary
	if verdict == "broad":
		var force: bool = st["uniform_armed"]
		res = patch_broad(D, st, card, force)
		st["non_members"].append(card_id)
		if force:
			st["uniform_armed"] = false
			res["uniform"] = true
	elif verdict == "narrow":
		var force: bool = st["uniform_armed"]
		res = patch_narrow(D, st, card, force)
		st["members"].append(card_id)
		if force:
			st["uniform_armed"] = false
			res["uniform"] = true
	else:
		var blocks := []
		if card["member"]:
			for l in free_lits(D, st):
				if not lit_holds(card, l):
					blocks.append(l)
		res = {"kind": "confirm", "blocks": blocks, "frei": not blocks.is_empty()}
		if card["member"]:
			st["members"].append(card_id)
		else:
			st["non_members"].append(card_id)
	res["card"] = card_id
	res["gain"] = GAIN[res["kind"]]
	if res["kind"] == "excl" or res["kind"] == "incl":
		st["exceptions"] += 1
	if verdict != "confirm" and st["first_widerlegung"]:
		st["first_widerlegung"] = false
		if has_kniff(run, "dudelsack"):
			st["extra"] += 1
			res["dudelsack"] = true
	st["score"] += res["gain"]
	res["last"] = last(st)
	var patch := {"type": "patch"}
	patch.merge(res)
	ev.append(patch)
	st["history"].append({"card": card_id, "verdict": verdict, "kind": res["kind"]})

	st["plays"] += 1
	# Beweisaufnahme: Eine Bestätigung, die dem Gegner ein freies Merkmal blockiert, kostet keinen Wurf.
	if not res.get("frei", false):
		st["wuerfe"] -= 1

	var drawn: Variant = _draw_one(st)
	if drawn != null:
		ev.append({"type": "draw", "card": drawn})

	if last(st) >= int(st["cap"]):
		_finish_instanz(data, run, true, ev)
		return ev

	if int(st["plays"]) % 3 == 0 and st["telegraph"] != null:
		_heartbeat(run, D, st, ev)

	if int(st["wuerfe"]) <= 0 or (st["hand"] as Array).is_empty():
		_finish_instanz(data, run, false, ev)
	return ev


static func _heartbeat(run: Dictionary, D: Dictionary, st: Dictionary, ev: Array) -> void:
	var tg: Dictionary = st["telegraph"]
	st["beats"] += 1
	var e := {"type": "beat", "rhet": tg["type"], "effect": "fizzle"}
	if has_kniff(run, "sonne") and not st["sonne_done"]:
		st["sonne_done"] = true
		e["effect"] = "sonne"
	elif tg["type"] == "autoritaet":
		var i: int = st["hand"].find(tg["target"]) if tg["target"] != null else -1
		if i >= 0:
			st["hand"].remove_at(i)
			st["seized"].append(tg["target"])
			e["effect"] = "seized"
			e["card"] = tg["target"]
			var d: Variant = _draw_one(st)
			if d != null:
				e["drawn"] = d
	elif tg["type"] == "knappheit":
		st["wuerfe"] = maxi(0, int(st["wuerfe"]) - 1)
		e["effect"] = "wurf"
	elif tg["type"] == "sozial":
		st["cap"] += 1
		e["effect"] = "cap"
	elif tg["type"] == "anstrich":
		var lehre: Array = st["lehre"]
		for i in range(lehre.size() - 1, -1, -1):
			var c: Dictionary = lehre[i]
			if (c["t"] == "excl" or c["t"] == "incl") and not c.get("painted", false):
				c["painted"] = true
				e["effect"] = "painted"
				e["id"] = c["id"]
				break
	e["last"] = last(st)
	e["cap"] = st["cap"]
	ev.append(e)
	st["rhet_idx"] += 1
	st["telegraph"] = make_telegraph(D, st)
	ev.append({"type": "telegraph", "tg": st["telegraph"]})


static func _finish_instanz(data: Dictionary, run: Dictionary, collapsed: bool, ev: Array) -> void:
	var st: Dictionary = run["inst"]
	st["status"] = "collapse" if collapsed else "hold"
	var bonus := 0
	if collapsed:
		bonus = 5 + 2 * maxi(0, int(st["wuerfe"]))
		var is_final := int(run["idx"]) == (data["instanzen"] as Array).size() - 1
		if is_final and run["alexander"] == "sonne":
			bonus += 15
	st["bonus"] = bonus
	st["score"] += bonus
	run["total"] += st["score"]
	var lehre_copy := []
	for c in st["lehre"]:
		var copy: Dictionary = c.duplicate()
		copy.erase("fresh")
		lehre_copy.append(copy)
	run["results"].append({
		"id": st["id"],
		"collapsed": collapsed,
		"at_wurf": st["plays"],
		"score": st["score"],
		"exceptions": st["exceptions"],
		"last": last(st),
		"cap": st["cap"],
		"lehre": lehre_copy,
	})
	run["phase"] = "result"
	ev.append({"type": "collapse" if collapsed else "hold", "bonus": bonus, "score": st["score"]})


# ---------------------------------------------------------------- Kniffe (aktiv)

static func use_kniff(run: Dictionary, id: String) -> Variant:
	var st: Variant = run.get("inst")
	if st == null or st["status"] != "play" or not has_kniff(run, id) or st["used"].get(id, false):
		return null
	if id == "fass":
		st["used"]["fass"] = true
		var old: Array = (st["hand"] as Array).duplicate()
		st["hand"] = []
		st["deck"] = st["deck"] + old
		var drawn := []
		for i in old.size():
			var d: Variant = _draw_one(st)
			if d != null:
				drawn.append(d)
		# Autorität zielt auf eine Karte, die nicht mehr in der Hand ist? Dann neu zielen.
		var tg: Variant = st["telegraph"]
		var hand: Array = st["hand"]
		if tg != null and tg["type"] == "autoritaet" and not hand.has(tg["target"]) and not hand.is_empty():
			tg["target"] = hand[int(floor(WiderlegungRng.rnd(st) * hand.size()))]
		return {"type": "fass", "old": old, "drawn": drawn}
	if id == "uniform":
		st["used"]["uniform"] = true
		st["uniform_armed"] = true
		return {"type": "uniform"}
	if id == "bettwaermer":
		st["used"]["bettwaermer"] = true
		var drawn := []
		for i in 2:
			var d: Variant = _draw_one(st)
			if d != null:
				drawn.append(d)
		return {"type": "bettwaermer", "drawn": drawn}
	return null


## Laterne: was würde der Gegner tun? Ändert nichts.
static func preview(data: Dictionary, run: Dictionary, card_id: String) -> Dictionary:
	var st: Dictionary = run["inst"]
	var D: Dictionary = data["instanzen"][run["idx"]]
	var card: Dictionary = D["card_map"][card_id]
	var lehre_copy := []
	for c in st["lehre"]:
		lehre_copy.append(c.duplicate())
	var tmp := {
		"lehre": lehre_copy,
		"members": (st["members"] as Array).duplicate(),
		"non_members": (st["non_members"] as Array).duplicate(),
	}
	var verdict := judge(card, tmp["lehre"])
	var res: Dictionary
	if verdict == "broad":
		res = patch_broad(D, tmp, card, st["uniform_armed"])
	elif verdict == "narrow":
		res = patch_narrow(D, tmp, card, st["uniform_armed"])
	else:
		var blocks := []
		if card["member"]:
			for l in free_lits(D, tmp):
				if not lit_holds(card, l):
					blocks.append(l)
		res = {"kind": "confirm", "blocks": blocks}
	res["verdict"] = verdict
	res["frei"] = res["kind"] == "confirm" and not (res["blocks"] as Array).is_empty()
	res["gain"] = GAIN[res["kind"]]
	var extra: int = st["extra"]
	if verdict != "confirm" and st["first_widerlegung"] and has_kniff(run, "dudelsack"):
		extra += 1
	res["last"] = weight(tmp["lehre"]) + extra
	res["collapse"] = int(res["last"]) >= int(st["cap"])
	return res


# ---------------------------------------------------------------- Zwischen den Instanzen

static func next_phase(data: Dictionary, run: Dictionary) -> String:
	var n: int = (data["instanzen"] as Array).size()
	if run["phase"] != "result":
		return run["phase"]
	if int(run["idx"]) >= n - 1:
		run["phase"] = "end"
		return "end"
	run["phase"] = "tonne"
	run["offers"] = kniff_offers(data, run)
	return "tonne"


static func kniff_offers(data: Dictionary, run: Dictionary) -> Array:
	var o := {"rs": WiderlegungRng.hash_str(str(run["az"]) + "#tonne" + str(run["idx"]))}
	var avail := []
	for k in data["kniffe"]:
		if not has_kniff(run, k["id"]):
			avail.append(k["id"])
	return WiderlegungRng.shuffle(avail, o).slice(0, 3)


static func choose_kniff(data: Dictionary, run: Dictionary, id: String) -> void:
	if run["phase"] != "tonne":
		return
	if not id.is_empty() and (run["offers"] as Array).has(id) and not has_kniff(run, id):
		run["kniffe"].append(id)
	run["offers"] = null
	run["idx"] = int(run["idx"]) + 1
	if int(run["idx"]) == (data["instanzen"] as Array).size() - 1 and run["alexander"] == null:
		run["phase"] = "alexander"
	else:
		run["phase"] = "intro"


static func choose_alexander(run: Dictionary, choice: String) -> void:
	if run["phase"] != "alexander":
		return
	run["alexander"] = "gold" if choice == "gold" else "sonne"
	if run["alexander"] == "gold":
		run["total"] += 8
	run["phase"] = "intro"


# ---------------------------------------------------------------- Wertung

static func rank(data: Dictionary, total: int) -> Dictionary:
	var raenge: Array = data["raenge"]
	var best: Dictionary = raenge[0]
	for x in raenge:
		if total >= int(x["min"]):
			best = x
	return best


static func pruefcode(run: Dictionary) -> String:
	var parts := PackedStringArray()
	for r in run["results"]:
		parts.append(("E%d" % int(r["at_wurf"]) if r["collapsed"] else "H") + str(r["score"]))
	var s := str(run["az"]) + ("|S" if run["streng"] else "") + "|" + str(run["total"]) + "|" + ",".join(parts) + "|" + (str(run["alexander"]) if run["alexander"] != null else "-")
	return ("%08X" % WiderlegungRng.hash_str(s)).substr(0, 4)
```

Falle beim Port: In JS hat ein Patch-Ereignis für `broad` und `narrow` **kein** Feld `frei`. Nur `confirm` setzt es. Hier deshalb `res.get("frei", false)` lesen und `frei` nie für die anderen Fälle setzen, sonst weicht die Textform im Golden ab.

- [ ] **Step 5: Tests laufen lassen**

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_rules.gd -gexit
```

Erwartung: 14/14 grün (13 übertragene Tests plus `test_data_loads_without_error`). Die Invariante braucht ein paar Sekunden.

- [ ] **Step 6: Commit**

```bash
git add scripts/core/widerlegung_rules.gd test/gut/helpers/widerlegung_canon.gd test/gut/test_widerlegung_rules.gd
git commit -m "feat(widerlegung): Instanz, Herzschlag, Kniffe, Laterne, Vorgang; 13 Regeltests portiert"
```

---

### Task 6: Gleichheitstest 200/200

**Files:**
- Test: `test/gut/test_widerlegung_golden.gd`

**Interfaces:**
- Consumes: `WiderlegungRules` (Task 4–5), `widerlegung_canon.gd` (Task 5), Golden-Format aus Task 2. Die Zugwahl `hand[(plays * 7 + g) % hand.size()]`, die Kniff-Sätze und die Reihenfolge `fass, bettwaermer, uniform` müssen exakt `playGame()` aus `tools/export-widerlegung.ts` entsprechen.

- [ ] **Step 1: Test schreiben**

`test/gut/test_widerlegung_golden.gd`:

```gdscript
# PURPOSE: Gleichheitstest: 200 Partien und 10 Vorgänge liefern in Godot exakt dieselben Züge, Lasten und Punkte wie die JS-Fassung.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungRules, test/gut/helpers/widerlegung_canon.gd, test/golden/widerlegung.json
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const Canon := preload("res://addons/lobby_loop/test/gut/helpers/widerlegung_canon.gd")
const GOLDEN_PATH := "res://addons/lobby_loop/test/golden/widerlegung.json"
const KNIFF_USE_ORDER := ["fass", "bettwaermer", "uniform"]
const MAX_REPORTED := 3

var golden: Dictionary = {}
var data: Dictionary = {}


func before_all() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	if parsed is Dictionary:
		golden = parsed
	data = WiderlegungRules.load_data()


func _play_game(g: int, kniffe: Array) -> Dictionary:
	var n: int = (data["instanzen"] as Array).size()
	var idx := g % n
	var run := WiderlegungRules.new_run("GOLD-%d" % g, {"kniffe": kniffe})
	run["idx"] = idx
	if idx == n - 1:
		run["alexander"] = "sonne" if g % 2 == 0 else "gold"
	var st := WiderlegungRules.start_instanz(data, run)
	var start := Canon.start(st)
	var lines := []
	while run["inst"]["status"] == "play":
		if int(run["inst"]["plays"]) == 1:
			for k in KNIFF_USE_ORDER:
				if WiderlegungRules.use_kniff(run, k) != null:
					lines.append("K|" + k + "|" + Canon.join(run["inst"]["hand"]))
		var hand: Array = run["inst"]["hand"]
		var card: String = hand[(int(run["inst"]["plays"]) * 7 + g) % hand.size()]
		lines.append("P|" + card)
		for e in WiderlegungRules.play(data, run, card):
			lines.append(Canon.event(e))
	return {"start": start, "lines": lines, "result": Canon.result(run["results"][0])}


func _first_diff(want: Dictionary, got: Dictionary) -> String:
	if str(want["start"]) != str(got["start"]):
		return "Start: erwartet %s, bekommen %s" % [want["start"], got["start"]]
	var a: Array = want["lines"]
	var b: Array = got["lines"]
	for i in mini(a.size(), b.size()):
		if str(a[i]) != str(b[i]):
			return "Zeile %d: erwartet %s, bekommen %s" % [i, a[i], b[i]]
	if a.size() != b.size():
		return "Zeilenzahl: erwartet %d, bekommen %d" % [a.size(), b.size()]
	if str(want["result"]) != str(got["result"]):
		return "Ergebnis: erwartet %s, bekommen %s" % [want["result"], got["result"]]
	return ""


func test_200_games_match_js() -> void:
	var games: Array = golden.get("games", [])
	assert_eq(games.size(), 200, "Golden fehlt oder unvollständig")
	var ok := 0
	var reported := 0
	for g in games:
		var diff := _first_diff(g, _play_game(int(g["g"]), g["kniffe"]))
		if diff.is_empty():
			ok += 1
		elif reported < MAX_REPORTED:
			reported += 1
			gut.p("Partie %d (%s, Kniffe %s): %s" % [int(g["g"]), g["az"], g["kniffe"], diff])
	assert_eq(ok, games.size(), "Gleichheitstest %d/%d" % [ok, games.size()])


func _run_full(i: int) -> String:
	var run := WiderlegungRules.new_run("FULL-%d" % i)
	while run["phase"] != "end":
		match run["phase"]:
			"intro": WiderlegungRules.start_instanz(data, run)
			"play": WiderlegungRules.play(data, run, run["inst"]["hand"][0])
			"result": WiderlegungRules.next_phase(data, run)
			"tonne": WiderlegungRules.choose_kniff(data, run, run["offers"][0])
			"alexander": WiderlegungRules.choose_alexander(run, "gold" if i % 2 == 0 else "sonne")
	var results := []
	for r in run["results"]:
		results.append(Canon.result(r))
	return Canon.join([run["total"], WiderlegungRules.pruefcode(run), Canon.join(run["kniffe"]), Canon.join(results, ";")], "|")


func test_full_runs_match_js_including_pruefcode() -> void:
	var full: Array = golden.get("full", [])
	assert_eq(full.size(), 10)
	for i in full.size():
		assert_eq(_run_full(i), str(full[i]), "Vorgang FULL-%d" % i)
```

- [ ] **Step 2: Test laufen lassen**

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_golden.gd -gexit
```

Erwartung: 2/2 grün, Meldung „Gleichheitstest 200/200".

Wenn es scheitert: Die Ausgabe nennt die erste abweichende Zeile von bis zu drei Partien. Typische Ursachen in dieser Reihenfolge prüfen:

1. Eine Zahl ist float (`"9.0"`): fehlender `int()`-Cast.
2. `frei` steht in einem `broad`/`narrow`-Patch: siehe Falle in Task 5.
3. Reihenfolge von Prüfungen in `play()` weicht von `engine.js` Zeile 272–334 ab.
4. Kniff-Auslösung: `use_kniff` muss vor dem zweiten Wurf (`plays == 1`) in der Reihenfolge `fass, bettwaermer, uniform` laufen.

Nach zwei erfolglosen Reparaturversuchen an derselben Abweichung: stopp, Abweichung und beide Versuche an mich (2-Strikes-Regel).

- [ ] **Step 3: Commit**

```bash
git add test/gut/test_widerlegung_golden.gd
git commit -m "test(widerlegung): Gleichheitstest 200/200 Partien und 10 Vorgänge gegen JS"
```

---

### Task 7: Simulation in Godot

Wird in Phase 2 zum Prüfer erfundener Lehren. Hier nur so weit, dass sie die Balance der fünf vorhandenen Lehren bestätigt. Die JS-Simulation nutzt einen eigenen Zufall, der sich in Ganzzahlen nicht exakt nachbauen lässt. Deshalb gibt es hier **Bänder statt Gleichheit**. Gemessen in JS (design.md): Gelegenheit 66–91 % Einsturz, Zufall 7–32 %.

**Files:**
- Create: `scripts/core/widerlegung_sim.gd`
- Test: `test/gut/test_widerlegung_sim.gd`

**Interfaces:**
- Consumes: `WiderlegungRules`, `WiderlegungRng`.
- Produces: `WiderlegungSim.simulate(data: Dictionary, idx: int, strategy: String, n: int, kniffe: Array = []) -> Dictionary` mit `einsturz: float` (0–1), `ausnahme_quote: float`, `avg_ausnahmen: float`, `avg_wurf: float`. Strategien: `"zufall"`, `"gelegenheit"`, `"gierig"`.

- [ ] **Step 1: Test schreiben**

`test/gut/test_widerlegung_sim.gd`:

```gdscript
# PURPOSE: WiderlegungSim: Balance-Bänder der fünf Lehren (Gelegenheit trägt, Zufall nicht), deterministisch.
# ARCHITECTURE: test
# DEPENDENCIES: WiderlegungSim, WiderlegungRules
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const N := 150

var data: Dictionary = {}


func before_all() -> void:
	data = WiderlegungRules.load_data()


func test_bands_per_lehre() -> void:
	for idx in (data["instanzen"] as Array).size():
		var lehre_id: String = data["instanzen"][idx]["id"]
		var gel := WiderlegungSim.simulate(data, idx, "gelegenheit", N)
		var zuf := WiderlegungSim.simulate(data, idx, "zufall", N)
		gut.p("%s: Gelegenheit %.0f %%, Zufall %.0f %%, Ausnahme in %.0f %%" % [lehre_id, gel["einsturz"] * 100, zuf["einsturz"] * 100, gel["ausnahme_quote"] * 100])
		assert_between(float(gel["einsturz"]), 0.55, 0.97, "Gelegenheit trägt in %s" % lehre_id)
		assert_lt(float(zuf["einsturz"]), 0.42, "Zufall trägt nicht in %s" % lehre_id)


func test_gierig_not_worse_than_gelegenheit_akademie() -> void:
	var gel := WiderlegungSim.simulate(data, 0, "gelegenheit", N)
	var gier := WiderlegungSim.simulate(data, 0, "gierig", N)
	assert_true(float(gier["einsturz"]) >= float(gel["einsturz"]) - 0.10)


func test_simulation_is_deterministic() -> void:
	assert_eq(WiderlegungSim.simulate(data, 1, "zufall", 30), WiderlegungSim.simulate(data, 1, "zufall", 30))
```

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_sim.gd -gexit
```

Erwartung: FAIL, „Identifier WiderlegungSim not declared".

- [ ] **Step 3: Implementieren**

`scripts/core/widerlegung_sim.gd`:

```gdscript
# PURPOSE: Balance-Simulation der Widerlegung (Zufall, Gelegenheit, Gierig); Grundlage der Spielbarkeitsprüfung in Phase 2.
# ARCHITECTURE: core
# DEPENDENCIES: WiderlegungRules, WiderlegungRng
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name WiderlegungSim
extends RefCounted

const STRATEGIES := ["zufall", "gelegenheit", "gierig"]


static func _pick(rng: Dictionary, n: int) -> int:
	return int(floor(WiderlegungRng.rnd(rng) * n))


static func choose(data: Dictionary, run: Dictionary, strategy: String, rng: Dictionary) -> String:
	var hand: Array = run["inst"]["hand"]
	if strategy == "gelegenheit":
		# liest nur das Urteil auf der Karte: Gegenbeispiele zuerst, sonst irgendwas
		var D: Dictionary = data["instanzen"][run["idx"]]
		var counter := []
		for id in hand:
			if WiderlegungRules.judge(D["card_map"][id], run["inst"]["lehre"]) != "confirm":
				counter.append(id)
		var pool: Array = counter if not counter.is_empty() else hand
		return pool[_pick(rng, pool.size())]
	if strategy == "gierig":
		# mit Laterne: nimmt den Wurf mit dem größten Lastzuwachs
		var best: String = hand[0]
		var best_value := -1e9
		for id in hand:
			var p := WiderlegungRules.preview(data, run, id)
			var value := (100.0 if p["collapse"] else 0.0) + float(p["last"]) * 3.0 + float(p["gain"]) + WiderlegungRng.rnd(rng) * 0.1
			if value > best_value:
				best_value = value
				best = id
		return best
	return hand[_pick(rng, hand.size())]


static func simulate(data: Dictionary, idx: int, strategy: String, n: int, kniffe: Array = []) -> Dictionary:
	var rng := {"rs": WiderlegungRng.hash_str("SIM#%s#%d" % [strategy, idx])}
	var instanz_count: int = (data["instanzen"] as Array).size()
	var collapsed := 0
	var any_exception := 0
	var exceptions := 0
	var plays_at_collapse := 0
	for s in n:
		var run := WiderlegungRules.new_run("SIM-%d" % s, {"kniffe": kniffe})
		run["idx"] = idx
		if idx == instanz_count - 1:
			run["alexander"] = "sonne"
		WiderlegungRules.start_instanz(data, run)
		while run["inst"]["status"] == "play":
			WiderlegungRules.play(data, run, choose(data, run, strategy, rng))
		var r: Dictionary = run["results"][0]
		if r["collapsed"]:
			collapsed += 1
			plays_at_collapse += int(r["at_wurf"])
		exceptions += int(r["exceptions"])
		if int(r["exceptions"]) > 0:
			any_exception += 1
	return {
		"einsturz": float(collapsed) / n,
		"ausnahme_quote": float(any_exception) / n,
		"avg_ausnahmen": float(exceptions) / n,
		"avg_wurf": float(plays_at_collapse) / collapsed if collapsed > 0 else 0.0,
	}
```

- [ ] **Step 4: Tests laufen lassen**

```bash
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_sim.gd -gexit
```

Erwartung: 3/3 grün, Ausgabe mit Prozentwerten je Lehre. Die Werte in `SESSION_NOTES.md` notieren (Vergleich zu JS: 66–91 % / 7–32 %). Liegt eine Lehre knapp außerhalb eines Bandes: Werte notieren und mir melden, **das Band nicht einfach verschieben**.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/widerlegung_sim.gd test/gut/test_widerlegung_sim.gd SESSION_NOTES.md
git commit -m "feat(widerlegung): Simulation in Godot, Balance-Bänder der fünf Lehren bestätigt"
```

---

### Task 8: Der Minispiel-Vertrag

**Files:**
- Create: `scripts/core/minigame_contract.gd`
- Modify: `scripts/core/event_applier.gd`
- Modify: `scripts/core/run_stats.gd`
- Modify: `scripts/autoload/GameState.gd`
- Test: `test/gut/test_minigame_contract.gd`, `test/gut/test_events.gd`, `test/gut/test_run_stats.gd`

**Interfaces:**
- Consumes: `WiderlegungRng.hash_str` (Task 3).
- Produces:
  - `MinigameContract.GAME_BELEIDIGUNGSFECHTEN = "beleidigungsfechten"`, `GAME_WIDERLEGUNG = "widerlegung"`, `GAMES`, `LEHREN`, `DEFAULT_LEHRE = "amt"`, `SCENE_DEFAULT_LEHRE`, `ALLOWED_EFFECTS`, `REWARD_ITEM`, `BONUS_ITEM`.
  - `game_of(event: Dictionary) -> String`, `widerlegung_params(raw: Dictionary, scene_id: String, az: String) -> Dictionary` (`{"lehre", "seed"}`), `derive_seed(material: String, scene_id: String, counter: int) -> String` (`LL-XXXXXXXX`), `sanitize_effects(effects: Variant) -> Array`, `widerlegung_result(lehre: Dictionary, instanz_result: Dictionary) -> Dictionary` (`{game, won, score, effects, chronik, lehre}`), `fallback_trigger(node_data: Dictionary, success: bool, trigger: Variant) -> Variant`, `apply_result(result: Dictionary, state: Object) -> void`.
  - `EventApplier.apply` ruft `state.start_minigame(game: String, params: Dictionary)`.
  - `GameState`: Signal `minigame_requested(game: String, params: Dictionary)`, `start_minigame(game := "beleidigungsfechten", params := {})`, `record_minigame(result)`, `apply_minigame_result(result)`.
  - `RunStats.minigames: Array` (gekappt auf 50), `RunStats.minigame_count: int` (nie gekappt), `record_minigame(result)`, `to_dict()["minigames"]`.

- [ ] **Step 1: Vertragstests schreiben**

`test/gut/test_minigame_contract.gd`:

```gdscript
# PURPOSE: MinigameContract: Spielauswahl, Parameter, Seed, erlaubte Effekte, Ergebnis, Offline-Start, Reihenfolge Akte vor Effekt.
# ARCHITECTURE: test
# DEPENDENCIES: MinigameContract, EventApplier
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest


class StubState:
	extends RefCounted

	var calls: Array = []

	func record_minigame(result: Dictionary) -> void:
		calls.append(["record_minigame", result.get("chronik", "")])

	func apply_trigger_event(event: Variant) -> bool:
		calls.append(["apply", event.get("type"), event.get("item", event.get("delta"))])
		return true


func test_missing_game_means_beleidigungsfechten() -> void:
	assert_eq(MinigameContract.game_of({"type": "start_minigame"}), "beleidigungsfechten")
	assert_eq(MinigameContract.game_of({"type": "start_minigame", "game": "widerlegung"}), "widerlegung")


func test_params_unknown_lehre_falls_back_to_scene_default() -> void:
	var p := MinigameContract.widerlegung_params({"lehre": "gibtsnicht"}, "fraktionssitzung", "LL-1")
	assert_eq(p, {"lehre": "spiel", "seed": "LL-1"})
	p = MinigameContract.widerlegung_params({}, "kommunalpolitik", "LL-2")
	assert_eq(p["lehre"], "amt")


func test_params_ignore_seed_from_gm() -> void:
	var p := MinigameContract.widerlegung_params({"lehre": "erfurt", "seed": "VOM-MODELL"}, "untersuchungsausschuss", "LL-CLIENT")
	assert_eq(p, {"lehre": "erfurt", "seed": "LL-CLIENT"})


func test_derive_seed_is_stable_and_counts() -> void:
	var a := MinigameContract.derive_seed("save#2026-10-12T10:00:00", "fraktionssitzung", 0)
	assert_eq(a, MinigameContract.derive_seed("save#2026-10-12T10:00:00", "fraktionssitzung", 0))
	assert_ne(a, MinigameContract.derive_seed("save#2026-10-12T10:00:00", "fraktionssitzung", 1))
	assert_true(RegEx.create_from_string("^LL-[0-9A-F]{8}$").search(a) != null, a)


func test_sanitize_effects_keeps_only_items_and_stats() -> void:
	var effects := [
		{"type": "modify_stat", "stat": "discipline", "delta": 1},
		{"type": "add_item", "item": "weggefallener_paragraph"},
		{"type": "change_scene", "scene": "kommunalpolitik"},
		{"type": "start_minigame", "game": "widerlegung"},
		{"type": "remove_item", "item": "schwarzer_koffer"},
		"kaputt",
		null,
	]
	var kept := MinigameContract.sanitize_effects(effects)
	assert_eq(kept.size(), 2)
	assert_eq(kept[0]["type"], "modify_stat")
	assert_eq(kept[1]["type"], "add_item")
	assert_eq(MinigameContract.sanitize_effects("keine liste"), [])


func test_result_collapse_with_two_exceptions() -> void:
	var lehre := {"id": "amt", "begriff": "Sitzgelegenheit"}
	var res := MinigameContract.widerlegung_result(lehre, {"collapsed": true, "at_wurf": 5, "score": 14, "exceptions": 2})
	assert_eq(res["game"], "widerlegung")
	assert_true(res["won"])
	assert_eq(res["score"], 14)
	assert_eq(res["effects"], [
		{"type": "modify_stat", "stat": "discipline", "delta": 1},
		{"type": "add_item", "item": "weggefallener_paragraph"},
		{"type": "add_item", "item": "gerupftes_huhn"},
	])
	assert_eq(res["chronik"], "Definition 'Sitzgelegenheit' bei Wurf 5 eingestürzt, 2 Ausnahmen")


func test_result_hold_costs_discipline() -> void:
	var lehre := {"id": "spiel", "begriff": "Spiel"}
	var res := MinigameContract.widerlegung_result(lehre, {"collapsed": false, "at_wurf": 8, "score": 6, "exceptions": 0})
	assert_false(res["won"])
	assert_eq(res["effects"], [{"type": "modify_stat", "stat": "discipline", "delta": -1}])
	assert_eq(res["chronik"], "Definition 'Spiel' hielt nach 8 Würfen, 0 Ausnahmen")


func test_fallback_trigger_starts_node_minigame_on_success() -> void:
	var node := {"id": "zeugenstuhl", "minigame": {"game": "widerlegung", "params": {"lehre": "amt"}}}
	var t: Variant = MinigameContract.fallback_trigger(node, true, null)
	assert_eq(t, {"type": "start_minigame", "game": "widerlegung", "params": {"lehre": "amt"}})


func test_fallback_trigger_respects_gm_and_failure() -> void:
	var node := {"id": "zeugenstuhl", "minigame": {"game": "widerlegung", "params": {"lehre": "amt"}}}
	var gm_event := {"type": "add_item", "item": "schredder"}
	assert_eq(MinigameContract.fallback_trigger(node, true, gm_event), gm_event, "Spielleiter hat Vorrang")
	assert_null(MinigameContract.fallback_trigger(node, false, null), "Misserfolg startet nichts")
	assert_null(MinigameContract.fallback_trigger({"id": "x"}, true, null), "Knoten ohne Minispiel")
	assert_null(MinigameContract.fallback_trigger({"id": "x", "minigame": {"game": "schach"}}, true, null), "unbekanntes Spiel")


func test_apply_result_records_before_effects_and_filters() -> void:
	var state := StubState.new()
	MinigameContract.apply_result({
		"chronik": "Definition 'Spiel' hielt",
		"effects": [
			{"type": "modify_stat", "stat": "discipline", "delta": -1},
			{"type": "change_scene", "scene": "kommunalpolitik"},
		],
	}, state)
	assert_eq(state.calls, [
		["record_minigame", "Definition 'Spiel' hielt"],
		["apply", "modify_stat", -1],
	])
```

In `test/gut/test_events.gd` den Stub und den alten Test ändern und zwei Tests ergänzen:

```gdscript
	func start_minigame(game: String = "", params: Dictionary = {}) -> void:
		calls.append(["start_minigame", game, params])
```

```gdscript
func test_start_minigame() -> void:
	assert_true(EventApplier.apply({"type": "start_minigame"}, state))
	assert_eq(state.calls, [["start_minigame", "beleidigungsfechten", {}]])


func test_start_minigame_widerlegung_passes_params() -> void:
	assert_true(EventApplier.apply({"type": "start_minigame", "game": "widerlegung", "params": {"lehre": "amt"}}, state))
	assert_eq(state.calls, [["start_minigame", "widerlegung", {"lehre": "amt"}]])


func test_start_minigame_unknown_game_is_rejected() -> void:
	assert_false(EventApplier.is_valid({"type": "start_minigame", "game": "schach"}))
	assert_false(EventApplier.apply({"type": "start_minigame", "game": "schach"}, state))
	assert_eq(state.calls, [])
```

In `test/gut/test_run_stats.gd` anhängen:

```gdscript
func test_record_minigame_lands_in_dict() -> void:
	stats.record_minigame({"game": "widerlegung", "won": true, "score": 14, "lehre": "amt", "chronik": "Definition 'Sitzgelegenheit' bei Wurf 5 eingestürzt, 2 Ausnahmen", "effects": [{"type": "add_item", "item": "x"}]})
	var d := stats.to_dict()
	assert_eq((d["minigames"] as Array).size(), 1)
	assert_eq(d["minigames"][0]["lehre"], "amt")
	assert_false((d["minigames"][0] as Dictionary).has("effects"), "Effekte stehen schon in events")


func test_record_minigame_is_capped() -> void:
	for i in RunStats.MAX_MINIGAMES + 5:
		stats.record_minigame({"game": "widerlegung", "won": false, "score": i})
	assert_eq(stats.minigames.size(), RunStats.MAX_MINIGAMES)
	assert_eq(stats.minigame_count, RunStats.MAX_MINIGAMES + 5, "Zähler läuft über die Kappung weiter, sonst wiederholt sich der Seed")
```

- [ ] **Step 2: Tests laufen lassen, sie müssen scheitern**

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://addons/lobby_loop/test/gut -gexit
```

Erwartung: FAIL in `test_minigame_contract.gd` („MinigameContract not declared"), `test_events.gd` (Aufruf ohne Argumente), `test_run_stats.gd` („record_minigame not found").

- [ ] **Step 3: `minigame_contract.gd` schreiben**

`scripts/core/minigame_contract.gd`:

```gdscript
# PURPOSE: Minispiel-Vertrag: welches Spiel, welche Parameter, welcher Seed, welche Effekte zurück; gilt für alle Minispiele.
# ARCHITECTURE: core
# DEPENDENCIES: EventApplier, WiderlegungRng
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
class_name MinigameContract
extends RefCounted

const GAME_BELEIDIGUNGSFECHTEN := "beleidigungsfechten"
const GAME_WIDERLEGUNG := "widerlegung"
const GAMES: Array = [GAME_BELEIDIGUNGSFECHTEN, GAME_WIDERLEGUNG]

const LEHREN: Array = ["akademie", "amt", "erfurt", "division7b", "spiel"]
const DEFAULT_LEHRE := "amt"
const SCENE_DEFAULT_LEHRE := {"untersuchungsausschuss": "amt", "fraktionssitzung": "spiel"}

## Ein Minispiel-Ergebnis darf nur Items geben und Werte ändern: kein Szenenwechsel, kein Minispiel im Minispiel.
const ALLOWED_EFFECTS: Array = [EventApplier.TYPE_ADD_ITEM, EventApplier.TYPE_MODIFY_STAT]
const REWARD_ITEM := "weggefallener_paragraph"
const BONUS_ITEM := "gerupftes_huhn"
const BONUS_MIN_EXCEPTIONS := 2


## Fehlt "game", ist das Beleidigungsfechten gemeint (abwärtskompatibel).
static func game_of(event: Dictionary) -> String:
	var game := str(event.get("game", ""))
	return GAME_BELEIDIGUNGSFECHTEN if game.is_empty() else game


## Lehre prüfen (unbekannt -> Szenen-Standard -> "amt"). Der Seed kommt immer vom Client.
static func widerlegung_params(raw: Dictionary, scene_id: String, az: String) -> Dictionary:
	var lehre := str(raw.get("lehre", ""))
	if not LEHREN.has(lehre):
		lehre = str(SCENE_DEFAULT_LEHRE.get(scene_id, DEFAULT_LEHRE))
	return {"lehre": lehre, "seed": az}


## Aktenzeichen aus Karriere, Szene und laufender Nummer: reproduzierbar, nie vom Sprachmodell.
static func derive_seed(material: String, scene_id: String, counter: int) -> String:
	return "LL-%08X" % WiderlegungRng.hash_str("%s#%s#%d" % [material, scene_id, counter])


static func sanitize_effects(effects: Variant) -> Array:
	var out := []
	if not (effects is Array):
		return out
	for e in effects:
		if e is Dictionary and ALLOWED_EFFECTS.has(str(e.get("type", ""))) and EventApplier.is_valid(e):
			out.append(e)
	return out


## Ergebnis einer Instanz (WiderlegungRules-Result) -> Vertrags-Ergebnis.
static func widerlegung_result(lehre: Dictionary, instanz_result: Dictionary) -> Dictionary:
	var won := bool(instanz_result.get("collapsed", false))
	var at_wurf := int(instanz_result.get("at_wurf", 0))
	var exceptions := int(instanz_result.get("exceptions", 0))
	var begriff := str(lehre.get("begriff", "?"))
	var effects: Array = []
	var chronik: String
	if won:
		effects.append({"type": EventApplier.TYPE_MODIFY_STAT, "stat": "discipline", "delta": 1})
		effects.append({"type": EventApplier.TYPE_ADD_ITEM, "item": REWARD_ITEM})
		if exceptions >= BONUS_MIN_EXCEPTIONS:
			effects.append({"type": EventApplier.TYPE_ADD_ITEM, "item": BONUS_ITEM})
		chronik = "Definition '%s' bei Wurf %d eingestürzt, %d Ausnahmen" % [begriff, at_wurf, exceptions]
	else:
		effects.append({"type": EventApplier.TYPE_MODIFY_STAT, "stat": "discipline", "delta": -1})
		chronik = "Definition '%s' hielt nach %d Würfen, %d Ausnahmen" % [begriff, at_wurf, exceptions]
	return {
		"game": GAME_WIDERLEGUNG,
		"won": won,
		"score": int(instanz_result.get("score", 0)),
		"effects": effects,
		"chronik": chronik,
		"lehre": str(lehre.get("id", "")),
	}


## Offline-Start: Hat der Spielleiter kein trigger_event geliefert, startet ein erfolgreicher Wurf
## an einem Knoten mit Feld "minigame" dieses Minispiel. So ist es ohne Netz erreichbar.
static func fallback_trigger(node_data: Dictionary, success: bool, trigger: Variant) -> Variant:
	if trigger != null or not success:
		return trigger
	var mg: Variant = node_data.get("minigame")
	if not (mg is Dictionary):
		return null
	var event := {"type": EventApplier.TYPE_START_MINIGAME, "game": str(mg.get("game", ""))}
	if mg.get("params") is Dictionary:
		event["params"] = (mg["params"] as Dictionary).duplicate()
	return event if EventApplier.is_valid(event) else null


## Erst in die Akte, dann die Effekte. Ein Effekt kann den Perma-Death auslösen,
## und die Akte muss das Ergebnis dann schon enthalten.
static func apply_result(result: Dictionary, state: Object) -> void:
	state.record_minigame(result)
	for effect in sanitize_effects(result.get("effects", [])):
		state.apply_trigger_event(effect)
```

- [ ] **Step 4: `EventApplier` anpassen**

In `scripts/core/event_applier.gd`:

Kopfzeile `# PURPOSE:` ersetzen durch:

```gdscript
# PURPOSE: Wendet trigger_event-Command-Objekte (geschlossenes 5er-Enum) auf den Spielstand an; start_minigame trägt game/params.
```

`is_valid` ersetzen:

```gdscript
## Nur bekannte Typen werden akzeptiert; null/nicht-Dictionary gilt als "kein Event".
## start_minigame mit unbekanntem "game" ist ungültig (fehlendes "game" = Beleidigungsfechten).
static func is_valid(event: Variant) -> bool:
	if event == null:
		return false
	if not (event is Dictionary):
		return false
	var type := str(event.get("type", ""))
	if not VALID_TYPES.has(type):
		return false
	if type == TYPE_START_MINIGAME:
		return MinigameContract.GAMES.has(MinigameContract.game_of(event))
	return true
```

Im `match` von `apply` die Zeile für `TYPE_START_MINIGAME` ersetzen:

```gdscript
		TYPE_START_MINIGAME:
			var params: Dictionary = event["params"] if event.get("params") is Dictionary else {}
			state.start_minigame(MinigameContract.game_of(event), params)
```

- [ ] **Step 5: `RunStats` erweitern**

In `scripts/core/run_stats.gd` nach `const MAX_TIMELINE := 100`:

```gdscript
const MAX_MINIGAMES := 50
```

Nach `var discipline_timeline: Array = []`:

```gdscript
var minigames: Array = []
## Zählt jedes Minispiel-Ergebnis, auch über die Kappung von minigames hinaus (Grundlage des Seeds).
var minigame_count := 0
```

Nach `record_stat_snapshot`:

```gdscript
## Nimmt ein Minispiel-Ergebnis nach dem Vertrag auf. Effekte nicht: die stehen schon in events.
func record_minigame(result: Dictionary) -> void:
	minigame_count += 1
	if minigames.size() >= MAX_MINIGAMES:
		minigames.pop_front()
	minigames.append({
		"game": str(result.get("game", "")),
		"won": bool(result.get("won", false)),
		"score": int(result.get("score", 0)),
		"lehre": str(result.get("lehre", "")),
		"chronik": str(result.get("chronik", "")),
	})
```

In `to_dict()` ergänzen:

```gdscript
		"minigames": minigames.duplicate(true),
```

- [ ] **Step 6: `GameState` anpassen**

In `scripts/autoload/GameState.gd`:

Kopfzeile `# DEPENDENCIES:` ersetzen durch:

```gdscript
# DEPENDENCIES: StatRules, EventApplier, SaveData, SaveManager, MinigameContract, ApiClient
```

Signal ersetzen:

```gdscript
signal minigame_requested(game: String, params: Dictionary)
```

`start_minigame` ersetzen und zwei Funktionen ergänzen:

```gdscript
## Startet ein Minispiel nach dem Vertrag. Für die Widerlegung werden Lehre und Seed hier festgelegt,
## der Seed kommt aus Karriere + Szene + laufender Nummer, nie vom Spielleiter.
func start_minigame(game: String = "beleidigungsfechten", params: Dictionary = {}) -> void:
	var final_params := params.duplicate()
	if game == MinigameContract.GAME_WIDERLEGUNG:
		var material := "%s#%s" % [ApiClient.session_id(), run_stats.started_at]
		var az := MinigameContract.derive_seed(material, current_scene, run_stats.minigame_count)
		final_params = MinigameContract.widerlegung_params(params, current_scene, az)
	else:
		minigame = {"round": 0, "won_rounds": 0, "lost_rounds": 0}
	minigame_requested.emit(game, final_params)


func record_minigame(result: Dictionary) -> void:
	run_stats.record_minigame(result)


## Ergebnis eines Minispiels: Akte zuerst, dann nur erlaubte Effekte über den EventApplier.
func apply_minigame_result(result: Dictionary) -> void:
	MinigameContract.apply_result(result, self)
```

- [ ] **Step 7: Tests laufen lassen**

```bash
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://addons/lobby_loop/test/gut -gexit
```

Erwartung: alle grün. Wenn Godot eine zyklische Abhängigkeit `EventApplier` ↔ `MinigameContract` meldet: `GAMES` und `game_of` nach `EventApplier` verschieben und in `MinigameContract` darauf verweisen. Fehlermeldung vorher vollständig notieren.

- [ ] **Step 8: Commit**

```bash
git add scripts/core/minigame_contract.gd scripts/core/event_applier.gd scripts/core/run_stats.gd scripts/autoload/GameState.gd test/gut/test_minigame_contract.gd test/gut/test_events.gd test/gut/test_run_stats.gd
git commit -m "feat: Minispiel-Vertrag (game/params, Client-Seed, erlaubte Effekte, Akte vor Effekt)"
```

---

### Task 9: Das Widerlegungs-Panel

**Files:**
- Create: `scripts/ui/widerlegung_panel.gd`
- Test: `test/gut/test_widerlegung_panel.gd`

**Interfaces:**
- Consumes: `WiderlegungRules` (Task 4–5), `MinigameContract.widerlegung_result`, `DEFAULT_LEHRE`, `sanitize_effects` (Task 8).
- Produces: Panel-Skript (`extends PanelContainer`, ohne `class_name`, wie `minigame_panel.gd`) mit Signal `finished(result: Dictionary)` und den Methoden `start(params: Dictionary)`, `play_card(card_id: String)`, `hand_ids() -> Array`, `is_playing() -> bool`, `is_open() -> bool`, `lehre_id() -> String`, `close()`, `abort()`.

- [ ] **Step 1: Test schreiben**

`test/gut/test_widerlegung_panel.gd`:

```gdscript
# PURPOSE: Widerlegungs-Panel: ganze Partie bis zum Ergebnis, Ergebnis erst beim Schließen, Abbruch ohne Ergebnis, Lehre-Fallback.
# ARCHITECTURE: test
# DEPENDENCIES: scripts/ui/widerlegung_panel.gd, MinigameContract
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const PanelScript := preload("res://addons/lobby_loop/scripts/ui/widerlegung_panel.gd")

var panel: PanelContainer


func before_each() -> void:
	panel = PanelScript.new()
	add_child_autofree(panel)


func _play_to_end() -> void:
	var guard := 0
	while panel.is_playing() and guard < 60:
		panel.play_card(panel.hand_ids()[0])
		guard += 1


func test_full_game_sends_result_only_on_close() -> void:
	watch_signals(panel)
	panel.start({"lehre": "amt", "seed": "LL-TEST0001"})
	assert_true(panel.is_open())
	assert_eq(panel.lehre_id(), "amt")
	_play_to_end()
	assert_false(panel.is_playing(), "Partie ist zu Ende")
	assert_true(panel.is_open(), "Ergebnis wird angezeigt, Panel noch offen")
	assert_signal_not_emitted(panel, "finished")
	panel.close()
	assert_false(panel.is_open())
	assert_signal_emitted(panel, "finished")
	var result: Dictionary = get_signal_parameters(panel, "finished")[0]
	assert_eq(result["game"], "widerlegung")
	assert_eq(result["lehre"], "amt")
	assert_false(MinigameContract.sanitize_effects(result["effects"]).is_empty())


func test_abort_sends_nothing() -> void:
	watch_signals(panel)
	panel.start({"lehre": "akademie", "seed": "LL-TEST0002"})
	panel.play_card(panel.hand_ids()[0])
	panel.abort()
	assert_false(panel.is_open())
	assert_false(panel.is_playing())
	panel.close()
	assert_signal_not_emitted(panel, "finished")


func test_unknown_lehre_falls_back_to_amt() -> void:
	panel.start({"lehre": "gibtsnicht", "seed": "LL-TEST0003"})
	assert_eq(panel.lehre_id(), "amt")


func test_same_seed_same_hand() -> void:
	panel.start({"lehre": "erfurt", "seed": "LL-SAME"})
	var first := panel.hand_ids()
	panel.abort()
	panel.start({"lehre": "erfurt", "seed": "LL-SAME"})
	assert_eq(panel.hand_ids(), first)
```

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_panel.gd -gexit
```

Erwartung: FAIL, Datei `widerlegung_panel.gd` fehlt.

- [ ] **Step 3: Panel schreiben**

`scripts/ui/widerlegung_panel.gd`:

```gdscript
# PURPOSE: Widerlegungs-Panel: Saal, Lehre, Last gegen Tragfähigkeit, Hand, Herzschlag, Protokoll; meldet ein Vertrags-Ergebnis.
# ARCHITECTURE: ui
# DEPENDENCIES: WiderlegungRules, MinigameContract
# PIPELINE: runtime
# LAST_VALIDATED: 2026-10-12
extends PanelContainer

## Ergebnis nach dem Minispiel-Vertrag. Wird erst beim Schließen gesendet,
## damit Effekte (auch ein Perma-Death) nie in ein offenes Panel fallen.
signal finished(result: Dictionary)

const MAX_PROTOCOL_LINES := 8
const VERDICT_TEXT := {
	"broad": "passt zur Lehre, gehört aber nicht dazu",
	"narrow": "gehört dazu, passt aber nicht zur Lehre",
	"confirm": "bestätigt die Lehre",
}
const KIND_TEXT := {
	"add": "Ergänzung (+1)",
	"repair": "Nachbesserung (+1)",
	"excl": "Ausnahme (+3)",
	"incl": "Ausnahme (+3)",
	"confirm": "Bestätigung",
}

var _data := {}
var _run := {}
var _lehre := {}
var _result := {}
var _aborted := false
var _protocol: Array = []

var _title_label: Label
var _lehre_label: Label
var _status_label: Label
var _last_bar: ProgressBar
var _telegraph_label: Label
var _hand_box: HFlowContainer
var _preview_label: Label
var _protocol_label: Label
var _end_button: Button


func _ready() -> void:
	visible = false
	set_anchors_preset(PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.95)
	add_theme_stylebox_override("panel", style)

	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.14)
	panel_style.border_color = Color(0.62, 0.48, 0.2)
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	_title_label = _label(column, 22, Color(0.95, 0.8, 0.45))
	_lehre_label = _label(column, 16, Color(0.95, 0.93, 0.85))
	_status_label = _label(column, 13, Color(0.85, 0.87, 0.92))
	_last_bar = ProgressBar.new()
	_last_bar.show_percentage = false
	_last_bar.custom_minimum_size = Vector2(0, 14)
	column.add_child(_last_bar)
	_telegraph_label = _label(column, 13, Color(0.9, 0.6, 0.4))
	_hand_box = HFlowContainer.new()
	_hand_box.add_theme_constant_override("h_separation", 6)
	_hand_box.add_theme_constant_override("v_separation", 6)
	column.add_child(_hand_box)
	_preview_label = _label(column, 12, Color(0.7, 0.8, 0.95))
	_protocol_label = _label(column, 13, Color(0.85, 0.9, 0.85))
	_end_button = Button.new()
	_end_button.text = "Saal verlassen"
	_end_button.visible = false
	_end_button.pressed.connect(close)
	column.add_child(_end_button)


func _label(parent: Node, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


# ---------------------------------------------------------------- Öffentlich

## params: {"lehre": String, "seed": String} aus GameState.start_minigame.
func start(params: Dictionary) -> void:
	_aborted = false
	_result = {}
	_run = {}
	_protocol = []
	if _data.is_empty() or _data.has("error"):
		_data = WiderlegungRules.load_data()
	if _data.has("error"):
		push_warning("WiderlegungPanel: %s" % _data["error"])
		_show_missing_file(str(_data["error"]))
		return
	var idx := WiderlegungRules.index_of(_data, str(params.get("lehre", "")))
	if idx < 0:
		idx = WiderlegungRules.index_of(_data, MinigameContract.DEFAULT_LEHRE)
	_lehre = _data["instanzen"][idx]
	_run = WiderlegungRules.new_run(str(params.get("seed", "LL-00000000")))
	_run["idx"] = idx
	WiderlegungRules.start_instanz(_data, _run)
	_title_label.text = "Widerlegung — %s" % str(_lehre.get("ort", ""))
	_push(str(_lehre.get("intro", "")))
	_push("%s: %s" % [str(_lehre.get("gegner", "")), str(_lehre.get("startSatz", ""))])
	_end_button.visible = false
	_hand_box.visible = true
	visible = true
	_refresh()


func play_card(card_id: String) -> void:
	if not is_playing():
		return
	for e in WiderlegungRules.play(_data, _run, card_id):
		_describe(e)
	if _run["phase"] == "result":
		_finish()
	else:
		_refresh()


func hand_ids() -> Array:
	if not is_playing():
		return []
	return (_run["inst"]["hand"] as Array).duplicate()


func is_playing() -> bool:
	return is_open() and not _run.is_empty() and _run.get("phase") == "play"


func is_open() -> bool:
	return visible and not _aborted


func lehre_id() -> String:
	return str(_lehre.get("id", ""))


## Schließt nach dem Ergebnis und sendet es. Ohne Ergebnis passiert nichts.
func close() -> void:
	if not is_open() or _result.is_empty():
		return
	visible = false
	finished.emit(_result)


## Abbruch von außen (Perma-Death, Szenenwechsel): kein Ergebnis, keine Effekte.
func abort() -> void:
	_aborted = true
	visible = false


# ---------------------------------------------------------------- Anzeige

func _refresh() -> void:
	var st: Dictionary = _run["inst"]
	var view := WiderlegungRules.lehre_view(_lehre, st["lehre"])
	var lines := PackedStringArray([str(_lehre.get("lehreHead", ""))])
	for r in view["reqs"]:
		var prefix := "  (weggefallen) " if r["gone"] else "  • "
		lines.append(prefix + str(r["text"]) + ("   ← neu" if r["fresh"] else ""))
	for x in view["excl"]:
		lines.append("  ausgenommen: %s%s" % [x["name"], " (überstrichen)" if x["painted"] else ""])
	for x in view["incl"]:
		lines.append("  eingeschlossen: %s%s" % [x["name"], " (überstrichen)" if x["painted"] else ""])
	_lehre_label.text = "\n".join(lines)

	var last_value := WiderlegungRules.last(st)
	var cap := int(st["cap"])
	_status_label.text = "Last %d / Tragfähigkeit %d · Würfe übrig %d" % [last_value, cap, int(st["wuerfe"])]
	_last_bar.max_value = cap
	_last_bar.value = mini(last_value, cap)
	_telegraph_label.text = _telegraph_text(st.get("telegraph"))
	_preview_label.text = ""

	for child in _hand_box.get_children():
		child.queue_free()
	for id in st["hand"]:
		var card: Dictionary = _lehre["card_map"][id]
		var button := Button.new()
		button.text = "%s %s" % [str(card.get("icon", "")), str(card.get("name", id))]
		button.tooltip_text = str(card.get("note", ""))
		button.pressed.connect(play_card.bind(str(id)))
		if bool(_lehre.get("laterneLeihgabe", false)):
			button.mouse_entered.connect(_show_preview.bind(str(id)))
		_hand_box.add_child(button)
	_protocol_label.text = "\n".join(PackedStringArray(_protocol))


func _telegraph_text(tg: Variant) -> String:
	if not (tg is Dictionary):
		return ""
	var info: Dictionary = _data["rhetorik"].get(tg["type"], {})
	var text := "Nächster Herzschlag: %s %s — %s" % [str(info.get("icon", "")), str(info.get("name", tg["type"])), str(info.get("tele", ""))]
	if tg.get("target") != null:
		text += " (%s)" % _card_name(str(tg["target"]))
	return text


func _show_preview(card_id: String) -> void:
	if not is_playing():
		return
	var p := WiderlegungRules.preview(_data, _run, card_id)
	_preview_label.text = "🏮 Laterne: %s → %s, Last danach %d%s" % [
		_card_name(card_id),
		str(KIND_TEXT.get(p["kind"], p["kind"])),
		int(p["last"]),
		" — Einsturz!" if p["collapse"] else "",
	]


func _card_name(card_id: String) -> String:
	var card: Dictionary = _lehre.get("card_map", {}).get(card_id, {})
	return str(card.get("name", card_id))


func _describe(e: Dictionary) -> void:
	match str(e.get("type", "")):
		"throw":
			_push("Du wirfst %s: %s." % [_card_name(str(e["card"])), str(VERDICT_TEXT.get(e["verdict"], ""))])
		"patch":
			_push(_patch_text(e))
		"beat":
			_push(_beat_text(e))
		"collapse":
			_push("Der Boden bricht. Die Lehre stürzt in die Sickergrube. Bonus +%d." % int(e["bonus"]))
		"hold":
			_push("Exakt wie erwartet. Die Lehre hält.")


func _patch_text(e: Dictionary) -> String:
	var gegner := str(_lehre.get("gegner", "Der Gegner"))
	match str(e["kind"]):
		"add":
			return "%s ergänzt: … was %s." % [gegner, WiderlegungRules.lit_phrase(_lehre, e["lit"])]
		"repair":
			return "%s bessert nach und streicht, was nicht mehr passt." % gegner
		"excl":
			return "%s nimmt %s ausdrücklich aus. Ausnahmen wiegen schwer." % [gegner, _card_name(str(e["card"]))]
		"incl":
			return "%s schließt %s ausdrücklich ein. Ausnahmen wiegen schwer." % [gegner, _card_name(str(e["card"]))]
	return "Beweisaufnahme: kostet keinen Wurf." if e.get("frei", false) else "Zur Kenntnis genommen."


func _beat_text(e: Dictionary) -> String:
	match str(e["effect"]):
		"sonne":
			return "Geh mir aus der Sonne: Der Herzschlag verpufft."
		"seized":
			return "Beschlagnahmt: %s." % _card_name(str(e["card"]))
		"wurf":
			return "Die Redezeit wird gekürzt: ein Wurf weniger."
		"cap":
			return "Ein Stützbalken wird eingezogen: Tragfähigkeit +1."
		"painted":
			return "Eine Ausnahme wird braun überstrichen und wiegt nur noch 1."
	return "Der Herzschlag verpufft."


func _push(line: String) -> void:
	if line.strip_edges().is_empty():
		return
	_protocol.append(line)
	while _protocol.size() > MAX_PROTOCOL_LINES:
		_protocol.pop_front()


func _finish() -> void:
	_result = MinigameContract.widerlegung_result(_lehre, _run["results"][0])
	_refresh()
	for child in _hand_box.get_children():
		child.queue_free()
	_hand_box.visible = false
	_telegraph_label.text = ""
	_preview_label.text = str(_result["chronik"])
	_end_button.visible = true


## Content fehlt: kein Spiel, keine Strafe für unseren Fehler.
func _show_missing_file(error: String) -> void:
	_lehre = {}
	_title_label.text = "Widerlegung — Akte unvollständig"
	_lehre_label.text = "Die Registratur findet die Lehre nicht. Die Sitzung wird vertagt."
	_status_label.text = ""
	_telegraph_label.text = ""
	_preview_label.text = ""
	_protocol_label.text = error
	_hand_box.visible = false
	_result = {
		"game": MinigameContract.GAME_WIDERLEGUNG,
		"won": false,
		"score": 0,
		"effects": [],
		"chronik": "Widerlegung vertagt: Akte unvollständig",
		"lehre": "",
	}
	_end_button.visible = true
	visible = true
```

- [ ] **Step 4: Tests laufen lassen**

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://addons/lobby_loop/test/gut/test_widerlegung_panel.gd -gexit
```

Erwartung: 4/4 grün.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/widerlegung_panel.gd test/gut/test_widerlegung_panel.gd
git commit -m "feat(widerlegung): Panel mit Lehre, Last, Hand, Herzschlag, Laterne, Protokoll"
```

---

### Task 10: Einhängen in Lobby-Loop (Szene, Overlay, Main, Akte, Content)

**Files:**
- Modify: `scripts/main.gd` (Konstanten Z. 8–12, Felder Z. 33, Aufbau Z. 98–99, Signale Z. 181–193, Guard Z. 240, `_on_minigame_requested` Z. 272–274, `_on_perma_death` Z. 277–279)
- Modify: `scripts/ui/pnp_overlay.gd` (`_finish` Z. 220–228, `_apply_trigger` Z. 231–239)
- Modify: `scripts/core/epitaph_generator.gd`
- Modify: `content/items.json`, `content/scenes/untersuchungsausschuss.json`, `content/scenes/fraktionssitzung.json`
- Modify: `tools/compile-fallback.ts`, `tools/tests/compile-fallback.test.ts`
- Test: `test/gut/test_run_stats.gd`

**Interfaces:**
- Consumes: Panel (Task 9), `GameState.minigame_requested(game, params)`, `GameState.apply_minigame_result` (Task 8), `MinigameContract.fallback_trigger` (Task 8).
- Produces: Szenenknoten dürfen ein optionales Feld `"minigame": {"game": "widerlegung", "params": {"lehre": "<id>"}}` tragen.

**Hinweis:** Dieser Task ändert 9 Dateien. Laut deinem `AGENTS.md` sage ich vorher Bescheid. Er ist trotzdem ein Task, weil die Teile nur zusammen etwas Spielbares ergeben. Wer will, teilt ihn in 10a (Content + Compiler, Step 1–4) und 10b (Godot-Verdrahtung, Step 5–9).

- [ ] **Step 1: Compiler-Test für das neue Feld schreiben**

In `tools/tests/compile-fallback.test.ts` den Import `import { unlinkSync } from 'node:fs';` erweitern zu

```ts
import { cpSync, mkdtempSync, readFileSync, rmSync, unlinkSync, writeFileSync } from 'node:fs';
```

und am Ende anhängen (`compileFallback({ contentDir, outFile })` wirft bei ungültigem Content einen Fehler mit Präfix `[compile-fallback]`):

```ts
test('compileFallback: minigame-Feld wird akzeptiert, unbekanntes Spiel abgelehnt', () => {
  const dir = mkdtempSync(join(tmpdir(), 'lobby-loop-content-'));
  const out = join(tmpdir(), `lobby-loop-mg-${process.pid}.sqlite`);
  try {
    cpSync(CONTENT_DIR, dir, { recursive: true });
    const scenePath = join(dir, 'scenes', 'untersuchungsausschuss.json');
    const scene = JSON.parse(readFileSync(scenePath, 'utf8')) as { nodes: Array<Record<string, unknown>> };
    assert.ok(scene.nodes.some((n) => n.minigame !== undefined), 'Content enthält einen Widerlegungs-Knoten');
    compileFallback({ contentDir: dir, outFile: out });
    scene.nodes.push({ ...scene.nodes[0], id: 'kaputt', minigame: { game: 'schach' } });
    writeFileSync(scenePath, JSON.stringify(scene));
    assert.throws(() => compileFallback({ contentDir: dir, outFile: out }), /minigame\.game ungültig/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
    try {
      unlinkSync(out);
    } catch {
      // Datei existiert nur, wenn der erste Lauf geklappt hat.
    }
  }
});
```

Wichtig: Der vorhandene Roundtrip-Test erwartet `summary.nodes >= 21`. Mit den zwei neuen Knoten steigt die Zahl, `>=` bleibt gültig.

- [ ] **Step 2: Test laufen lassen, er muss scheitern**

```bash
pnpm run test:tools
```

Erwartung: FAIL, „Content enthält einen Widerlegungs-Knoten".

- [ ] **Step 3: Content ergänzen**

In `content/items.json` ins Array `items` einfügen:

```json
    {
      "id": "weggefallener_paragraph",
      "display_name": "Weggefallener Paragraph",
      "description": "Steht noch im Gesetz, gilt aber nicht mehr. Das Amt löscht nichts, es streicht nur. Wiegt trotzdem."
    },
    {
      "id": "gerupftes_huhn",
      "display_name": "Gerupftes Huhn",
      "description": "Zwei Beine, keine Federn, ein vorwurfsvoller Blick. Fällt unter jede Definition, die man zu schnell geschrieben hat."
    }
```

In `content/scenes/untersuchungsausschuss.json` ins Array `nodes` einfügen:

```json
    {
      "id": "zeugenstuhl",
      "type": "object",
      "label": "Zeugenstuhl",
      "position": {"x": 1000, "y": 240},
      "prompt_hint": "Der Zeugenstuhl des Ausschusses. Laut Anlage 3 der Geschäftsordnung eine Sitzgelegenheit mit Lehne und vier Beinen. Wer die Definition anzweifelt, startet eine Widerlegung: trigger_event {\"type\": \"start_minigame\", \"game\": \"widerlegung\", \"params\": {\"lehre\": \"amt\"}}.",
      "default_dc": 10,
      "fallback_dialogue": "Der Protokollführer schiebt Ihnen Anlage 3 hin. 'Sitzgelegenheit im Sinne dieser Ordnung ist ...' Er wartet.",
      "absurd_actions": [
        "Sich auf den Boden setzen und fragen, ob das jetzt auch zählt"
      ],
      "minigame": {"game": "widerlegung", "params": {"lehre": "amt"}}
    }
```

In `content/scenes/fraktionssitzung.json` ins Array `nodes` einfügen:

```json
    {
      "id": "gesetzentwurf",
      "type": "object",
      "label": "Gesetzentwurf",
      "position": {"x": 920, "y": 400},
      "prompt_hint": "Der Entwurf eines Spielgesetzes liegt zur Abstimmung. § 1 definiert, was ein Spiel ist. Reißt der Spieler die Definition ein, gewinnt die Fraktion die Abstimmung: trigger_event {\"type\": \"start_minigame\", \"game\": \"widerlegung\", \"params\": {\"lehre\": \"spiel\"}}.",
      "default_dc": 10,
      "fallback_dialogue": "Die Fraktionsvorsitzende tippt auf § 1. 'Spiel im Sinne dieses Gesetzes ist ... Einwände?'",
      "absurd_actions": [
        "Den Entwurf zu einem Papierflieger falten und fragen, ob das ein Spiel ist"
      ],
      "minigame": {"game": "widerlegung", "params": {"lehre": "spiel"}}
    }
```

Die Positionen liegen frei (geprüft gegen die vorhandenen Knoten). Falls die Schemaprüfung in `compile-fallback.ts` ein Pflichtfeld verlangt, das hier fehlt, das Feld aus einem Nachbarknoten übernehmen.

- [ ] **Step 4: Compiler prüft das Feld**

In `tools/compile-fallback.ts` in der Knotenschleife (nach der Prüfung von `fallback_dialogue`, Zeile ~110) ergänzen:

```ts
      if (node.minigame !== undefined) {
        if (!isRecord(node.minigame) || !['beleidigungsfechten', 'widerlegung'].includes(String(node.minigame.game))) {
          return fail(where, `minigame.game ungültig (${String(isRecord(node.minigame) ? node.minigame.game : node.minigame)}); erlaubt: beleidigungsfechten, widerlegung.`);
        }
      }
```

Dann:

```bash
pnpm run test:tools
pnpm run build:fallback
pnpm run typecheck
```

Erwartung: grün, `data/fallback.sqlite` neu gebaut.

- [ ] **Step 5: Offline-Start im Overlay**

In `scripts/ui/pnp_overlay.gd` in `_finish` die Zeile

```gdscript
	_apply_trigger(result.get("trigger_event"))
```

ersetzen durch

```gdscript
	_apply_trigger(result.get("trigger_event"), bool(roll.get("success", false)))
```

und `_apply_trigger` ersetzen durch:

```gdscript
func _apply_trigger(trigger: Variant, success: bool) -> void:
	if trigger == null and _pending_action is Dictionary:
		trigger = _pending_action.get("trigger_event")
	# Ohne Spielleiter-Event startet ein erfolgreicher Wurf das Minispiel des Knotens (Offline-Weg).
	trigger = MinigameContract.fallback_trigger(_node_data, success, trigger)
	if trigger == null:
		return
	if not EventApplier.is_valid(trigger):
		push_warning("PnpOverlay: unbekannter trigger_event ignoriert: %s" % [str(trigger)])
		return
	GameState.apply_trigger_event(trigger)
```

- [ ] **Step 6: `main.gd` verdrahten**

Konstanten ergänzen (nach `MinigamePanelScript`):

```gdscript
const WiderlegungPanelScript := preload("res://addons/lobby_loop/scripts/ui/widerlegung_panel.gd")
```

Feld ergänzen (nach `var _minigame: PanelContainer`):

```gdscript
var _widerlegung: PanelContainer
```

Aufbau ergänzen (nach `add_child(_minigame)`):

```gdscript
	_widerlegung = WiderlegungPanelScript.new()
	add_child(_widerlegung)
```

In `_connect_signals` ergänzen:

```gdscript
	_widerlegung.finished.connect(_on_widerlegung_finished)
```

Guard in der Hotspot-Funktion ersetzen:

```gdscript
			if _overlay.is_busy() or _minigame.is_open() or _widerlegung.is_open():
				return
```

`_on_minigame_requested` ersetzen und Ergebnis-Handler ergänzen:

```gdscript
func _on_minigame_requested(game: String, params: Dictionary) -> void:
	_overlay.abort()
	if game == MinigameContract.GAME_WIDERLEGUNG:
		_widerlegung.start(params)
	else:
		_minigame.start()


func _on_widerlegung_finished(result: Dictionary) -> void:
	GameState.apply_minigame_result(result)
	SaveManager.autosave()
```

In `_on_perma_death` nach `_minigame.abort()` ergänzen:

```gdscript
	_widerlegung.abort()
```

- [ ] **Step 7: Akte zählt Widerlegungen (Test zuerst)**

In `test/gut/test_run_stats.gd` anhängen:

```gdscript
func test_epitaph_counts_widerlegungen() -> void:
	stats.record_minigame({"game": "widerlegung", "won": true, "score": 14, "lehre": "amt"})
	stats.record_minigame({"game": "widerlegung", "won": false, "score": 4, "lehre": "spiel"})
	stats.record_minigame({"game": "widerlegung", "won": true, "score": 11, "lehre": "spiel"})
	var result: Dictionary = EpitaphGenerator.generate(stats.to_dict())
	assert_string_contains(str(result["epitaph"]), "Widerlegungen: 2 Lehren eingestürzt, 1 gehalten")
	assert_has(result["highlights"], "2 Definitionen unter ihrem eigenen Gewicht begraben")
```

Laufen lassen, er muss scheitern. Dann in `scripts/core/epitaph_generator.gd`:

In `generate` nach `var minigame: Dictionary = ...`:

```gdscript
	var minigames: Array = stats.get("minigames", []) if stats.get("minigames") is Array else []
	var refuted := _count_widerlegungen(minigames, true)
	var held := _count_widerlegungen(minigames, false)
```

In `lines` nach der Zeile `"Kreuzverhör: …"`:

```gdscript
		"Widerlegungen: %d Lehren eingestürzt, %d gehalten" % [refuted, held],
```

Den Aufruf `_highlights(rolls, burned, won)` ändern zu `_highlights(rolls, burned, won, refuted)` und die Funktion anpassen:

```gdscript
static func _highlights(rolls: Array, burned: int, won: int, refuted: int = 0) -> Array:
	var highlights: Array = []
	if rolls.size() > 0:
		highlights.append("%d Wurfproben gegen den Apparat" % rolls.size())
	if burned > 0:
		highlights.append("%d Konzepte restlos verbrannt" % burned)
	if won > 0:
		highlights.append("Ermittlungsführer %d× in den Burnout geredet" % won)
	if refuted > 0:
		highlights.append("%d Definitionen unter ihrem eigenen Gewicht begraben" % refuted)
	if highlights.is_empty():
		highlights.append("Ein stiller Abgang ohne nennenswerte Vorkommnisse — verdächtig still.")
	return highlights
```

Neue Hilfsfunktion:

```gdscript
static func _count_widerlegungen(minigames: Array, won: bool) -> int:
	var count := 0
	for entry in minigames:
		if entry is Dictionary and str(entry.get("game", "")) == "widerlegung" and bool(entry.get("won", false)) == won:
			count += 1
	return count
```

- [ ] **Step 8: Alle Tests**

```bash
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://addons/lobby_loop/test/gut -gexit
pnpm test
```

Erwartung: alles grün. Der vorhandene Test `test_epitaph_mentions_death_cause_and_stats` erwartet weiter genau 3 Highlights. Das bleibt so, weil ohne Widerlegung keine vierte Zeile entsteht.

- [ ] **Step 9: Commit**

```bash
git add scripts/main.gd scripts/ui/pnp_overlay.gd scripts/core/epitaph_generator.gd content/items.json content/scenes/untersuchungsausschuss.json content/scenes/fraktionssitzung.json tools/compile-fallback.ts tools/tests/compile-fallback.test.ts test/gut/test_run_stats.gd data/fallback.sqlite
git commit -m "feat: Widerlegung in Untersuchungsausschuss und Fraktionssitzung, offline startbar, Akte zählt mit"
```

---

### Task 11: Spielleiter kennt die Widerlegung (Proxy)

**Files:**
- Modify: `gm-proxy/src/types.ts` (TriggerEvent Z. 10–15, RunStats Z. 88–94)
- Modify: `gm-proxy/src/validate.ts` (Z. 55–56, `validateEpitaphRequest`)
- Modify: `gm-proxy/src/schemas.ts` (TRIGGER_EVENT)
- Modify: `gm-proxy/prompts/gm-system.md` (Befehls-Enum, Abschnitt Minispiele)
- Modify: `gm-proxy/prompts/epitaph.md`
- Test: `gm-proxy/tests/validate.test.ts`

**Interfaces:**
- Produces: `TriggerEvent` `{ type: 'start_minigame'; game?: 'beleidigungsfechten' | 'widerlegung'; params?: { lehre: LehreId } }`. Ein `seed` vom Modell wird verworfen. Unbekanntes Spiel → ungültig. Unbekannte Lehre → `params` entfällt, der Client wählt den Szenen-Standard.

- [ ] **Step 1: Tests schreiben**

In `gm-proxy/tests/validate.test.ts` anhängen:

```ts
test('start_minigame: game und lehre werden geprüft, seed verworfen', () => {
  assert.deepEqual(validateTriggerEvent({ type: 'start_minigame' }), { type: 'start_minigame' });
  assert.deepEqual(
    validateTriggerEvent({ type: 'start_minigame', game: 'widerlegung', params: { lehre: 'amt', seed: 'VOM-MODELL' } }),
    { type: 'start_minigame', game: 'widerlegung', params: { lehre: 'amt' } },
  );
  assert.deepEqual(
    validateTriggerEvent({ type: 'start_minigame', game: 'widerlegung', params: { lehre: 'gibtsnicht' } }),
    { type: 'start_minigame', game: 'widerlegung' },
  );
  assert.deepEqual(validateTriggerEvent({ type: 'start_minigame', game: 'beleidigungsfechten' }), {
    type: 'start_minigame',
    game: 'beleidigungsfechten',
  });
  assert.equal(validateTriggerEvent({ type: 'start_minigame', game: 'schach' }), null);
  assert.equal(validateTriggerEvent({ type: 'start_minigame', game: 7 }), null);
});

test('epitaph: minigames wird durchgereicht, kaputte Liste abgelehnt', () => {
  const base = {
    stats: { rolls: [], items_burned: [], minigame: {}, alignment_timeline: [], started_at: '2026-10-12T10:00:00' },
  };
  const ok = validateEpitaphRequest({ ...base, stats: { ...base.stats, minigames: [{ game: 'widerlegung', won: true }] } });
  assert.deepEqual(ok?.stats.minigames, [{ game: 'widerlegung', won: true }]);
  assert.equal(validateEpitaphRequest({ ...base, stats: { ...base.stats, minigames: 'nein' } }), null);
  assert.equal(validateEpitaphRequest(base)?.stats.minigames, undefined);
});
```

- [ ] **Step 2: Tests laufen lassen, sie müssen scheitern**

```bash
pnpm run test:proxy
```

Erwartung: FAIL, das erste `deepEqual` für `widerlegung` bekommt `{ type: 'start_minigame' }`.

- [ ] **Step 3: Typen**

In `gm-proxy/src/types.ts` die letzte Zeile des `TriggerEvent`-Typs ersetzen und Typen ergänzen:

```ts
  | { type: 'start_minigame'; game?: MinigameGame; params?: { lehre: LehreId } };

/** Minispiele des Vertrags; fehlt game, gilt beleidigungsfechten. */
export type MinigameGame = 'beleidigungsfechten' | 'widerlegung';
/** Lehren der Widerlegung (content/widerlegung/_common.json, order). */
export type LehreId = 'akademie' | 'amt' | 'erfurt' | 'division7b' | 'spiel';
```

In `RunStats` ergänzen:

```ts
  /** Ergebnisse von Minispielen nach dem Vertrag (Widerlegung), optional. */
  minigames?: unknown[];
```

- [ ] **Step 4: Validierung**

In `gm-proxy/src/validate.ts` oben nach den Hilfsfunktionen:

```ts
const MINIGAME_GAMES: readonly string[] = ['beleidigungsfechten', 'widerlegung'];
const LEHRE_IDS: readonly string[] = ['akademie', 'amt', 'erfurt', 'division7b', 'spiel'];

/** game optional aus dem Enum; lehre nur, wenn bekannt; seed vom Modell wird nie übernommen. */
function validateStartMinigame(value: Record<string, unknown>): TriggerEvent | null {
  if (value.game === undefined) return { type: 'start_minigame' };
  if (typeof value.game !== 'string' || !MINIGAME_GAMES.includes(value.game)) return null;
  const event: Extract<TriggerEvent, { type: 'start_minigame' }> = {
    type: 'start_minigame',
    game: value.game as MinigameGame,
  };
  if (
    value.game === 'widerlegung' &&
    isRecord(value.params) &&
    typeof value.params.lehre === 'string' &&
    LEHRE_IDS.includes(value.params.lehre)
  ) {
    event.params = { lehre: value.params.lehre as LehreId };
  }
  return event;
}
```

Import oben um `LehreId, MinigameGame` ergänzen. Im `switch` von `validateTriggerEvent`:

```ts
    case 'start_minigame':
      return validateStartMinigame(value);
```

In `validateEpitaphRequest` vor `if (body.session_id !== undefined)`:

```ts
  if (body.stats.minigames !== undefined) {
    if (!Array.isArray(body.stats.minigames)) return null;
    req.stats.minigames = body.stats.minigames;
  }
```

- [ ] **Step 5: Schema für Structured Output**

In `gm-proxy/src/schemas.ts` in `TRIGGER_EVENT.anyOf` die Zeile `event('start_minigame'),` ersetzen durch:

```ts
    event('start_minigame'),
    event('start_minigame', {
      game: { type: 'string', enum: ['beleidigungsfechten', 'widerlegung'] },
      params: {
        type: 'object',
        properties: { lehre: { type: 'string', enum: ['akademie', 'amt', 'erfurt', 'division7b', 'spiel'] } },
        required: ['lehre'],
        additionalProperties: false,
      },
    }),
```

Beide Formen bleiben drin: die alte ohne Felder, die neue mit Spiel und Lehre. `event()` setzt alle Felder einer Form auf `required`, deshalb sind es zwei Einträge.

- [ ] **Step 6: Prompts**

In `gm-proxy/prompts/gm-system.md` die Zeile

```
  - `{"type": "start_minigame"}` — Beleidigungsfechten starten
```

ersetzen durch

```
  - `{"type": "start_minigame"}` — Beleidigungsfechten starten
  - `{"type": "start_minigame", "game": "widerlegung", "params": {"lehre": "<lehre_id>"}}` — eine Widerlegung starten: Der Spieler reißt eine Definition mit Gegenbeispielen ein. Lehren: `amt` (Sitzgelegenheit), `spiel` (Spielgesetz), `akademie` (Mensch), `erfurt` (Fisch), `division7b` (Lebewesen). Starte sie, wenn eine Definition, ein Paragraph oder eine Anlage auf dem Tisch liegt. Setze keinen Seed.
```

In `gm-proxy/prompts/epitaph.md` im Abschnitt „Output-Vertrag" vor `epitaph` einen Satz ergänzen:

```
Die Statistik kann `minigames` enthalten: Widerlegungen mit `won` (Definition eingestürzt) und `chronik`. Eingerissene Definitionen sind eine Leistung, die die Registratur widerwillig vermerkt.
```

- [ ] **Step 7: Tests**

```bash
pnpm test
pnpm run typecheck
```

Erwartung: grün.

- [ ] **Step 8: Commit**

```bash
git add gm-proxy/src/types.ts gm-proxy/src/validate.ts gm-proxy/src/schemas.ts gm-proxy/prompts/gm-system.md gm-proxy/prompts/epitaph.md gm-proxy/tests/validate.test.ts
git commit -m "feat(gm-proxy): start_minigame mit game/lehre, Seed verworfen; Widerlegungen in der Karriere-Akte"
```

---

### Task 12: Ganze Suite und Contract-Test

- [ ] **Step 1: Alles laufen lassen**

```bash
pnpm test
pnpm run typecheck
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://addons/lobby_loop/test/gut -gexit
```

Erwartung: alles grün, GUT-Zahl = Baseline aus Task 0 plus die neuen Tests. Zahl in `SESSION_NOTES.md`.

- [ ] **Step 2: Contract-Test gegen den echten Proxy (nur mit Netz und Schlüssel)**

Wie in `DEPLOY.md` beschrieben: `pnpm run proxy:dev` in einem Terminal, dann den Contract-Test laufen lassen. Erwartung: weiterhin 4/4 grün. Ohne Schlüssel: Schritt überspringen und in `SESSION_NOTES.md` vermerken.

---

### Task 13: Abnahme von Phase 1 (manuell, mit dir)

- [ ] **Step 1: Offline-Durchgang**

Proxy **nicht** starten. Spiel öffnen:

```bash
"/c/Users/Buxe/tools/Godot/Godot_v4.7.2-stable_win64.exe" --path .
```

1. Zum Untersuchungsausschuss gehen, „Zeugenstuhl" anklicken, Absicht eingeben, würfeln.
2. Bei Erfolg: Widerlegung startet. Wenn der Wurf misslingt, nochmal versuchen.
3. **Stoppuhr:** vom ersten Kartenwurf bis „Saal verlassen". Ziel 3–6 Minuten.
4. Während die Widerlegung offen ist, auf einen Hotspot im Hintergrund klicken. Erwartung: nichts passiert.
5. Nach „Saal verlassen": Fraktionsdisziplin hat sich um ±1 geändert, bei Einsturz liegt „Weggefallener Paragraph" im Inventar.
6. Dasselbe in der Fraktionssitzung am „Gesetzentwurf".
7. Akademie zum Testen der Laterne: In `content/scenes/fraktionssitzung.json` vorübergehend `"lehre": "akademie"` setzen, Hover über Karten zeigt die Vorschau. Danach zurücksetzen.

- [ ] **Step 2: Abnahme-Liste der Spec abhaken**

- [ ] Alle GUT-Tests grün, Gleichheitstest 200/200
- [ ] Widerlegung aus einer Szene startbar, Ergebnis ändert Disziplin und Inventar über den `EventApplier`
- [ ] Ohne Netz vollständig spielbar
- [ ] Ein Durchgang dauert 3–6 Minuten (gemessene Zeiten notieren)

- [ ] **Step 3: Notizen und Abschluss**

In `SESSION_NOTES.md`: gemessene Zeiten, Simulationswerte, offene Auffälligkeiten. Dann:

```bash
git add SESSION_NOTES.md
git commit -m "docs: Abnahme Phase 1 Widerlegung"
git push -u origin feat/widerlegung
```

Danach Pull Request gegen `master`. Erst wenn dieses Tor erreicht ist, beginnt Phase 2.

---

## Phase 2: Der Spielleiter erfindet Lehren

**Warum hier nur Meilensteine statt Code:** Die genauen Prüfschwellen hängen an den Simulationswerten, die Task 7 in Godot misst. Und die Modellnamen sind ungeprüft. Wenn ich jetzt Code dafür schreibe, rate ich. Der Detailplan entsteht, wenn das Tor von Phase 1 erreicht ist, als eigene Datei `plan-phase2.md`.

**Tor zum Start:** Phase 1 abgenommen.

**Meilensteine:**

1. **Modellnamen prüfen (zuerst, Pflicht).** ADR 0007 setzt `gemini-3-flash` und `gemini-3.1-flash-lite` voraus, unverifiziert. Aktuelle IDs und Free-Tier-Grenzen per Web-Suche auf ai.google.dev prüfen, Ergebnis in ADR 0007 nachtragen. Kein Raten.
2. **Formprüfung in Godot:** `WiderlegungValidator.check_form(lehre)` prüft 8–12 Merkmale, Startlehre 2–3 Bestimmungen, Prisma 5–7, 15–22 Karten, jede mit `note`. Dazu die vorhandene Logikprüfung `WiderlegungRules.prepare()`.
3. **Kartenpaare zählen:** Ding scheitert an genau einem Merkmal, Mitglied ohne dieses Merkmal. Mindestens 3.
4. **Spielbarkeitsprüfung:** 300 Partien je Strategie über `WiderlegungSim`. Zulassen nur bei Gelegenheit 55–80 %, Zufall unter 35 %, Ausnahme in mindestens 60 % der Partien. Die Tragfähigkeit `cap` setzt die Prüfung selbst (Suche über `cap`, bis die Bänder passen), nie das Modell.
5. **Endpunkt `POST /lehre/generate`** im Proxy mit Schema nach ADR 0007 (`gm-proxy/src/schemas.ts`), Validator in `validate.ts`, Tests wie in Task 11.
6. **Nachbesserung:** Ein Befund („zu leicht, keine Paare") geht einmal zurück ans Modell. Danach greift die Bibliothek.
7. **Lokale Bibliothek:** bestandene Lehren als JSON unter `user://widerlegung_bibliothek/`, Index-Datei, offline spielbar.
8. **Einspruch-Knopf** im Panel: markiert eine Karte als falsch, sie fliegt aus dieser Lehre und landet auf einer Sperrliste.
9. **Messung auf dem Handy:** Prüfdauer unter 3 Sekunden auf einem Mittelklasse-Gerät (Web-Export im Handy-Browser).

**Tor (Spec):**
- [ ] Von 20 erfundenen Lehren bestehen mindestens 12 direkt oder nach einer Nachbesserung
- [ ] Prüfung unter 3 Sekunden auf einem Mittelklasse-Handy
- [ ] Ohne Netz spielt man aus Bibliothek und Grundbestand, ohne Fehlermeldung

**Stand 12.10.2026 (umgesetzt, lokal auf `master`):**
- [x] M1 Modellnamen live geprüft, umgestellt auf `gemini-3.8-flash` / `gemini-3.5-flash-lite` (ADR 0007). Free Tier 3.8 Flash: nur 20 Anfragen/Tag.
- [x] M2–4 Form-, Paar-, Spielbarkeitsprüfung (`WiderlegungValidator`), jetzt mit binärer cap-Suche und selbst gewählten Ankern.
- [x] M5 `POST /lehre/generate` (Schema, Prompt `gm-proxy/prompts/lehre.md`, Tests).
- [x] M6 genau eine Nachbesserung (`WiderlegungForge`).
- [x] M7 Bibliothek `user://widerlegung_bibliothek/` (robust gegen kaputten Index), offline per Seed erreichbar.
- [x] M8 Einspruch-Knopf „!" mit Sperrliste.
- [ ] M9 Handy-Messung: Prüfung läuft jetzt häppchenweise im Hintergrund (Pakete à 50 Partien, Desktop ≤ 50 ms je Häppchen), der Spieler wartet nie. Mit Würfe-Suche Desktop nativ Median 1,4–2,6 s, Ausreißer bis 7,3 s (Fehlschläge probieren alle Wurfzahlen). Vorher Desktop nativ 0,9–1,5 s, WebAssembly in Chromium (Desktop) 1,0–1,5 s je Lehre. **Mittelklasse-Handy offen (LO)**, Mess-Szene `tools/lehre/bench.tscn`.
- [x] Tor 12/20 **erreicht (Flash-Lite):** Seit die Prüfung auch die Würfe setzt (5–9, Standard 7 zuerst; LO-Entscheidung 12.10.2026): **17/20 und 14/20**, zusammen 31/40 = 78 %. Vorher: Frühe Läufe: 6, 5, 9, 9. Nach konkreten Befunden, cap bis 20 und 6–10 Paaren (nur Flash-Lite): **13, 14, 10, 10, 14** von 20, Läufe 7–10 zusammen 48/80 = 60 %. Häufigster Rest-Fehler „Alles oder nichts" (Ausnahmen wiegen 3, die Kurve springt). Offen: Lauf mit 3.8 Flash nach Quota-Reset. Werkzeuge: `tools/lehre/forge_gate.gd`, `tools/lehre/curve.gd`.

**Risiko:** 300 Partien × 3 Strategien × mehrere `cap`-Werte können auf dem Handy zu langsam sein. Gegenmittel: erst mit 100 Partien grob suchen, nur den Kandidaten mit 300 bestätigen.

---

## Phase 3: Eine App, ein Hauptmenü (`latte-app`)

**Tor zum Start:** Phase 2 abgenommen. Der Minispiel-Vertrag ist in Lobby-Loop erprobt.

**Befund, der die Spec präzisiert:**
- DAME testet mit eigenem Runner (`pnpm test:godot`, 565 Checks), Lobby-Loop mit GUT. **Beide Runner bleiben**, keiner wird umgeschrieben.
- DAMEs Dienste heißen `audio_service`, `catalog`, `json_store`, `profile_service`, `purchase_provider`, `save_service`, `settings_service`, `stats_service`. `i18n.gd` liegt eine Ebene höher. Die Spec-Liste ist bis auf `catalog` und `json_store` korrekt; beide müssen mit umziehen, weil die anderen Dienste auf `json_store` aufbauen (vor dem Umzug prüfen).
- DAME hat genau einen Autoload (`App`). Lobby-Loop hat fünf. In einer App dürfen die Namen nicht kollidieren.
- Lobby-Loop nutzt `godot-sqlite` als GDExtension. **Im Web-Export braucht eine GDExtension die Export-Option „Extensions Support"**, und die WASM-Datei ist im Addon vorhanden. Das ist der größte Unsicherheitsfaktor für das 70-MB-Ziel und für den Browser-Betrieb.

**Meilensteine:**

1. **Spike Web-Export Lobby-Loop** (vor allem anderen): Lobby-Loop allein als Web exportieren, SQLite-Fallback im Browser testen, Größe messen. Wenn SQLite im Web nicht läuft: Fallback auf JSON umstellen (die Daten kommen ohnehin aus `content/`, ADR 0002).
2. Repo `latte-app` anlegen, Godot 4.7.2, GL Compatibility.
3. `addons/amt_core/`: DAME-Dienste plus `i18n.gd`, unverändert verschoben, DAME-Checks im alten Repo gegen die neue Quelle grün.
4. `addons/dame/` und `addons/lobby_loop/` als Addons, beide alten Repos bleiben Quelle, bis alle Tests im neuen Repo grün sind.
5. Lobby-Loops `SaveManager` durch `save_service` ersetzen, Migration alter Spielstände testen.
6. Flur des Amts als Startszene mit drei Türen: Karriere, Hörsaal (Widerlegung einzeln, Lehre wählbar), Hinterzimmer.
7. Karriere-Akte: ein Abschnitt je Spiel (Format ADR 0005 erweitern).

**Stand 12.10.2026, Spike (M1) erledigt:** Web-Export (nothreads, PWA) **39 MB**, läuft in Chromium/WebGL2, Widerlegung offline spielbar. SQLite läuft im Web nicht ohne dlink-Templates; `FallbackDb` liest dort direkt `content/*.json`. Proxy sendet CORS (`GM_CORS_ORIGINS`). Gefundene Web-Fehler (Emojis, Wurfanzeige, Perma-Death-Schirm beim Start) behoben. M2–7 warten laut Tor auf die Abnahme von Phase 2.

**Tor (Spec):**
- [ ] Alle Tests beider Projekte im gemeinsamen Repo grün (DAME: 565 Checks)
- [ ] Ein Spielstand, ein Profil, eine Einstellungsseite für alle drei Spiele
- [ ] Web-Build unter 70 MB, läuft als installierbare Web-App

---

## Phase 4: DAME als Hinterzimmer

**Tor zum Start:** Phase 3 abgenommen. **Und deine Entscheidung, ob DAME den Amts-Look bekommt** (Spec: Geschmacksfrage).

**Meilensteine:**

1. Hinterzimmer-Tisch als neue Kosmetik (Aktenschränke statt Bar), Casino bleibt wählbar.
2. Kartenrücken mit Aktenzeichen, Figuren als Beamte.
3. Chips heißen Gefälligkeiten. Regel bleibt: nur erspielt, nie gekauft, nur Kosmetik und kleine einmalige Karriere-Vorteile (z. B. +2 auf einen Wurf, einmal).
4. DAME im Minispiel-Vertrag: `MinigameContract.GAMES` um `"dame"` erweitern, Partie gegen Computergegner, Ergebnis `{game, won, score, effects, chronik}` wie die Widerlegung.
5. Online-Partien zählen in der Statistik, nie in einer Karriere. Test: Ein Online-Ergebnis erzeugt keine Effekte.

**Tor (Spec):**
- [ ] DAME aus der Karriere spielbar
- [ ] Online-Partien zählen nicht in Karrieren

---

## Nach Phase 4

Die Erweiterungen aus der Spec (Huhn-Duell, Lehren-Werkstatt, Wochenlehre, neue Minispiele, historische Kapitel, Druckfassung) bekommen jeweils einen eigenen Plan, wenn sie dran sind. Jede passt in den Minispiel-Vertrag aus Task 8.

## Selbstprüfung des Plans

- **Spec-Abdeckung Phase 1:** Lehren als JSON (Task 2), Regeln (4–5), Simulation (7), Panel (9), `event_applier` (8), `GameState` (8), `schemas.ts` (11), Regeltests (4–5), Golden 200 (6), alter `start_minigame` startet Beleidigungsfechten (8, Test `test_start_minigame`), offline (8 `fallback_trigger`, 10, 13), Effekte nur über `EventApplier` (8 `apply_result`), Abnahme (13). Zusätzlich, weil der Code es verlangt: Git-Abgleich (0), Renderer (1), `main.gd`, `pnp_overlay.gd`, Content, Compiler, Akte (10), Proxy-Typen und Prompts (11).
- **Bewusst nicht portiert:** `shareText`, `dailyAz`, `randomAz`, `rank` wird portiert, aber nirgends angezeigt. Lobby-Loop braucht keine Teilen-Funktion.
- **Namen über Tasks hinweg:** `WiderlegungRules.play(data, run, card_id)`, `start_instanz(data, run)`, `preview(data, run, card_id)`, `use_kniff(run, id)`, `next_phase(data, run)`, `choose_kniff(data, run, id)`, `choose_alexander(run, choice)`, `pruefcode(run)`, Ergebnis-Schlüssel `at_wurf`. Vertrag: `widerlegung_params(raw, scene_id, az)`, `derive_seed(material, scene_id, counter)`, `widerlegung_result(lehre, instanz_result)`, `fallback_trigger(node_data, success, trigger)`, `apply_result(result, state)`.
