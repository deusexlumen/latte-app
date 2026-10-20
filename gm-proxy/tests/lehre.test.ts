/*
 * PURPOSE: Tests für /lehre/generate: Formprüfung, Normalisierung (kein cap vom Modell), Request, Handler-Retry, HTTP-Route
 * ARCHITECTURE: gm-proxy/tests
 * DEPENDENCIES: node:test, node:assert/strict, node:fs, ../src/lehre.js, ../src/llm-handlers.js, ../src/server.js
 * PIPELINE: test
 * LAST_VALIDATED: 2026-10-12
 */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { GmUnavailableError } from '../src/errors.js';
import { buildLehrePrompt, countPairs, normalizeLehreDraft, toDraftFormat, validateLehreGenerateRequest } from '../src/lehre.js';
import { createGmHandlers, type LlmCallOptions, type LlmCaller } from '../src/llm-handlers.js';
import { createGmServer } from '../src/server.js';
import type { GmHandlers } from '../src/types.js';

/** Die Grundbestand-Lehre "amt", ins Modellformat gebracht und auf 20 Karten gekürzt. */
function amtDraft(): Record<string, unknown> {
  const l = JSON.parse(readFileSync(new URL('../../addons/lobby_loop/content/widerlegung/amt.json', import.meta.url), 'utf8'));
  return {
    shortName: l.shortName, ort: l.ort, jahr: l.jahr, gegner: l.gegner, gegnerTitel: l.gegnerTitel,
    siegel: l.siegel, begriff: l.begriff, truthYes: l.truthYes, truthNo: l.truthNo, lehreHead: l.lehreHead,
    startSatz: l.startSatz, intro: l.intro, rhetorik: l.rhetorik,
    attrs: Object.entries(l.attrs).map(([id, a]) => ({ id, ...(a as object) })),
    start: l.start, prisma: l.prisma,
    cards: l.cards.slice(0, 20).map((c: Record<string, unknown>) => ({ ...c, a: String(c.a).split(' ') })),
    refMembers: l.refMembers, refNon: l.refNon, lines: l.lines,
  };
}

test('normalize: gültiger Entwurf wird zur Lehre im Engine-Format', () => {
  const lehre = normalizeLehreDraft(amtDraft());
  assert.ok(lehre !== null);
  assert.match(lehre.id, /^bib_[0-9a-f]{10}$/);
  assert.equal(lehre.attrs.lehne.short, 'Lehne');
  assert.equal(typeof lehre.cards[0].a, 'string');
  assert.equal(lehre.hand, 5);
  assert.equal(lehre.erfunden, true);
});

test('normalize: cap, Seed und fremde Felder vom Modell werden verworfen', () => {
  const lehre = normalizeLehreDraft({ ...amtDraft(), cap: 2, seed: 'LL-1', hand: 99 });
  assert.ok(lehre !== null);
  assert.equal('cap' in lehre, false);
  assert.equal('seed' in lehre, false);
  assert.equal(lehre.hand, 5);
});

test('normalize: gleiche Lehre, gleiche ID', () => {
  assert.equal(normalizeLehreDraft(amtDraft())?.id, normalizeLehreDraft(amtDraft())?.id);
});

test('normalize: Formfehler ergeben null', () => {
  const broken: Array<(d: Record<string, any>) => void> = [
    (d) => { d.cards[0].a.push('fluegel'); },          // unbekanntes Merkmal
    (d) => { d.start = ['moebel']; },                   // Literal ohne Vorzeichen
    (d) => { d.start = ['+moebel', '-moebel']; },       // Merkmal doppelt
    (d) => { d.prisma = d.prisma.slice(0, 3); },        // Prisma zu klein
    (d) => { d.cards = d.cards.slice(0, 10); },         // zu wenige Karten
    (d) => { d.cards[1].id = d.cards[0].id; },          // doppelte Karte
    (d) => { d.cards[0].note = ''; },                   // Karte ohne Begründung
    (d) => { d.refMembers = ['gibtsnicht']; },          // Anker existiert nicht
    (d) => { d.rhetorik = ['charme']; },                // unbekannte Rhetorik
    (d) => { delete d.lines.collapse; },                // Einsturzsatz fehlt
    (d) => { d.attrs[0].id = '!!'; },                   // ID ohne verwertbare Zeichen
  ];
  for (const breakIt of broken) {
    const d = amtDraft();
    breakIt(d);
    assert.equal(normalizeLehreDraft(d), null, String(breakIt));
  }
});

test('request: Thema optional, Nachbesserung braucht Befunde und Vorlage', () => {
  assert.deepEqual(validateLehreGenerateRequest({}), {});
  assert.deepEqual(validateLehreGenerateRequest({ thema: ' Parkplatz ' }), { thema: 'Parkplatz' });
  assert.equal(validateLehreGenerateRequest({ thema: 'x'.repeat(500) }), null);
  assert.equal(validateLehreGenerateRequest({ nachbesserung: { befunde: [], vorlage: {} } }), null);
  assert.equal(validateLehreGenerateRequest({ nachbesserung: { befunde: ['zu leicht'] } }), null);
  assert.ok(validateLehreGenerateRequest({ nachbesserung: { befunde: ['zu leicht'], vorlage: { begriff: 'X' } } }));
  assert.equal(validateLehreGenerateRequest([]), null);
});

