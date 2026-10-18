# Die Latte liegt am Boden
## Spezifikation der gemeinsamen Spielwelt

**Version:** 0.1 · **Datum:** 18. Oktober 2026  
**Status:** Ausgearbeiteter Entwurf für Konzept, Prototyp und spätere Umsetzung. Keine Behauptung über bereits implementierte Funktionen.  
**Arbeitstitel der Welt:** Das Amt  
**Umfang:** Welt, Erzählung, Spielregeln, Integration, erster spielbarer Vorgang, technische Verträge und Abnahme.

> Du willst etwas erledigen. Du veränderst etwas. Andere machen damit weiter. Gelegentlich erkennst du deine eigene Handschrift darin.

## 0. Leseschlüssel und Verbindlichkeit

Dieses Dokument verbindet die bereitgestellten Werke mit den im Gespräch entwickelten Absichten. Es ist als Arbeitsgrundlage für Menschen und implementierende KI gedacht. Die künstlerische Absicht steht vor der Menge der Funktionen.

Es unterscheidet drei Status:

- **Vorgabe:** vom Nutzer im Gespräch festgelegt oder ausdrücklich bestätigt. Bei Konflikten haben diese Vorgaben Vorrang vor älteren Konzepten.
- **Entwurfsentscheidung:** hier konkret festgelegte Arbeitsannahme, damit ein Prototyp gebaut werden kann. Sie ist revidierbar und keine nachträglich behauptete Nutzerentscheidung.
- **Prüfbedarf:** nur durch Repository-Prüfung, Umsetzung oder Spieltests klärbar. Zahlen in Zielkriterien sind gesetzte Entwicklungsziele, keine gemessenen Ergebnisse.

Die in diesem Dokument verwendeten Figuren, Fallnummern, Dialoge und Regeln des Bank-Vorgangs sind neue Entwurfsentscheidungen. Die bisherigen Werke bleiben Quellen mit eigener Stimme. Nomos gehört ausdrücklich nicht zum Umfang.

### Inhaltsübersicht

1. Produktabsicht und Erlebnisversprechen
2. Verbindliche Gestaltungsregeln
3. Welt, Figuren und Ton
4. Anschluss der eigenständigen Werke
5. Gemeinsame Systemregeln
6. Spielablauf und Zeit
7. Wissen, Spuren und Konsequenzen
8. Mechaniken der Spielformen
9. Erster spielbarer Vorgang: Die gesperrte Bank
10. Varianten und Zustandsübergänge des Vorgangs
11. Verständlichkeit und Vermittlung
12. Oberfläche, Bild und Ton
13. Fortschritt, Karriere und Scheitern
14. Inhaltsproduktion und Erweiterbarkeit
15. Technische Architektur
16. Datenmodell und Schnittstellen
17. Speichern, Wiederholen und Fehlerbehandlung
18. Rolle eines optionalen Sprachmodells
19. Umsetzung in überprüfbaren Etappen
20. Test- und Abnahmeplan
21. Risiken und Entscheidungsregister
22. Rückverfolgbarkeit der Anforderungen
23. Quellen und Grenzen der Bestandskenntnis
24. Übergabe an die Umsetzung

## 1. Produktabsicht und Erlebnisversprechen

### 1.1 Zweck

**Vorgabe:** Der primäre Zweck ist Immersion. Der Spieler ist Teil des Geschehens und kann sich zugleich als Beteiligten beobachten. Humor, Regeln und Geschichte dienen diesem Erleben. Das Spiel vermittelt seine Haltung durch Situationen und Folgen; es verlangt keine Zustimmung zu einer ausformulierten Theorie.

Die künstlerische Perspektive: Institutionen verarbeiten Kritik, Reformen und Widerstand in ihrer eigenen Logik. Auch gut gemeinte Versuche können den Betrieb erhalten, den sie verändern wollen. Diese Perspektive ist die Setzung der fiktionalen Welt, kein hier bewiesenes universelles Gesetz über reale Politik.

Der Spieler darf etwas verstehen, ohne dadurch außerhalb der Welt zu stehen. Eine Einsicht ist kein Schlüssel zu einem endgültigen Befreiungsende. Die Welt ist seinen Erkenntnissen gegenüber indifferent, kann aber auf seine Handlungen konkret reagieren.

### 1.2 Erlebnisversprechen

Der Spieler kann:

1. ein unmittelbar verständliches Anliegen verfolgen;
2. Menschen kennenlernen, deren Verhalten aus eigenen Interessen verständlich wird;
3. mit unterschiedlichen Mitteln echte Veränderungen erreichen;
4. später erkennen, wie andere seine Handlungen weiterverarbeiten;
5. darüber lachen, sich ärgern, weiterspielen oder etwas liegen lassen.

Ein gelungenes Erlebnis muss keine philosophische Erklärung hervorbringen. Die Aussage „Ich habe die Bank freibekommen, und jetzt machen sie aus meinem Antrag eine neue Prüfung“ reicht als Zeichen eines erkannten Zusammenhangs.

### 1.3 Produktform und Zielgruppe

**Entwurfsentscheidung:** Ein satirisches, szenenbasiertes Rollenspiel mit kurzen integrierten Denk-, Beobachtungs- und Kartenspielen. Es richtet sich zunächst an Menschen, die gern Situationen lesen, Entscheidungen ausprobieren und trockenen Humor mögen. Kenntnisse in Systemtheorie werden nicht vorausgesetzt.

Der erste Prototyp ist für eine einzelne Person spielbar. Geschätzte Dauer: 30–45 Minuten einschließlich freiwilliger DAME-Partie; ohne diese voraussichtlich 20–30 Minuten. Diese Schätzungen müssen getestet werden. Es gibt keine Echtzeitpflicht und keinen täglichen Anwesenheitszwang.

### 1.4 Ausgeschlossen aus dem ersten Umfang

Nomos; vollständige Simulation einer Stadt; neue Action- oder Klassenkampfsysteme; öffentliche Online-Ökonomie; Shop; kostenpflichtige Spielvorteile; automatisch generierte Hauptgeschichten; umfassende Division-7B-Kampagne; eine Wertung der philosophischen Reife des Spielers.

## 2. Verbindliche Gestaltungsregeln

| ID | Regel | Konsequenz für die Umsetzung |
|---|---|---|
| G-01 | Immersion ist der Zweck. | Jede Funktion braucht einen Beitrag zum Erleben, zur Handlungsfähigkeit oder zur Orientierung. |
| G-02 | Teilnahme und Beobachtung sind gleichzeitig möglich. | Der Spieler sieht Folgen eigener Eingriffe, bleibt aber eine Figur mit begrenztem Wissen. |
| G-03 | Handlungen wirken. | Mindestens zwei unterschiedliche Vorgehensweisen müssen unterschiedliche materielle oder soziale Ergebnisse erzeugen. |
| G-04 | Erfolge werden nicht automatisch entwertet. | Eine freigegebene Bank darf benutzbar bleiben, obwohl aus der Freigabe weitere Verwaltung entsteht. |
| G-05 | Die Welt ist indifferent. | Kein Erzähler gratuliert zur richtigen Weltanschauung; alltägliche Abläufe gehen weiter. |
| G-06 | Folgen müssen nachvollziehbar sein. | Bedeutende Rückwirkungen haben eine Ursache, einen verarbeitenden Akteur und eine erkennbare Spur. |
| G-07 | Werke behalten ihre Eigenständigkeit. | Es gibt keine erzwungene Einheitslehre und keine Pflicht, alle Texte gelesen zu haben. |
| G-08 | Nomos bleibt ausgeklammert. | Keine Schnittstelle, Platzhalterabteilung oder spätere Integrationszusage für Nomos. |
| G-09 | Humor entsteht aus ernsthaft vollzogenen Abläufen. | Figuren erklären die Pointe nicht und zwinkern dem Publikum nicht nach jedem Satz zu. |
| G-10 | Deutung bleibt offen. | Kein Moral-, Erkenntnis- oder Systemdurchschauungswert. |
| G-11 | Schwierigkeit entsteht nicht durch undurchsichtige Bedienung. | Ziele, verfügbare Handlungen und bekannte Kosten sind verständlich. |
| G-12 | Verbindungen entstehen durch fortgesetztes Geschehen. | Gemeinsame Figuren, Gegenstände, Dokumente und Folgen tragen die Einheit der Welt. |

### 2.1 Drei wichtige Grenzen

**Indifferenz und Folgen:** Die Welt muss sich nicht für den Spieler interessieren, um auf ihn zu reagieren. Eine Sachbearbeiterin kann seinen Antrag wichtig finden, weil sie ihre Vorgänge abschließen will.

**Verstrickung und Vorbestimmung:** Institutionelle Verarbeitung darf Veränderungen hervorbringen. Es gibt keinen unsichtbaren Regler, der jeden Ausgang in denselben Zustand zurücksetzt.

**Selbstreferenz und Beliebigkeit:** Ein Widerspruch darf Teil einer Akte sein. Die zugrunde liegenden Spielregeln müssen trotzdem reproduzierbar sein. „Das System ist absurd“ rechtfertigt keinen Regelbruch der Engine.

## 3. Welt, Figuren und Ton

### 3.1 Räumlicher Rahmen

**Entwurfsentscheidung:** Das Amt bildet das Zentrum eines kleinen, bewohnten Ausschnitts der Welt. Der Prototyp besteht aus sechs Orten:

| Ort | Alltag | Funktion im ersten Vorgang |
|---|---|---|
| Vorhalle | Warten, Nummern ziehen, kurze Begegnungen | Einstieg und Orientierung |
| Innenhof | Pause, Durchgang, Vogel, Bank | Sichtbarer Ausgangszustand und spätere Folgen |
| Hausdienst | Werkzeug, Reparaturzettel, Schlüssel | Materielle Informationen und Hausmeister |
| Registratur | Aktenbewegung und Bestandsführung | Frühere Entscheidungen und widersprüchliche Einträge |
| Ausschussraum | Sitzungen und Definitionsentscheidungen | Widerlegung und Fallentscheidung |
| Hinterzimmer | Feierabend, Getränke, Kartenspiel | DAME und informelle Beziehungen |

Die Orte werden mehrfach besucht. Neue Zusammenhänge ergeben sich aus verändertem Zustand und anderen Anwesenden. Neue Projekte erhalten nicht automatisch neue Flügel des Gebäudes.

### 3.2 Spielerrolle

Der Spieler ist für den ersten Vorgang ein vorläufig mit einer Prüfung beauftragter Antragsteller. Er wollte eine Angelegenheit klären und hat mit dem Einspruch eine befristete Zuständigkeit erhalten. Er bekommt Zugriff auf diesen Vorgang, nicht auf sämtliche privaten Informationen im Amt.

Diese Rolle erklärt die Dienstaufsicht als begrenzten Auftrag und wahrt die bestehende Lobby-Loop-Idee des Antragstellers. Der Aktenkoffer fungiert als Spielleiter beziehungsweise Begleiter: Er nennt bekannte Verfahrensmöglichkeiten, protokolliert und interpretiert innerhalb seiner Rolle. Er kennt keine außerhalb seines Zugriffs liegenden Tatsachen und verkündet keine endgültige Wahrheit.

### 3.3 Figuren des ersten Vorgangs

| Figur | Konkretes Anliegen | Eigenständigkeit | Verhalten unter Prüfung |
|---|---|---|---|
| Frau Kern, Besucherin | Im Hof auf ihren Termin warten und sitzen | Sie möchte nicht zum Symbol einer Reform werden. | Fragt nach einem Sitzplatz, auch wenn gerade eine Grundsatzdebatte läuft. |
| Herr Mertens, Hausmeister | Reparaturen abschließen und nichts zweimal erklären | Hilfsbereit, sofern Hilfe nicht automatisch zu unbegrenzter Zuständigkeit wird. | Zeigt Prüfzettel; sichert sich bei offizieller Befragung schriftlich ab. |
| Frau Seidel, Registratur | Widersprüchliche Einträge einem Verantwortlichen zuordnen | Kennt das Verfahren, hat trotzdem nicht alle Informationen. | Ordnet Originale um, wenn eine Aktenprüfung angekündigt wird. |
| Herr Voss, Ausschuss | Einen formal tragfähigen Beschluss erreichen | Kann einem guten Argument folgen; möchte keine neue offene Akte. | Präzisiert Definitionen und fordert belegbare Anträge. |

