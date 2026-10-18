# Fahrplan ab 18. Oktober 2026

**Bezug:** `../lobby-loop/docs/konzept/gesamtkonzept-latte.md` (Gesamtkonzept, Phasen 1 bis 4), Spezifikation 0.1 (E0 bis E5), `../Dame-Card-Game/docs/online-p2p-plan.md`
**Gilt für:** Latte (diese App), DAME (`Dame-Card-Game`), Lobby-Loop (`lobby-loop`)

## Wo wir stehen

| Teil | Stand | Was fehlt |
|---|---|---|
| Gesamtkonzept Phase 1 bis 4 | umgesetzt: Widerlegung in Lobby-Loop, Spielleiter erfindet Lehren, Latte mit Flur und vier Türen, DAME als Hinterzimmer | Abnahme „Web-Build unter 70 MB, installierbare Web-App“ nicht gemessen |
| Gemeinsame Welt (Spez. 0.1) | E0 bis E4 fertig (BANK-01, Widerlegung im Ausschuss, echte DAME-Partie) | **Spieltest BANK-01 nicht durchgeführt**, danach Überarbeitung und E5 |
| DAME eigenständig | live auf GitHub Pages; online mit Raumcode, bis 5 Gäste, Wiedereintritt, Abwesenheitsanzeige, Live-Test gegen Supabase täglich | Online-Oberfläche noch Testaufbau, Gästenamen, TURN-Kontingent ungeschützt, kein Test mit echten Geräten |
| DAME in Latte | Stand `a5e503d` (vor dem ganzen Online-Ausbau vom 18.10.) | 5 DAME-PRs nicht gesynct (#16, #18 bis #21); ob Online in Latte läuft, ist ungeprüft |
| Lobby-Loop | Widerlegung, Lehren-Forge (Tor 12/20 erreicht), Proxy gehärtet | Hoster und Domain für den Spielleiter, Itch-Preset |
| Geld | nur Stub (`PurchaseProvider`) | Kanal und Preis offen |

## Entscheidungen, die nur du treffen kannst

Jede mit meiner Empfehlung. Bis du entscheidest, gilt die Empfehlung als Arbeitsannahme, gebaut wird aber nichts Unumkehrbares.

1. **Bleibt DAME eigenständig im Netz?** Empfehlung: ja. Die Pages-Fassung ist kostenlos und das Schaufenster aus dem Geschäftsmodell („kostenlose Web-Fassung … DAME gegen den Computer“). Online darin bleibt kostenlos, solange es nichts kostet (P2P, Gratis-Kontingente).
2. **Erster Verkaufskanal.** Empfehlung: itch.io mit Windows- und Web-Build von Latte, ein Preis, kein Abo. Steam erst nach Rückmeldung von Spielern.
3. **Spielleiter-Kosten.** Empfehlung wie im Gesamtkonzept: Vollversion ohne Spielleiter komplett spielbar, Spielleiter nur mit eigenem Schlüssel des Spielers. Ein eigener gehosteter Proxy erst, wenn klar ist, wie viele Aufrufe ein Abend braucht.
4. **Altlasten.** Die React-App in `Dame-Card-Game/src/`, die Repos `dame-kartenspiel` (Node-Server-Variante) und `Dame---Strategic-Card-Game` (AI-Studio-Entwurf) und PR Dame-Card-Game#11 werden nicht mehr gebraucht. Empfehlung: Repos auf GitHub archivieren (umkehrbar), React-Code in einem eigenen PR entfernen, #11 schließen. Löschen nur auf dein Wort.
5. **Matchmaking und Rangliste.** Brauchen einen vertrauenswürdigen Server (beim P2P sieht der Host alle Karten). Empfehlung: zurückstellen, bis es Spieler gibt, die Fremde suchen. Freunde-Partien per Raumcode decken den Anfang ab.

## Phasen

Jede Phase endet an einem prüfbaren Tor. Was ich ohne dich erledigen kann, steht unter **Ich**, was nur mit dir geht, unter **Du**.

### A. DAME online fertig (jetzt)

**Ich**
- Online-Bildschirm aufräumen: Raum als Hauptweg, Copy-Paste eingeklappt, „Online (Test)“ heißt „Online“.
- Gäste schicken ihren Spielernamen mit; Namen am Tisch statt „Gast 2“.
- TURN-Funktion mit Abruflimit pro IP absichern (Supabase-Funktion, Deploy über die Supabase-Anbindung).
- DAME neu nach Latte syncen (`tools/sync-games.mjs`), Latte-Tests grün, Online im Latte-Build einmal mit zwei Fenstern prüfen.

**Du**
- Eine Partie mit drei Geräten über „Raum öffnen“, eins davon im Mobilfunk, einmal kurz das Netz trennen.

**Tor:** Partie mit drei Geräten bis zum Ende, Wiedereintritt nach Netztrennung klappt, kein Fehler im Spiel.

### B. Latte spieltestreif (danach)

**Du**
- Spieltest BANK-01 nach `docs/spieltest-bank-01.md`. Ohne ihn ist jede weitere Arbeit an der Welt geraten.

**Ich**
- Auswertung mit `tools/spieltest-auswertung.mjs`, Überarbeitung nach der Diagnosetabelle (Spez. Kap. 20.6).
- Browser-Speicher absichern: Heute kann eine Handlung verloren gehen, wenn der Tab innerhalb von etwa zwei Sekunden geschlossen wird (`e4-konsolidierung.md`). Speichern beim Verlassen der Seite erzwingen.
- „Mandat verloren“-Schirm nach verlorener Hinterzimmer-Partie nachziehen (bekannter Fehler aus Phase 4).
- Größe messen: Web-Build von Latte gegen das Tor „unter 70 MB“; wenn darüber, Assets verkleinern (DAME hat den eigenen Download schon halbiert).

**Tor:** Spieltest ausgewertet, Überarbeitung gemergt, Web-Build unter 70 MB und als App installierbar.

### C. E5 und Veröffentlichung (danach)

**Ich**
- E5: zweiter Vorgang aus denselben Regeln (Nachweis, dass die Welt ohne Sonderbau wächst).
- Build-Kette für Latte in CI: Windows- und Web-Export bei jedem Merge, Artefakte zum Herunterladen, Tests aller drei Projekte.
- Spielleiter mit eigenem Schlüssel: Eingabefeld in den Einstellungen, Schlüssel nur lokal gespeichert, klare Anzeige, wenn ohne Spielleiter gespielt wird.
- Erste Partie DAME geführt (heute gibt es nur das Hilfefenster): drei Hinweise beim ersten Spiel, abschaltbar.
- Zugänglichkeit aus dem Konzept: Tastatur überall, große Schrift; Bildschirmleser zuletzt (in DAME seit dem 3D-Umbau offen).

**Du**
- Entscheidungen 2 und 3 von oben; itch.io-Konto und Seite (Texte und Bilder kann ich vorbereiten).

**Tor:** Kaufbare Fassung auf itch.io, ohne Spielleiter vollständig spielbar.

### D. Langzeit (nach Veröffentlichung, nach Hebel geordnet)

1. **Huhn-Duell** über den DAME-Netzkern: Raumcode, Wiedereintritt und Abwesenheit sind fertig und spielunabhängig. Größter Hebel für Langzeitspaß laut Gesamtkonzept.
2. **Lehren-Werkstatt** mit Prüfsiegel aus der Simulation, Teilen per Code (Raum-Dienst ist da).
3. **Android-Export** (DAME-Notizen: „später“; WebRTC dort über `webrtc-native` prüfen).
4. **Neue Minispiele aus dem Manifest** (Garbo, Köpenick, Vasa, Poyais) im selben Vertrag.
5. **Matchmaking, Rangliste, Wochenlehre**: erst mit Spielern und Server (Entscheidung 5).

## Laufende Pflichten (ohne Termin)

- Täglicher Live-Test des Raum-Dienstes (`Dame-Card-Game/.github/workflows/online-live.yml`) hält das Supabase-Gratisprojekt wach. Schlägt er fehl, ist Online für alle kaputt.
- Kontingente: Supabase Realtime (2 Mio. Nachrichten/Monat), ExpressTURN (1.000 GB/Monat), Gemini (Gratis-Kontingent pro Schlüssel). Vor der Veröffentlichung einmal Verbrauch je Partie messen.
- Sync-Regel: DAME und Lobby-Loop werden nur in ihren eigenen Repos geändert, Latte bekommt sie über `sync-games.mjs`.

## Risiken

| Stufe | Risiko | Gegenmittel |
|---|---|---|
| P1 | Spieltest bleibt aus, die Welt wächst auf Vermutungen | Phase B beginnt mit dem Spieltest; ohne ihn keine E5 |
| P1 | TURN-Kontingent wird von Fremden leergezogen, Online fällt im Mobilfunk aus | Abruflimit in Phase A |
| P2 | Latte und DAME laufen auseinander (heute 5 PRs Abstand) | Sync nach jedem DAME-Merge, Latte-CI in Phase C |
| P2 | Browser verliert Spielstand beim schnellen Schließen | Speichern beim Verlassen erzwingen (Phase B) |
| P3 | Host sieht alle Karten | Für Freunde vertretbar; erst mit Rangliste ein Problem (Entscheidung 5) |
