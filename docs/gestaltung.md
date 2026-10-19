# Gestaltungsleitlinie

**Stand:** 19.10.2026, nach Gespräch mit dem Nutzer. Vom Nutzer stammen Grundsatz, Richtung und Anspruch an die Assets; was als **Vorschlag** markiert ist, ist meine Übersetzung davon in Gestaltung und wartet auf sein Urteil.
**Maßstab:** Leitbild in `CLAUDE.md`, Gestaltungsregeln G-01 bis G-12 der Spezifikation 0.1, besonders G-05 (Welt indifferent), G-09 (Humor aus ernsthaft vollzogenen Abläufen) und G-10 (Deutung bleibt offen).

## 1. Grundsatz

Gestaltung ist Teil der Aussage, keine Verpackung. Alles Sichtbare transportiert Information, auch wenn niemand es analysiert, so wie Körpersprache wirkt, ohne dass man darüber nachdenkt. Genau deshalb muss sie stimmen. Wer das Spiel sieht, soll ahnen oder fühlen, warum es das gibt und warum es so ist, ohne dass es ihm erklärt wird.

Daraus folgt für die Umsetzung: **Anspielung statt Erklärung.** Nichts im Bild sagt „das Amt ist ein Moloch“. Das Bild verhält sich so, als wäre es selbstverständlich (G-05, G-09, G-10).

## 2. Richtung für das Amt

**Neobrutalismus mit Religionscharakter.**

Die gnostische Linie dahinter: Demiurg und Archonten, Moloch und andere Dämonen sind frühe Versuche, abstrakte Systeme und ihre Zwänge (Systemtheorie, Tragik der Allmende) als Gestalt zu fassen. Dieser Zusammenhang soll **an einigen Stellen** sichtbar anklingen, nicht durchgehend.

**Vorschlag, wie das aussieht:**

| Mittel | Neobrutalismus | Religionscharakter |
|---|---|---|
| Form | schwere, flache Blöcke, harte Kanten, dicke schwarze Konturen, harte Versatzschatten ohne Weichzeichnung | strenge Symmetrie, Mittelachse, Portale statt Türen, Stufen |
| Farbe | roher Beton, Papier, Tinte; eine einzige Signalfarbe | Signalfarbe nur für das Heilige: Siegel, Stempel, Aktenzeichen |
| Schrift | schwer, grotesk, groß, wenig Schnitte | Aktenzeichen und Titel wie Inschriften; Wiederholung wie Liturgie |
| Wiederkehrendes | Stempel, Formularfelder, Rastermaße | Siegel und Zeichen, die an Archonten-Sigel erinnern, ohne zu erklären, was sie sind |

**Wo die Anspielung auftaucht (Vorschlag, bewusst wenige Stellen):** Flur (die vier Portale und ein Zeichen über der Mitte), Titelblatt der Akte, die Blende beim Türwechsel, später Division 7B. Nicht im Alltag der Vorgänge selbst: dort bleibt das Amt ein Amt.

## 3. Assets

Anspruch des Nutzers: Figuren und Räume in der Qualität eines großen Spiels, keine Platzhalter. Die jetzigen DAME-Figuren genügen dem nicht und werden ersetzt.

- **Quellen, in dieser Reihenfolge:** (1) freie Grundlagen als Ausgangspunkt, (2) Eigenfertigung des Nutzers mit Blender, KI-Werkzeugen oder eigenen Scans, (3) gezielter Nachbau einer Idee im sauberen Verfahren („Clean Room“). **Keine 1:1-Kopie** fremder Werke.
- **Herkunftsnachweis ist Pflicht:** Zu jedem Asset gehören Quelle, Lizenz und, bei KI-Werkzeugen, die Nutzungsbedingungen des Werkzeugs. Ohne Nachweis kommt nichts ins Repo. Das gilt auch für bestehende Dateien; die vorhandenen sind geprüft (19.10.): selbst erzeugt oder CC0 bzw. freie Schriften mit Lizenztext.
- **Technische Grenzen, die jede Entscheidung mitträgt:**
  - Web-Build heute 50 MB, Ziel unter 70 MB (Notizen vom 12.10.). Hochwertige Modelle und Texturen kosten Platz; sie brauchen komprimierte Texturen, Detailstufen und gegebenenfalls Nachladen.
  - Renderer ist GL Compatibility (nötig für den Web-Export). Das begrenzt Schatten, Nachbearbeitung und Materialien.
  - Auf schwachen Geräten und im Browser zählt jedes Dreieck.
- **Arbeitsteilung:** Ich liefere Code, Themes, Shader, prozedurale Flächen, die Einbindung der Assets und die Prüfung (Größe, Lizenzliste, Ladezeit). Modelle, Scans und die Arbeit in Blender oder mit KI-Werkzeugen entstehen beim Nutzer, denn in dieser Sandbox gibt es dafür weder Blender noch Bildwerkzeuge im Projekt.

## 4. Reihenfolge

1. **Flur als erste Fläche.** Die Richtung an einem Bildschirm sehen, bevor mehr entsteht (Vorschlag als eigener PR, Urteil des Nutzers abwarten).
2. Gemeinsames Theme für alle App-eigenen Szenen (Flur, Hörsaal, Akte, Hinterzimmer-Rahmen). Lobby-Loop und DAME bleiben Quellen und behalten ihr Aussehen, bis dort entschieden ist, wie weit der Look reicht.
3. Figuren: erst nach Entscheidung über Quelle und Stil; sie sind der größte Posten.
4. Anspielungen (Siegel, Zeichen) an den wenigen gewählten Stellen.

## 5. Offen für den Nutzer

- Gefällt die Richtung am Flur-Vorschlag, oder ist sie zu laut, zu leise, zu sehr Web-Design?
- Wie weit soll der Look in DAME und Lobby-Loop hineinreichen, oder sind sie bewusst eigene Räume?
- Welche Stellen sollen die gnostische Anspielung tragen, außer den vorgeschlagenen?
