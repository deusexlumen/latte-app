/*
 * PURPOSE: Tests für den Secret-Scanner: Muster-Erkennung, Whitelist (.env/.git/node_modules/data), Binär-Skip, Repo-Integration
 * ARCHITECTURE: tools/tests
 * DEPENDENCIES: node:assert/strict, node:fs, node:os, node:path, node:test, node:url, ../check-no-secrets.js
 * PIPELINE: test
 * LAST_VALIDATED: 2026-09-18
 */
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { scanForSecrets } from '../check-no-secrets.js';

// Zur Laufzeit zusammensetzen, damit diese Testdatei selbst kein Scan-Treffer wird.
const GOOGLE_KEY = `AIza${'A1'.repeat(14)}`;
const SK_KEY = `sk-${'B2'.repeat(14)}`;
const BEARER_TOKEN = `Bearer ${'C3'.repeat(14)}`;

const REPO_ROOT = fileURLToPath(new URL('../..', import.meta.url));

const writeFixture = (root: string, relPath: string, content: string | Buffer): void => {
  const fullPath = join(root, relPath);
  mkdirSync(dirname(fullPath), { recursive: true });
  writeFileSync(fullPath, content);
};

const makeFixtureRoot = (): string => mkdtempSync(join(tmpdir(), `lobby-loop-secrets-${process.pid}-`));

test('erkennt alle drei Muster mit Datei und Zeilennummer', () => {
  const root = makeFixtureRoot();
  try {
    writeFixture(
      root,
      'leak.ts',
      [`const key = "${GOOGLE_KEY}";`, `const other = "${SK_KEY}";`, `headers: { authorization: "${BEARER_TOKEN}" }`].join('\n'),
    );

    const findings = scanForSecrets({ rootDir: root });
    assert.equal(findings.length, 3);
    assert.deepEqual(
      findings.map((finding) => finding.file),
      ['leak.ts', 'leak.ts', 'leak.ts'],
    );
    assert.deepEqual(
      findings.map((finding) => finding.line),
      [1, 2, 3],
    );
    assert.deepEqual(
      findings.map((finding) => finding.pattern).sort(),
      ['bearer-token', 'generic-sk-key', 'google-api-key'],
    );
    for (const finding of findings) {
      assert.ok(finding.excerpt.includes('…[maskiert]'), `Excerpt maskiert den Treffer: ${finding.excerpt}`);
    }
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('Whitelist: .env, .env.example, .git, node_modules und data/ (jede Tiefe) werden übersprungen', () => {
  const root = makeFixtureRoot();
  try {
    writeFixture(root, '.env', `GEMINI_API_KEY=${GOOGLE_KEY}`);
    writeFixture(root, '.env.example', `GEMINI_API_KEY=${GOOGLE_KEY}`);
    writeFixture(root, '.git/config', `[core]\nkey=${GOOGLE_KEY}`);
    writeFixture(root, 'node_modules/pkg/index.js', `module.exports = "${SK_KEY}";`);
    writeFixture(root, 'data/leak.txt', `key=${GOOGLE_KEY}`);
    writeFixture(root, 'gm-proxy/data/leak.txt', `key=${SK_KEY}`);
    writeFixture(root, 'sub/leak.txt', `key=${GOOGLE_KEY}`);

    const findings = scanForSecrets({ rootDir: root });
    assert.deepEqual(
      findings.map((finding) => `${finding.file}:${finding.line}`),
      ['sub/leak.txt:1'],
    );
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('Binärdateien und leere Funde werden übersprungen', () => {
  const root = makeFixtureRoot();
  try {
    writeFixture(root, 'secret.bin', Buffer.concat([Buffer.from([0x00, 0xff]), Buffer.from(`AIza${'A1'.repeat(30)}`, 'utf8')]));
    writeFixture(root, 'clean.txt', 'const greeting = "Hallo, Ausschuss!";');

    const findings = scanForSecrets({ rootDir: root });
    assert.deepEqual(findings, []);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('Integration: der eigene Repo-Root ist sauber', () => {
  const findings = scanForSecrets({ rootDir: REPO_ROOT });
  assert.deepEqual(findings, []);
});
