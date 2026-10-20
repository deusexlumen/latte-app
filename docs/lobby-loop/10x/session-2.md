# 10x Analysis: LOBBY-LOOP

Session 2 | Date: 2026-09-19

## Current Value

Seit Session 1 ist der „Do Now/Do Next"-Riesensprung passiert — der Kern-Loop
hat jetzt die Differenzierungs-Schicht:

- **GM-Gedächtnis** (ADR-0004): Fakten-Chronik pro Session, letzte 10 Einträge
  im System-Prompt. Der GM kennt den Spieler wieder.
- **Karriere-Akte** (ADR-0005): Perma-Death generiert ein amtlich-satirisches
  Artefakt (`epitaph_generator.gd` clientseitig, `/run/epitaph` am Proxy),
  offline mit Template-Fallback.
- **Case-File-Panel** (`scripts/ui/case_file_panel.gd`): Ermittlungsstand
  sichtbar.
- **Minigame-Fallback permutiert** (`minigame_shuffle.gd`), **Buffs aktiv**
  (4 von 13 Items haben `buff`-Felder), Router **gevendort** (ADR-0006).
- **Welt:** 5 Szenen, 21 Knoten, 13 Items, 5 Kombinationen.

Der Spielerlebnis-Unterschied zu Session 1: Aus Einzelrunden ist eine Kampagne
geworden, aus dem Reset ein Artefakt. Genau die zwei Hebel, die Session 1 als
entscheidend identifiziert hat.

Neue Engpässe (ersetzen die alten):

1. **Verteilung = null.** Das Spiel braucht einen laufenden Node-Proxy mit
   API-Keys. Niemand außer LO kann es starten. Alle Features darüber sind für
   ein Publikum von einem Menschen gebaut.
2. **Knoten-Dichte:** 21 Knoten auf 5 Szenen (~4/Szene) — die Kampagne ist ein
   Gerüst, keine Welt. Der GM kann nur reagieren, was es zu reagieren gibt.
3. **Die Artefakte sterben im Vakuum:** Karriere-Akten existieren pro Run und
   verschwinden. Nichts verbindet Run 1 mit Run 7.
4. **Kein Grund, morgen wieder zu spielen.** Ein Run ist ein Ereignis, kein
   Ritual.

## Follow-up: Session 1 Priorities

| Item | Status |
|------|--------|
| Minigame-Fallback randomisieren | ✅ shipped (`minigame_shuffle.gd`) |
| Buff-Item + Roll-History | ✅ teilweise (4 Buff-Items; Roll-History im Overlay unverifiziert) |
| llm-router-blueprint absichern | ✅ ADR-0006, gevendort |
| Karriere-Akte | ✅ ADR-0005 |
| GM-Gedächtnis | ✅ ADR-0004 |
| Case-File-Panel | ✅ shipped |
| UGC-Editor, Stream-Modus, TTS, lokaler GM | offen — Bewertung unten aktualisiert |

## The Question

Session 1: „Aus Einzelrunden eine Kampagne machen." — erledigt.
Session 2: **Was macht aus einer Kampagne ein Universum, und aus einem
Spieler ein Stammpublikum?**

---

## Massive Opportunities