Namen sind vorläufig. Keine Figur ist dauerhafter Trottel, allwissender Zyniker oder Sprachrohr des Autors. Jede erhält mindestens eine alltägliche Äußerung ohne satirische Funktion. Beziehungen können sich ändern; ein gewonnener Kartentisch macht aus einer Person keinen willenlosen Helfer.

### 3.4 Sprache und Humor

Der Ton ist trocken und konkret. Offizielle Texte können verschachtelt sein; ihre operative Bedeutung muss über Handlung oder Kurzfassung zugänglich bleiben. Die meisten Sätze der Figuren sind brauchbare Alltagskommunikation. Pointen gewinnen durch den normalen Zusammenhang.

Geeignete Formen: überpräzise Zuständigkeit, höflicher Widerspruch, ein wörtlich genommenes Anliegen, eine vernünftige lokale Entscheidung mit absurdem Gesamtergebnis, Wiederkehr einer Formulierung in verändertem Kontext.

Ungeeignet: permanentes Augenzwinkern, zufälliger Nonsens ohne Folgewirkung, eine Beleidigung pro Dialogoption, ein Erzähler, der jede Szene als Systemkritik kommentiert. Kraftausdrücke dürfen zu einzelnen Stimmen gehören, bilden aber keinen universellen Stilfilter.

### 3.5 Der Spatz

Der Spatz ist ein wiederkehrendes, weitgehend eigenständiges Alltagsdetail. Er kann den Ort wechseln, picken oder fehlen. Er ist kein versteckter Erleuchtungsindikator und kein allwissender Kommentator. Eine optionale Beobachtungsnotiz kann einen kurzen Vorgang auslösen; nicht jeder Klick auf den Vogel produziert eine Pointe. Die Welt erlaubt ihm auch, schlicht da zu sein.

## 4. Anschluss der eigenständigen Werke

| Werk oder Projekt | Beitrag | Form der Einbindung | Grenze |
|---|---|---|---|
| Die Latte liegt am Boden | Fundamente, Repräsentation, institutionelle Fiktionen | Arbeitstitel, Weltmotive, konkrete Gegenstände und Vorgänge | Das vollständige ursprüngliche Buch liegt hier nicht als eigenständige Quelle vor. |
| Lobby-Loop | Alltag, Absichten, Szenen, Karriere | Trägt die übergreifende Interaktion und Fallentwicklung | Kein reines Menü zwischen Spielen. |
| Das gerupfte Huhn | Definitionen und Gegenbeispiele | Als Widerlegung bei einem konkreten Streitfall; frei spielbar im Hörsaal | Bestehende Logik nicht stillschweigend umschreiben. |
| DAME | Bluff, Gedächtnis, soziale Begegnung | Kartenspiel nach Dienstschluss mit wiederkehrenden Figuren | Kernregeln bleiben eigenständig; Gewinnen ist keine Voraussetzung für Hauptfortschritt. |
| Ethik des Vogelbeobachtens | Beobachtung, Eingriff, Selbstbezug, wechselnde Textformen | Dienstaufsicht; freiwillig auffindbare Fragmente und literarische Gegenstände | Poetische Aussagen werden nicht als naturwissenschaftliche Regeln behauptet. |
| Manifest der Zynischen Kunst | Kaltes Material, Galgenhumor, Anspruch des Unbeteiligten | Eine identifizierbare Stimme innerhalb der Welt | Keine verpflichtende Welterklärung. |
| Manifest des Ästhetisierten Koprolithismus | Affekt, sprachliche Veredelung, Verstrickung des Kritikers | Texte, öffentliche Stellungnahmen und spätere Verarbeitung von Kritik | Satirische Formel nicht als empirisches Modell implementieren. |
| Boden-Inspektion | Verwaltungsverfahren als Werk | Urkunde, Amtsauftritt, beiläufige institutionelle Praxis | Kein echter Kauf oder externer Kontakt für Spielfortschritt nötig. |
| Division 7B | Bürokratischer Umgang mit metaphysischen Ungewissheiten | Zunächst Aktenverweis; später eigenständiger Vorgang | Übernatürliches im ersten Prototyp nicht als allzuständige Erklärung benutzen. |
| Systemisches Design-Framework | Kleine kombinierbare Regeln, Erhaltung der Handlungsfähigkeit | Gemeinsamer Zustands- und Ereigniskern | Action-, Klassen- und Kampfkonzepte werden nicht pauschal übertragen. |

### 4.1 Regel für literarische Einbettung

Ein Werk kann im Spiel zitiert, gelesen, missverstanden oder kommentiert werden. Seine Existenz als Gegenstand der Welt ist eine Rahmung, keine Umschreibung des Originals. Ein Autor kann eine andere Haltung vertreten als eine Behörde oder ein zweiter Text. Zentrale Hinweise stehen auch außerhalb langer Literaturtexte zur Verfügung.

Neue Adaptionen werden getrennt vom Original abgelegt und mit ihrer Quelle bezeichnet. Texte sind weder Tutorialpflicht noch Sammelaufgabe zum Nachweis, dass der Spieler alles verstanden hat.

### 4.2 Prüfung einer neuen Verbindung

Eine Verbindung ist belastbar, wenn sie erklärt: Wer braucht hier etwas? Warum kommt dieses Werk oder diese Spielform ins Spiel? Was bleibt anschließend an diesem Ort, bei diesen Menschen oder in diesen Akten anders? Ein bloßer Verweis auf einen bekannten Titel erfüllt diese Prüfung nicht.

## 5. Gemeinsame Systemregeln

### 5.1 Kleinster Vorgang

Ein Vorgang benötigt ein Anliegen, einen betroffenen Gegenstand oder Sachverhalt, mindestens einen zuständigen Akteur, einen bekannten Zustand, einen Aktenstand und mögliche Handlungen. Realität, institutionelle Behauptung und Spielerwissen werden getrennt geführt.

Beispiel: Die Bank ist repariert. Die Bestandsakte nennt sie weiterhin ein Exponat. Der Spieler kennt zunächst nur das Absperrband. Diese drei Angaben sind gleichzeitig möglich und erzeugen Spielraum.

### 5.2 Verarbeitung einer Handlung

Jede verbindliche Handlung folgt demselben Ablauf:

1. **Absicht:** Was will der Spieler erreichen?
2. **Prüfung:** Welche bekannten Voraussetzungen, Zuständigkeiten und Kosten gelten?
3. **Ausführung:** Welche unmittelbare Veränderung erfolgt?
4. **Spur:** Was wird dokumentiert, gesehen, erzählt oder versprochen?
5. **Weiterverarbeitung:** Welcher Akteur erhält die Spur und was tut er entsprechend seiner Regeln damit?
6. **Begegnung:** Wo kann der Spieler die Folge später wahrnehmen?

Nicht jede Handlung erzeugt alle sechs Schritte sichtbar. Jede bedeutende Folge muss diese Kette jedoch intern besitzen. Ein Papier darf auch ungelesen im Archiv bleiben.

### 5.3 Zustände statt universeller Moralwerte

| Zustand | Beispiele | Sichtbarkeit |
|---|---|---|
| Materiell | Bank benutzbar, Tür offen, Stuhl im Hof | Direkt in der Szene |
| Institutionell | Zuständigkeit, gültige Definition, vorläufige Freigabe | Bescheid, Schild, Dialog |
| Sozial | Vertrauen, bekanntes Versprechen, geteilte Information | Reaktionen und erinnerte Begegnungen |
| Wissen | Beobachtet, belegt, behauptet, vermutet | Spielerakte mit Quellen |
| Aufmerksamkeit | Prüfung bekannt, Verhalten angepasst | Wahrnehmbare Anzeichen; keine allwissende Anzeige |
| Zeit | Verfügbare Diensthandlungen, Tagesphase | Eindeutig in der Oberfläche |

Interne Werte für Vertrauen oder Aufmerksamkeit sind Implementierungshilfen. Sie dürfen nicht die ganze Person ersetzen. Ein bekanntes Versprechen kann für eine Entscheidung wichtiger sein als ein hoher allgemeiner Beziehungswert.

### 5.4 Begrenzte Autonomie

Der Prototyp simuliert nur die beteiligten Orte und Fälle. Figuren folgen wenigen festen Absichten und reagieren auf tatsächlich erhaltene Informationen. Ereignisse werden durch Spielhandlungen und Phasenwechsel ausgelöst. Es gibt keinen fortlaufenden Hintergrundprozess während geschlossener App.

Die Begrenzung verhindert unnötigen Aufwand und bewahrt Nachvollziehbarkeit. Erweiterbarkeit entsteht aus wiederverwendbaren Regeln, nicht aus dem Anspruch, alles gleichzeitig zu simulieren.

## 6. Spielablauf und Zeit

Der Hauptablauf lautet: Szene betreten, Lage wahrnehmen, Absicht wählen, handeln, Reaktion erleben und bei Bedarf die Akte ansehen. Der Wechsel in ein Minispiel geschieht aus einer verständlichen Situation und kehrt an denselben Ort beziehungsweise Vorgang zurück.

### 6.1 Zeitmodell des Prototyps

**Entwurfsentscheidung:** Drei erzählte Phasen, ohne Echtzeitwartezeit:

- **Tag 1, Untersuchung:** acht Diensthandlungen. Lesen, bereits bekannte Akten vergleichen, Bedienhilfe und Navigation kosten keine Handlung. Neue Beobachtung, Anforderung, Befragung oder bewusstes Verstreichenlassen jeweils eine.
- **Abend:** eine freiwillige Begegnung im Hinterzimmer. DAME, Gespräch und direkter Übergang zum nächsten Tag sind Alternativen. Sie verbrauchen keine der acht Diensthandlungen.
- **Tag 2, Entscheidung und Nachgang:** Einreichung, gegebenenfalls Ausschuss, Rückkehr in den Hof. Ein abschließender Phasenwechsel zeigt die spätere Weiterverarbeitung. Kein reales Warten auf den nächsten Kalendertag.

Eine notwendige Aktenlieferung nach verbrauchter achter Handlung wird vor dem Phasenende noch verarbeitet. Schon vorhandene Unterlagen bleiben lesbar. Eine freiwillig früh beendete Untersuchung darf Informationslücken hinterlassen, blockiert aber den Abschluss nicht.

### 6.2 Würfel und Können

Lobby-Loop darf seine Würfelmechanik für unsichere soziale oder riskante Handlungen behalten. Nachweisbare Tatsachen und klar definierte Minispielregeln werden nicht nachträglich ausgewürfelt. Ein misslungener Wurf kann einen Zugang verteuern oder die Reaktion ändern; er löscht keine bereits erarbeiteten Belege.

Der Bank-Prototyp benötigt keine Zufallswürfe auf dem Hauptweg. Damit werden zunächst Kausalität und Verständlichkeit geprüft. Die Einbindung von Würfeln in spätere Varianten ist ein eigener Balanceschritt.

## 7. Wissen, Spuren und Konsequenzen

### 7.1 Spielerakte

Jeder Eintrag besitzt Inhalt, Quelle, Zeitpunkt und Status: eigene Beobachtung, Dokument, Aussage oder Vermutung. Der Spieler kann Einträge nebeneinanderlegen. Das Spiel ergänzt Quellenbezüge automatisch, entscheidet aber nicht mit einem großen Wahrheitsstempel über jede Aussage.

Im Bericht wählt der Spieler bis zu drei Feststellungen samt Belegen, eine Schlussfolgerung und mindestens eine vorhandene offene Frage oder „keine weiteren offenen Punkte bekannt“. Vermutungen dürfen eingereicht werden, bleiben als solche gekennzeichnet. Es gibt keine Pflicht zur perfekten Vollständigkeit.

### 7.2 Sichtbare Kausalität

Jede wesentliche Rückwirkung hat mindestens einen klaren Wiedererkennungspunkt: Fallnummer, markante Formulierung, Unterschrift, Gegenstand oder Figur. Der erste Vorgang hat zwei solcher Punkte, damit eine übersehene Textzeile nicht die gesamte Verbindung verbirgt.

Später können Verbindungen subtiler werden. Die Engine speichert die Ereigniskette immer. Eine freiwillige Ansicht „Verlauf dieses Vorgangs“ zeigt bereits bekannte Stationen, keine unsichtbaren Absichten.

### 7.3 Reaktionsregeln der Institution

Neue Bestimmungen entstehen nur bei einem konkreten Anlass: Eine zuständige Figur erhält einen Beschluss oder ein dokumentiertes Problem und hat einen Grund, es weiterzuverarbeiten. Die Prototypregel „Voss verallgemeinert eine offiziell beschlossene Zugänglichkeitsbegründung“ löst beispielsweise genau einmal aus. Ein informell bereitgestellter Stuhl löst sie nicht aus.