test('prompt: Nachbesserung trägt Befunde und vorige Lehre', () => {
  const p = buildLehrePrompt({ nachbesserung: { befunde: ['Zu wenige Kartenpaare'], vorlage: { begriff: 'Sitzgelegenheit' } } });
  assert.match(p, /<befunde>\n- Zu wenige Kartenpaare/);
  assert.match(p, /Sitzgelegenheit/);
  assert.match(buildLehrePrompt({ thema: 'Parkplatz' }), /<thema>\nParkplatz/);
});

test('handler: großes Token-Budget, eigener System-Prompt, ein Retry bei Formfehler', async () => {
  const options: Array<LlmCallOptions | undefined> = [];
  const answers = [JSON.stringify({ begriff: 'kaputt' }), JSON.stringify(amtDraft())];
  const call: LlmCaller = async (_prompt, opts) => {
    options.push(opts);
    return answers.shift() ?? '';
  };
  const lehre = await createGmHandlers(call).lehreGenerate!({ thema: 'Sitzen' });
  assert.equal(lehre.begriff, 'Sitzgelegenheit');
  assert.equal(options.length, 2);
  assert.ok((options[0]?.maxTokens ?? 0) >= 8000);
  assert.match(options[0]?.system ?? '', /Kartenpaare/);
});

test('handler: zweimal unbrauchbar ergibt 503 (Client fällt auf Bibliothek zurück)', async () => {
  const call: LlmCaller = async () => '{"begriff": "kaputt"}';
  await assert.rejects(createGmHandlers(call).lehreGenerate!({}), GmUnavailableError);
});

test('HTTP: /lehre/generate liefert die Lehre, ungültiger Request 400, ohne Handler 404', async () => {
  const lehre = normalizeLehreDraft(amtDraft())!;
  const base: GmHandlers = {
    action: async () => { throw new Error('nicht benutzt'); },
    result: async () => { throw new Error('nicht benutzt'); },
    minigameRound: async () => { throw new Error('nicht benutzt'); },
    minigameJudge: async () => { throw new Error('nicht benutzt'); },
    epitaph: async () => { throw new Error('nicht benutzt'); },
  };
  for (const [handlers, body, status] of [
    [{ ...base, lehreGenerate: async () => lehre }, { thema: 'Sitzen' }, 200],
    [{ ...base, lehreGenerate: async () => lehre }, { thema: 42 }, 400],
    [base, {}, 404],
  ] as const) {
    const server = createGmServer(handlers);
    await new Promise<void>((r) => server.listen(0, r));
    const address = server.address();
    if (address === null || typeof address === 'string') throw new Error('keine Adresse');
    const res = await fetch(`http://127.0.0.1:${address.port}/lehre/generate`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    });
    assert.equal(res.status, status);
    if (status === 200) assert.equal(((await res.json()) as { id: string }).id, lehre.id);
    await new Promise<void>((r) => server.close(() => r()));
  }
});

test('normalize: Referenzfälle und Paare prüft erst der Client (damit die Nachbesserung einen Befund bekommt)', () => {
  const d = amtDraft() as Record<string, any>;
  d.refMembers = ['buerostuhl'];
  for (const c of d.cards) if (c.m) c.a = [...new Set([...c.a, 'moebel', 'vierbeine', 'lehne'])];
  const lehre = normalizeLehreDraft(d);
  assert.ok(lehre !== null);
  assert.equal(countPairs(lehre.cards, lehre.start), 0);
});

test('normalize: Umlaute und Bindestriche in IDs werden einheitlich normalisiert', () => {
  const d = amtDraft() as Record<string, any>;
  d.attrs[0].id = 'Möbel';
  for (const c of d.cards) c.a = c.a.map((x: string) => (x === 'moebel' ? 'Möbel' : x));
  d.start = d.start.map((l: string) => (l === '+moebel' ? '+Möbel' : l));
  d.cards[0].id = 'küchen-stuhl';
  d.refMembers = d.refMembers.map((id: string) => (id === 'kuechenstuhl' ? 'küchen-stuhl' : id));
  const lehre = normalizeLehreDraft(d);
  assert.ok(lehre !== null);
  assert.ok('moebel' in lehre.attrs);
  assert.equal(lehre.cards[0].id, 'kuechen_stuhl');
  assert.ok(lehre.refMembers.includes('kuechen_stuhl'));
});

test('Nachbesserung: Vorlage im Engine-Format wird ins Schema-Format zurückgebracht', () => {
  const engine = normalizeLehreDraft(amtDraft())! as unknown as Record<string, unknown>;
  const draft = toDraftFormat({ ...engine, cap: 9, pruefung: {} });
  assert.ok(Array.isArray(draft.attrs));
  assert.ok(Array.isArray((draft.cards as Array<{ a: unknown }>)[0].a));
  assert.equal('cap' in draft, false);
  assert.ok(normalizeLehreDraft(draft) !== null, 'zurückgewandelt wieder gültig');
});
