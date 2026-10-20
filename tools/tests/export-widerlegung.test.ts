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

const GOLDEN_FILE = fileURLToPath(new URL('../../addons/lobby_loop/test/golden/widerlegung.json', import.meta.url));

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