Wiederholte identische Aktionen dürfen keine unendliche Ereignisvermehrung erzeugen. Dokumente und Folgeereignisse tragen eindeutige Kennungen; doppelte Verarbeitung wird verhindert.

### 7.4 Rückwirkungen haben unterschiedliche Größen

Nicht jede Spur wird zur Verordnung. Manche erzeugt nur einen Satz im Flur, eine veränderte Begrüßung, ein neues Schild oder eine kleine Nachfrage. Große Folgen sind selten genug, dass der Alltag glaubwürdig bleibt. Verpflichtende Quoten für negative Folgen gibt es nicht.

## 8. Mechaniken der Spielformen

### 8.1 Lobby-Loop: Träger des Alltags

Lobby-Loop verwaltet Szenen, Absichten, bekannte Zugänge, Inventar und die Karriere. Neue Interaktionen benötigen einen sinnvollen Anlass. Der Aktenkoffer kann „Antrag einreichen“, „Akte vergleichen“ oder „Widerspruch formulieren“ anbieten, ohne die Folge zu verraten.

Anforderungen: Rückkehr nach Minispielen an den korrekten Vorgang; Erinnerung an relevante Begegnungen; keine widersprüchlichen Dialoge nach einer Freigabe; kein Hauptfortschritt ausschließlich durch einen glücklichen Wurf.

### 8.2 Widerlegung: Das gerupfte Huhn

Bestehender Kern: Eine öffentlich sichtbare Definition wird mit Fällen konfrontiert. Gegenbeispiele machen Nachbesserungen nötig. Der Gegner nutzt eine vorhersagbare Reihenfolge von Merkmalen, sein Prisma. Ausnahmen belasten die Lehre; bei Erreichen der Tragfähigkeit bricht sie zusammen. In der vorhandenen Fassung wiegen weggefallene Bestimmungen weiter. Die v2-Beweisaufnahme kann bestätigende Karten ohne Wurfverbrauch nutzen, wenn sie eine freie Nachbesserung blockieren; der Herzschlag läuft nach den vorhandenen Regeln weiter.

**Integrationsregel:** Das Ergebnis entscheidet eine konkrete Definitionsfrage. Es gibt keine automatische globale Zuständigkeit, Freundschaft oder physische Reparatur als Siegesprämie. Eine gewonnene Widerlegung kann die Einstufung der Bank aufheben; für ihre Nutzung bleiben bereits bekannte materielle Voraussetzungen relevant.

Die Darstellung eines einstürzenden Hörsaals wird für eingebettete Fälle als inszenierte Darstellung der Aktenlast gerahmt: etwa als Saalmodell auf dem Ausschusstisch. Der reale Ausschussraum wird dadurch nicht bei jeder Partie zerstört. Die eigenständige Huhn-Fassung darf ihre ursprüngliche Darstellung behalten. Diese Rahmung ist eine neue Entwurfsentscheidung und visuell zu testen.

Pro Fall wird ein kleiner Datensatz mit Mitgliedschaft, Merkmalen und Begründungen autorisiert. Für die fiktive Bankdebatte bedeutet „gehört dazu“ die im Vorgang festgelegte Referenzklasse, keine universelle Wahrheit über Kunst. Ein gewonnenes Definitionsspiel beweist nicht die Weltanschauung des Autors.

Die Portierung muss das reale Verhalten der vorhandenen JS-Engine abbilden. Ältere Designskizzen weichen in Details vom Code ab. Der Quellcode und reproduzierbare Vergleichspartien sind maßgeblich für technische Parität.

### 8.3 DAME: Das Hinterzimmer

Die bestehenden Kartenregeln werden übernommen, sobald die konkrete aktive Fassung geprüft ist. Dieses Dokument erfindet keine Ersatzregeln. Figuren bleiben während und nach der Partie dieselben Personen wie tagsüber.

Im Prototyp ist eine lokale Partie gegen Computergegner vorgesehen. Ein vollständig beendetes Spiel kann unabhängig vom Gewinn ein Gespräch öffnen. Ein Sieg kann genau eine begrenzte Gefälligkeit bewirken, sofern die Figur sie tatsächlich leisten kann. Ein verlorenes Spiel sperrt keine wesentliche Information.

Beispiel: Mertens bietet dem Gewinner an, am Folgetag einen Klappstuhl bereitzustellen. Ohne Sieg lässt sich derselbe praktische Effekt über eine zusätzliche Diensthandlung am Tag 1 erbitten. DAME spart gegebenenfalls Aufwand und schafft eine besondere Begegnung; es ist kein Zugangsschlüssel zur Geschichte.

Gefälligkeiten bleiben zweckgebunden, nicht übertragbar und nicht kaufbar. Sie verfallen nach ihrer Einlösung. Wiederholte Partien am selben Vorgang erzeugen keine unbegrenzten Vorteile. Online-Partien bleiben später vom verbindlichen Karrierefortschritt getrennt.

### 8.4 Dienstaufsicht: Beobachtung verändert die Lage

Jede Untersuchungsaktion liefert Informationen und kann Aufmerksamkeit erhöhen. Für den Prototyp ist die Aufmerksamkeit je Stelle intern auf 0 bis 3 begrenzt:

| Stufe | Zustand | Erkennbare Anzeichen |
|---|---|---|
| 0 | Normalbetrieb | Unvorbereitete Abläufe und gewöhnliche Gespräche |
| 1 | Prüfung bemerkt | Nachfrage nach Name oder Auftrag |
| 2 | Offizielle Vorbereitung | Vorgelegte Ordner, eingeübte Formulierungen, angekündigte Zuständigkeit |
| 3 | Abgestimmte Darstellung | Gleichlautende Antworten und Verweise auf einen gemeinsamen Vermerk |

Diese Stufen sind keine Schuldskala. In allen Varianten kann ordentliche Aktenvorbereitung stattfinden.

| Aktion | Zeit | Regel | Informationswert |
|---|---:|---|---|
| Neu beobachten | 1 | Erstes Mal am Ort: keine Erhöhung. Weitere unmittelbare Beobachtung: +1. | Aktueller Ablauf; vorherige Vorbereitung bleibt sichtbar. |
| Akte anfordern | 1 | +2 bei der empfangenden Stelle, maximal 3. | Datierte Unterlagen; Auslieferung spätestens nach der nächsten Diensthandlung. |
| Befragen | 1 | +1; ab Stufe 2 wird eine zugehörige Stelle nach der Handlung informiert. | Aussage mit Sprecher und Zeitpunkt. |
| Anderen Ort prüfen | 1 für dortige Aktion | Nach zwei Handlungen ohne Kontakt sinkt die Aufmerksamkeit der ersten Stelle um 1. | Vergleich; ein einmal erhaltener Hinweis wird dadurch nicht vergessen. |
| Zeit verstreichen lassen | 1 | Gleicher Aufmerksamkeitsabbau; fällige Abläufe werden verarbeitet. | Gelegenheit, eine angekündigte Bewegung zu sehen. |

Regelreihenfolge: sichtbare Aktion ausführen, unmittelbare Beobachtung erfassen, Aufmerksamkeit und Benachrichtigungen anwenden, fällige Lieferungen/Bewegungen verarbeiten, Uhr fortschreiben. Ereignisse, die während dieser Verarbeitung am beobachteten Ort stattfinden, erzeugen zusätzlich einen zeitlich zugeordneten Beobachtungseintrag. Somit sieht die erste unauffällige Beobachtung nicht rückwirkend einen schon alarmierten Zustand. Eine für die nächste Handlung geplante Bewegung wird erst nach dieser nächsten Handlung verarbeitet, nicht noch im selben Zug ihrer Ankündigung.

Untersuchungsberichte werden anhand ihrer Belege verarbeitet. Eine unbewiesene Behauptung kann eine weitere Prüfung auslösen; sie erzeugt keine allwissende Strafe. Intern prüft das Testsystem die Richtigkeit und kausale Zuordnung. Im Spiel gibt es dafür keine Erkenntnispunkte.

### 8.5 Zusammenspiel statt Pflichtparcours

Ein Vorgang darf nur eine Spielform benötigen. Die Bank verbindet mehrere, um ihre Übergänge zu prüfen; nicht jede spätere Geschichte muss denselben Ablauf wiederholen. Wenn eine Einbindung nur durch einen künstlichen Vorwand funktioniert, wird sie aus diesem Vorgang entfernt.

## 9. Erster spielbarer Vorgang: Die gesperrte Bank

### 9.1 Zweck und Umfang

**Fall-ID:** `BANK-01`  
**Spielerziel:** Für Frau Kern eine benutzbare Sitzgelegenheit im Innenhof ermöglichen.  
**Institutioneller Auftrag:** Den Grund der Banksperrung und die zuständige Stelle feststellen.  
**Gestaltungsziel:** Eigene Eingriffe und ihre Weiterverarbeitung erkennbar machen, ohne den erreichten Nutzen zu leugnen.

Der Vorgang besitzt ein erreichbares Ende bei jeder legalen Folge von Handlungen. Der Spieler kann ihn unvollständig abschließen. Ein optionaler späterer Rückbesuch zeigt, was weitergelaufen ist. Als wiederholbarer Test enthält die Entwicklungsversion feste Varianten; die erste öffentliche Demonstration verwendet einen festgelegten Ausgangszustand.

### 9.2 Ausgangslage und intern festgelegte Tatsachen

Die Bank wurde vor Monaten wegen einer beschädigten Leiste gesperrt. Um ihre Reparatur finanzieren zu können, wurde sie als Teil eines Kunstprojekts geführt. Die Leiste ist inzwischen repariert und vom Hausdienst freigegeben. Im Inventar gilt sie noch als Exponat. Das Absperrband blieb deshalb hängen.

Es liegt im kanonischen Ausgangsfall keine heimliche Sabotage vor. Das Hindernis entsteht aus mehreren nachvollziehbaren Bearbeitungsschritten und einem nicht abgeglichenen Bestand. Der Spieler erfährt diese Tatsachen nicht automatisch.

| Schlüssel | Startwert | Bedeutung |
|---|---|---|
| `bench.physically_usable` | `true` | Die Bank ist im Fall tatsächlich repariert. |
| `bench.access` | `blocked` | Nutzung ist noch nicht freigegeben. |
| `bench.inventory_class` | `exhibit` | Aktueller offizieller Bestandseintrag. |
| `bench.intended_use` | `public_seating` | Zweck laut älterem Auftrag. |
| `chair.available` | `false` | Keine Ersatzsitzgelegenheit im Hof. |
| `case.hours_remaining` | `8` | Verfügbare Untersuchungshandlungen. |
| `case.report_submitted` | `false` | Einmalige Einreichung noch offen. |
| `case.followup_rule` | `none` | Es existiert noch keine neue Zugänglichkeitsprüfung. |

Die Welt enthält keine versteckte Bedingung, nach der die Bank nach Erfolg wieder kaputtgehen muss. Eine spätere Variante mit realem Reparaturbedarf wäre ein anderer, ausdrücklich gekennzeichneter Testfall.

### 9.3 Einstieg ohne Vortrag

Der Spieler kommt durch die Vorhalle in den Hof. Frau Kern steht neben der gesperrten Bank. Auf Nachfrage sagt sie sinngemäß: „Ich muss noch warten. Stehen habe ich schon.“ Mertens kann das Band nicht ohne Vorgangsabschluss entfernen. Ein Klick auf das Schild zeigt eine Fallnummer und den Verweis auf die Registratur.

Die Handlung „Sperrung klären“ eröffnet die Prüfung. Der Aktenkoffer vermerkt: „Antrag auf Prüfung angenommen. Mit der Prüfung beauftragt: Antragsteller.“ Die Oberfläche erklärt anschließend die acht Diensthandlungen in einem Satz. Die Szene führt über das konkrete Anliegen in die Regeln.

Der Spieler kann sich sofort anderweitig um einen Stuhl bemühen. Die Untersuchung ist keine moralische Pflicht.

### 9.4 Hinweise und Bezugsquellen

