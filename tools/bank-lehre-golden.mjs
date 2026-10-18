// PURPOSE: Erzeugt die Golden-Datei für die Bank-Lehre von BANK-01: 200 Partien mit festen Seeds, gespielt von der JS-Engine von "Das gerupfte Huhn".
// PURPOSE: Der Godot-Port spielt dieselben Partien nach (test/test_bank_widerlegung.gd) und muss Zug für Zug dasselbe liefern (Spezifikation 0.1, Kap. 20.2).
// ARCHITECTURE: tools
// DEPENDENCIES: node:fs, node:crypto, node:module, JS-Engine (engine.cjs + data.cjs)
// PIPELINE: build, test
// LAST_VALIDATED: 2026-10-18
//
// Aufruf: node tools/bank-lehre-golden.mjs [--engine <engine.cjs>] [--data <data.cjs>] [--out <datei>]
// Standard: die Kopie in ../lobby-loop/vendor/huhn. Mit dem Archiv des Originals: --engine .../src/engine.js --data .../src/data.js
// Die Treiberlogik (Kartenwahl, Kniff-Reihenfolge, Textform der Ereignisse) ist dieselbe wie in lobby-loop/tools/export-widerlegung.ts.

import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
const LEHRE_PATH = join(ROOT, 'cases/bank_01/lehre/bib_bank_01.json');

export const GOLDEN_GAMES = 200;
/** Kniff-Sätze: decken jede Kniff-Verzweigung der Engine mindestens einmal ab (wie in Lobby-Loop). */
export const GOLDEN_KNIFFE = [[], ['inspektion', 'huhn2'], ['dudelsack', 'sonne'], ['uniform', 'fass', 'bettwaermer']];
const KNIFF_USE_ORDER = ['fass', 'bettwaermer', 'uniform'];
const CANON_FIELDS = [
  'type', 'card', 'verdict', 'kind', 'gain', 'last', 'frei', 'effect',
  'rhet', 'cap', 'bonus', 'score', 'drawn', 'id', 'dudelsack', 'uniform',
];

const litStr = (l) => (l.neg ? '-' : '+') + l.a;

export function canonEvent(e) {
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

export function canonStart(st) {
  const tg = st.telegraph ? st.telegraph.type + '>' + (st.telegraph.target ?? '') : '';
  return [st.hand.join(','), st.deck.join(','), st.cap, st.wuerfe, tg].join('/');
}

const canonClause = (c) => c.t + ':' + (c.a ?? c.id) + (c.neg ? '-' : '') + (c.painted ? '*' : '');

export function canonResult(r) {
  return [r.collapsed ? 1 : 0, r.atWurf, r.score, r.exceptions, r.last, r.cap, r.lehre.map(canonClause).join(',')].join('|');
}

export function playGame(E, idx, g) {
  const kniffe = GOLDEN_KNIFFE[g % GOLDEN_KNIFFE.length];
  const az = 'BANKGOLD-' + g;
  const run = E.newRun(az, { kniffe });
  run.idx = idx;
  const st = E.startInstanz(run);
  const start = canonStart(st);
  const lines = [];
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
  return { g, az, kniffe, start, lines, result: canonResult(run.results[0]) };
}

function arg(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 ? resolve(process.argv[i + 1]) : fallback;
}

export function build(enginePath, dataPath) {
  const DATA = require(dataPath);
  const E = require(enginePath);
  const lehre = JSON.parse(readFileSync(LEHRE_PATH, 'utf8'));
  // Wie im Spiel: Die Bank-Lehre kommt nach den Grund-Lehren (Godot: load_data mit Lehren-Ordner).
  DATA.instanzen.push(lehre);
  E.setData(DATA);
  const idx = DATA.instanzen.length - 1;
  const games = Array.from({ length: GOLDEN_GAMES }, (_, g) => playGame(E, idx, g));
  const sha = (p) => createHash('sha256').update(readFileSync(p)).digest('hex').slice(0, 16);
  return { version: 1, lehre: lehre.id, engine_sha256: sha(enginePath), games };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const engine = arg('--engine', resolve(ROOT, '../lobby-loop/vendor/huhn/engine.cjs'));
  const data = arg('--data', resolve(ROOT, '../lobby-loop/vendor/huhn/data.cjs'));
  const out = arg('--out', join(ROOT, 'test/golden/bank_01_widerlegung.json'));
  const golden = build(engine, data);
  // Der Engine-Hash steht nur zur Nachvollziehbarkeit; zwei Engines mit gleichem Verhalten liefern dasselbe "games".
  writeFileSync(out, JSON.stringify(golden) + '\n');
  const won = golden.games.filter((g) => g.result.startsWith('1|')).length;
  console.log(`${golden.games.length} Partien nach ${out}, davon eingestürzt: ${won}`);
}
