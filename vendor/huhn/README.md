# vendor/huhn

Kopie der Spiel-Engine aus „Das gerupfte Huhn" (lokal `C:\Users\Buxe\Projects\huhn\src\`, Stand 12.10.2026, v2).

- `engine.cjs` = `src/engine.js`. Einzige Änderung: `rnd` und `shuffle` stehen zusätzlich im exportierten `API`-Objekt, damit der Golden-Test Zufall und Mischen direkt vergleichen kann.
- `data.cjs` = `src/data.js`, unverändert.

Die Dateien sind die Referenz für die GDScript-Portierung. Wer sie ändert, muss danach `pnpm run build:widerlegung` laufen lassen und den neuen Golden-Stand committen. Der Test `tools/tests/export-widerlegung.test.ts` schlägt sonst fehl.