| ID | Hinweis | Erwerb | Was er belegt | Was er nicht belegt |
|---|---|---|---|---|
| B-01 | Reparaturzettel mit Datum und Freigabe | Mertens befragen oder Hausdienstakte anfordern | Technische Freigabe der Bank | Inventareinstufung aufgehoben |
| B-02 | Inventareintrag „Exponat“ | Registraturakte anfordern | Aktuelle offizielle Klassifikation | Dass die Bank nicht zum Sitzen gedacht ist |
| B-03 | Ursprünglicher Auftrag „Sitzbank für Wartende“ | Unterlagen vergleichen, nachdem B-02 geliefert wurde | Vorgesehene Nutzung | Heute erteilte Benutzungserlaubnis |
| B-04 | Begründung für die Kunstzuordnung | Mertens im Hinterzimmer ansprechen oder am Tag befragen | Seine Erklärung der Finanzierung | Allein schon ein rechtswirksamer Beschluss |
| B-05 | Anweisung zur Aufbewahrung von Prüfungsoriginalen | Seidel nach der Aktenbewegung befragen oder ihr Verfahrensblatt lesen | Warum Originale nach Prüfungsankündigung umgelagert werden | Dass keinerlei andere Aktenprobleme existieren |
| B-06 | Beobachtete Aktenbewegung mit Uhrzeit | Registratur nach offizieller Anforderung beobachten | Dass Ordner nach Bekanntwerden der Prüfung verlagert wurden | Absicht der Verschleierung |
| B-07 | Neue Bestimmung mit eigener Fallnummer | Nachgang bei formeller Freigabe | Dass der eigene Beschluss weiterverarbeitet wurde | Allgemeines Scheitern jedes Reformversuchs |

B-03 wird durch das Vergleichen bereits gelieferter Unterlagen sichtbar und kostet keine zusätzliche Handlung. Die Zuordnung des Ursprungsauftrags ist eindeutig durch Inventarnummer möglich. Die Hinweise hängen nicht von einem einzigen leicht übersehbaren Pixel ab.

### 9.5 Reaktion auf die Untersuchung

Sobald die Registratur von einer offiziellen Aktenanforderung erfährt, erhält sie das Ereignis `audit_announced`. Am Ende der nächsten Diensthandlung werden die Originale in den abschließbaren Prüfschrank verlegt. Wer während dieser Handlung die Registratur beobachtet, erhält B-06. Wer anderswo ist, erfährt die Bewegung erst über eine spätere Aussage und erhält keine rückwirkende eigene Augenzeugenbeobachtung. Dieser Ablauf ist durch die Anweisung B-05 festgelegt. Er findet auch statt, wenn Seidel kooperativ ist.

Der Spieler kann diese Bewegung als Verdacht deuten. Ein Vergleich von Zeitpunkt und Anweisung zeigt den eigenen Anteil. Wer die Anforderung unterlässt, sieht diese konkrete Bewegung nicht. Die Szene wird nicht unabhängig von der Handlung künstlich abgespielt.

Im Nachgang kann Seidel knapp sagen: „Die Originale haben wir wegen Ihrer Prüfung umgelagert.“ Das bietet eine zweite Gelegenheit, den Zusammenhang zu erkennen, ohne eine philosophische Erklärung einzuschieben.

### 9.6 Abend und DAME

Mertens sitzt im Hinterzimmer. Drei gleichwertig auswählbare Zugänge stehen offen: mitspielen, nur sprechen oder den Abend überspringen. Wer mitspielt, kann nach der Partie dieselbe Frage zur Bank stellen wie beim direkten Gespräch. Das Spiel kennt den bereits erreichten Wissensstand und wiederholt B-04 nicht als angeblich neue Entdeckung.

Eine gewonnene erste Partie kann eine einmalige Hilfe mit dem Ersatzstuhl erzeugen. Ohne Kartengewinn ist diese Hilfe durch die dafür vorgesehene Tageshandlung erreichbar. Wer bereits eine Hilfe zugesagt bekam, erhält keinen zweiten Vorteil. Alle für die formelle Freigabe erforderlichen Dokumente sind ohne DAME zugänglich.

### 9.7 Ausschuss und Widerlegung

Der Spieler kann eine formelle Freigabe beantragen, wenn B-01 und B-02 vorliegen. B-03 eröffnet die begründete Anfechtung der Einstufung. Das Bedienfeld nennt die vorhandenen beziehungsweise fehlenden Belege ausdrücklich.

Im Ausschuss vertritt Voss eine zu enge Arbeitsdefinition von öffentlicher Sitzgelegenheit. Der Fall erhält eine eigene Lehre für die Huhn-Engine. Ausgangspunkt der Debatte ist die Spannung zwischen der älteren Zweckbestimmung und der späteren Inventarisierung.

**Arbeitsentwurf der Startlehre:** „Öffentliche Sitzgelegenheit ist ein bewegliches Möbel mit Rückenlehne, das nicht als Kunst inventarisiert ist.“ Die Referenzfälle richten sich nach dem im Fall dokumentierten Nutzungsauftrag. Das Spiel benennt diese Referenz, damit ein Sieg nicht von einer unausgesprochenen Definition im Kopf des Autors abhängt.

Beispiele für den später vollständig auszuarbeitenden Kartenpool:

| Fall | Relevantes Merkmal | Rolle im Streit |
|---|---|---|
| Fest verschraubte Wartebank | Nicht beweglich, zum Sitzen bereitgestellt | Gegenbeispiel zur Beweglichkeitsbedingung |
| Offizieller Wartehocker | Keine Lehne, zum Sitzen bereitgestellt | Gegenbeispiel zur Lehnenbedingung |
| BANK-01 | Als Kunst geführt und zum Sitzen vorgesehen | Gegenbeispiel zum Kunst-Ausschluss |
| Normaler Besucherstuhl | Beweglich, Lehne, keine Kunst | Bestätigter Referenzfall |
| Stuhl im Miniaturmodell | Möbelabbild, nicht für Personen bereitgestellt | Möglicher zu weiter Fall; Größe muss als Merkmal vorliegen |
| Ausstellungsstuhl mit Berührungsverbot | Beweglich und Lehne, reine Ausstellung | Schärft die Unterscheidung von Form und Nutzung |
| Wartebank als Sitzskulptur | Kunst und ausdrücklich benutzbar | Paarbildung für die Kunstbedingung |
| Transportkiste | Darauf sitzen möglich, nicht dafür bereitgestellt | Grenzfall zwischen Möglichkeit und Nutzungsauftrag |

Diese Tabelle ist ein Autorenansatz, kein bereits validierter Datensatz. Vor Umsetzung der Partie müssen 15–20 eindeutige Karten, Prisma, Startreferenzen, Tragfähigkeit und Wurfzahl als getestetes Inhaltspaket festgelegt werden. Die acht Beispiele allein gelten nicht als abnahmefähige Lehre.

Gewinnt der Spieler die Widerlegung, ist die enge Definition im konkreten Vorgang aufgehoben. Bei belegter technischer Freigabe wird die Bank regulär zugänglich. Verliert er, kann er mit demselben Reparaturbeleg eine befristete Ausnahme erhalten. Der Verlust wird nicht als intellektuelle Blamage kommentiert.

### 9.8 Rückkehr in den Hof

Der Spieler sieht das Ergebnis zuerst materiell: Frau Kern sitzt auf der Bank, auf einem Klappstuhl oder weiterhin nicht. Sie reagiert auf den praktischen Zustand. Die Welt wartet nicht auf einen perfekten Abschlussbericht.

Erst nach diesem Moment zeigt der Nachgang die institutionelle Weiterverarbeitung. Bei formeller Freigabe übernimmt Voss die Formulierung „Sitzgelegenheiten müssen zugänglich sein“ aus dem Antrag in eine allgemeine Prüfanforderung. Der Wortlaut wird bei Auswahl des Antrags sichtbar festgelegt und in der Akte gespeichert.

Ein späteres Schild lautet etwa: „Zur Sicherstellung der Zugänglichkeit sind neue Sitzgelegenheiten vor Aufstellung zur Zugänglichkeitsprüfung anzumelden.“ Darunter steht `BANK-01`. Die bereits freigegebene Bank bleibt nutzbar; am Nebeneingang wartet jemand mit einem neuen Stuhl. So koexistieren der konkrete Erfolg und die Ausweitung des Verfahrens.

Ein Mitarbeiter bedankt sich beim Spieler für den Hinweis. Der Aktenkoffer protokolliert den Beschluss ohne Deutung. Der Spieler kann weggehen, den Folgefall ansehen oder im Hof bleiben.

## 10. Varianten und Zustandsübergänge des Vorgangs

### 10.1 Verbindliche Übergangstabelle für den Prototyp

| Übergang | Voraussetzung | Unmittelbares Ergebnis | Spätere Verarbeitung |
|---|---|---|---|
| T-01 Prüfung eröffnen | Fall nicht eröffnet | Acht Diensthandlungen, Aktenzugriff auf BANK-01 | Keine automatische Verordnung |
| T-02 Reparatur belegen | B-01 erworben | Technische Freigabe im Spielerwissen | Noch keine Freigabe im Inventar |
| T-03 Einstufung klären | B-02 und B-03 vorliegend | Widerspruch zwischen Zweck und Bestand benennbar | Formeller Definitionsweg verfügbar |
| T-04 Regulär freigeben | B-01, B-02, B-03; Widerlegung gewonnen; Antrag bestätigt | Bank zugänglich, Bestand als öffentliche Sitzgelegenheit berichtigt | Einmalige allgemeine Prüfanforderung durch Voss |
| T-05 Ausnahme freigeben | B-01, B-02; Ausnahme gewählt oder Widerlegung verloren; Antrag bestätigt | Bank für die laufende Wartezeit zugänglich, Kunststatus bleibt | Erinnerung zur Verlängerung, keine allgemeine Prüfstelle |
| T-06 Ersatzstuhl organisieren | Hilfe am Tag erbeten oder erste DAME-Gefälligkeit vorhanden | Stuhl im Hof, Bank unverändert | Rückgabezettel und begrenzte Beziehungsspur |
| T-07 Ohne Lösung schließen | Jederzeit vor verbindlicher Einreichung möglich | Keine Freigabe; bekannter Stand wird abgelegt | Vorgang bleibt in der Zuständigkeit des Amts |
| T-08 Unbelegten Verdacht einreichen | B-06 vorhanden, Schlussfolgerung „Verschleierung“ ohne B-05 | Zusätzliche Nachfrage der Registratur | Gelegenheit zur Korrektur; kein automatischer Schuldspruch |

T-06 kann mit T-04 oder T-05 kombiniert werden. In diesem Fall wird der Stuhl nach Freigabe zurückgestellt; die frühere Hilfe bleibt erinnert. T-04 und T-05 sind für denselben Abschluss exklusiv. T-08 ist eine Berichtskomponente, kein Ersatz für eine materielle Lösung.

### 10.2 Abbruch und fehlende Informationen

Ohne B-01 kann keine administrative Bankfreigabe erfolgen. Der Spieler kann einen Ersatzstuhl nutzen oder einen offenen Bericht abgeben. Ohne B-03 kann er die Ausnahme beantragen, aber den Definitionsweg nicht mit unlesbaren Voraussetzungen starten.

Bei Abbruch der Widerlegung wird die Szene vor der Partie wiederhergestellt; noch kein Sieg oder Verlust wird verbucht. Der Spieler kann eine Ausnahme beantragen oder den Vorgang offenlassen. Ein abgeschlossener Ausgang wird erst nach Bestätigung des Antrags verbindlich. Wiederholtes Laden darf nicht mehrere Gefälligkeiten oder Folgeerlasse erzeugen.

### 10.3 Drei vollständige Beispielpfade

**Pfad A – formeller Erfolg:** Im Hof beobachten (1); Mertens befragen und B-01 erhalten (2); Registraturakte anfordern (3); als nächste Handlung die Registratur beobachten (4), wodurch die angekündigte Aktenbewegung sichtbar und B-06 erworben wird. Zugleich wird die angeforderte Akte geliefert. B-02/B-03 ohne weitere Zeitkosten lesen und vergleichen. Seidel befragen und B-05 erhalten (5). Untersuchung nach fünf Handlungen abschließen. Abend frei wählen. Widerlegung gewinnen und formellen Antrag bestätigen. Frau Kern sitzt auf der Bank. Im Nachgang erscheint B-07 mit dem eigenen Satz und der Fallnummer.

**Pfad B – praktische Hilfe:** Mertens nach einem Stuhl fragen und eine Diensthandlung einsetzen. Den Stuhl in den Hof bringen lassen, Frau Kern kann sitzen. Der Spieler schließt den Vorgang als praktisch entlastet, formal offen. Die Bank bleibt gesperrt. Später liegt ein Rückgabezettel vor; es entsteht keine neue Zugänglichkeitsregel.

