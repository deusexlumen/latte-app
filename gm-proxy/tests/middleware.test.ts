/*
 * PURPOSE: Auth- und Rate-Limit-Tests: 401 ohne/falscher Token, Durchlass mit Token, 429-Burst, session_id-Keys, IP-Fallback, /health offen, Dev-Modus
 * ARCHITECTURE: gm-proxy/tests
 * DEPENDENCIES: node:http, node:test, node:assert/strict, ../src/middleware.js, ../src/server.js, ../src/types.js
 * PIPELINE: test
 * LAST_VALIDATED: 2026-09-18
 */
import assert from 'node:assert/strict';
import type { IncomingMessage, Server } from 'node:http';
import test from 'node:test';
import { createAuthCheck, createRateLimiter } from '../src/middleware.js';
import { createGmServer } from '../src/server.js';
import type { GmServerConfig } from '../src/server.js';
import type { GmHandlers } from '../src/types.js';

const ACTION_BODY = {
  player_inventory: [],
  current_scene: 'kommunalpolitik',
  alignment_score: 0,
  player_input: 'Test.',
};

const mockHandlers = (): GmHandlers => ({
  action: async () => ({ gm_dialogue: 'ok', required_roll: 'W20', difficulty_class: 10, trigger_event: null }),
  result: async () => ({ gm_dialogue: 'ok', required_roll: 'W20', difficulty_class: 10, trigger_event: null }),
  minigameRound: async () => ({ accusation: 'Vorwurf', phrases: ['a', 'b', 'c'] }),
  minigameJudge: async () => ({ correct: true, correct_index: 0, commentary: 'ok' }),
  epitaph: async () => ({ epitaph: 'ok', highlights: [] }),
});

interface Fixture {
  server: Server;
  baseUrl: string;
}

async function startServer(config: GmServerConfig = {}): Promise<Fixture> {
  const server = createGmServer(mockHandlers(), () => undefined, config);
  await new Promise<void>((resolveListen) => server.listen(0, resolveListen));
  const address = server.address();
  if (address === null || typeof address === 'string') {
    throw new Error('Server meldet keine TCP-Adresse.');
  }
  return { server, baseUrl: `http://127.0.0.1:${address.port}` };
}

const postAction = (baseUrl: string, body: unknown, token?: string): Promise<Response> =>
  fetch(`${baseUrl}/gm/action`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token !== undefined ? { 'x-lobby-token': token } : {}),
    },
    body: JSON.stringify(body),
  });

test('Auth aktiv: fehlender Token → 401', async () => {
  const { server, baseUrl } = await startServer({ authToken: 'geheim' });
  try {
    const res = await postAction(baseUrl, ACTION_BODY);
    assert.equal(res.status, 401);
    const payload = (await res.json()) as { error: string };
    assert.match(payload.error, /x-lobby-token/);
  } finally {
    server.close();
  }
});

test('Auth aktiv: falscher Token → 401', async () => {
  const { server, baseUrl } = await startServer({ authToken: 'geheim' });
  try {
    const res = await postAction(baseUrl, ACTION_BODY, 'falsch');
    assert.equal(res.status, 401);
  } finally {
    server.close();
  }
});

test('Auth aktiv: korrekter Token → 200', async () => {
  const { server, baseUrl } = await startServer({ authToken: 'geheim' });
  try {
    const res = await postAction(baseUrl, ACTION_BODY, 'geheim');
    assert.equal(res.status, 200);
    const payload = (await res.json()) as { difficulty_class: number };
    assert.equal(payload.difficulty_class, 10);
  } finally {
    server.close();
  }
});

test('Rate-Limit: Burst von limit+1 Requests → letzter 429 mit Retry-After', async () => {
  const limit = 3;
  const { server, baseUrl } = await startServer({ rateLimitPerMinute: limit });
  try {
    const statuses: number[] = [];
    for (let i = 0; i <= limit; i += 1) {
      const res = await postAction(baseUrl, { ...ACTION_BODY, session_id: 'burst-session' });
      statuses.push(res.status);
      if (i === limit) {
        assert.ok(res.headers.get('retry-after') !== null, '429-Antwort trägt Retry-After-Header.');
        assert.ok(Number(res.headers.get('retry-after')) > 0, 'Retry-After ist positiv.');
        const payload = (await res.json()) as { error: string };
        assert.match(payload.error, /Rate-Limit/);
      } else {
        await res.json();
      }
    }
    assert.deepEqual(statuses, [200, 200, 200, 429]);
  } finally {
    server.close();
  }
});

