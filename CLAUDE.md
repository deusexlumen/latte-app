# CLAUDE.md – Latte

Die Latte-App ist **das** Projekt: eine Godot-App (4.7.2, GL Compatibility), der Flur des Amts mit Karriere (Lobby-Loop), Hörsaal (Widerlegung), Hinterzimmer (DAME) und Innenhof (gemeinsame Welt, Vorgänge). Aufbau und Türen: `README.md`. Stand und Entscheidungen: `SESSION_NOTES.md`. Was als Nächstes kommt: `docs/fahrplan-2026-10.md`. Grundlagen (Spezifikation 0.1, systemisches Design-Framework, systemtheoretische Analyse): `docs/grundlagen/`.

## Leitbild (verbindlich, vom Nutzer, gilt vor allen anderen Dokumenten)

1. **Herzensprojekt.** Es soll funktionieren und Spaß machen, weil es Spaß machen soll. Geld ist kein Ziel. Keine Planung zu Shop, Preisen, Verkauf, Geschäftsmodell oder Veröffentlichung, außer der Nutzer spricht es selbst an.
2. **Eine App.** Alles wird eine einzige App: die Latte-App („Die Latte liegt am Boden“, Repo `latte-app`). Kein Spiel ist als eigenständige App ein Ziel; DAME und Lobby-Loop sind Quellen dieser App.
3. **Wofür.** Im Mittelpunkt stehen die Welt, ihre Funktion und das Erleben. Man soll mit mehr aus dem Spiel gehen, als man hineingegangen ist, obwohl man die ganze Zeit verliert. Grundlage sind das Manifest „Die Latte liegt am Boden“ (Kulisse gegen Fundament, Diogenes, Mad Jack) und ein systemtheoretischer Blick auf Institutionen. Jede Funktion wird daran gemessen, ob sie die Welt, das Erleben und diese Erkenntnis stärkt. Ausgeführt in der Spezifikation 0.1 (`docs/grundlagen/spezifikation-0.1-gemeinsame-spielwelt.md`, Kap. 1 Zweck und Kap. 2 Gestaltungsregeln G-01 bis G-12): Immersion ist der Zweck, die Welt ist indifferent, Deutung bleibt offen (kein Erkenntnis- oder Moralwert).
4. Ältere Dokumente, die Verkauf, Geschäftsmodell oder eigenständige Apps planen (z. B. im Gesamtkonzept „Geld ohne Gier“ und „Kein Spiel hängt vom anderen ab … einzeln startbar“), sind darin überholt.

## Arbeitsweise mit dem Nutzer (verbindlich, geht allem anderen vor)

Der Nutzer gibt Routinearbeit komplett ab. Diese Regeln gelten wörtlich:

1. **Selbst erledigen, nicht fragen.** Eigene PRs gleich als „ready“ (kein Draft) öffnen, CI-Fehler und Review-Kommentare selbst beheben und **selbst nach `main` mergen** (Squash), sobald CI auf dem aktuellen Commit grün ist, kein Konflikt besteht und kein Review-Thread offen ist. Dafür keine Rückfrage. Gefragt wird nur bei echten Produktentscheidungen (Spielregeln, Geld, Datenschutz, Löschen).
2. **Nur melden, was der Nutzer zum Handeln braucht.** Keine Bestätigung von Selbstverständlichem (Merge geklappt, Subscription beendet, Benachrichtigung gelesen). Läuft alles glatt, reicht ein Satz.
3. **Kein „offen“ oder „ungeprüft“ ohne Lösungsversuch.** Erst lösen. Geht es nicht: sagen, warum nicht, was das praktisch fürs Spiel bedeutet und wer konkret was tun muss. Ein Grund muss geprüft sein, nicht vermutet.
4. **Wörter meinen, was sie sagen.** „Nichts zu tun“ heißt: gemergt, Notizen aktuell, kein offener Punkt. Sonst die offenen Punkte nennen.

## Arbeiten im Repo

- `addons/dame/`, `addons/lobby_loop/`, `addons/amt_core/` sind **erzeugt** (`tools/sync-games.mjs`), nie von Hand ändern. DAME wird in `Dame-Card-Game` geändert, Lobby-Loop in `lobby-loop`, danach hier neu syncen (`sync-manifest.json` hält die Stände).
- Tests: `npm test` (DAME, DAME-Fluss, Latte-Fluss, Lobby-Loop, Latte, Node).
- Code-Kommentare und Spieltexte deutsch, Bezeichner englisch.

## Cloud-Sandbox (Claude Code im Web)

- Godot: `/root/.cache/godot-4.7.2/…` per `GODOT_BIN` (Hook im DAME-Repo); `npm test` braucht `GODOT_BIN`.
- **SQLite:** Lobby-Loop liefert die SQLite-Erweiterung nur für Windows. Unter Linux meldet der Latte-Fluss deshalb 3 Ladefehler (`libgdsqlite.linux…so`), sonst ist er grün; das Spiel fällt dann auf JSON zurück. Die Linux-Datei lässt sich hier nicht holen (GitHub ist auf die eigenen Repos beschränkt).
- **WebRTC:** Mit `addons/webrtc/lib` laufen DAMEs Verbindungstests, die in der Sandbox (keine Netzwerkschnittstellen) zeitweise in Zeitüberschreitung laufen. Gegenprobe: `lib` kurz wegschieben, dann werden sie übersprungen und der Rest muss grün sein.
