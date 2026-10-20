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
  const contentDir = join(ROOT, 'addons/lobby_loop/content/widerlegung');
  mkdirSync(contentDir, { recursive: true });
  for (const [name, text] of Object.entries(exportContent(raw))) writeFileSync(join(contentDir, name), text);
  const goldenDir = join(ROOT, 'addons/lobby_loop/test/golden');
  mkdirSync(goldenDir, { recursive: true });
  writeFileSync(join(goldenDir, 'widerlegung.json'), JSON.stringify(buildGolden(E, DATA)) + '\n');
  console.log('addons/lobby_loop/content/widerlegung/ und addons/lobby_loop/test/golden/widerlegung.json geschrieben');
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) main();
