/*
 * PURPOSE: Tests des Contract-Test-Skripts: Validierfunktionen + Happy-Path gegen Mock-Server (Port 0, kein LLM)
 * ARCHITECTURE: tools/tests
 * DEPENDENCIES: node:http, node:test, node:assert/strict, ../../gm-proxy/src/server.js, ../../gm-proxy/src/types.js, ../contract-test.js
 * PIPELINE: test
 * LAST_VALIDATED: 2026-09-18
 */
import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import test from 'node:test';
import { createGmServer } from '../../gm-proxy/src/server.js';
import type { GmHandlers } from '../../gm-proxy/src/types.js';
import { isValidActionResponse, isValidHealthResponse, runContractChecks } from '../contract-test.js';

const ACTION_RESPONSE = {
  gm_dialogue: 'Der Aktenkoffer rattert zustimmend.',
  required_roll: 'W20',
  difficulty_class: 12,
  trigger_event: null,
};

const mockHandlers = (): GmHandlers => ({
  action: async () => ACTION_RESPONSE,
  result: async () => ACTION_RESPONSE,
  minigameRound: async () => ({ accusation: 'a', phrases: ['eins', 'zwei', 'drei'] }),
  minigameJudge: async () => ({ correct: true, correct_index: 0, commentary: 'ok' }),
  epitaph: async () => ({ epitaph: 'x', highlights: ['a', 'b', 'c'] }),
});

const withServer = async (fn: (baseUrl: string) => Promise<void>): Promise<void> => {
  const server: Server = createGmServer(mockHandlers());
  await new Promise<void>((resolveListen) => server.listen(0, resolveListen));
  const address = server.address();
  assert.ok(address !== null && typeof address === 'object');
  try {
    await fn(`http://127.0.0.1:${address.port}`);
  } finally {
    await new Promise<void>((resolveClose, rejectClose) =>
      server.close((err) => (err ? rejectClose(err) : resolveClose())),
    );
  }
};

test('isValidHealthResponse: akzeptiert {ok:true}, lehnt Rest ab', () => {
  assert.equal(isValidHealthResponse({ ok: true }), true);
  assert.equal(isValidHealthResponse({ ok: false }), false);
  assert.equal(isValidHealthResponse({}), false);
  assert.equal(isValidHealthResponse(null), false);
  assert.equal(isValidHealthResponse('ok'), false);
});

test('isValidActionResponse: akzeptiert Kontrakt-Payload inkl. fehlendem trigger_event', () => {
  assert.equal(
    isValidActionResponse({
      gm_dialogue: 'Der Vorsitzende schwitzt.',
      required_roll: 'W20',
      difficulty_class: 12,
      trigger_event: { type: 'add_item', item: 'Schwarzer Koffer' },
    }),
    true,
  );
  assert.equal(
    isValidActionResponse({ gm_dialogue: 'x', required_roll: 'W20', difficulty_class: 20 }),
    true,
  );
});

test('isValidActionResponse: lehnt kaputte Shapes ab', () => {
  const base = { gm_dialogue: 'x', required_roll: 'W20', difficulty_class: 12 };
  assert.equal(isValidActionResponse({ ...base, gm_dialogue: '' }), false);
  assert.equal(isValidActionResponse({ ...base, gm_dialogue: 42 }), false);
  assert.equal(isValidActionResponse({ ...base, required_roll: '' }), false);
  assert.equal(isValidActionResponse({ ...base, difficulty_class: 0 }), false);
  assert.equal(isValidActionResponse({ ...base, difficulty_class: 21 }), false);
  assert.equal(isValidActionResponse({ ...base, difficulty_class: 12.5 }), false);
  assert.equal(isValidActionResponse({ ...base, trigger_event: 'add_item' }), false);
  assert.equal(isValidActionResponse({ ...base, trigger_event: 7 }), false);
  assert.equal(isValidActionResponse({ ...base, trigger_event: [1, 2] }), false);
  assert.equal(isValidActionResponse(null), false);
  assert.equal(isValidActionResponse('gm_dialogue'), false);
});

test('runContractChecks: Mock-Server besteht alle Checks lokal (Health, Action, 400)', async () => {
  await withServer(async (baseUrl) => {
    const checks = await runContractChecks(baseUrl);
    assert.equal(checks.length, 3);
    for (const check of checks) {
      assert.ok(check.ok, `${check.name} — ${check.detail}`);
    }
  });
});

test('runContractChecks: ohne wrongToken wird kein Auth-Check gefordert', async () => {
  await withServer(async (baseUrl) => {
    const checks = await runContractChecks(baseUrl);
    assert.ok(checks.every((check) => !check.name.includes('401')));
  });
});

test('runContractChecks: wrongToken-Option fügt 401-Check hinzu (Mock ohne Auth → schlägt fehl)', async () => {
  await withServer(async (baseUrl) => {
    const checks = await runContractChecks(baseUrl, { wrongToken: 'falsch' });
    assert.equal(checks.length, 4);
    const authCheck = checks.find((check) => check.name.includes('401'));
    assert.ok(authCheck !== undefined);
    assert.equal(authCheck.ok, false);
  });
});

test('runContractChecks: unreachable Host → genau ein Netzfehler-Check, kein Throw', async () => {
  const checks = await runContractChecks('http://127.0.0.1:1');
  assert.equal(checks.length, 1);
  assert.equal(checks[0]!.ok, false);
  assert.match(checks[0]!.detail, /Netzfehler/);
});