### 1. Die Registratur: Meta-Archiv über alle Runs
**What**: Jede Karriere-Akte wird persistent archiviert (lokal, `user://`).
Das Titelmenü bekommt eine „Registratur": alle verstorbenen Mandate als
Aktenordner, durchblätterbar, mit Zynismus-Kurven-Vergleich. Optional:
Anonym-Share (Akten-Text, kein Savegame).
**Why 10x**: Perma-Death war der Schmerz, die Akte war der Trost — das Archiv
ist die **Bedeutung**. Jeder Run wird Kanon; der Spieler baut eine
persönliche Geschichte aus gescheiterten Karrieren. Das ist exakt das
Rogue-like-Versprechen (Hades' Codex, slay-the-spire-Statistiken), satirisch
übersetzt: *„Sechs Mandate. Kein einziges unbeschädigt."*
**Unlocks**: Run-Vergleiche, Meta-Ziele („sterbe einmal an jedem
Szenentyp"), Langzeit-Retention, Share-Content ohne neues Feature.
**Effort**: Mittel (Speicherformat existiert mit `run_stats`; UI-Panel +
Titelmenü-Eintrag). Der teuerste Teil ist schon gebaut.
**Risk**: Niedrig. Lokales Archiv hat keinen Betrieb.
**Score**: 🔥

### 2. Daily Scandal: der Sitzungskalender
**What**: Täglich ein deterministisch geseedeter Skandal (Datum → Seed →
Szene, DC-Modifikatoren, Minispiel-Konfig, Ziel-Alignment). Jeder Spieler
bekommt denselben Tagesskandal; am Ende die Akte mit Tages-Ranking.
Fairness durch Determinismus: Seed erzeugt Content-Konfiguration aus dem
Content-JSON, das Würfelglück bleibt individuell.
**Why 10x**: Verwandelt „ich spiele mal wieder" in **tägliches Ritual**
(Wordle-Nachweis: Retention durch geteilte Tagesaufgabe schlägt jede
Feature-Liste). Satire profitiert zusätzlich: Der Tagesskandal kann aktuelle
Köpfe/Konstellationen spiegeln — der Content-Seed ist Redaktionsarbeit, kein
Code.
**Unlocks**: Täglicher Return-Grund, virale Vergleichbarkeit („Heute
geschreddert, 14 Zynismus-Punkte. Schaffst du weniger?"), Content-Pipeline
(Redaktion schreibt Seeds statt Szenen).
**Effort**: Hoch (Seed→Content-Resolver, DC-Balancing, Anti-Cheat ist
egal — Single Player).
**Risk**: Täglicher Content-Aufwand killt es; Skalierung über
Seed-Granularität (eine Woche pro Seed-Ausarbeitung).
**Score**: 👍 (nach Registratur; Daily ohne Archiv ist sinnlos)

### 3. Ship It: Verteilung ohne Dev-Umgebung
**What**: Zwei Varianten: (a) **Gehosteter GM-Proxy** — ein Endpoint mit
serverseitigen Keys, Session-Rate-Limit, Free-Tier-Kaskade wie heute; Client
fragt URL + optionales Spieler-Token ab. (b) **Eingebetteter Proxy** —
GM-Proxy als mitgeliefertes Binary im Godot-Export (Node single-executable),
Spieler bringt eigenen Key mit (`.env`-Setup-Assistent im Titelmenü).
**Why 10x**: Das ist kein Feature, es ist **die Tür**. Aktuell ist jede
Idee in dieser Datei für ein Publikum von einer Person gebaut. Erst mit
Verteilung existieren Nutzer, Feedback, Bugs, Community — alles, was
„Produkt" aus „Projekt" macht.
**Unlocks**: Itch/Steam-Release, UGC-Austausch, Streamer.
**Effort**: Mittel (a) bis hoch (b). Variante (a) ist der pragmatische Weg:
Der Proxy läuft schon, es fehlen Auth, Rate-Limiting und ein Build.
**Risk**: Kosten (pro Run ~2 API-Calls/Aktion; Rate-Limit nötig), Key-
Management, „der Proxy ist down"-Supportlast. Variante (b) scheitert
evtl. an Node-in-Export-UX — deshalb (a) zuerst.
**Score**: 🔥 (als Gate, nicht als Feature — blockiert UGC, Sharing,
Streaming allesamt)

### 4. UGC-Plattform mit GM-Playtest (Session-1-Carry-over, neu bewertet)
**What**: Unverändert: Spieler schreiben Szenen/Items als Content-JSON, der GM
playtestet beim Import (DC-Bewertung, Absurditäts-Check, Fallback-Dialoge).
**Warum jetzt eher als in Session 1:** Das Fundament ist gereifter —
stabilen Content-JSON (ADR-0002), Chronik als Qualitätsanker, Epitaph als
Bewertungskontext. **Aber:** Ohne Ship It (Nr. 3) hat UGC keine Spieler.
**Score**: 🤔 → 👍, **Reihenfolge strikt: erst Verteilung, dann UGC.**

### 5. Stream-Modus: der Pressepool (Session-1-Carry-over)
**What**: Zuschauer-Votes als Fraktionsdruck; Chat landet als *Fakten-Einträge*
in der Chronik (ADR-0004 macht das strukturell trivial — die Chronik ist ein
append-only Fakten-Log). Der GM kommentiert den Pool als Presse.
**Update**: Durch die Chronik deutlich billiger geworden; Injection-Trennung
(Chat = Fakten, nie Instruktion) bleibt das zentrale Design-Kriterium.
**Score**: 🤔 (nach Ship It; Streamer sind das Publikum, das diese Satire
am schnellsten trägt — aber es braucht Spieler außerhalb des Dev-Setups)

---

## Medium Opportunities

### 1. GM-Personas: wählbare System-Entitäten
**What**: Zwei-drei GM-Charaktere (Der korrekte Vorsitzende / Das
zynische Kanzleramts / Die unbestechliche Registratur), jeweils eigenes
System-Prompt, gleiches JSON-Protokoll. Auswahl im Titelmenü, Persistenz via
Chronik — die Persona „erinnert" sich an frühere Runs *als dieselbe Figur*.
**Why 10x**: Die LLM-Persona ist die Alleinstellung; ein wählbarer,
wiedererkennbarer GM macht sie von „cooler Technik" zu **Beziehung**.
Derselbe Mechanismus, der Hades' Götter trägt.
**Effort**: Mittel (Prompt-Varianten + Menü-Option; Protokoll unverändert).
**Score**: 👍

### 2. NPC-Stammkader mit chronikbasiertem Eigenleben
**What**: Wiederkehrende NPCs werden aus der Chronik gespeist: *„Sie
verschwinden seit drei Sitzungen alle Koffer, Herr Antragsteller. Der
stellvertretende Vorsitzende hat eine Excel-Tabelle angelegt."* Der Prompt
bekommt NPC-Aggregate (wer wurde belogen, wem wurde ein Posten versprochen).
**Why 10x**: Der Schritt von „der GM erinnert sich" zu **„die Welt erinnert
sich"** — Konsequenzen mit Gesicht statt Score-Veränderung.
**Effort**: Mittel (NPC-Extraktion aus Chronik-Einträgen, Prompt-Block).
**Risk**: Chronik-Fenster (10 Einträge) zu klein für lange Bögen → Fenster
größenabhängig anpassen.
**Score**: 👍

### 3. Timed Decisions: die Sitzungsuhr
**What**: Ausgewählte Knoten bekommen einen Countdown (Stoppuhr im
P&P-Overlay). Zögern erhöht die DC oder kostet Disziplin („Der Ausschuss
beobachtet Ihr Zögern."). Content-Feld `time_limit` im Szenen-JSON.
**Why 10x**: Neue mechanische Dimension, die den GM nicht berührt (DC-
Modifikation clientseitig) — Spannung ohne Prompt-Komplexität. Macht das
Absurde (Aktenordner essen) riskanter: Zeitdruck produziert schlechte Ideen,
schlechte Ideen produzieren gute Satire.
**Effort**: Mittel (UI + DiceRoller-Integration + Content-Feld).
**Score**: 👍

### 4. Content-Dichte: von Gerüst zu Welt
**Beleg**: 21 Knoten / 5 Szenen (~4 pro Szene), 5 Kombinationen bei 13
Items. LucasArts-Logik lebt von Kombinations-Dichte (Monkey Island: hunderte).
**What**: Zielbild 8–10 Knoten pro Szene, 15+ Kombinationen, darunter
bewusst **Sackgassen** (absurd, nicht tot — jede Kombi bekommt eine
GM-Reaktion, auch die sinnlosen; das macht Experimentieren sicher).
**Effort**: Mittel bis hoch (reine Redaktionsarbeit — das ist das ehrliche
Bild: Content ist jetzt der Flaschenhals, nicht Technik).
**Score**: 🔥 (ohne Dichte bleibt jede GM-Verbesserung unsichtbar)

### 5. Epitaph-Share-Card
**What**: Karriere-Akte als gerendertes Bild (Godot-Viewport → PNG),
amtliches Format mit Stempel, ein Tipp für Bluesky/Mastodon. Text-Template
liegt bereits mit dem Generator vor.
**Effort**: Niedrig bis mittel.
**Score**: 👍 (verstärkt Registratur; allein schwach, zusammen stark)

---

## Small Gems

### 1. „Letzte Akte" am Titelbildschirm
Die zuletzt generierte Karriere-Akte liegt beim Start als Papierstapel im
Menü. Erinnert an Perma-Death, ohne zu mahnen. Effort: niedrig. 🔥

### 2. Chronik-Rückblick im Spiel
„Was habe ich getan?"-Panel: Chronik-Fakten aus dem letzten Payload
mitanzeigen (Client speichert sie beim Empfang). Reduziert „der GM
halluziniert"-Misstrauen, indem Faktenlage sichtbar wird. Effort: niedrig. 👍

### 3. Der Koffer kommentiert das Menü
GM-One-Liner beim Pausieren, Speichern, Rage-Quit-Versuch („Ihr Mandat
ruht auf Dateien. Wohin wollen Sie?"). Persona-Streuung außerhalb des Loops.
Effort: niedrig (Texte + Fallback-DB-Einträge). 👍

### 4. Roll-History verifizieren
Session 1 forderte sie, Status ist unklar — falls nicht im Overlay: letzte 3
Würfe mit Bonus-Aufschlüsselung („14 +3 berufspolitisch = 17 vs DC 12").
Vertrauens-Quick-Win. Effort: niedrig. 🔥

---

## Recommended Priority

### Do Now (Quick Wins)
1. **Registratur (Meta-Archiv)** — teuerster Teil (Epitaph-Generation) steht;
   es fehlt nur Speichern + Durchblättern. Macht Perma-Death dauerhaft
   bedeutsam. Impact: Retention durch Kanon.
2. **Content-Dichte Knoten/Kombis** — Technik ist fertig, die Welt ist leer.
   Impact: Jede GM-Reaktion wird erst durch Anlass sichtbar.
3. **Roll-History prüfen/nachliefern + „Letzte Akte" im Titelmenü** — zwei
   Tage Arbeit, sofortiges Vertrauen und narrative Kontinuität außerhalb des
   Runs.

### Do Next (High Leverage)
1. **Ship It, Variante (a): gehosteter Proxy** — der Gate für alles Weitere.
   Ohne Verteilung bleibt UGC, Sharing und Streaming theoretisch.
2. **GM-Personas** — billig (Prompt × N), enorme Beziehungs-Tiefe.
3. **NPC-Stammkader** — „die Welt erinnert sich", Chronik-Hebel voll ausnutzen.
4. **Epitaph-Share-Card** — nach Registratur, davor hat niemand genug Akten.

### Explore (Strategic Bets)
1. **Daily Scandal** — Retention-Ritual, aber Content-Redaktion muss
   skalieren. Risk: Tages-Aufwand. Upside: Der Wordle-Effekt für Satire.
2. **UGC-Plattform** — erst nach Ship It sinnvoll; Chronik + Epitaph sind
   dann die Qualitäts-Infrastruktur dafür.
3. **Stream-Modus / Pressepool** — Chronik macht Chat-Integration billig;
   Injection-Trennung strikt: Chat ist Fakten-Log, nie Instruktion.

### Backlog (Good but not now)
1. **TTS für den Koffer** — schön, aber nach Persona-Textqualität priorisieren;
   eine schlechte deutsche TTS-Stimme schadet der Persona mehr als sie hilft.
2. **Lokaler Offline-GM (Kleinstmodell)** — Evaluierung nach
   Protokoll-Treue; SQLite-Fallback reicht bis dahin.
3. **Multiplayer-Koalition** — unverändert von Session 1: Das Spiel lebt an
   der Einzelperspektive gegen den Apparat.

---

## Questions

### Answered (seit Session 1)
- **Q**: Gedächtnis server- oder clientseitig? **A**: Serverseitig, Fakten-
  Chronik am Proxy, 10er-Fenster (ADR-0004).
- **Q**: Was passiert mit Perma-Death-Frust? **A**: Karriere-Akte als
  Artefakt, Template-Fallback offline (ADR-0005).
- **Q**: Ist der Proxy deploybar? **A**: Technisch ja (stateless, Keys
  serverseitig) — Auth/Rate-Limit fehlen noch.

### Blockers
- **Q**: Zielplattform (Itch? Steam? nur selbst + Freunde?) — entscheidet
  jetzt konkret über Ship-It-Variante (a) vs. (b) und ob UGC-Sharing
  priorität bekommt. (Unverändert aus Session 1 — wird jetzt zum echten
  Blocker für den obersten Strategie-Punkt.)
- **Q**: LLM-Kostenbudget pro Run/Monat? Skaliert mit Verteilung, Daily
  Scandal und Personas multiplikativ.
- **Q**: Roll-History im P&P-Overlay — existiert sie seit Session 1?
  (Verifikation vor Umsetzung, vermeidet Doppelbau.)

## Next Steps
- [ ] Registratur spezifizieren: Archiv-Format (lokal `user://`), Titelmenü-
  Panel, Akten-Vergleich (Zynismus-Kurven aus `run_stats`)
- [ ] Content-Sprint: Knoten 4→8/Szene, Kombinationen 5→15, Sackgassen mit
  GM-Reaktion (auch im Fallback-Content)
- [ ] Verifizieren: Roll-History im Overlay; falls fehlend, nachliefern
- [ ] Ship-It-Skizze: gehosteter Proxy — Auth-Modell, Session-Rate-Limit,
  Kostenabschätzung pro Run
- [ ] GM-Personas prototypen: 2 Prompt-Varianten, gleiche Suites laufen
  lassen (Protokoll-Treue prüfen)