**Pfad C – begrenzte Entscheidung:** Reparaturbeleg und Bestandsakte beschaffen. Eine Ausnahme beantragen, ohne Widerlegung zu spielen oder nachdem sie verloren wurde. Frau Kern sitzt auf der Bank. Der Eintrag „Exponat“ bleibt bestehen. Beim späteren Rückbesuch ist die Ausnahme als überprüfungsbedürftig vermerkt; die neue allgemeine Prüfanforderung aus Pfad A existiert nicht.

Alle drei Pfade erfüllen unterschiedliche Ziele und verändern erkennbare Zustände. Keiner wird als einzig philosophisch richtiger Weg markiert.

### 10.4 Kleine Variationen nach dem ersten Test

Erst nach funktionierendem Grundfall dürfen Rollenwissen, Reihenfolge der Aktenlieferung oder der Ursprung einer Zuständigkeit variieren. Der ursprüngliche Reparaturzustand, Quellen und Folgebedingungen müssen dann konsistent mitvariiert werden. Zufällig neue Namen bei identischer Entscheidung sind keine ausreichende Wiederspielbarkeit.

## 11. Verständlichkeit und Vermittlung

### 11.1 Drei Ebenen der Lesbarkeit

| Ebene | Frage des Spielers | Gestalterische Antwort |
|---|---|---|
| Handlung | Was kann ich jetzt tun? | Klare Verben, bekannte Voraussetzungen, sichtbare Zeitkosten |
| Folge | Was hat sich durch mich verändert? | Veränderter Ort, wiederkehrender Satz, bekannte Figur, Fallnummer |
| Deutung | Was sagt das über diese Welt? | Raum für eigene Schlüsse; keine aufgelöste Musterantwort |

Die erste und zweite Ebene müssen verlässlich verständlich sein. Die dritte darf unterschiedlich tief aufgenommen werden. Bedienungsfrust ist kein Ersatz für institutionelle Absurdität.

### 11.2 Einführung durch Handeln

Der Einstieg zeigt ein konkretes Hindernis, eine Person und zwei mögliche Handlungen. Weitere Regeln werden erst bei Bedarf eingeführt. Die Huhn-Partie hat einen ersten klaren Gegenfall. DAME verweist auf seine eigene Hilfe. Die Dienstaufsicht zeigt nach der ersten Anforderung eine wahrnehmbare Reaktion.

Nach einer bedeutenden Folge bleibt die Szene bedienbar, aber startet nicht sofort automatisch den nächsten Dialog. Der Spieler erhält Zeit, den Zustand zu betrachten. Überspringen und schnelleres Lesen bleiben möglich.

### 11.3 Hilfe, ohne die Pointe zu erklären

Eine optionale Aktenhilfe beantwortet operative Fragen: „Welche Unterlage fehlt?“, „Wann wurde diese Aussage gemacht?“, „Welche Stelle kennt meine Anfrage?“ Sie verwendet nur bereits erworbenes Wissen. Sie sagt nicht: „Du hast durch deinen Widerstand das System stabilisiert.“

Wer wenig Text lesen möchte, kann den unmittelbar handlungsrelevanten Inhalt einer Akte aufklappen. Die vollständige literarische Fassung bleibt zugänglich. Kernaussagen sind nicht allein von Farbe oder winziger Fußnotenschrift abhängig.

## 12. Oberfläche, Bild und Ton

### 12.1 Gestaltung

**Entwurfsentscheidung:** Eine in erster Linie räumlich lesbare Oberfläche mit Papier, Gebrauchsspuren, Holz, Beton und zurückhaltenden amtlichen Farben. Dunkles Rot dient als Akzent, nicht als dauernde Alarmfarbe. Figuren und Räume werden zusammen gestaltet; einzelne Werke dürfen erkennbare eigene Druck- oder Bildsprachen tragen.

Der räumliche Stil der Gesamthülle und die Darstellung des bestehenden 3D-DAME-Tisches benötigen einen gemeinsamen visuellen Prototyp. Die bloße Verwendung derselben Schrift genügt nicht. Der Kartenraum soll denselben Ort vor, während und nach der Partie zeigen. Ein technischer Übergang darf sichtbar sein, solange Perspektive, Licht, Geräusche und Personen Kontinuität schaffen.

### 12.2 Informationsaufbau

- Hauptfläche: Ort, Menschen und veränderbare Gegenstände.
- Kleine Statuszeile: Tagesphase und verbleibende Diensthandlungen.
- Aktenkoffer: Inventar, bekannte Dokumente und eigener Verlauf.
- Kontextaktionen: höchstens vier primäre Handlungen gleichzeitig; weitere als verständliche Unterauswahl.
- Konsequenzen: zuerst in Szene und Gespräch, ergänzend in der Akte. Kein unablässiger Strom von Zahlenmeldungen.

### 12.3 Zugänglichkeit

Der Prototyp unterstützt Maus, Berührung und vollständige Tastatursteuerung. Bedienziele werden mindestens auf 44 × 44 logische Pixel ausgelegt. Eine schmale Darstellung ab 360 logischen Pixeln darf keine entscheidenden Aktionen abschneiden. Text lässt sich vergrößern; farbliche Zustände besitzen zusätzliche Beschriftung. Bewegung, Flackern und synthetische Effekte sind reduzierbar, Audio ist abschaltbar.

Screenreader-Tauglichkeit ist ein expliziter Prüfbedarf für die gewählte Engine und den Web-Export. Sie wird nicht aus vorhandenen Beschriftungen abgeleitet. Ist die Hauptdarstellung damit nicht ausreichend zugänglich, ist eine textorientierte Interaktionsansicht vorzusehen und gesondert zu testen.

### 12.4 Sound und Pausen

Raumton verbindet Szenen: Papier, Schritte, eine entfernte Tür, Stühle und gelegentlich der Hof. Musik kommentiert keine philosophische Erkenntnis. Ein kleiner Erfolg darf angenehm klingen. Das Spatzenmotiv wird sparsam eingesetzt. Keine Vertonung ist Voraussetzung, um Hinweise zu verstehen.

## 13. Fortschritt, Karriere und Scheitern

### 13.1 Karriere-Akte

Die Karriere-Akte bewahrt Ergebnisse, relevante Handlungen und die institutionelle Darstellung davon. Für den Spieler erkennbare Abweichungen zwischen Erlebnis und amtlicher Zusammenfassung dürfen bestehen. Intern bleiben die tatsächlichen Ereignisse erhalten; die Akte überschreibt nicht die Historie.

Beispiel: Der Spieler organisiert aus Hilfsbereitschaft einen Stuhl. Die amtliche Zusammenfassung lautet: „Vorläufige Auslagerung eines Sitzmittels abgeschlossen.“ Diese Differenz ist eine perspektivische Beschreibung, keine verlorene Spielstandsänderung.

### 13.2 Fortschritt ohne endgültige Außenposition

Fortschritt kann Zugang zu neuen Orten, zusätzliche Kontakte, bessere Kenntnis von Verfahren und andere Arten von Anliegen bedeuten. Höhere Positionen erzeugen mehr Reichweite und andere Bindungen. Sie verleihen keine allwissende Übersicht.

Lokale Erfolge zählen. Der Spieler kann Personen helfen und Beziehungen pflegen. Es gibt keine finale Zahl, die den gesellschaftlichen Nutzen aller Handlungen verrechnet. DAME darf seine internen Spielpunkte und Huhn seine interne Wertung behalten; diese werden nicht zu einer allgemeinen Rangliste moralischer Überlegenheit kombiniert.

### 13.3 Scheitern und Karriereende

Der Bank-Prototyp hat keine permanente Todesstrafe und keinen irreversiblen Verlust für einen falschen Bericht. Lobby-Loops vorhandene Perma-Death-Idee ist für die spätere Gesamtkarriere ein Prüfpunkt: Sie darf nur bei vorher verständlich gemachten Risiken greifen, nie durch eine Modellhalluzination oder einen unklaren UI-Zustand.

Ein Karriereende kann Versetzung, Ruhestand oder ein anderer erzählter Abschluss sein. Der Betrieb geht weiter. Eine exportierbare Schlussakte ist später möglich, für den ersten Prototyp reicht die lesbare In-App-Fassung.

## 14. Inhaltsproduktion und Erweiterbarkeit

### 14.1 Pflichtfelder eines neuen Vorgangs

| Feld | Inhalt |
|---|---|
| Konkretes Anliegen | Was jemand im Alltag erreichen möchte |
| Ausgangslage | Materielle Tatsachen, Aktenstand, anfängliches Spielerwissen |
| Beteiligte | Eigenes Ziel, bekannte Informationen, Reaktionsregeln |
| Eingriffe | Handlungen, Kosten, Voraussetzungen |
| Spuren | Dokumente, Aussagen, beobachtete Ereignisse, Verpflichtungen |
| Weiterverarbeitung | Empfänger, Anlass, Verzögerung und begrenzte Wirkung |
| Alternative Wege | Mindestens zwei unterschiedlich wirksame Vorgehensweisen |
| Ruhige Momente | Alltag ohne zwingende Lehrfunktion |
| Sichtbare Rückkehr | Ort und Form, in denen eine eigene Spur wiedererkennbar wird |
| Abschluss | Erfolgreich, teilweise gelöst oder offen; jeweils fortsetzbar |

### 14.2 Qualitätsprüfung vor Aufnahme

Ein neuer Vorgang muss ohne Kenntnis seines Ursprungswerks verständlich sein. Mindestens eine Person hat ein Anliegen jenseits des satirischen Mechanismus. Die Folgen haben konkrete Träger. Nicht jede Regel produziert zusätzliche Bürokratie. Ein Erfolg darf ohne abschließende Entwertung stehen bleiben.

Falls nur eine lange Erzählererklärung den Zusammenhang verständlich macht, wird zuerst die Ereigniskette überarbeitet. Falls jeder Ausgang dieselbe institutionelle Folge hat, wird die tatsächliche Handlungswirkung geprüft.

### 14.3 Erweiterungen in sinnvoller Reihenfolge

Nach dem Bank-Vorgang folgt ein zweiter kleiner Fall mit denselben Orten und mindestens einer bekannten Figur. Er muss die gleichen Systemregeln mit anderer Dynamik nutzen, etwa eine verschwundene Zuständigkeit oder eine Beschwerde über Beschwerden. Erst wenn das gelingt, folgen neue Abteilungen, umfangreiche Texte oder Division 7B.

Historische Episoden aus den bisherigen Werken werden als spätere Inhalte behandelt. Ihre historischen Aussagen benötigen vor Veröffentlichung eine eigene Quellenprüfung. Im Prototyp gibt es keine Behauptung, alle entsprechenden Geschichten seien bereits überprüft.

## 15. Technische Architektur

### 15.1 Ausgangspunkt und Grenze der Aussagen

Das ältere Gesamtkonzept beschreibt Godot-Projekte für Lobby-Loop und DAME sowie eine eigenständige JavaScript-Fassung des Huhns. Das Huhn-Archiv liegt lokal vor. Die aktiven GitHub-Stände von Lobby-Loop und DAME wurden für dieses Dokument nicht neu abgerufen. Versionsnummern, Dateipfade, Testzahlen und vorhandene Dienste aus dem Alttext gelten daher als Prüfhinweise, nicht als bestätigter heutiger Stand.

**Entwurfsentscheidung:** Zunächst die gemeinsame Falllogik und den Bank-Vorgang in einem isolierten Integrationszweig beziehungsweise neuen Prototypbereich umsetzen. Bestehende Projekte nicht vor dieser Prüfung zusammenkopieren. Der gemeinsame Laufzeitkern soll mit der vorhandenen Godot-Linie vereinbar sein; genaue Version und Renderer werden nach Sichtung der tatsächlichen Projektdateien festgehalten.

### 15.2 Verantwortlichkeiten

| Komponente | Verantwortung | Darf nicht |
|---|---|---|
| Weltkern | Zustand, Zeit, Ereignisse, Zuständigkeiten, bekannte Beziehungen | Darstellung oder Modelltexte als Wahrheit übernehmen |
| Fallsteuerung | Bedingungen und Übergänge eines Vorgangs | Eigene parallele Zeit oder unkontrollierte Änderungen speichern |
| Szenenoberfläche | Handlungen anbieten, Ergebnisse darstellen | Direkt beliebige Weltwerte verändern |
| Minispieladapter | Gültigen Startzustand erzeugen, Spiel kapseln, Ergebnis zurückgeben | Globalen Spielstand selbst ändern |
| Aktenansicht | Bekannte Quellen und Verlauf darstellen | Verdeckte Daten aus der Debug-Ansicht preisgeben |
| Inhaltsregister | Versionierte Fall-, Figuren- und Lehrendaten | Regeln zur Laufzeit unbemerkt austauschen |
| Optionaler Spielleiterdienst | Sprachliche Varianten innerhalb des bekannten Zustands vorschlagen | Eigenmächtig Belohnungen, Wahrheiten oder Enden setzen |

