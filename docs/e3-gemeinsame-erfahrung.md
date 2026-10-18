# E3 – Gemeinsame Erfahrung

**Bezug:** Spezifikation 0.1, Kap. 8.3, 9.6, 11.3, 12.1, 13.1, 17.1, 19 (E3), 20.4
**Stand:** 18. Oktober 2026
**Abnahmetor E3:** Keine Pflichtpartie, keine falsche Kontinuität; erster unvorbereiteter Spieltest.

Der Spieltest selbst ist **nicht durchgeführt**: Er braucht fünf Menschen, die den Vorgang unvorbereitet spielen. Diese Etappe liefert alles, was dafür gebraucht wird (Anleitung, Bogen, Auswertungsskript), und macht den Vorgang spielbar, wie er getestet werden soll.

## Was neu ist

### Echte DAME-Partie im Hinterzimmer

- Am Abend startet „Mit Mertens spielen (DAME)“ die **echte Partie** am 3D-Tisch. Gegner sind **Herr Mertens** und **Frau Seidel**, dieselben Personen wie tagsüber; Frau Seidel sitzt abends im Hinterzimmer und ist am nächsten Morgen wieder in der Registratur.
- Die Begegnung findet in der **Amtsstube** statt (Akte-Kartenrücken, graue Aktenschränke). Die Raumwahl des Spielers kommt danach zurück.
- Die Partie gehört der Session: Ihre `match_id` (`BANK-01-<session>`) läuft durch Konfiguration, DAMEs Spielstand und Ergebnis. **Nur ein Ergebnis mit dieser Kennung zählt.** Eine fremde Partie, eine freie Partie oder eine Online-Partie ändert den Vorgang nicht.
- **Fortsetzen:** Verlässt der Spieler die Partie (Menü, Flur, Neustart), bietet der Innenhof „Partie fortsetzen“, sofern DAMEs gespeicherte Partie die `match_id` der Session trägt. Ein Abbruch verwirft nur den eigenen Spielstand.
- Gewinn gibt wie bisher höchstens die eine Gefälligkeit; ein Verlust sperrt nichts, die Frage an Mertens bleibt offen. Keine Partie ist Pflicht (Tests aus E1 gelten weiter).

### Übergang

Eine kurze Blende (0,3 s aus, 0,4 s ein) mit Ortsnamen („Hinterzimmer“, „Innenhof“) deckt den Szenenwechsel. Sie entfällt bei abgeschalteten Animationen (DAMEs Einstellung) und im Testlauf. Der Rückweg-Knopf bleibt darüber bedienbar.

### Aktenhilfe (Kap. 11.3)

Reiter „Hilfe“ im Aktenkoffer mit drei Fragen, ohne Kosten und ohne Zustandsänderung:

- „Welche Unterlage fehlt?“ nennt je Antrag, was noch fehlt (derselbe Umfang wie das Einreichungsformular).
- „Welche Stelle kennt meine Anfrage?“ zählt nur **eigene Handlungen** je Stelle auf (angefordert, befragt, beobachtet). Aufmerksamkeit und Benachrichtigungen zwischen Stellen bleiben unsichtbar.
- „Wann wurde das festgehalten?“ nennt Art, Zeitpunkt und Quelle eines Eintrags.

### Akte (Kap. 13.1)

Die Akte-Seite im Flur hat einen vierten Abschnitt „Innenhof (BANK-01)“ mit **amtlicher Fassung** neben dem **Tatsächlichen**. Beispiel: Wurde ein Stuhl organisiert, steht amtlich „Vorläufige Auslagerung eines Sitzmittels abgeschlossen“, tatsächlich „Frau Kern sitzt auf einem Klappstuhl“. Die Ereignisse bleiben unverändert.

### Spieltest-Unterlagen

- `docs/spieltest-bank-01.md`: Vorbereitung, genauer Wortlaut, Beobachtungsbogen, die fünf Fragen, Weiterbaukriterien, Diagnosetabelle.
- `tools/spieltest-auswertung.mjs`: fasst den Spielstand einer Testperson zusammen (Abschluss amtlich/tatsächlich, Aufwand, Belege, Wege, Minispiele, Bericht, sichtbare Folgen). Fixture eines vollständigen Durchlaufs: `tools/fixtures/bank01-pfad-a.json`, erzeugt von `tools/make_spieltest_fixture.gd`.

## Tests

`npm test` vollständig grün:

```
OK   DAME: ALL_TESTS_OK checks=9495 suites=15
OK   DAME-Fluss: FLOW_OK
OK   Latte-Fluss: REENTRY_OK     (jetzt inkl. Innenhof → DAME-Tisch → Innenhof mit echtem Szenenwechsel)
OK   Lobby-Loop: Passing Tests 145
OK   Latte: Passing Tests 111    (vorher 87)
Node: 9 Tests (4 neu für die Auswertung)
```

