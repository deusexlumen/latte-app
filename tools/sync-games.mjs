// PURPOSE: Baut die Spiele DAME und Lobby-Loop aus ihren Quell-Repos in latte-app ein (Phase 3, M3/M4).
// ARCHITECTURE: tools
// DEPENDENCIES: git, tar (Git for Windows), node:fs
// PIPELINE: manual
// LAST_VALIDATED: 2026-10-12
//
// Regeln:
// - Eigener Code kommt aus dem letzten Commit des festgelegten Branches (git archive), nie aus dem Arbeitsverzeichnis.
// - Fremd-Addons (GUT, godot-sqlite, webrtc) kommen aus dem Arbeitsverzeichnis, weil ihre Binärdateien
//   nicht versioniert sind. Sie landen unverändert unter addons/<name>/ und werden nie umgeschrieben.
// - Jeder res://-Pfad wird über die Pfadtabelle umgeschrieben (längster Präfix zuerst).
// - Ergebnis nie von Hand ändern: Bis zur Freigabe (manifest.source = "latte-app") sind die alten Repos die Quelle.
//
// Aufruf: node tools/sync-games.mjs

import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const PROJECTS = resolve(ROOT, '..');

/** Pfade, die nie umgeschrieben werden: Godot-Cache und Fremd-Addons auf oberster Ebene. */
const KEEP = ['res://.godot/', 'res://addons/gut/', 'res://addons/godot-sqlite/', 'res://addons/webrtc/'];

export const GAMES = [
  {
    name: 'dame',
    repo: join(PROJECTS, 'Dame-Card-Game'),
    // Fest benannter Branch statt HEAD: Ein Branchwechsel im DAME-Repo soll latte nicht still verändern.
    // feat/online-webrtc enthält main (gemergt) plus Online-Test.
    branch: 'feat/online-webrtc',
    sub: 'godot',
    // Längster Präfix zuerst. DAMEs Dienste und i18n werden zum gemeinsamen Kern (amt_core).
    map: [
      ['res://scripts/services/', 'res://addons/amt_core/services/'],
      ['res://scripts/i18n.gd', 'res://addons/amt_core/i18n.gd'],
      ['res://', 'res://addons/dame/'],
    ],
    exclude: ['project.godot', 'export_presets.cfg', 'addons/', '.godot/', 'build/'],
    thirdParty: [['godot/addons/webrtc', 'addons/webrtc']],
  },
  {
    name: 'lobby_loop',
    repo: join(PROJECTS, 'point and pen'),
    branch: 'master',
    sub: '',
    map: [['res://', 'res://addons/lobby_loop/']],
    exclude: [
      'project.godot', 'export_presets.cfg', 'addons/', '.godot/', 'build/', 'gm-proxy/', 'tools/', 'vendor/',
      'docs/', 'node_modules/', '.claude/', 'package.json', 'pnpm-lock.yaml', 'tsconfig.json', 'Dockerfile',
      '.env.example', '.github/', '.dockerignore',
    ],
    thirdParty: [['addons/gut', 'addons/gut'], ['addons/godot-sqlite', 'addons/godot-sqlite']],
  },
];

const TEXT_EXT = new Set(['.gd', '.tscn', '.tres', '.json', '.cfg', '.import', '.gdshader', '.gdshaderinc', '.md', '.txt', '.csv']);

/** Schreibt einen res://-Pfad nach der Tabelle eines Spiels um. */
export function rewritePath(path, map) {
  if (KEEP.some((k) => path.startsWith(k))) return path;
  for (const [from, to] of map) {
    if (path.startsWith(from)) return to + path.slice(from.length);
  }
  return path;
}

/** Alle res://-Vorkommen in einem Text umschreiben. Erfasst auch "res://" + x (dann wird nur der Präfix ersetzt). */
export function rewriteText(text, map) {
  return text.replace(/res:\/\/[^"'\s)\]},]*/g, (m) => rewritePath(m, map));
}

/** Zielort einer Quelldatei (relativ zum Spielordner) innerhalb von latte-app. */
export function targetOf(relPath, map) {
  return rewritePath('res://' + relPath.replace(/\\/g, '/'), map).slice('res://'.length);
}

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p, out);
    else out.push(p);
  }
  return out;
}

function ext(p) {
  const i = p.lastIndexOf('.');
  return i < 0 ? '' : p.slice(i).toLowerCase();
}

function syncGame(game) {
  const ref = execFileSync('git', ['-C', game.repo, 'rev-parse', game.branch], { encoding: 'utf8' }).trim();
  const tmp = mkdtempSync(join(tmpdir(), `latte-${game.name}-`));
  const tar = join(tmp, 'src.tar');
  execFileSync('git', ['-C', game.repo, 'archive', '--format=tar', '-o', tar, ref, ...(game.sub ? [game.sub] : [])]);
  const extract = join(tmp, 'x');
  mkdirSync(extract);
  // Relativer Pfad: GNU-tar liest "C:" sonst als Netzwerkrechner.
  execFileSync('tar', ['-xf', '../src.tar'], { cwd: extract });
  const base = game.sub ? join(extract, game.sub) : extract;

  let files = 0;
  for (const abs of walk(base)) {
    const rel = relative(base, abs).replace(/\\/g, '/');
    if (game.exclude.some((e) => (e.endsWith('/') ? rel.startsWith(e) : rel === e))) continue;
    if (rel.endsWith('/project.godot') || rel === 'project.godot') continue; // Godot ignoriert sonst den ganzen Ordner
    const dest = join(ROOT, targetOf(rel, game.map));
    mkdirSync(dirname(dest), { recursive: true });
    if (TEXT_EXT.has(ext(rel))) writeFileSync(dest, rewriteText(readFileSync(abs, 'utf8'), game.map));
    else cpSync(abs, dest);
    files++;
  }
  for (const [from, to] of game.thirdParty) {
    const src = join(game.repo, from);
    if (!existsSync(src)) continue;
    cpSync(src, join(ROOT, to), {
      recursive: true,
      // GUTs eigenes Repo-Abbild hat eine project.godot und würde das Addon unsichtbar machen.
      filter: (p) => !p.replace(/\\/g, '/').includes('/_repo'),
    });
  }
  rmSync(tmp, { recursive: true, force: true });
  return { name: game.name, branch: game.branch, ref, files };
}

function main() {
  // Nur die generierten Ordner leeren, nie eigenen latte-Code.
  for (const dir of ['addons/dame', 'addons/lobby_loop', 'addons/amt_core']) {
    rmSync(join(ROOT, dir), { recursive: true, force: true });
  }
  const results = GAMES.map(syncGame);
  const manifest = { source: 'repos', synced_at: new Date().toISOString(), games: results };
  writeFileSync(join(ROOT, 'sync-manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
  for (const r of results) console.log(`${r.name}: ${r.files} Dateien aus ${r.branch} @ ${r.ref.slice(0, 7)}`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const manifestPath = join(ROOT, 'sync-manifest.json');
  if (existsSync(manifestPath) && JSON.parse(readFileSync(manifestPath, 'utf8')).source === 'latte-app') {
    console.error('Abbruch: latte-app ist bereits die Quelle (sync-manifest.json). Ein Sync würde eigene Arbeit überschreiben.');
    process.exit(1);
  }
  main();
}