### 15.3 Einziger Änderungspfad

Jede dauerhafte Änderung läuft über einen überprüften Befehl und den zentralen Zustandsanwender. Dieser erzeugt Ereignisse. Folgeregeln dürfen daraus weitere zulässige Ereignisse planen. Minispiele liefern Ergebnisse zurück; der Fall entscheidet anhand dieser Ergebnisse über die Weltfolgen.

Für den Prototyp genügt ein einfacher lokaler Ereignisverlauf mit regelmäßigen Zustandsabbildern. Eine verteilte Infrastruktur, eine umfassende Event-Sourcing-Plattform oder ein Server werden nicht benötigt.

### 15.4 Modulgrenzen

Vorgeschlagenes logisches Layout; tatsächliche Pfade werden an die geprüften Repositories angepasst:

```text
world_core/       Zustand, Befehle, Ereignisse, Zeit, Folgeregeln
cases/bank_01/    Falldaten, Texte, Übergänge, Darstellungshinweise
content/         Figuren, Orte, Dokumente, Referenzdefinitionen
adapters/        Lobby-Loop, Huhn, DAME
ui/              Szenen, Akte, Berichte, Barrierefreiheitsansicht
tests/           Regeln, Vergleichspartien, Fallabläufe, Speicherfälle
```

Gemeinsame Profil-, Speicher- oder Audiofunktionen aus DAME werden erst übernommen, wenn ihre Schnittstellen und Abhängigkeiten geprüft sind. Ein bereits vorhandener Dienst ist kein Grund, ungeprüft die gesamte App darum herum umzubauen.

### 15.5 Darstellung und Zielplattform

Ziel ist eine lokal spielbare Anwendung mit möglichst gemeinsamem Web- und Desktop-Pfad. Das ältere Konzept bevorzugt GL Compatibility für die Web-Fassung. Diese Wahl wird vor der Migration mit den realen Projekten, dem DAME-Tisch, Schrift, Eingaben und Speichern getestet. Ein Rendererwechsel gilt erst nach einem funktionierenden Export als geklärt.

Die Spezifikation fordert keine neue 3D-Welt. Szenen dürfen zunächst statische oder leicht animierte Hintergründe mit interaktiven Bereichen sein. Für den Prototyp werden Gestaltung und Technik nur so weit ausgebaut, wie die Erfahrung überprüfbar wird.

## 16. Datenmodell und Schnittstellen

### 16.1 Kernobjekte

| Objekt | Pflichtfelder | Zweck |
|---|---|---|
| `WorldState` | `schema_version`, `content_version`, `run_id`, `phase`, `turn`, `cases`, `actors`, `objects`, `knowledge`, `pending_events`, `applied_transactions` | Ein autoritativer Zustand pro Karriere |
| `CaseState` | `case_id`, `status`, `hours_remaining`, `evidence_ids`, `report`, `resolution`, `scheduled_followups` | Fortschritt eines Vorgangs |
| `ActorState` | `actor_id`, `location_id`, `goals`, `known_fact_ids`, `attention`, `commitments` | Begrenztes Wissen und konkrete Bindungen |
| `Evidence` | `evidence_id`, `case_id`, `kind`, `source_id`, `observed_at`, `content_ref`, `claim_ids` | Quelle und Zeitpunkt eines Hinweises |
| `Claim` | `claim_id`, `speaker_id`, `proposition`, `status`, `evidence_ids` | Behauptung, Beobachtung oder Schlussfolgerung |
| `RuleRecord` | `rule_id`, `scope`, `issuer_id`, `valid_from`, `origin_event_ids`, `status` | Institutionelle Regel samt Herkunft |
| `WorldEvent` | `event_id`, `transaction_id`, `type`, `actor_id`, `case_id`, `turn`, `caused_by`, `payload` | Tatsächliche Zustandsänderung |
| `KnowledgeEntry` | `observer_id`, `fact_id`, `learned_from`, `learned_at` | Wer welche Tatsache erfahren hat |
| `MinigameSession` | `session_id`, `game`, `case_id`, `ruleset_version`, `seed`, `status`, `checkpoint` | Wiederaufnahme und eindeutiges Ergebnis |

Die Engine darf mehr wissen als eine Figur. Zugriff auf dieses Wissen ist ausdrücklich begrenzt. Eine Aussage einer Figur verändert zunächst ihre Behauptung und das Spielerwissen über diese Aussage, nicht die zugrunde liegende Weltwahrheit.

### 16.2 Befehl für eine Untersuchungshandlung

```json
{
  "schema_version": 1,
  "command_id": "cmd-bank01-004",
  "actor_id": "player",
  "case_id": "BANK-01",
  "type": "request_document",
  "target_id": "registry",
  "params": { "document_id": "bench_inventory" }
}
```

Vor Ausführung prüft der Kern: Existiert der Fall? Ist die Handlung in dieser Phase zulässig? Hat der Spieler Zugriff? Sind ausreichend Diensthandlungen vorhanden? Wurde die `command_id` bereits verarbeitet? Ist das Dokument schon angefordert oder geliefert? Doppelklicks verbrauchen keine zweite Handlung.

### 16.3 Ereignis und kausale Herkunft

```json
{
  "event_id": "evt-bank01-011",
  "transaction_id": "tx-bank01-004",
  "type": "audit_announced",
  "actor_id": "registry",
  "case_id": "BANK-01",
  "turn": 4,
  "caused_by": ["cmd-bank01-004"],
  "payload": {
    "document_id": "bench_inventory",
    "attention_delta": 2,
    "scheduled_action": "move_originals_to_review_cabinet"
  }
}
```

`caused_by` kann auf einen Befehl oder frühere Ereignisse verweisen. Zyklen im Herkunftsgraphen sind unzulässig. Zukünftige Ereignisse dürfen rückwirkend keine Quellen für vergangene Tatsachen werden. Die Meldung der Aufmerksamkeit allein verrät dem Spieler nicht den Grund der Aktenbewegung.

### 16.4 Minispielstart

```json
{
  "schema_version": 1,
  "type": "start_minigame",
  "command_id": "cmd-bank01-hearing",
  "session_id": "session-bank01-huhn-1",
  "game": "widerlegung",
  "case_id": "BANK-01",
  "params": {
    "content_id": "bank_public_seating_v1",
    "ruleset_version": "huhn-port-v1",
    "seed": "BANK-01-A",
    "return_scene": "committee_room"
  }
}
```

Für ältere Lobby-Loop-Befehle ohne `game` sieht das Alt-Konzept die Zuordnung zu `beleidigungsfechten` vor. Diese Kompatibilität muss nach Sichtung der echten bisherigen Aufrufstellen ausdrücklich implementiert und getestet werden. Fehlende Felder neuer Aufrufe dürfen nicht stillschweigend geraten werden.

### 16.5 Minispielergebnis

```json
{
  "schema_version": 1,
  "session_id": "session-bank01-huhn-1",
  "game": "widerlegung",
  "case_id": "BANK-01",
  "status": "completed",
  "outcome": "won",
  "score": 14,
  "facts": { "definition_collapsed": true },
  "chronicle_key": "bank_definition_rejected"
}
```

Zulässige Status sind `completed` und `aborted`; bei Abbruch gibt es keinen Sieg oder Verlust. Ergebnisse müssen zur gestarteten Session, zum erwarteten Spiel und zur Regelversion passen. Der Weltkern akzeptiert nur ein abgeschlossenes Ergebnis pro Session.

**Entscheidung gegenüber dem Alttext:** Das Minispiel liefert keine frei ausführbare Liste globaler Effekte. Die Fallsteuerung übersetzt sein geprüftes Ergebnis in freigegebene Weltbefehle. So kann ein Spiel oder ein Sprachmodell nicht beliebige Inventargegenstände, Statistiken oder Zuständigkeiten setzen. Ein Adapter kann ältere Ergebnisformate einlesen, muss deren Effekte aber gegen diese Zuordnung prüfen.

Für den Bankfall bewirkt `definition_collapsed = true` zunächst nur, dass der Definitionsweg gewonnen ist. T-04 wird erst nach vorhandenem Reparaturbeleg und bestätigtem Antrag angewandt. Das Beispiel `score: 14` ist ein Formatbeispiel, keine festgelegte notwendige Punktzahl.

### 16.6 Fallregel für den Nachgang

```text
WENN resolution == formal_release
UND die bestätigte Antragsformulierung vorliegt
UND Voss den Beschluss erhalten hat
UND followup_accessibility_rule noch nicht angewandt wurde:
    plane genau ein Ereignis für die Nachgangphase
    übernimm die gespeicherte Formulierung und BANK-01 als Herkunft
    erzeuge die neue Prüfanforderung für neu aufzustellende Sitzgelegenheiten
    belasse die bereits freigegebene Bank zugänglich
```

Für `temporary_exception`, `replacement_chair` und `unresolved` gelten getrennte Nachgangregeln. Sie dürfen nicht zusätzlich den formellen Erlass erzeugen.

### 16.7 Ausgabe für Menschen und Debugging

Die Spielerakte zeigt Quellen, bekannte Ereignisse und verständliche Bezeichnungen. Die Entwicklungsansicht zeigt zusätzlich interne Zustände, Aufmerksamkeit, unerfahrene Tatsachen und die vollständige Kausalkette. Die Entwicklungsansicht ist in öffentlichen Builds nicht versehentlich erreichbar.

## 17. Speichern, Wiederholen und Fehlerbehandlung

### 17.1 Speicherpunkte

Automatisch gespeichert wird nach jeder abgeschlossenen Weltaktion, vor einem Minispiel, nach einem gültigen Minispielergebnis und bei Phasenwechsel. Während einer Partie muss der Adapter einen fortsetzbaren Spielzustand sichern können. Ist dies bei der geprüften DAME-Fassung noch nicht verfügbar, ist es ein Integrationshindernis und kein Grund, nach Neuladen willkürlich einen Ausgang zu setzen.

Ein Speicherstand enthält Regel- und Inhaltsversionen, Zufallszustände, offene Sessions, bereits angewandte Transaktionen und geplante Ereignisse. Speichern erfolgt als zusammenhängende, möglichst atomare Aktualisierung mit einem vorherigen funktionsfähigen Stand als Rückfall.

### 17.2 Determinismus

Gleiche Ausgangsdaten, gleicher Zufallszustand und gleiche Handlungsfolge müssen dieselben regelrelevanten Ergebnisse erzeugen. Reine Formulierungsvarianten sind davon getrennt. Bereits angezeigte Varianten werden bei Wiederaufnahme wiederverwendet.

Bei der Huhn-Portierung genügt es nicht, nur denselben Seed-Text zu verwenden. Hashfunktion, 32-Bit-Überläufe, Zufallsalgorithmus, Reihenfolge der Zufallsaufrufe und Mischalgorithmus müssen bei Vergleichspartien übereinstimmen. Andernfalls wird die Abweichung als bewusste neue Regelversion behandelt; sie darf nicht als Parität ausgegeben werden.

### 17.3 Unterbrechung und Fehler

| Fehler | Verhalten |
|---|---|
| Anwendung während einer Aktion geschlossen | Letzten vollständig gespeicherten Zustand wiederherstellen |
| Ergebnis doppelt übertragen | Gleiche Session erkennen; keine erneuten Belohnungen oder Ereignisse |
| Unbekannte Inhaltsversion | Verständliche Meldung und vorherigen Stand anbieten; keine stillen Datenverluste |
| Modellantwort ungültig oder ausbleibend | Feste autorisierte Formulierung verwenden |
| Minispiel nicht ladbar | Zur Startszene zurückkehren, keinen Ausgang verbuchen; alternative Fallhandlung bleibt erreichbar |
| Speichern fehlgeschlagen | Sichtbar melden und erneuten Versuch ermöglichen; Erfolg nicht vortäuschen |

### 17.4 Offline und Daten

Der erste Vorgang läuft vollständig offline einschließlich Hinweise, Dialoge und Minispiele. Die Anwendung speichert lokal. Telemetrie, Cloud-Synchronisierung oder öffentliche Karriereakten sind keine Voraussetzungen. Ein später freiwilliger Export enthält nur die vorgesehenen Spieldaten; keine API-Schlüssel oder Debug-Protokolle.

