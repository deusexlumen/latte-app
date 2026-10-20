/*
 * PURPOSE: Erzeugt N Lehren über den echten Gemini-Caller (ohne HTTP) und legt sie als JSON ab — Rohmaterial für die Tor-Messung in Godot
 * ARCHITECTURE: tools
 * DEPENDENCIES: ../../gm-proxy/src/gemini.js, ../../gm-proxy/src/llm-handlers.js
 * PIPELINE: manual
 * LAST_VALIDATED: 2026-10-12
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { createGeminiLlmCaller } from '../../gm-proxy/src/gemini.js';
import { createGmHandlers } from '../../gm-proxy/src/llm-handlers.js';

// Aufruf: tsx tools/lehre/generate-batch.ts <anzahl> <zielordner> [pause-ms]
const count = Number(process.argv[2] ?? 1);
const outDir = resolve(process.argv[3] ?? 'tools/lehre/out');
const pauseMs = Number(process.argv[4] ?? 13_000); // Free Tier: ~5 Anfragen pro Minute

const THEMEN = [
  'Parkplatz', 'Haustier', 'Brief', 'Werkzeug', 'Getränk', 'Fahrzeug', 'Gebäude', 'Musikinstrument',
  'Kleidungsstück', 'Spielzeug', 'Obst', 'Vogel', 'Behältnis', 'Sportgerät', 'Lichtquelle', 'Schreibgerät',
  'Kopfbedeckung', 'Brücke', 'Insekt', 'Formular',
];

try { process.loadEnvFile(); } catch { /* .env optional */ }
mkdirSync(outDir, { recursive: true });
const gm = createGmHandlers(createGeminiLlmCaller());
for (let i = 0; i < count; i++) {
  const thema = THEMEN[i % THEMEN.length];
  const t0 = Date.now();
  try {
    const lehre = await gm.lehreGenerate!({ thema });
    writeFileSync(resolve(outDir, `${String(i).padStart(2, '0')}_${lehre.id}.json`), JSON.stringify(lehre, null, 1));
    console.log(`${i} ${thema}: ${lehre.begriff} (${lehre.cards.length} Karten) ${Date.now() - t0} ms`);
  } catch (err) {
    console.log(`${i} ${thema}: FEHLER ${err instanceof Error ? err.message : String(err)}`);
  }
  if (i < count - 1) await new Promise((r) => setTimeout(r, pauseMs));
}
