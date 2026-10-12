// PURPOSE: Ein Befehl für alle Tests der App: DAME-Runner, DAME-Szenenfluss, Lobby-Loop-GUT, latte-eigene GUT-Tests
// ARCHITECTURE: tools
// DEPENDENCIES: Godot 4.7.2 (GODOT_BIN)
// PIPELINE: test
// LAST_VALIDATED: 2026-10-12
import { spawnSync } from 'node:child_process';

const bin = process.env.GODOT_BIN ?? 'C:/Users/Buxe/tools/Godot/Godot_v4.7.2-stable_win64_console.exe';
const runs = [
  { name: 'DAME', args: ['--headless', '--path', '.', 'res://addons/dame/tests/run_all.tscn'], ok: /ALL_TESTS_OK checks=(\d+) suites=(\d+)/ },
  { name: 'DAME-Fluss', args: ['--headless', '--path', '.', '--script', 'res://addons/dame/tools/flow_smoke.gd'], ok: /FLOW_OK/ },
  { name: 'Lobby-Loop', args: ['--headless', '--path', '.', '-s', 'addons/gut/gut_cmdln.gd', '-gdir=res://addons/lobby_loop/test/gut', '-gexit'], ok: /Passing Tests\s+(\d+)/, fail: /Failing Tests\s+\d+/ },
  { name: 'Latte', args: ['--headless', '--path', '.', '-s', 'addons/gut/gut_cmdln.gd', '-gdir=res://test', '-gexit'], ok: /Passing Tests\s+(\d+)/, fail: /Failing Tests\s+\d+/ },
];

let failed = false;
for (const r of runs) {
  const p = spawnSync(bin, r.args, { encoding: 'utf8' });
  const out = `${p.stdout}${p.stderr}`;
  const errors = out.split(/\r?\n/).filter((l) => /SCRIPT ERROR|Parse Error/.test(l));
  const m = out.match(r.ok);
  const bad = !m || errors.length > 0 || (r.fail && r.fail.test(out));
  console.log(`${bad ? 'FAIL' : 'OK  '} ${r.name}: ${m ? m[0] : 'kein Erfolgsmarker'}${errors.length ? ` (${errors.length} Skriptfehler)` : ''}`);
  for (const l of errors.slice(0, 5)) console.log(`     ${l.trim()}`);
  failed ||= bad;
}
process.exit(failed ? 1 : 0);