## 18. Rolle eines optionalen Sprachmodells

### 18.1 Reihenfolge

Die erste abnahmefähige Fassung verwendet handgeschriebene Inhalte. Erst danach kann ein Sprachmodell Varianten erzeugen. So wird sichtbar, ob die Regeln und Figuren die Erfahrung tragen. Ein Modell ersetzt keine fehlende Falllogik.

### 18.2 Zulässige Aufgaben

Sprachliche Varianten bereits festgelegter Reaktionen; kurze atmosphärische Äußerungen im passenden Ton; Entwürfe für neue Lehren in einer Autorenwerkstatt; Zusammenfassungen autorisierter Karriereereignisse. Neue Inhalte werden vor verbindlicher Aufnahme geprüft und versioniert.

### 18.3 Unzulässige Autorität

Das Modell entscheidet nicht, welche vergangenen Ereignisse stattgefunden haben, welche Figur ein Geheimnis kennt, ob der Spieler gewinnt, welche globalen Effekte ausgeführt werden oder was eine wahre moralische Deutung ist. Unverarbeitete Modelltexte dürfen keinen Weltzustand mutieren.

Für eine Figurenäußerung erhält der Dienst nur deren erlaubtes Wissen, die Szene, relevante Beziehungen und freigegebene Reaktionsabsichten. Spieltexte oder eingegebene Spielertexte werden als Inhalt behandelt, nicht als Anweisung zur Veränderung der Engine-Regeln.

### 18.4 Validierung neuer Lehren

Eine spätere Generierung durchläuft vier getrennte Prüfungen: korrektes Datenformat; logische Konsistenz der Merkmale und Referenzfälle; Spielbarkeit durch Simulation; inhaltliche und sprachliche Qualität. Eine Simulation belegt weder Wahrheit noch Witz noch Spaß.

Die im älteren Konzept formulierte Zusage „unbegrenzter Inhalt mit geprüfter Qualität“ wird hier nicht übernommen. Geprüft werden definierte Eigenschaften; die Qualität des Gesamterlebnisses bleibt empirisch offen. Bei Fehlschlag wird ein bekanntes Inhaltspaket verwendet.

### 18.5 Betrieb und Kosten

Kein Anbieter, Modellname oder Tarif ist durch dieses Dokument festgelegt. Falls eine Online-Option entsteht, werden Kosten pro Spielstunde, Wartezeit, Schlüsselverwaltung und Datenübertragung separat geprüft. Eigene Schlüssel werden nicht in eine öffentliche Web-Datei eingebaut. Die Offline-Fassung bleibt vollständig spielbar.

## 19. Umsetzung in überprüfbaren Etappen

Die Reihenfolge gegenüber dem älteren Konzept ändert sich: Die Immersion und kausale Verbindung werden vor einer großen Zusammenführung der Infrastruktur geprüft. Automatische Lehrengenerierung rückt hinter den handgeschriebenen Gesamtvorgang.

| Etappe | Ergebnis | Abnahmetor |
|---|---|---|
| E0 – Bestandsprüfung | Aktive Repositories, Versionen, Einstiegspunkte und Abhängigkeiten eindeutig dokumentiert | Jeder Integrationspunkt besitzt eine geprüfte Quelle; keine unklare Lobby-Loop-Arbeitskopie |
| E1 – Fallkern | BANK-01 als schlichter Text- oder Klickprototyp, alle materiellen Ausgänge | T-01 bis T-08 samt Speicher- und Folgeereignissen reproduzierbar |
| E2 – Dienstaufsicht und Widerlegung | Untersuchung mit Reaktionen; reale Huhn-Partie im Ausschuss | Hinweise kausal korrekt; Huhn-Portierung geprüft; Verlust und Abbruch fortsetzbar |
| E3 – Gemeinsame Erfahrung | Räume, Figuren, Akte, Nachgang und tatsächliche DAME-Begegnung | Keine Pflichtpartie, keine falsche Kontinuität; erster unvorbereiteter Spieltest |
| E4 – Konsolidierung | Gemeinsame Hülle und Dienste nur nach erprobten Schnittstellen | Bestehende Spiele weiterhin regelkonform; Offline- und Exportprüfung bestanden |
| E5 – Wiederverwendung | Zweiter Vorgang aus denselben Regeln | Unterschiedliche Dynamik ohne Sondercode für jede Kleinigkeit |
| Später | Division 7B, weitere Werke, optionale Generierung, Online-Funktionen | Eigene begründete Spezifikation nach Ergebnissen von E1–E5 |

### 19.1 Abgrenzung von Testersatz und fertiger Integration

E1 darf Minispielausgänge in einer ausdrücklich als Entwicklung gekennzeichneten Ansicht setzen, um Fallfolgen zu prüfen. Das ist kein spielbares Huhn oder DAME und zählt nicht als abgeschlossene Integration. Vor E3 werden diese Platzhalter durch die tatsächlichen Mechaniken ersetzt.

### 19.2 Aufwand und Arbeitsgröße

Kalendertermine werden erst nach E0 geschätzt. Die bisher beschriebenen Repository-Größen und Testzahlen sind keine verlässliche Aufwandsschätzung. Jede Etappe muss einen kleinen prüfbaren Stand hinterlassen. Bei zu hohem Aufwand werden zunächst visuelle Varianten und zusätzliche Inhalte reduziert; die kausale Handlungswirkung bleibt Kernumfang.

### 19.3 Erster konkreter Entwicklungsauftrag

Nach E0: Datenmodell für BANK-01, zentrale Aktionstransaktion, acht Diensthandlungen, Hinweisgewinn und die vier materiellen Abschlüsse implementieren. Die Nachgangregeln müssen schon in diesem einfachen Stand unterscheidbar sein. Danach erst Untersuchungskomfort, Minispiele und räumliche Gestaltung ausbauen.

## 20. Test- und Abnahmeplan

### 20.1 Regeltests

| Test | Bedingung | Erwartetes Ergebnis |
|---|---|---|
| QA-01 | Identische Seed- und Aktionsfolge | Identischer regelrelevanter Zustand |
| QA-02 | Gleiche `command_id` zweimal | Eine Handlung und eine Änderung |
| QA-03 | Keine offizielle Anforderung | Keine durch Prüfung ausgelöste Aktenbewegung |
| QA-04 | Anforderung vor Beobachtung | Bewegung korrekt terminiert; Begründung erst bei erworbener Quelle bekannt |
| QA-05 | Acht Handlungen verbraucht | Keine neunte kostenpflichtige Untersuchung; ausstehende Akte wird geliefert |
| QA-06 | Formelle Freigabe | Bank zugänglich, genau eine Nachgangregel mit eigener Herkunft |
| QA-07 | Ausnahme oder Ersatzstuhl | Keine formelle allgemeine Zugänglichkeitsregel |
| QA-08 | Widerlegung gewonnen, B-01 fehlt | Keine unzulässige materielle Freigabe |
| QA-09 | Niederlage, Abbruch oder fehlendes Minispiel | Fall besitzt weiterhin erreichbaren Abschluss |
| QA-10 | DAME-Sieg wiederholt oder geladen | Höchstens die eine vorgesehene Gefälligkeit |
| QA-11 | Figur hat Hinweis nicht erhalten | Kein Dialog mit diesem Wissen |
| QA-12 | Formular mit eigener Begründung gespeichert | Nachgang übernimmt genau die bestätigte Formulierung |
| QA-13 | Laden nach jedem Phasenwechsel | Hinweise, offene Ereignisse und Ort stimmen überein |
| QA-14 | Fremdes oder manipuliertes Minispielergebnis | Abgewiesen; kein beliebiger Weltzustand gesetzt |
| QA-15 | Wiederholter Besuch des Hofs | Darstellung entspricht dem aktuellen Ergebnis |
| QA-16 | Bereits abgeschlossene Folge verarbeitet | Kein zweites identisches Schreiben, keine Ereignisschleife |
| QA-17 | Spieler ist während der Aktenbewegung an anderem Ort | Kein eigener Beobachtungseintrag B-06; spätere Aussage bleibt als Aussage gekennzeichnet |

### 20.2 Prüfung der Huhn-Portierung

Die vorhandene JS-Fassung ist die Vergleichsgrundlage für die übernommenen Regeln. Vor einer Übertragung werden ihre tatsächlichen Tests ausgeführt und ihre Ergebnisse festgehalten. Mindestens 200 Partien mit festen Seeds und gespeicherten Entscheidungen werden zwischen Fassungen verglichen: Hand, Nachbesserung, Last, Herzschlag, Zufallszustand und Ergebnis.

Zusätzlich werden Randfälle der kostenlosen Beweisaufnahme, des Weiterwiegens gestrichener Bestimmungen und des Abbruchs geprüft. Die Zahl vorhandener Tests wird aus der aktuellen Datei ermittelt, nicht aus dem älteren Bericht übernommen. In dieser Spezifikation wurden diese Tests nicht ausgeführt.

### 20.3 End-to-End-Prüfung

Je ein vollständiger Durchlauf für formelle Freigabe, Ausnahme, Ersatzstuhl und offenen Abschluss. Mindestens ein Durchlauf ohne DAME und einer mit verlorener Widerlegung. Speichern und Neuladen jeweils vor sowie nach dem Minispielergebnis. Danach ein vollständig netzfreier Durchlauf.

Bedienprüfung: schmale Ansicht, große Schrift, Tastatur, reduzierte Bewegung und ausgeschalteter Ton. Unbekannte Zugriffsmöglichkeiten oder abgeschnittene Handlungen gelten als Fehler. Die vereinbarte Screenreader-Prüfung bleibt separat sichtbar, bis sie tatsächlich durchgeführt wurde.

### 20.4 Erster qualitativer Spieltest

Fünf Personen, die weder die Werke noch die beabsichtigte Aussage kennen, spielen den Vorgang. Das ist eine kleine formative Prüfung; sie kann keine Aussage darüber belegen, wie „die meisten Menschen“ das Spiel verstehen. Vorab wird nur das praktische Spielziel erklärt.

Währenddessen werden beobachtet: Wo entsteht der erste selbstständige Schritt? Wo wird Hilfe nötig? Welche Folge wird bemerkt? Welche Szene wird übersprungen? Wo entstehen Lachen, Neugier oder Ermüdung? Bloßes Schweigen wird nicht als fehlendes Verständnis gewertet.

Fragen danach, in dieser Reihenfolge:

1. „Was wolltest du erreichen, und was ist daraus geworden?“
2. „Was hat sich durch deine Entscheidungen verändert?“
3. „Gab es eine spätere Situation, die mit einer früheren Handlung zusammenhing?“
4. „Wo war dir unklar, was du tun konntest oder warum etwas passiert ist?“
5. „Welche Person oder Szene ist dir geblieben? Würdest du weiterspielen wollen?“

Begriffe wie Systemerhalt, Verstrickung oder Bürokratiekritik werden nicht vorgegeben. Nachfragen dürfen Quellen klären, aber keine gewünschte Antwort hineinlegen.

### 20.5 Vorläufige Weiterbaukriterien

- Mindestens vier von fünf Personen finden nach kurzer Bedienungseinführung selbstständig einen Weg zum Abschluss.
- Mindestens drei von fünf nennen ohne thematischen Hinweis einen konkreten eigenen Eingriff und eine spätere Verarbeitung davon.
- Die verschiedenen Abschlusswege werden als unterschiedlich wirksam wahrgenommen; ein begründeter Eindruck „am Ende passiert sowieso dasselbe“ löst eine Überarbeitung aus.
- Es gibt keinen wiederkehrenden technischen oder sprachlichen Blocker, der mehr als eine Person ohne Hilfe festhält.
- Humor und Interesse werden qualitativ dokumentiert. Das Bestehen der obigen Zahlen beweist noch keinen Spielspaß.

Diese Schwellen sind Arbeitsentscheidungen für den kleinen Test. Nach Überarbeitung folgt eine zweite unabhängige Runde, bevor eine öffentliche Aussage zur Verständlichkeit getroffen wird.

### 20.6 Diagnose bei Problemen

