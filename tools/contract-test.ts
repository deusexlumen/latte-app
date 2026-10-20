/*
 * PURPOSE: Contract-Test gegen einen laufenden GM-Proxy: /health, /gm/action (gültig/ungültig), optionaler 401-Auth-Check
 * ARCHITECTURE: tools/contract-test
 * DEPENDENCIES: node:path, node:url
 * PIPELINE: test, runtime
 * LAST_VALIDATED: 2026-09-18
 */
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const isNonEmptyString = (value: unknown): value is string =>
  typeof value === 'string' && value.trim().length > 0;

export function isValidHealthResponse(body: unknown): boolean {
  return isRecord(body) && body.ok === true;
}

/** Antwort-Shape von POST /gm/action gemäß LOBBY-LOOP.md-Kontrakt. */
export function isValidActionResponse(body: unknown): boolean {
  if (!isRecord(body)) return false;
  if (!isNonEmptyString(body.gm_dialogue)) return false;
  if (typeof body.difficulty_class !== 'number' || !Number.isInteger(body.difficulty_class)) return false;
  if (body.difficulty_class < 1 || body.difficulty_class > 20) return false;
  if (!isNonEmptyString(body.required_roll)) return false;
  if (body.trigger_event !== undefined && body.trigger_event !== null && !isRecord(body.trigger_event)) return false;
  return true;
}

export interface ContractCheck {
  name: string;
  ok: boolean;
  detail: string;
}

interface CheckOptions {
  /** Falscher Token für den optionalen Auth-Check (nur gesetzt, wenn per Env-Flag aktiviert). */
  wrongToken?: string;
  /** Korrekter Token: wird als x-lobby-token auf den /gm/action-Requests mitsendet, wenn gesetzt. */
  token?: string;
}

const VALID_ACTION_PAYLOAD = {
  session_id: 'contract-test',
  player_inventory: ['Gedächtnislücke', 'Schwarzer Koffer'],
  current_scene: 'Untersuchungsausschuss',
  alignment_score: -4,
  fraktionsdisziplin: 5,
  player_input: 'Ich biete dem Vorsitzenden einen Aufsichtsratsposten an.',
};

const postJson = async (
  baseUrl: string,
  path: string,
  payload: unknown,
  headers: Record<string, string> = {},
): Promise<{ status: number; body: unknown }> => {
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(payload),
  });
  return { status: res.status, body: await res.json().catch(() => null) };
};

/** Führt alle Contract-Checks gegen baseUrl aus. Wirft nur bei Netzfehlern, nie wegen failed Checks. */
export async function runContractChecks(baseUrl: string, options: CheckOptions = {}): Promise<ContractCheck[]> {
  const checks: ContractCheck[] = [];
  const trimmed = baseUrl.replace(/\/+$/, '');

  try {
    const res = await fetch(`${trimmed}/health`);
    const body: unknown = await res.json().catch(() => null);
    checks.push({
      name: 'GET /health → 200 {ok:true}',
      ok: res.status === 200 && isValidHealthResponse(body),
      detail: `status=${res.status} body=${JSON.stringify(body)}`,
    });
  } catch (err) {
    checks.push({ name: 'GET /health', ok: false, detail: `Netzfehler: ${err instanceof Error ? err.message : String(err)}` });
    // Proxy nicht erreichbar — Rest sinnlos.
    return checks;
  }

  const authHeaders: Record<string, string> =
    options.token !== undefined ? { 'x-lobby-token': options.token } : {};
  const action = await postJson(trimmed, '/gm/action', VALID_ACTION_PAYLOAD, authHeaders);
  checks.push({
    name: `POST /gm/action (gültig${options.token !== undefined ? ', authentisiert' : ''}) → 200 + Kontrakt-Shape`,
    ok: action.status === 200 && isValidActionResponse(action.body),
    detail: `status=${action.status} body=${JSON.stringify(action.body)}`,
  });

  const bad = await postJson(trimmed, '/gm/action', { current_scene: 'x' }, authHeaders);
  checks.push({
    name: 'POST /gm/action (ungültig) → 400',
    ok: bad.status === 400,
    detail: `status=${bad.status} body=${JSON.stringify(bad.body)}`,
  });

  if (options.wrongToken !== undefined) {
    const denied = await postJson(trimmed, '/gm/action', VALID_ACTION_PAYLOAD, { 'x-lobby-token': options.wrongToken });
    checks.push({
      name: 'POST /gm/action (falscher x-lobby-token) → 401',
      ok: denied.status === 401,
      detail: `status=${denied.status} body=${JSON.stringify(denied.body)}`,
    });
  }

  return checks;
}

const isMainModule = (): boolean => {
  const entry = process.argv[1];
  if (!entry) return false;
  try {
    return import.meta.url === pathToFileURL(resolve(entry)).href;
  } catch {
    return false;
  }
};

if (isMainModule()) {
  const baseUrl = process.argv[2] ?? process.env.GM_PROXY_URL ?? 'http://localhost:8787';
  const wrongToken = process.env.GM_CONTRACT_TEST_AUTH === '1' ? 'contract-test-wrong-token' : undefined;
  const token = process.env.GM_CONTRACT_TEST_TOKEN;

  console.log(`[contract-test] Ziel: ${baseUrl}${wrongToken !== undefined ? ' (Auth-Checks aktiv)' : ''}`);
  const checks = await runContractChecks(baseUrl, { wrongToken, token });
  let failed = 0;
  for (const check of checks) {
    console.log(`${check.ok ? 'PASS' : 'FAIL'}  ${check.name}  — ${check.detail}`);
    if (!check.ok) failed += 1;
  }
  if (failed > 0) {
    console.error(`[contract-test] ${failed}/${checks.length} Checks fehlgeschlagen.`);
    process.exit(1);
  }
  console.log(`[contract-test] Alle ${checks.length} Checks grün.`);
}
