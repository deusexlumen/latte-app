// PURPOSE: Tests der Pfadtabelle von sync-games (Umschreiben, Zielorte, Fremd-Addons bleiben)
// ARCHITECTURE: tools
// DEPENDENCIES: node:test, ./sync-games.mjs
// PIPELINE: test
// LAST_VALIDATED: 2026-10-12
import assert from 'node:assert/strict';
import test from 'node:test';
import { GAMES, rewritePath, rewriteText, targetOf } from './sync-games.mjs';

const dame = GAMES.find((g) => g.name === 'dame').map;
const lobby = GAMES.find((g) => g.name === 'lobby_loop').map;

test('DAME-Dienste und i18n landen im gemeinsamen Kern, der Rest unter addons/dame', () => {
  assert.equal(rewritePath('res://scripts/services/json_store.gd', dame), 'res://addons/amt_core/services/json_store.gd');
  assert.equal(rewritePath('res://scripts/i18n.gd', dame), 'res://addons/amt_core/i18n.gd');
  assert.equal(rewritePath('res://scripts/app.gd', dame), 'res://addons/dame/scripts/app.gd');
  assert.equal(targetOf('scripts/services/catalog.gd', dame), 'addons/amt_core/services/catalog.gd');
});

test('Lobby-Loop landet unter addons/lobby_loop', () => {
  assert.equal(rewritePath('res://content/widerlegung/amt.json', lobby), 'res://addons/lobby_loop/content/widerlegung/amt.json');
  assert.equal(targetOf('scripts/main.gd', lobby), 'addons/lobby_loop/scripts/main.gd');
});

test('Godot-Cache und Fremd-Addons werden nie umgeschrieben', () => {
  for (const p of ['res://.godot/imported/x.ctex', 'res://addons/gut/gut_cmdln.gd', 'res://addons/webrtc/webrtc.gdextension']) {
    assert.equal(rewritePath(p, dame), p);
    assert.equal(rewritePath(p, lobby), p);
  }
});

test('Text: alle Vorkommen, auch nackter Präfix und Formatpfade', () => {
  const src = 'preload("res://scripts/app.gd")\nload("res://assets/audio/%s.ogg" % f)\nfor p in _collect("res://"):\n[ext_resource path="res://scenes/a.tscn"]';
  const out = rewriteText(src, dame);
  assert.match(out, /"res:\/\/addons\/dame\/scripts\/app.gd"/);
  assert.match(out, /"res:\/\/addons\/dame\/assets\/audio\/%s.ogg"/);
  assert.match(out, /_collect\("res:\/\/addons\/dame\/"\)/);
  assert.match(out, /path="res:\/\/addons\/dame\/scenes\/a.tscn"/);
});
