# Systemisches Game-Design Framework
**Ansätze zur Synthese von Action, Strategie und fraktaler Systemik für unabhängige Entwickler**

Dieses Dokument fasst die systemischen Mechaniken, Konflikte und Lösungsansätze zusammen, um als Fundament für die Entwicklung eines neuartigen, skalierbaren Spiels zu dienen. Der Fokus liegt auf Systemik (Regelwerke, Physik, Kombinatorik, System-Grammatik) statt auf statischem Content (Leveldesign, lineare Story, bloßes Feature-Creep).

---

## 1. Die Kern-Philosophie: Das "Fraktale Spiel" & System-Grammatik
Ein nachhaltiges Spiel besteht nicht aus einer Ansammlung isolierter Features, sondern ist ein sich selbst tragendes System. 
* **Die System-Grammatik:** Bevor man über Features oder Content nachdenkt, muss die grundlegende "Grammatik" des Systems stehen – die fundamentalen Regeln, die bestimmen, wie Elemente miteinander sprechen und interagieren.
* **Das fraktale Prinzip:** Ein extrem simples, robustes Regelwerk (der Kern), das durch seine Einfachheit und die Kombination seiner Elemente eine tiefe, organische Komplexität erzeugt, ohne in sich zusammenzubrechen. Das System generiert die Varianz und den Content, nicht der handgebaute Pfad.

---

## 2. Der Kernkonflikt: Action vs. Strategie
Das grundlegende Design-Problem vieler Spiele (exemplarisch sichtbar in MOBAs wie *League of Legends*) ist die fehlerhafte Balance zwischen dem **reaktiven Vektor** (Action/Reflexe) und dem **kognitiven Vektor** (Strategie/Planung).

### Die systemischen Fallen (Anti-Patterns)
*   **Stat-Checking:** Mechanischer Skill wird in harte, mathematische Werte (Gold, Level) konvertiert. Ab einem Schwellenwert überschreibt die Mathematik den Skill vollständig; der Spieler verliert seine Handlungsfähigkeit (Agency).
*   **Asymmetrische Sabotage (Geisel-Szenario):** Schlechte Entscheidungen einzelner Mitspieler bestrafen das Kollektiv irreparabel, ohne dass mechanische Kompensation möglich ist.
*   **APM-Illusion:** "Action" wird oft mit reiner Eingabegeschwindigkeit (Tastendruck-Frequenz auf flachen Grids) statt mit echter räumlicher, physikalischer Interaktion verwechselt.

### Die Lösungs-Mechaniken (Bsp. Global Agenda)
*   **TTK (Time-to-Kill) als taktischer Puffer:** Das Zeitfenster bis zur Eliminierung ist so kalibriert, dass Reflexe belohnt werden, aber genug Raum bleibt, um teaminterne Konter und strategische Manöver zu aktivieren.
*   **Ressourcen-gekoppelte Raumkontrolle:** Fortbewegung (z. B. Jetpacks auf der Z-Achse) macht den Raum zu einer Ressource, die in Echtzeit gegen Energie und Cooldowns gemanagt werden muss.
*   **Harte, nicht-skalierbare Konter:** Strategische Elemente (Schilder, Geschütze) erzwingen asymmetrische Antworten, statt sich durch reines Zielen auflösen zu lassen. Taktik passiert direkt im Flow der Action, niemals in statischen Menü-Pausen.

---

## 3. Wahre Klassen-Synergie vs. Künstliche Rollen
Klassen dürfen kein Selbstzweck oder reines Marketing-Feature ("Content") sein.
*   **Synergie als Existenzgrundlage:** Klassen existieren, um systemische Lücken zu füllen. Sie sind Werkzeuge, die erst im Zusammenspiel ihre volle Wirkung entfalten (inspiriert durch *Team Fortress* und *Global Agenda*).
*   **Individuelle Interpretation:** Spieler haben innerhalb der systemischen Grenzen (der Grammatik) die Freiheit, ihre Rolle anzupassen, ohne in starre, linear gedachte Korsetts gezwängt zu werden.
*   **Das Schere-Stein-Papier der Systeme:** Klassen balancieren sich durch asymmetrische Mechaniken aus, die sich gegenseitig bedingen.

---

## 4. Skalierbarkeits-Motoren für Solo-Entwickler
Um als Solo-Entwickler den Content-Flaschenhals zu umgehen, muss das Spiel auf Systemen aufbauen, die unendliche Varianz erzeugen:

1.  **Physik als Emergenz-Motor (Bsp. Badland Brawl):**
    Das System stellt Parameter bereit; das Chaos und die Tiefe entstehen durch physikalische Kettenreaktionen der Spieler.
2.  **Taktische Latenz-Minimierung (Bsp. Iron Marines):**
    Komplexität entsteht durch den fließenden, instanziierten Wechsel von Rollen mitten im Gefecht.
3.  **Kombinatorische Autopoiesis (Bsp. Otherworld Legends):**
    Spieltiefe wächst durch exponentielle Kombinationsmöglichkeiten von Items und Fähigkeiten (RNG-gestützte Logikketten).
4.  **Ökonomische Inversion (Bsp. Necro RPG):**
    Gegner sind Ressourcen. Die Dynamik entsteht durch das Nutzen feindlicher Masse gegen das System selbst.

---

## 5. Manifest für dein Projekt
Richte deinen Prototyp an diesen Pfeilern aus:
1.  **Verstehe die Grammatik:** Baue keine Features, sondern definiere zuerst die elementaren Regeln, wie das System in sich greift.
2.  **Die fraktale Basis:** Eine einzige Kernmechanik muss isoliert funktionieren und durch Kombination organische Komplexität erzeugen.
3.  **Erhaltung der Agency:** Das System darf dem Spieler niemals das Gefühl geben, dass seine Eingaben irrelevant geworden sind (Vermeidung von harten Stat-Check-Wänden).
4.  **Taktik in Bewegung:** Ressourcen, Cooldowns und Loadouts müssen im physischen Raum verwaltet werden, ohne den Action-Flow zu unterbrechen.
5.  **Echte Synergien:** Jedes Element im Spiel muss in messbare Wechselwirkung mit anderen treten können.