| Befund | Zuerst ändern |
|---|---|
| Handlungsmöglichkeiten unklar | Verben, Voraussetzungen, sichtbare Kosten |
| Eigene Folge nicht erkannt | Wiederkehrende Formulierung, Zeitpunkt, Fallnummer, räumliche Begegnung |
| Alles wirkt vorherbestimmt | Unterschiedliche Zustandsänderungen und Wegbedingungen |
| Welt wirkt wie eine Minispielsammlung | Anlass, gemeinsame Personen, Rückkehr in denselben Vorgang |
| Text wirkt belehrend | Erklärsätze entfernen; Folge in Handlung oder Gegenstand zeigen |
| Zu wenig Interesse | Anliegen und Figuren konkretisieren; Routinetätigkeiten verkürzen |
| Jede Szene wirkt wie eine Pointe | Mehr gewöhnlichen Alltag und unbeachtete Nebenhandlungen zulassen |

## 21. Risiken und Entscheidungsregister

### 21.1 Größte Risiken

| Risiko | Frühes Warnsignal | Gegenmaßnahme |
|---|---|---|
| Fragmente bleiben sichtbar zusammengeklebt | Spieler benennt vor allem Titelwechsel und neue Oberflächen | Denselben Vorgang mit denselben Personen über Übergänge tragen |
| Satire wird zur gepredigten These | Figuren erklären, was der Spieler denken soll | Konsequenz statt Kommentar; mehrere Stimmen erlauben |
| Jede Handlung führt zur gleichen Falle | Spieler handelt beliebig, weil es ohnehin egal erscheint | Echte materielle Alternativen und spezifische Folgeregeln |
| Weltkern wird überdimensioniert | Viele globale Systeme, noch kein kompletter Fall | Nur Zustände implementieren, die BANK-01 benötigt |
| Wiederholung wird durchschaubar | Nach jedem Erfolg folgt erwartbar ein neues Formular | Häufigkeit und Größe von Folgen variieren; echte Ruhe zulassen |
| Minispiele überlagern die Szene | Spieler vergisst, weshalb er gerade spielt | Anlass und Rückkehr knapp verankern; keine Pflichtpartie |
| Modell erfindet Kausalität | Rückwirkend neue Motive oder Belege | Autoritativer Zustand, begrenzte Modellrolle, feste Ersatztexte |
| Migration beschädigt funktionierende Spiele | Alte Tests scheitern nach bloßer Zusammenführung | Adapter zuerst, Dienste später übernehmen |
| Lesbarkeit geht in Ästhetik verloren | Kleine Schrift und Aktenwände verhindern Entscheidungen | Kurze operative Ansicht plus freiwilliger Volltext |

### 21.2 Register der Entwurfsentscheidungen

| ID | Entscheidung | Status / Zeitpunkt der Überprüfung |
|---|---|---|
| D-01 | Nomos vollständig außerhalb des Umfangs | Vorgabe |
| D-02 | Immersion und Beteiligung vor theoretischer Erklärung | Vorgabe |
| D-03 | Amt als Zentrum mit belebter Umgebung | Im Gespräch akzeptierte Richtung; räumlicher Umfang hier konkretisiert |
| D-04 | BANK-01 als erster vollständiger Vorgang | Entwurfsentscheidung; nach erstem Spieltest prüfen |
| D-05 | Acht Diensthandlungen, Abend, Entscheidung, Nachgang | Entwurfsentscheidung; Dauer und Druck testen |
| D-06 | Feste, offline verfügbare Inhalte zuerst | Entwurfsentscheidung für verlässliche Prüfung |
| D-07 | Weltfolgen werden vom Fallkern zugeordnet | Technische Entwurfsentscheidung |
| D-08 | DAME freiwillig und sozial bedeutsam | Entwurfsentscheidung im Sinn eigenständiger Spielbarkeit |
| D-09 | Kein allgemeiner Erkenntnis- oder Moralwert | Aus der Nutzerabsicht abgeleitete Gestaltungsregel |
| D-10 | Huhn-Einsturz im integrierten Fall als Saalmodell | Entwurfsentscheidung; visuell prüfen |
| D-11 | Bestehende Werke als eigene Stimmen der Welt | Im Gespräch akzeptierte Richtung; einzelne Autorenzuordnungen bleiben offen |
| D-12 | Perma-Death im ersten Vorgang deaktiviert | Entwurfsentscheidung; spätere Karriere separat prüfen |
| D-13 | Kein Shop und keine Online-Pflicht im Prototyp | Entwurfsentscheidung zum Umfang |
| D-14 | Markdown als bearbeitbare Hauptspezifikation | Lieferformat dieser Fassung |

### 21.3 Offene Punkte, die den Entwurf nicht blockieren

Vor E1 zu klären: aktive Repository-Standorte und Branches; tatsächliche Engine-Version; eindeutige Lobby-Loop-Arbeitskopie; vorhandene Speicher- und Minispielschnittstellen. Vor E2: finaler und geprüfter Bank-Kartenpool sowie Verhalten der Huhn-Portierung. Vor E3: gemeinsamer visueller Übergang, tatsächliche DAME-Botfähigkeit und Wiederaufnahme, Accessibility-Befund.

Nach dem ersten Spieltest zu klären: gewünschte Sitzungsdauer, Ausmaß späterer Karrierefolgen, Umfang der frei startbaren Modi, zeitliche Einordnung und Zugang zu Division 7B. Name, Geschäftsmodell und Veröffentlichungsplattform sind keine Voraussetzung für die Prüfung des ersten Vorgangs.

## 22. Rückverfolgbarkeit der Anforderungen

| Nutzerabsicht | Umsetzung in dieser Spezifikation | Prüfung |
|---|---|---|
| Alles soll wie eine Welt wirken | Wiederkehrende Orte/Figuren, gemeinsamer Fallkern, Folgen über Spielformen | E3-Spieltest, End-to-End-Durchläufe |
| Eigenständige Werke nicht verlieren | Getrennte Stimmen, unveränderte Originale, optionale Texte | Inhaltsreview nach Kapitel 4 |
| Immersion ist der Zweck | Anliegen zuerst, räumliche Folgen, Alltag und Pausen | Freie Nacherzählung und Beobachtung im Spieltest |
| Mitten im Geschehen und gleichzeitig Beobachter | Eigenes Eingreifen verändert Hinweise und spätere Regeln | QA-03/04, Fragen 2 und 3 |
| Welt bleibt indifferent | Kein Erkenntnispreis, keine abschließende Autorenerklärung | Textreview, Kapitel 2 und 3 |
| Eigene Versuche können den Betrieb fortsetzen | Formeller Erfolg führt zu konkreter Weiterverarbeitung | QA-06 und Pfad A |
| Handlungen sollen nicht bedeutungslos werden | Mehrere materielle Ausgänge; Erfolg bleibt bestehen | QA-06/07 und Variantenvergleich |
| Möglichst viele sollen den Zusammenhang erkennen können | Konkrete Ziele, Quellen, wiederkehrende eigene Spur | Kleine formative Tests, später breitere Prüfung |
| Humor und Spaß | Ernsthafte Figuren, kleine Anliegen, wiederkehrende Formulierungen | Qualitative Rückmeldung, keine bloße Simulation |
| Systemische Grundlage | Gemeinsame Regeln und überprüfbare Ereignisketten | QA-01 bis QA-17, zweiter Vorgang in E5 |
| Nomos vorerst eigenständig | Vollständiger Ausschluss | Umfangskontrolle vor jeder Erweiterung |

## 23. Quellen und Grenzen der Bestandskenntnis

### 23.1 Verwendete Quellen

| Kennung | Quelle | Verwendeter Inhalt |
|---|---|---|
| Q-01 | Gespräch vom 18. Oktober 2026 | Nutzerabsicht, Immersion, Indifferenz, Verstrickung, Eigenständigkeit, Ausschluss von Nomos, akzeptierte Richtung |
| Q-02 | Gesamtkonzept Die Latte liegt am Boden – eine Spielewelt.md | Frühere Integration von Lobby-Loop, DAME und Huhn; Karriere-Akte; technische Vorschläge |
| Q-03 | das-gerupfte-huhn-projekt.zip: README und Design-Dokument | Regeln, v2-Änderungen, Aufbau, dokumentierte frühere Tests und Grenzen |
| Q-04 | Dasselbe Archiv: Ausschnitte aus src/engine.js und test/engine.test.js | Tatsächlicher Engine-Einstieg, Funktionen, Seed-Logik und Beispiele vorhandener Tests |
| Q-05 | zynisch pragmatische Kunst in Realitäten.zip: Manifest der Zynischen Kunst.md | Haltung und Ästhetik einer eigenständigen Stimme |
| Q-06 | Dasselbe Archiv: Systemtheoretische Gesamtanalyse.md | Beschreibung von Division 7B und deren Motiven; Sekundärbeschreibung innerhalb des Materials |
| Q-07 | Enthaltenes boden-inspektion.zip: WERKDOSSIER.md | Partizipatives Werk, institutioneller Vollzug, Urkunde und Archiv |
| Q-08 | Manifest des Ästhetisierten Koprolithismus.md | Selbstverstrickung des Kritikers und satirische Sprachformen |
| Q-09 | Ethik_des_Vogelbeobachtens_Druckausgabe(1).pdf | Gelesener Text der Druckausgabe: Beobachtung, Selbstreferenz, Spatz, verschiedene literarische Formen |
| Q-10 | Systemisches Design-Framework.md | System-Grammatik, kombinierbare Regeln, Handlungsfähigkeit, Skalierungsanspruch |

Dateien sind über die beigefügten Namen identifizierbar. Die Quellen werden als kreative und technische Arbeitsmaterialien verwendet. Ihre pauschalen philosophischen oder naturwissenschaftlichen Aussagen wurden hier nicht als externe Tatsachen verifiziert.

### 23.2 Was nicht geprüft wurde

Kein vollständiges aktuelles Audit der GitHub-Repositories; keine erneute Ausführung der Huhn-Tests; kein spielbarer Bank-Prototyp; kein Nutzertest; keine aktuelle Validierung der Engine- oder Modellversionen aus dem älteren Konzept. Die enthaltenen Astral-Handbücher wurden nicht vollständig direkt gelesen; ihre Rolle wird aus den gelesenen Begleitmaterialien abgeleitet. Die interaktiven Eigenschaften des Vogelbuchs können aus der Druckausgabe nicht verifiziert werden.

### 23.3 Vorrang bei Widersprüchen

Für künstlerische Absichten gilt die jüngste ausdrückliche Nutzerentscheidung. Für bestehendes Spielverhalten gilt der geprüfte Quellcode mit Tests. Für neue Funktionen gilt diese Spezifikation als Entwurf. Bei Widersprüchen zwischen Alttext, v2-Design und Code wird der Konflikt dokumentiert; keine Fassung wird stillschweigend als gleichzeitig gültig behandelt.

## 24. Übergabe an die Umsetzung

Der nächste ausführende Schritt ist E0, danach E1. Die implementierende Person oder KI muss zunächst die reale Projektstruktur prüfen und einen konkreten Änderungsplan an diese Struktur anpassen. Sie soll weder den ganzen Bestand neu schreiben noch alle Erweiterungen gleichzeitig anfangen.

**Definition des ersten lieferbaren Stands:** Ein vollständiger BANK-01-Durchlauf mit acht Diensthandlungen, belegbaren Hinweisen, vier unterscheidbaren materiellen Abschlüssen, korrekter Akte, gespeichertem Zustand und genau den dazugehörigen Nachgangereignissen. Minispielersatz darf in E1 nur ausdrücklich als Entwicklungsfunktion dienen.

**Definition des ersten erlebnisfähigen Stands:** Derselbe Vorgang mit tatsächlicher Dienstaufsicht, getesteter Widerlegung, freiwilliger DAME-Begegnung, kohärenten Orten und Figuren sowie einem unvorbereiteten Spieltest. Die Ergebnisse des Tests bestimmen die Überarbeitung, nicht die Hoffnung, dass die Aussage schon ankommen werde.

**Leitfrage für jede Änderung:** Kann der Spieler hier sinnvoll handeln, die Wirkung erleben und später seine eigene Spur darin erkennen?

---

### Änderungsstand dieser Fassung

Version 0.1 führt die bisher eigenständigen Materialien zu einer prüfbaren Spiel- und Systemspezifikation zusammen. Sie ergänzt Dienstaufsicht und BANK-01, ersetzt frei ausführbare Minispiel-Welteffekte durch eine geprüfte Zuordnung im Fallkern und verschiebt automatische Inhaltsgenerierung hinter den handgeschriebenen Gesamtprototyp. Sämtliche Abnahmetore sind noch offen. Dieses Dokument ist das erstellte Arbeitsergebnis; eine Implementierung wurde damit nicht vorgenommen.