Neu: `test_bank_dame.gd` (19 Tests) und fünf Tests in `test_vorgang_ui.gd`. Sie prüfen Konfiguration und Seed, `match_id`-Bindung in Weltkern **und** Adapter, Fortsetzen und Abbruch, Raumwechsel nur für die Begegnung, Seidels Weg, Aktenhilfe (nur eigenes Wissen, kostet nichts), amtliche Fassung, die Akte-Seite. Drei Mutationsproben (Kern prüft `match_id` nicht, Adapter prüft sie nicht, Seidel bleibt am Morgen im Hinterzimmer) werden jeweils von mindestens einem Test erkannt. Den Tisch habe ich auf einem Screenshot unter Xvfb gesehen: Amtsstuben-Raum, Mertens und Seidel mit Namen am Tisch.

## Neue Entwurfsentscheidungen in E3

Revidierbar, keine Nutzervorgaben.

| ID | Entscheidung | Grund |
|---|---|---|
| E3-01 | DAME mit drei Plätzen (Spieler, Mertens, Seidel), KI „mittel“, Seed aus dem Durchlauf | Figuren bleiben dieselben (Kap. 9.6); gleicher Durchlauf, gleiche Verteilung |
| E3-02 | Ergebnis gilt nur mit der `match_id` der Session | Verhindert, dass eine freie oder Karriere-Partie den Vorgang entscheidet |
| E3-03 | Fortsetzen über DAMEs Spielstand, gebunden an die `match_id` | DAME kann das schon; ein Spielstand einer anderen Partie wird nie angeboten |
| E3-04 | Seidel ist abends im Hinterzimmer, morgens in der Registratur | Sie sitzt am Tisch; sonst wäre die Partie eine falsche Kontinuität |
| E3-05 | Amtsstube nur für die Begegnung, Raumwahl wird zurückgegeben | Hinterzimmer = derselbe Ort; die Wahl des Spielers bleibt seine |
| E3-06 | Blende statt Überblendung zwischen Räumen; entfällt bei reduzierter Bewegung | Kap. 12.1 erlaubt einen sichtbaren Übergang; Kap. 12.3 verlangt Reduzierbarkeit |
| E3-07 | Aktenhilfe antwortet nur aus eigenen Handlungen und Einträgen | Kap. 11.3: „nur bereits erworbenes Wissen“; Aufmerksamkeit bleibt verdeckt (Kap. 12.2) |
| E3-08 | Akte zeigt amtliche Fassung und Tatsächliches nebeneinander | Kap. 13.1: Abweichung darf bestehen, die Historie bleibt |
| E3-09 | Minispiele ohne Entwicklungsansicht anbieten; Abkürzungen nur in Debug-Builds | Beide Spiele sind jetzt echt (E1-11 entfällt) |

## Grenzen

- **DAME-Ergebnisse sind nicht nachprüfbar.** Anders als die Widerlegung (E2) lässt sich eine DAME-Partie mit menschlichen Zügen nicht aus einem Seed nachspielen. Die `match_id`-Bindung schützt vor Verwechslung, nicht vor einem Spieler, der den lokalen Spielstand selbst verändert. Für ein Einzelspieler-Spiel ohne Rangliste ist das hier akzeptiert (Kap. 8.3: keine Pflicht, keine Schlüsselfunktion).
- **Übergang und Tisch sind nur auf Standbildern geprüft,** nicht als Bewegung. Ob die Blende angenehm wirkt, zeigt erst das Spiel.
- **Der Innenhof bleibt ein Klickprototyp.** Nur das Hinterzimmer hat eine Raumdarstellung (DAMEs Tisch); Hof, Registratur und Ausschussraum sind Text. Kap. 12.1 verlangt am Ende denselben Ort „vor, während und nach der Partie“; hier steht davor und danach Text.
- **Das Widerlegungs-Panel** ist weiter das von Lobby-Loop; das „Saalmodell auf dem Ausschusstisch“ (Kap. 8.2) ist noch nicht umgesetzt.
- **Ton im Innenhof fehlt,** Screenreader und schmale Darstellung sind nicht geprüft (Kap. 12.3).
- **Der Spieltest** (Kap. 20.4) steht aus. Erst seine Ergebnisse bestimmen die Überarbeitung (Kap. 24).

## Als Nächstes (E4/E5)

Nach dem Spieltest: Überarbeitung nach Diagnosetabelle (Kap. 20.6). Danach E4 (gemeinsame Hülle und Dienste nur über erprobte Schnittstellen, Offline- und Exportprüfung, Web-Build mit den neuen Autoloads) und E5 (zweiter Vorgang aus denselben Regeln). Ein Web-Export mit den neuen Dateien ist noch nicht gebaut.
