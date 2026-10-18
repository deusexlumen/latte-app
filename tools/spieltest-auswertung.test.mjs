// PURPOSE: Prüft die Auswertung des Spieltests gegen ein vollständig durchgespieltes Fixture (Pfad A, gewonnene Widerlegung, gewonnene DAME-Partie).
// ARCHITECTURE: tools
// DEPENDENCIES: tools/spieltest-auswertung.mjs, tools/fixtures/bank01-pfad-a.json
// PIPELINE: test
// LAST_VALIDATED: 2026-10-18
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { analyze, format } from './spieltest-auswertung.mjs';

const fixture = () => JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), 'fixtures/bank01-pfad-a.json'), 'utf8'));

test('Pfad A: Abschluss, amtliche Fassung und Folgen', () => {
  const r = analyze(fixture());
  assert.equal(r.abschluss, 'formal_release');
  assert.match(r.amtlich, /PA-12/);
  assert.equal(r.tatsaechlich.kern_sitzt, 'bench');
  assert.equal(r.nachgang_erreicht, true);
  assert.deepEqual(r.regeln, ['PA-12 (Herkunft BANK-01)']);
  assert.ok(r.sichtbare_folgen.some((s) => s.includes('Neues Schild')));
  assert.ok(r.sichtbare_folgen.some((s) => s.includes('Seidel')));
});

test('Pfad A: Aufwand und Handlungen stimmen mit dem Protokoll überein', () => {
  const s = fixture();
  const r = analyze(s);
  assert.equal(r.aufwand.diensthandlungen, 8 - s.cases['BANK-01'].hours_remaining);
  assert.equal(r.aufwand.befehle, s.applied_transactions.length);
  assert.equal(r.handlungen.angefordert, 1);
  assert.equal(r.handlungen.befragt, 2);
  assert.equal(r.handlungen.verglichen, 1);
  assert.equal(r.wege.augenzeuge_umlagerung, true);
  assert.ok(r.wege.eigener_abgleich.includes('B-03'));
});

test('Pfad A: Minispiele und Bericht', () => {
  const r = analyze(fixture());
  assert.deepEqual(r.dame, [{ status: 'completed', ausgang: 'won' }]);
  assert.equal(r.widerlegung.length, 1);
  assert.equal(r.widerlegung[0].ausgang, 'won');
  assert.ok(r.widerlegung[0].karten >= 3, 'die Karten der Partie stehen im Protokoll');
  assert.equal(r.bericht.antrag, 'formal');
  assert.equal(r.bericht.status, 'belegt');
  assert.equal(r.bericht.wortlaut, 'Sitzgelegenheiten müssen zugänglich sein.');
});

test('Der Bericht für Menschen nennt die wesentlichen Punkte', () => {
  const text = format(analyze(fixture()));
  for (const part of ['Abschluss: formal_release', 'Amtlich:', 'Frau Kern sitzt auf der Bank, Bank freigegeben', 'DAME: completed (won)', 'Widerlegung: completed (won)', 'Erlassene Regeln: PA-12']) {
    assert.ok(text.includes(part), part);
  }
});

test('Ein unvollständiger Durchlauf wird ohne Fehler ausgewertet', () => {
  const s = fixture();
  s.phase = 'tag1';
  s.cases['BANK-01'].status = 'open';
  s.cases['BANK-01'].resolution = '';
  s.cases['BANK-01'].report = {};
  s.sessions = {};
  s.events = s.events.slice(0, 5);
  s.rules = [];
  const r = analyze(s);
  assert.equal(r.abschluss, null);
  assert.equal(r.bericht, null);
  assert.deepEqual(r.dame, []);
  const text = format(r);
  assert.match(text, /Bericht: nicht eingereicht/);
  assert.match(text, /DAME: nicht gespielt/);
});