test('Rate-Limit: unterschiedliche session_ids zählen getrennt', async () => {
  const { server, baseUrl } = await startServer({ rateLimitPerMinute: 1 });
  try {
    const first = await postAction(baseUrl, { ...ACTION_BODY, session_id: 'session-a' });
    assert.equal(first.status, 200);
    await first.json();
    const second = await postAction(baseUrl, { ...ACTION_BODY, session_id: 'session-b' });
    assert.equal(second.status, 200);
  } finally {
    server.close();
  }
});

test('Rate-Limit: Fallback Client-IP ohne session_id', async () => {
  const limit = 2;
  const { server, baseUrl } = await startServer({ rateLimitPerMinute: limit });
  try {
    for (let i = 0; i < limit; i += 1) {
      const res = await postAction(baseUrl, ACTION_BODY);
      assert.equal(res.status, 200);
      await res.json();
    }
    const denied = await postAction(baseUrl, ACTION_BODY);
    assert.equal(denied.status, 429);
  } finally {
    server.close();
  }
});

test('/health bleibt ohne Token erreichbar', async () => {
  const { server, baseUrl } = await startServer({ authToken: 'geheim', rateLimitPerMinute: 1 });
  try {
    const res = await fetch(`${baseUrl}/health`);
    assert.equal(res.status, 200);
    const payload = (await res.json()) as { ok: boolean };
    assert.equal(payload.ok, true);
  } finally {
    server.close();
  }
});

test('Dev-Modus: kein Token, kein Limit → unverändert offen', async () => {
  const { server, baseUrl } = await startServer();
  try {
    for (let i = 0; i < 5; i += 1) {
      const res = await postAction(baseUrl, { ...ACTION_BODY, session_id: 'dev-session' });
      assert.equal(res.status, 200);
      await res.json();
    }
  } finally {
    server.close();
  }
});

test('createAuthCheck: leerer Token → null, sonst Header-Prüfung', () => {
  assert.equal(createAuthCheck(undefined), null);
  assert.equal(createAuthCheck('   '), null);
  const check = createAuthCheck('geheim');
  if (check === null) throw new Error('Token-Check sollte aktiv sein.');
  const fakeReq = (header?: string): IncomingMessage =>
    ({ headers: header === undefined ? {} : { 'x-lobby-token': header } }) as IncomingMessage;
  assert.equal(check(fakeReq('geheim')), true);
  assert.equal(check(fakeReq('falsch')), false);
  assert.equal(check(fakeReq()), false);
});

test('createRateLimiter: Fixfenster mit injizierter Uhr', () => {
  let current = 1_000_000;
  const check = createRateLimiter({ limit: 1, windowMs: 60_000, now: () => current });
  assert.deepEqual(check('s1'), { allowed: true, retryAfterSeconds: 0 });
  const denied = check('s1');
  assert.equal(denied.allowed, false);
  assert.equal(denied.retryAfterSeconds, 60);
  current += 30_000;
  assert.equal(check('s1').allowed, false);
  current += 30_000;
  assert.deepEqual(check('s1'), { allowed: true, retryAfterSeconds: 0 });
  assert.deepEqual(check('s2'), { allowed: true, retryAfterSeconds: 0 });
});

test('cors: leer = keine Header, Liste erlaubt nur genannte Origins, * erlaubt alle', async () => {
  const { corsHeaders, parseCorsOrigins } = await import('../src/middleware.js');
  assert.equal(corsHeaders([], 'https://a.example'), null);
  assert.equal(corsHeaders(['https://a.example'], 'https://b.example'), null);
  assert.equal(corsHeaders(['https://a.example'], 'https://a.example')?.['Access-Control-Allow-Origin'], 'https://a.example');
  assert.equal(corsHeaders(['*'], 'https://x.example')?.['Access-Control-Allow-Origin'], '*');
  assert.match(corsHeaders(['*'], 'https://x.example')?.['Access-Control-Allow-Headers'] ?? '', /x-lobby-token/);
  assert.deepEqual(parseCorsOrigins(' https://a.example , ,* '), ['https://a.example', '*']);
});
