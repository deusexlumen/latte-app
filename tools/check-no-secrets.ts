/*
 * PURPOSE: Scannt Repo-Textdateien nach Secret-Mustern (API-Keys, Bearer-Tokens); CLI-Exit 0 bei 0 Funden, sonst 1 mit Fundliste
 * ARCHITECTURE: tools/secrets-scan
 * DEPENDENCIES: node:child_process, node:fs, node:path, node:url
 * PIPELINE: test, check:secrets
 * LAST_VALIDATED: 2026-09-19
 */
import { spawnSync } from 'node:child_process';
import { readdirSync, readFileSync, statSync, type Dirent } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

export interface SecretPattern {
  name: string;
  regex: RegExp;
}

export interface SecretFinding {
  file: string;
  line: number;
  pattern: string;
  excerpt: string;
}

export interface ScanOptions {
  rootDir?: string;
}

export const SECRET_PATTERNS: readonly SecretPattern[] = [
  { name: 'google-api-key', regex: /AIza[0-9A-Za-z_-]{20,}/ },
  { name: 'generic-sk-key', regex: /sk-[0-9A-Za-z]{20,}/ },
  { name: 'bearer-token', regex: /Bearer [A-Za-z0-9_-]{20,}/ },
];

const EXCLUDED_DIR_SEGMENTS = new Set(['.git', 'node_modules', 'data']);
const EXCLUDED_FILE_NAMES = new Set(['.env', '.env.example']);
const MAX_FILE_BYTES = 2 * 1024 * 1024;
const BINARY_SNIFF_BYTES = 8192;
const EXCERPT_MAX_CHARS = 160;
const MASK_KEEP_CHARS = 4;

const isBinary = (buffer: Buffer): boolean => {
  const limit = Math.min(buffer.length, BINARY_SNIFF_BYTES);
  for (let i = 0; i < limit; i += 1) {
    if (buffer[i] === 0) return true;
  }
  return false;
};

/** Fundstellen gehen in Logs/CI — Treffer im Auszug maskieren. */
const buildExcerpt = (line: string, match: string): string =>
  line
    .trim()
    .slice(0, EXCERPT_MAX_CHARS)
    .replace(match, match.length <= MASK_KEEP_CHARS ? match : `${match.slice(0, MASK_KEEP_CHARS)}…[maskiert]`);

const scanFile = (fullPath: string, relPath: string, findings: SecretFinding[]): void => {
  let size: number;
  try {
    size = statSync(fullPath).size;
  } catch {
    return;
  }
  if (size === 0 || size > MAX_FILE_BYTES) return;

  const buffer = readFileSync(fullPath);
  if (isBinary(buffer)) return;

  const lines = buffer.toString('utf8').split(/\r?\n/);
  for (let index = 0; index < lines.length; index += 1) {
    for (const pattern of SECRET_PATTERNS) {
      const match = pattern.regex.exec(lines[index]);
      if (match === null) continue;
      findings.push({ file: relPath, line: index + 1, pattern: pattern.name, excerpt: buildExcerpt(lines[index], match[0]) });
    }
  }
};

interface ScanCandidate {
  fullPath: string;
  relPath: string;
}

const collectFiles = (dir: string, rootDir: string, out: ScanCandidate[]): void => {
  let entries: Dirent[];
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (EXCLUDED_DIR_SEGMENTS.has(entry.name)) continue;
      collectFiles(fullPath, rootDir, out);
    } else if (entry.isFile()) {
      if (EXCLUDED_FILE_NAMES.has(entry.name)) continue;
      const relPath = relative(rootDir, fullPath).split(sep).join('/');
      out.push({ fullPath, relPath });
    }
  }
};

/**
 * Pfade, die git ignoriert (untracked Laufzeit-State wie gm-proxy/router-state.json).
 * Batch via `git check-ignore`; bei git-Ausfall leere Menge = ohne Filter scannen.
 */
const gitIgnoredPaths = (rootDir: string, relPaths: string[]): Set<string> => {
  const ignored = new Set<string>();
  if (relPaths.length === 0) return ignored;
  try {
    const result = spawnSync('git', ['check-ignore', '--stdin', '-z', '--no-index'], {
      cwd: rootDir,
      input: `${relPaths.join('\0')}\0`,
      maxBuffer: 16 * 1024 * 1024,
    });
    if (result.error !== undefined || result.stdout === null) return ignored;
    for (const entry of result.stdout.toString('utf8').split('\0')) {
      if (entry.length > 0) ignored.add(entry);
    }
  } catch {
    // git nicht verfügbar — ohne Ignore-Filter scannen.
  }
  return ignored;
};

/**
 * Rekursiver Scan; Whitelist: .git, node_modules, data/ (jede Tiefe), .env, .env.example,
 * git-ignorierte Pfade, Binärdateien.
 */
export function scanForSecrets(options: ScanOptions = {}): SecretFinding[] {
  const rootDir = options.rootDir ?? fileURLToPath(new URL('..', import.meta.url));
  const candidates: ScanCandidate[] = [];
  collectFiles(rootDir, rootDir, candidates);
  const ignored = gitIgnoredPaths(
    rootDir,
    candidates.map((candidate) => candidate.relPath),
  );
  const findings: SecretFinding[] = [];
  for (const candidate of candidates) {
    if (ignored.has(candidate.relPath)) continue;
    scanFile(candidate.fullPath, candidate.relPath, findings);
  }
  findings.sort((a, b) => (a.file === b.file ? a.line - b.line : a.file < b.file ? -1 : 1));
  return findings;
}

const isMainModule = (): boolean => {
  const entry = process.argv[1];
  if (!entry) return false;
  try {
    return import.meta.url === pathToFileURL(entry).href;
  } catch {
    return false;
  }
};

if (isMainModule()) {
  const args = process.argv.slice(2).filter((arg) => arg !== '--');
  const rootDir = args[0] ?? fileURLToPath(new URL('..', import.meta.url));
  const findings = scanForSecrets({ rootDir });
  if (findings.length > 0) {
    for (const finding of findings) {
      console.error(`[check-no-secrets] ${finding.file}:${finding.line} (${finding.pattern}): ${finding.excerpt}`);
    }
    console.error(`[check-no-secrets] FEHLGESCHLAGEN: ${findings.length} Fund(e).`);
    process.exit(1);
  }
  console.log('[check-no-secrets] OK: keine Secrets in Repo-Textdateien gefunden.');
}
