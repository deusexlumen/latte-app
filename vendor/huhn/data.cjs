/* DAS GERUPFTE HUHN — Daten
 * Fünf Instanzen. Jede Karte: id, name, icon, m (gehört zum Begriff?), a (Merkmale, die zutreffen), note.
 * Merkmale, die nicht in a stehen, treffen nicht zu.
 */
(function (root) {
  'use strict';

  const RHETORIK = {
    autoritaet: { name: 'Autorität', icon: '🏛️', tele: 'beschlagnahmt eine Karte', rule: 'Die markierte Karte wird beim nächsten Herzschlag beschlagnahmt, wenn du sie bis dahin nicht wirfst.' },
    knappheit: { name: 'Knappheit', icon: '⏳', tele: 'kürzt die Redezeit', rule: 'Beim nächsten Herzschlag verlierst du einen Wurf.' },
    sozial: { name: 'Sozialer Beweis', icon: '👏', tele: 'zieht einen Stützbalken ein', rule: 'Beim nächsten Herzschlag steigt die Tragfähigkeit um 1.' },
    anstrich: { name: 'Anstrich', icon: '🖌️', tele: 'überstreicht eine Ausnahme', rule: 'Beim nächsten Herzschlag wird die jüngste Ausnahme braun überstrichen und wiegt nur noch 1 statt 3.' }
  };

  const KNIFFE = [
    { id: 'laterne', icon: '🏮', name: 'Laterne', quote: '„Ich suche einen Menschen.“', rule: 'Zeigt vor jedem Wurf, wie der Gegner nachbessern würde.', active: false },
    { id: 'fass', icon: '🛢️', name: 'Die Tonne', quote: 'Wohnung, Werkstatt, Weltanschauung.', rule: 'Einmal je Instanz: ganze Hand zurück in den Sack, neu ziehen. Kostet keinen Wurf.', active: true },
    { id: 'huhn2', icon: '🐔', name: 'Zweites Huhn', quote: 'Man nimmt immer eins mehr mit.', rule: 'Jede Instanz: +1 Wurf.', active: false },
    { id: 'sonne', icon: '☀️', name: 'Geh mir aus der Sonne', quote: '„Nur ein wenig zur Seite, bitte.“', rule: 'Der erste Herzschlag jeder Instanz verpufft.', active: false },
    { id: 'uniform', icon: '🪖', name: 'Trödler-Uniform', quote: '„Das sind meine Papiere.“ Köpenick, 1906.', rule: 'Einmal je Instanz: Dein nächstes Gegenbeispiel erzwingt eine Ausnahme statt einer Ergänzung.', active: true },
    { id: 'inspektion', icon: '🔦', name: 'Lizenz zur Boden-Inspektion', quote: 'Wer den Blick senkt, sieht die Risse.', rule: 'Jede Instanz: Tragfähigkeit −1.', active: false },
    { id: 'dudelsack', icon: '🎺', name: 'Dudelsack', quote: 'Mad Jack, Vågsøy 1941. Niemand hatte eine Vorschrift dafür.', rule: 'Dein erstes Gegenbeispiel jeder Instanz legt +1 Last zusätzlich auf den Boden.', active: false },
    { id: 'bettwaermer', icon: '🍳', name: 'Dexters Bettwärmer', quote: 'In die Karibik verschifft. Mit Gewinn.', rule: 'Einmal je Instanz: ziehe 2 zusätzliche Karten.', active: true }
  ];

  const RAENGE = [
    { min: 0, name: 'Bedenkenträger', text: 'Hat die Lehren gelesen, abgeheftet und für tragfähig befunden.' },
    { min: 45, name: 'Zaungast der Vernunft', text: 'Hat gesehen, dass der Boden knarzt. Hat es nicht laut gesagt.' },
    { min: 70, name: 'Huhnwerfer', text: 'Wirft, was die Wirklichkeit hergibt. Trifft gelegentlich.' },
    { min: 88, name: 'Kyniker', text: 'Lässt Lehren unter ihrem eigenen Gewicht einstürzen.' },
    { min: 102, name: 'Kyniker 1. Klasse', text: 'Ganze Institutionen liegen in der Sickergrube. Er sitzt in der Sonne.' },
    { min: 114, name: 'Hof-Diogenes', text: 'Alexander wäre gern er. Er wäre gern niemand.' }
  ];

  const L = (o) => o; // Lesbarkeit

  const INSTANZEN = [
    // ------------------------------------------------------------------ 1
    L({
      id: 'akademie', nr: 1, shortName: 'Akademie', shareIcon: '🏛️',
      ort: 'Akademie zu Athen', jahr: 'um 360 v. Chr.',
      gegner: 'Platon', gegnerTitel: 'Leiter der Akademie',
      siegel: ['AKADEMIE', 'ZU ATHEN', 'PLATON'],
      begriff: 'Mensch', truthYes: 'ist ein Mensch', truthNo: 'ist kein Mensch',
      lehreHead: 'Mensch im Sinne dieser Lehre ist, was',
      startSatz: '„Der Mensch ist ein zweibeiniges Lebewesen ohne Federn.“',
      intro: 'Platon hat den Menschen definiert. Die Schüler klatschen. Der Hörsaal ist voll, das Gebälk alt. Du stehst hinten, mit einem Sack voller Wirklichkeit.',
      hand: 5, wuerfe: 7, cap: 9, laterneLeihgabe: true, fixedHand: ['huhn'],
      rhetorik: ['autoritaet', 'sozial'],
      attrs: {
        lebt: { pos: 'ein Lebewesen ist', neg: 'kein Lebewesen ist', short: 'Lebewesen', icon: '🫀' },
        zweibeinig: { pos: 'auf zwei Beinen geht', neg: 'nicht auf zwei Beinen geht', short: 'zwei Beine', icon: '🦵' },
        federn: { pos: 'Federn trägt', neg: 'keine Federn trägt', short: 'Federn', icon: '🪶' },
        naegel: { pos: 'breite Nägel hat', neg: 'keine breiten Nägel hat', short: 'breite Nägel', icon: '💅' },
        spricht: { pos: 'spricht', neg: 'nicht spricht', short: 'spricht', icon: '🗣️' },
        kleidung: { pos: 'Kleidung trägt', neg: 'keine Kleidung trägt', short: 'Kleidung', icon: '👘' },
        lacht: { pos: 'lacht', neg: 'nicht lacht', short: 'lacht', icon: '😄' },
        schwanz: { pos: 'einen Schwanz hat', neg: 'keinen Schwanz hat', short: 'Schwanz', icon: '〰️' },
        fell: { pos: 'ein Fell hat', neg: 'kein Fell hat', short: 'Fell', icon: '🐾' },
        steuern: { pos: 'Steuern zahlt', neg: 'keine Steuern zahlt', short: 'Steuern', icon: '🪙' },
        schreibt: { pos: 'schreiben kann', neg: 'nicht schreiben kann', short: 'schreibt', icon: '✍️' },
        sterblich: { pos: 'sterblich ist', neg: 'unsterblich ist', short: 'sterblich', icon: '⚱️' }
      },
      start: ['+lebt', '+zweibeinig', '-federn'],
      prisma: ['+naegel', '+spricht', '-fell', '-schwanz', '+kleidung', '+lacht'],
      refMembers: ['sokrates', 'alkibiades'],
      refNon: ['pferd', 'gans'],
      cards: [
        { id: 'sokrates', name: 'Sokrates', icon: '🧔', m: true, a: 'lebt zweibeinig naegel spricht kleidung lacht steuern sterblich', note: 'Hat nie etwas aufgeschrieben. Gilt trotzdem als Mensch.' },
        { id: 'alkibiades', name: 'Alkibiades', icon: '🍷', m: true, a: 'lebt zweibeinig naegel spricht kleidung lacht steuern schreibt sterblich', note: 'Feldherr, Redner, Trinker. Mensch.' },
        { id: 'pferd', name: 'Pferd', icon: '🐎', m: false, a: 'lebt fell schwanz sterblich', note: 'Vier Beine. Fiel nie unter die Lehre.' },
        { id: 'gans', name: 'Gans', icon: '🪿', m: false, a: 'lebt zweibeinig federn schwanz sterblich', note: 'Zwei Beine, aber gefiedert. Das war der Plan.' },

        { id: 'huhn', name: 'Gerupftes Huhn', icon: '🐔', m: false, a: 'lebt zweibeinig schwanz sterblich', note: 'Frisch gerupft. Zwei Beine, keine Federn. Gackert vorwurfsvoll.' },
        { id: 'kaenguru', name: 'Känguru', icon: '🦘', m: false, a: 'lebt zweibeinig schwanz fell sterblich', note: 'Hüpft auf zwei Beinen. Hat keine Steuernummer.' },
        { id: 'schimpanse', name: 'Zirkusaffe in Hosen', icon: '🐒', m: false, a: 'lebt zweibeinig naegel kleidung lacht fell sterblich', note: 'Geht aufrecht, trägt Hosen, lacht über Platon. Bleibt ein Affe.' },
        { id: 'tanzbaer', name: 'Tanzbär', icon: '🐻', m: false, a: 'lebt zweibeinig kleidung fell schwanz sterblich', note: 'Tanzt aufrecht, trägt eine Rüschenkrause. Hat Krallen, keine Nägel.' },
        { id: 'kyklop', name: 'Kyklop Polyphem', icon: '👁️', m: false, a: 'lebt zweibeinig naegel spricht kleidung sterblich', note: 'Ein Auge, zwei Beine, ein Schaffell als Mantel. Lacht nie. Ein Riese.' },
        { id: 'hermes', name: 'Hermes als Wanderer', icon: '🧳', m: false, a: 'lebt zweibeinig naegel spricht kleidung lacht schreibt', note: 'Ein Gott in Reisekleidung. Bittet um Wasser, zahlt keine Steuern, stirbt nie.' },

        { id: 'echo', name: 'Echo, die Nymphe', icon: '🗻', m: false, a: 'lebt zweibeinig naegel spricht kleidung sterblich', note: 'Kann nur wiederholen, was andere sagen. Lacht nie zuerst. Eine Nymphe.' },
        { id: 'satyr', name: 'Satyr', icon: '🐐', m: false, a: 'lebt zweibeinig naegel spricht lacht fell schwanz sterblich', note: 'Bocksbeine, Schwanz, beste Laune. Bei jedem Symposion dabei.' },

        { id: 'saeugling', name: 'Säugling', icon: '👶', m: true, a: 'lebt naegel lacht kleidung sterblich', note: 'Krabbelt auf vieren. Spricht nicht. Lacht über alles.' },
        { id: 'veteran', name: 'Veteran mit Holzbein', icon: '🦿', m: true, a: 'lebt naegel spricht kleidung lacht steuern schreibt sterblich', note: 'Ein Bein bei Marathon gelassen. Zahlt trotzdem Steuern.' },
        { id: 'pythagoreer', name: 'Pythagoreer im Schweigejahr', icon: '🤐', m: true, a: 'lebt zweibeinig naegel kleidung steuern schreibt sterblich', note: 'Fünf Jahre Schweigegebot. Lachen ist ebenfalls untersagt.' },
        { id: 'olympionike', name: 'Olympionike', icon: '🏃', m: true, a: 'lebt zweibeinig naegel spricht lacht steuern sterblich', note: 'Startet nackt, wie es sich in Olympia gehört.' },
        { id: 'schauspieler', name: 'Darsteller aus „Die Vögel“', icon: '🎭', m: true, a: 'lebt zweibeinig naegel spricht kleidung lacht federn steuern schreibt sterblich', note: 'Aristophanes-Kostüm, voll befiedert. Darunter ein Athener.' },
        { id: 'wolfskind', name: 'Wolfskind', icon: '🐺', m: true, a: 'lebt zweibeinig naegel lacht sterblich', note: 'Von Wölfen aufgezogen. Spricht nicht, trägt nichts. Ein Mensch.' },
        { id: 'tithonos', name: 'Tithonos', icon: '⏳', m: true, a: 'lebt zweibeinig naegel spricht kleidung schreibt', note: 'Bekam Unsterblichkeit. Vergaß, ewige Jugend mitzubeantragen.' }
      ],
      lines: {
        add: ['Ein Einwand ohne Rang. Dennoch: Die Lehre wird präzisiert.', 'Gewiss. Gemeint war selbstverständlich auch: …{lit}.', 'Das war mitgedacht. Es steht jetzt auch da.'],
        repair: ['Eine Bestimmung entfällt. Die Lehre wird dadurch klarer, nicht schwächer.', 'Ich streiche, was nie wesentlich war, und setze, was immer gemeint war.'],
        excl: ['Ein Einzelfall. Er wird namentlich ausgenommen.', 'Dieses Ding verdient keine Regel. Es bekommt eine eigene Zeile.'],
        incl: ['Ein Sonderfall. Er wird ausdrücklich eingeschlossen.', 'Selbstverständlich ist auch dies gemeint. Ich schreibe es dazu.'],
        confirm: ['Bestätigt. Die Lehre hält.', 'Exakt wie erwartet.', 'Ein schönes Beispiel. Für mich.'],
        collapse: 'Der Boden gibt nach. Die Akademie verschwindet samt Lehre in der Sickergrube. Platon ergänzt noch im Fallen: „…mit breiten Nägeln.“',
        hold: 'Die Lehre hält. Die Schüler schreiben mit. Exakt wie erwartet.'
      }
    }),

    // ------------------------------------------------------------------ 2
    L({
      id: 'amt', nr: 2, shortName: 'Amt', shareIcon: '📋',
      ort: 'Amt für Systemische Erwartungsreduktion', jahr: 'Abteilung IV · Stelle 04',
      gegner: 'Sachbearbeitung', gegnerTitel: 'nicht besetzt · Rückfragen zwecklos',
      siegel: ['AMT F. SYST.', 'ERWARTUNGS-', 'REDUKTION'],
      begriff: 'Sitzgelegenheit', truthYes: 'ist eine Sitzgelegenheit', truthNo: 'ist keine Sitzgelegenheit',
      lehreHead: 'Sitzgelegenheit im Sinne dieser Verordnung ist, was',
      startSatz: '„Eine Sitzgelegenheit ist ein Möbelstück auf vier Beinen mit Rückenlehne.“',
      intro: 'Das Amt erlässt die Verordnung über Sitzgelegenheiten an Arbeitsstätten. Die Sachbearbeitung ist nicht besetzt, die Verordnung schreibt sich trotzdem fort. Abteilung IV liegt im dritten Stock. Der Boden ist aus den Siebzigern.',
      hand: 5, wuerfe: 7, cap: 9,
      rhetorik: ['knappheit', 'anstrich'],
      attrs: {
        moebel: { pos: 'ein Möbelstück ist', neg: 'kein Möbelstück ist', short: 'Möbel', icon: '🪑' },
        vierbeine: { pos: 'auf vier Beinen steht', neg: 'nicht auf vier Beinen steht', short: 'vier Beine', icon: '🦵' },
        lehne: { pos: 'eine Rückenlehne hat', neg: 'keine Rückenlehne hat', short: 'Lehne', icon: '🔙' },
        sitzflaeche: { pos: 'eine Sitzfläche bietet', neg: 'keine Sitzfläche bietet', short: 'Sitzfläche', icon: '🟫' },
        traegt: { pos: 'einen Erwachsenen trägt', neg: 'keinen Erwachsenen trägt', short: 'trägt 80 kg', icon: '🏋️' },
        genehmigt: { pos: 'behördlich zugelassen ist', neg: 'nicht zugelassen ist', short: 'zugelassen', icon: '🔏' },
        liegen: { pos: 'zum Liegen bestimmt ist', neg: 'nicht zum Liegen bestimmt ist', short: 'zum Liegen', icon: '🛌' },
        innen: { pos: 'für Innenräume bestimmt ist', neg: 'nicht für Innenräume bestimmt ist', short: 'für drinnen', icon: '🏠' },
        tragbar: { pos: 'von einer Person getragen werden kann', neg: 'nicht von einer Person getragen werden kann', short: 'tragbar', icon: '👜' },
        lebt: { pos: 'lebendig ist', neg: 'nicht lebendig ist', short: 'lebendig', icon: '🫀' },
        weich: { pos: 'gepolstert ist', neg: 'ungepolstert ist', short: 'gepolstert', icon: '☁️' },
        rollen: { pos: 'auf Rollen fährt', neg: 'keine Rollen hat', short: 'Rollen', icon: '🛞' }
      },
      start: ['+moebel', '+vierbeine', '+lehne'],
      prisma: ['+sitzflaeche', '+traegt', '+genehmigt', '-liegen', '+innen', '-lebt'],
      refMembers: ['kuechenstuhl', 'sofa'],
      refNon: ['tisch', 'aktenschrank'],
      cards: [
        { id: 'kuechenstuhl', name: 'Küchenstuhl', icon: '🪑', m: true, a: 'moebel vierbeine lehne sitzflaeche traegt genehmigt innen tragbar', note: 'Der Normalfall. Steht im Formular als Beispiel.' },
        { id: 'sofa', name: 'Sofa', icon: '🛋️', m: true, a: 'moebel vierbeine lehne sitzflaeche traegt genehmigt innen weich', note: 'Gepolstert, zugelassen, zu schwer zum Tragen.' },
        { id: 'tisch', name: 'Schreibtisch', icon: '🗃️', m: false, a: 'moebel vierbeine traegt genehmigt innen tragbar', note: 'Vier Beine, keine Lehne. Man arbeitet daran, nicht darauf.' },
        { id: 'aktenschrank', name: 'Aktenschrank (voll)', icon: '🗄️', m: false, a: 'moebel genehmigt innen', note: 'Enthält die Vorgänge 1 bis 4.000. Bewegt sich nicht.' },

        { id: 'buerostuhl', name: 'Bürostuhl', icon: '💺', m: true, a: 'moebel lehne sitzflaeche traegt genehmigt innen tragbar weich rollen', note: 'Fünf Rollen, null Beine. Steht in jedem Amt.' },
        { id: 'melkschemel', name: 'Melkschemel', icon: '🪵', m: true, a: 'moebel sitzflaeche traegt tragbar', note: 'Drei Beine. Wackelt nie. Nie zugelassen.' },
        { id: 'sitzsack', name: 'Sitzsack', icon: '🫘', m: true, a: 'moebel sitzflaeche traegt tragbar weich innen', note: 'Formlos, beinlos, lehnenlos. Bequem.' },
        { id: 'fensternische', name: 'Fensternische, Erfurt 1184', icon: '🪟', m: true, a: 'sitzflaeche traegt', note: 'Fest im Mauerwerk. Hielt als Einzige. Rettete einem König das Leben.' },
        { id: 'latrine', name: 'Latrine', icon: '🚽', m: true, a: 'sitzflaeche traegt innen', note: 'Technisch eine Sitzgelegenheit. Historisch eine Falle.' },
        { id: 'thron', name: 'Thron', icon: '👑', m: true, a: 'moebel vierbeine lehne sitzflaeche traegt weich innen', note: 'Nie beantragt. Nie genehmigt. Wird trotzdem besessen.' },
        { id: 'sattel', name: 'Sattel', icon: '🏇', m: true, a: 'sitzflaeche traegt tragbar weich', note: 'Sitzgelegenheit mit Pferd als Unterbau.' },
        { id: 'karussellpferd', name: 'Karussellpferd', icon: '🎠', m: true, a: 'vierbeine sitzflaeche traegt genehmigt', note: 'Vier Beine, eine Stange, TÜV-geprüft. Kein Möbel.' },
        { id: 'parkbank', name: 'Parkbank', icon: '🌳', m: true, a: 'moebel lehne sitzflaeche traegt genehmigt', note: 'Zwei gusseiserne Füße. Steht im Regen. Ist zugelassen.' },
        { id: 'verbotsstuhl', name: 'Stuhl mit Schild „Nicht benutzen“', icon: '🚫', m: true, a: 'moebel vierbeine lehne sitzflaeche traegt innen tragbar', note: 'Ein Stuhl bleibt ein Stuhl, auch wenn ihn keiner benutzen darf. Zulassung entzogen.' },
        { id: 'rollstuhl', name: 'Rollstuhl', icon: '♿', m: true, a: 'lehne sitzflaeche traegt genehmigt tragbar weich rollen', note: 'Hilfsmittel, kein Möbel. Scheitert regelmäßig an Behördentreppen, nicht an Definitionen.' },
        { id: 'liegestuhl', name: 'Liegestuhl', icon: '⛱️', m: true, a: 'moebel lehne sitzflaeche traegt tragbar genehmigt liegen', note: 'Heißt Stuhl, ist halb zum Liegen. Klappgestell statt Beinen.' },
        { id: 'strandkorb', name: 'Strandkorb', icon: '🏖️', m: true, a: 'moebel lehne sitzflaeche traegt weich', note: 'Steht im Sand. Hat ein Dach und keine Beine.' },

        { id: 'bett', name: 'Bett', icon: '🛏️', m: false, a: 'moebel vierbeine lehne sitzflaeche traegt genehmigt innen weich liegen', note: 'Kopfteil zählt als Lehne. Gedacht ist es zum Liegen.' },
        { id: 'puppenstuhl', name: 'Puppenstuhl', icon: '🧸', m: false, a: 'moebel vierbeine lehne sitzflaeche genehmigt innen tragbar', note: 'Maßstab 1:12. Trägt keinen Erwachsenen.' },
        { id: 'kaputterstuhl', name: 'Stuhl ohne Sitzfläche', icon: '🪚', m: false, a: 'moebel vierbeine lehne genehmigt innen tragbar', note: 'Sitzfläche seit 1998 in Reparatur. Vorgang offen.' },
        { id: 'kniebank', name: 'Kniebank', icon: '🙏', m: false, a: 'moebel vierbeine lehne sitzflaeche traegt innen', note: 'Gepolstertes Brett, Pultlehne. Zum Knien gedacht. Kirchlich, nicht behördlich zugelassen.' },
        { id: 'kuh', name: 'Kuh', icon: '🐄', m: false, a: 'lebt vierbeine sitzflaeche traegt', note: 'Vier Beine, breiter Rücken, trägt einen Erwachsenen. Ist dagegen.' },
        { id: 'mauer', name: 'Gartenmauer', icon: '🧱', m: false, a: 'sitzflaeche traegt', note: 'Man kann darauf sitzen. Gebaut wurde sie zum Trennen.' },
        { id: 'haengematte', name: 'Hängematte', icon: '🪢', m: false, a: 'sitzflaeche traegt tragbar weich liegen', note: 'Man liegt. Man sitzt nur beim Herausfallen.' }
      ],
      lines: {
        add: ['Ihre Eingabe wurde zur Kenntnis genommen. Die Verordnung wird ergänzt.', 'Änderungsbescheid ergeht von Amts wegen.', 'Die Lücke war bekannt. Sie ist jetzt geregelt.'],
        repair: ['Eine Bestimmung wird aufgehoben. Eine andere tritt an ihre Stelle.', 'Novelle. Gilt rückwirkend.'],
        excl: ['Für den vorliegenden Gegenstand wird eine Einzelfallregelung erlassen.', 'Ausnahmetatbestand angelegt. Aktenzeichen folgt.'],
        incl: ['Der Gegenstand wird im Wege der Ausnahme anerkannt.', 'Sondergenehmigung erteilt. Ein Widerspruch ist nicht vorgesehen.'],
        confirm: ['Vorgang ohne Befund.', 'Kein Änderungsbedarf erkennbar.', 'Zu den Akten.'],
        collapse: 'Die Verordnung wiegt mehr als das Gebäude. Abteilung IV ist ab sofort ebenerdig. Eine Rückmeldung ist unerwünscht.',
        hold: 'Die Verordnung tritt in Kraft. Eine Rückmeldung über ihre Wirkung ist unerwünscht.'
      }
    }),

    // ------------------------------------------------------------------ 3
    L({
      id: 'erfurt', nr: 3, shortName: 'Erfurt 1184', shareIcon: '🐟',
      ort: 'Dompropstei zu Erfurt', jahr: 'Juli 1184 · Hoftag',
      gegner: 'Die Fastenkommission', gegnerTitel: 'tagt im Obergeschoss',
      siegel: ['FASTEN-', 'KOMMISSION', 'ERFURT 1184'],
      begriff: 'Fisch', truthYes: 'ist ein Fisch', truthNo: 'ist kein Fisch',
      lehreHead: 'Fisch im Sinne der Fastenordnung ist, was',
      startSatz: '„Ein Fisch ist ein Tier, das im Wasser lebt und schwimmt.“',
      intro: 'Juli 1184. Die Elite des Reiches drängt sich im Obergeschoss der Dompropstei. Die Fastenkommission legt fest, was freitags als Fisch auf den Tisch darf. Unter dem Saal liegt die Sickergrube des Klosters. Die Wirklichkeit heißt hier: Biologie.',
      hand: 5, wuerfe: 7, cap: 11,
      rhetorik: ['anstrich', 'autoritaet'],
      attrs: {
        tier: { pos: 'ein Tier ist', neg: 'kein Tier ist', short: 'Tier', icon: '🐾' },
        wasser: { pos: 'im Wasser lebt', neg: 'nicht im Wasser lebt', short: 'im Wasser', icon: '💧' },
        schwimmt: { pos: 'schwimmt', neg: 'nicht schwimmt', short: 'schwimmt', icon: '🏊' },
        flossen: { pos: 'Flossen hat', neg: 'keine Flossen hat', short: 'Flossen', icon: '🪭' },
        schuppen: { pos: 'Schuppen trägt', neg: 'keine Schuppen trägt', short: 'Schuppen', icon: '🛡️' },
        kiemen: { pos: 'mit Kiemen atmet', neg: 'nicht mit Kiemen atmet', short: 'Kiemen', icon: '🫧' },
        wirbel: { pos: 'eine Wirbelsäule hat', neg: 'keine Wirbelsäule hat', short: 'Wirbelsäule', icon: '🦴' },
        eier: { pos: 'Eier legt', neg: 'keine Eier legt', short: 'legt Eier', icon: '🥚' },
        warm: { pos: 'warmblütig ist', neg: 'kaltblütig ist', short: 'warmblütig', icon: '🌡️' },
        fell: { pos: 'ein Fell hat', neg: 'kein Fell hat', short: 'Fell', icon: '🧶' },
        federn: { pos: 'Federn trägt', neg: 'keine Federn trägt', short: 'Federn', icon: '🪶' },
        beine: { pos: 'Beine hat', neg: 'keine Beine hat', short: 'Beine', icon: '🦵' }
      },
      start: ['+tier', '+wasser', '+schwimmt'],
      prisma: ['+flossen', '-fell', '-federn', '+schuppen', '-beine', '+kiemen', '+eier'],
      refMembers: ['hering', 'karpfen'],
      refNon: ['ochse', 'muschel'],
      cards: [
        { id: 'hering', name: 'Hering', icon: '🐟', m: true, a: 'tier wasser schwimmt flossen schuppen kiemen wirbel eier', note: 'Der Fisch, an den die Kommission denkt.' },
        { id: 'karpfen', name: 'Karpfen', icon: '🎏', m: true, a: 'tier wasser schwimmt flossen schuppen kiemen wirbel eier', note: 'Klosterteich, zweites Becken links.' },
        { id: 'ochse', name: 'Ochse', icon: '🐂', m: false, a: 'tier warm fell beine wirbel', note: 'Fleisch. Freitags verboten. Unstrittig.' },
        { id: 'muschel', name: 'Muschel', icon: '🐚', m: false, a: 'tier wasser eier', note: 'Lebt im Wasser, schwimmt nicht. Liegt herum.' },

        { id: 'hai', name: 'Hai', icon: '🦈', m: true, a: 'tier wasser schwimmt flossen schuppen kiemen wirbel', note: 'Knorpel statt Gräten, bringt lebende Junge zur Welt. Trotzdem Fisch.' },
        { id: 'seepferdchen', name: 'Seepferdchen', icon: '♞', m: true, a: 'tier wasser schwimmt flossen kiemen wirbel eier', note: 'Knochenplatten statt Schuppen. Das Männchen trägt die Eier aus.' },
        { id: 'lungenfisch', name: 'Lungenfisch', icon: '🫁', m: true, a: 'tier wasser schwimmt flossen schuppen wirbel eier', note: 'Atmet mit der Lunge. Überlebt Dürre eingegraben im Schlamm.' },
        { id: 'schlammspringer', name: 'Schlammspringer', icon: '🐡', m: true, a: 'tier schwimmt flossen schuppen kiemen wirbel eier', note: 'Lebt an Land im Watt und klettert auf Mangroven. Ein Fisch.' },
        { id: 'anglerfisch', name: 'Anglerfisch-Männchen', icon: '🎣', m: true, a: 'tier wasser flossen kiemen wirbel', note: 'Verwächst mit dem Weibchen und schwimmt nie wieder.' },
        { id: 'stockfisch', name: 'Stockfisch', icon: '🪝', m: true, a: 'tier flossen wirbel', note: 'Getrocknet, hängt am Gestell. Ein toter Fisch ist ein Fisch. Fragen Sie den Händler.' },
        { id: 'rochen', name: 'Rochen', icon: '🪁', m: true, a: 'tier wasser schwimmt flossen kiemen wirbel eier', note: 'Flach wie eine Verordnung. Keine Schuppen. Ein Fisch.' },

        { id: 'wal', name: 'Wal', icon: '🐋', m: false, a: 'tier wasser schwimmt flossen wirbel warm', note: 'Atmet Luft, säugt Junge. Moby Dick nennt ihn trotzdem Fisch.' },
        { id: 'biber', name: 'Biber', icon: '🦫', m: false, a: 'tier wasser schwimmt schuppen fell wirbel warm beine', note: 'Schuppiger Schwanz. Deshalb im Mittelalter als Fastenspeise geduldet.' },
        { id: 'bernikelgans', name: 'Bernikelgans', icon: '🪿', m: false, a: 'tier wasser schwimmt federn wirbel eier warm beine', note: 'Wächst laut gelehrter Meinung an Treibholz. Darum angeblich fastentauglich.' },
        { id: 'tintenfisch', name: 'Tintenfisch', icon: '🦑', m: false, a: 'tier wasser schwimmt flossen kiemen eier', note: 'Heißt Fisch. Ist eine Schnecke mit Ehrgeiz.' },
        { id: 'qualle', name: 'Qualle', icon: '🪼', m: false, a: 'tier wasser schwimmt', note: 'Zu 98 % Wasser. Der Rest ist schlechte Laune.' },
        { id: 'krokodil', name: 'Krokodil vom Achterdeck', icon: '🐊', m: false, a: 'tier wasser schwimmt schuppen wirbel eier beine', note: 'Zugestiegen auf Madagaskar, 1905. Frisst Seekarten.' },
        { id: 'kaulquappe', name: 'Kaulquappe', icon: '🐸', m: false, a: 'tier wasser schwimmt flossen kiemen wirbel', note: 'Kiemen, Flossensaum, Wirbelsäule. Wird später ein Frosch.' },
        { id: 'axolotl', name: 'Axolotl', icon: '🦎', m: false, a: 'tier wasser schwimmt flossen kiemen wirbel eier beine', note: 'Kiemen außen, Flossensaum, vier Beinchen. Ein Lurch, der nie erwachsen wird.' },
        { id: 'robbe', name: 'Robbe', icon: '🦭', m: false, a: 'tier wasser schwimmt flossen fell warm wirbel', note: 'Flossen, Fell, Fischgeruch. Säugetier.' },
        { id: 'garnele', name: 'Garnele', icon: '🦐', m: false, a: 'tier wasser schwimmt kiemen beine eier', note: 'Zehn Beine, Kiemen, kein Rückgrat.' },
        { id: 'schildkroete', name: 'Meeresschildkröte', icon: '🐢', m: false, a: 'tier wasser schwimmt flossen schuppen wirbel eier', note: 'Flossen, Schuppen, Eier, Wirbelsäule. Atmet Luft.' }
      ],
      lines: {
        add: ['Im Namen der Kommission: Die Fastenordnung wird ergänzt.', 'Ein frommer Hinweis. Er wird Gesetz.', 'Wir hatten das stets so gemeint. Nun steht es da.'],
        repair: ['Die Kommission verwirft eine Bestimmung und setzt eine bessere ein.', 'Was gestern galt, galt nie. Ab heute gilt dies.'],
        excl: ['Dieses Geschöpf wird ausdrücklich vom Freitagstisch verwiesen.', 'Für dieses eine Tier ergeht ein eigener Bescheid.'],
        incl: ['Dieses Geschöpf gilt fortan als Fisch. Ausnahmsweise.', 'Der Bischof isst es ohnehin. Es wird eingeschlossen.'],
        confirm: ['Die Kommission nickt.', 'Bekannt. Abgelegt.', 'Exakt wie erwartet.'],
        collapse: 'Das Gebälk bricht. Die Kommission stürzt zwei Stockwerke tief in die Sickergrube der Dompropstei. Der König hält sich in der Fensternische fest.',
        hold: 'Die Fastenordnung steht. Das Gebälk hält. Noch.'
      }
    }),

    // ------------------------------------------------------------------ 4
    L({
      id: 'division7b', nr: 4, shortName: 'Division 7B', shareIcon: '👁️',
      ort: 'Division 7B · Metaphysische Dienste', jahr: 'Postfach 0 · 00000 Nirgendwo',
      gegner: 'Die Klassifizierungsstelle', gegnerTitel: 'Formular 7b-BLANK, Feld 4 · kein Kundendienst',
      siegel: ['DIVISION 7B', 'METAPHYS.', 'DIENSTE'],
      begriff: 'Lebewesen', truthYes: 'ist ein Lebewesen', truthNo: 'ist kein Lebewesen',
      lehreHead: 'Lebewesen im Sinne der Dienstvorschrift MD-7B ist, was',
      startSatz: '„Ein Lebewesen ist, was wächst und sich bewegt.“',
      intro: 'Division 7B führt das Register der Lebewesen, damit Entitäten ordentlich abgelehnt werden können. Abgelegt wird nach Aussehen. Die Wirklichkeit heißt hier: Biologie, ergänzt um zwei Gutachten der Division.',
      hand: 5, wuerfe: 7, cap: 10,
      rhetorik: ['sozial', 'knappheit'],
      attrs: {
        waechst: { pos: 'wächst', neg: 'nicht wächst', short: 'wächst', icon: '🌱' },
        bewegt: { pos: 'sich selbst bewegt', neg: 'sich nicht selbst bewegt', short: 'bewegt sich', icon: '🏃' },
        atmet: { pos: 'Sauerstoff veratmet', neg: 'keinen Sauerstoff veratmet', short: 'atmet', icon: '🌬️' },
        vermehrt: { pos: 'sich vermehrt', neg: 'sich nicht vermehrt', short: 'vermehrt sich', icon: '🐣' },
        zellen: { pos: 'aus Zellen besteht', neg: 'nicht aus Zellen besteht', short: 'Zellen', icon: '🧫' },
        frisst: { pos: 'Nahrung aufnimmt', neg: 'keine Nahrung aufnimmt', short: 'frisst', icon: '🍽️' },
        reagiert: { pos: 'auf Reize reagiert', neg: 'nicht auf Reize reagiert', short: 'reagiert', icon: '⚡' },
        erbgut: { pos: 'Erbgut trägt', neg: 'kein Erbgut trägt', short: 'Erbgut', icon: '🧬' },
        warm: { pos: 'Wärme abgibt', neg: 'keine Wärme abgibt', short: 'warm', icon: '🌡️' },
        akte: { pos: 'bei Division 7B aktenkundig ist', neg: 'nicht aktenkundig ist', short: 'aktenkundig', icon: '🗂️' },
        stirbt: { pos: 'sterben oder vergehen kann', neg: 'nicht vergehen kann', short: 'vergänglich', icon: '⚱️' }
      },
      start: ['+waechst', '+bewegt'],
      prisma: ['+reagiert', '+frisst', '+stirbt', '+vermehrt', '+atmet', '+warm'],
      refMembers: ['hund', 'leiterin'],
      refNon: ['stein', 'kaffeeautomat'],
      cards: [
        { id: 'hund', name: 'Hund', icon: '🐕', m: true, a: 'waechst bewegt atmet vermehrt zellen frisst reagiert erbgut warm stirbt', note: 'Lebt. Bellt Entitäten an.' },
        { id: 'leiterin', name: 'Abteilungsleiterin 7B', icon: '👩‍💼', m: true, a: 'waechst bewegt atmet vermehrt zellen frisst reagiert erbgut warm stirbt akte', note: 'Lebt. Ist aktenkundig. Beides ungefragt.' },
        { id: 'stein', name: 'Stein', icon: '🪨', m: false, a: '', note: 'Liegt. Liegt weiter.' },
        { id: 'kaffeeautomat', name: 'Kaffeeautomat, 3. OG', icon: '☕', m: false, a: 'frisst reagiert warm akte', note: 'Frisst Münzen, reagiert gelegentlich, Störungsmeldung 7B-K-3.' },

        { id: 'eiche', name: 'Eiche', icon: '🌳', m: true, a: 'waechst atmet vermehrt zellen reagiert erbgut stirbt', note: 'Bewegt sich in 800 Jahren keinen Meter.' },
        { id: 'schimmel', name: 'Schimmel in der Kantine', icon: '🍄', m: true, a: 'waechst atmet vermehrt zellen frisst erbgut stirbt akte', note: 'Wächst seit 2019. Dreimal gemeldet, nie bearbeitet.' },
        { id: 'maultier', name: 'Maultier', icon: '🫏', m: true, a: 'waechst bewegt atmet zellen frisst reagiert erbgut warm stirbt', note: 'Unfruchtbar. Lebt trotzdem, aus Prinzip.' },
        { id: 'baertierchen', name: 'Bärtierchen (eingetrocknet)', icon: '🐛', m: true, a: 'zellen erbgut stirbt', note: 'In Kryptobiose. Übersteht Vakuum, Strahlung und Montage.' },
        { id: 'koralle', name: 'Koralle', icon: '🪸', m: true, a: 'waechst atmet vermehrt zellen frisst reagiert erbgut stirbt', note: 'Ein Tier, das aussieht wie ein Stein, der aussieht wie eine Pflanze.' },
        { id: 'hefe', name: 'Hefe im Teig', icon: '🍞', m: true, a: 'waechst vermehrt zellen frisst erbgut stirbt', note: 'Gärt ohne Sauerstoff. Lebt trotzdem.' },
        { id: 'samen', name: 'Samenkorn (ruhend)', icon: '🌰', m: true, a: 'atmet zellen erbgut stirbt', note: 'Tut seit Jahren nichts. Lebt, auf Abruf.' },
        { id: 'turritopsis', name: 'Unsterbliche Qualle', icon: '🎐', m: true, a: 'waechst bewegt atmet vermehrt zellen frisst reagiert erbgut', note: 'Verjüngt sich bei Bedarf. Stirbt nicht. Lebt.' },
        { id: 'darmbakterium', name: 'Darmbakterium', icon: '🦠', m: true, a: 'waechst bewegt vermehrt zellen frisst reagiert erbgut stirbt', note: 'Schwimmt mit Geißel, braucht keinen Sauerstoff, gibt keine Wärme ab.' },
        { id: 'fliegenfalle', name: 'Venusfliegenfalle', icon: '🪴', m: true, a: 'waechst bewegt atmet vermehrt zellen frisst reagiert erbgut stirbt', note: 'Eine Pflanze, die zuschnappt.' },

        { id: 'feuer', name: 'Feuer', icon: '🔥', m: false, a: 'waechst bewegt atmet vermehrt frisst reagiert warm stirbt', note: 'Wächst, frisst, atmet, vermehrt sich, stirbt. Ist trotzdem nur Feuer.' },
        { id: 'wirbelsturm', name: 'Wirbelsturm', icon: '🌪️', m: false, a: 'waechst bewegt frisst stirbt', note: 'Wächst über warmem Wasser, zieht weiter, vergeht. Hat einen Vornamen.' },
        { id: 'schattenesser', name: 'Der Schattenesser (EB-004)', icon: '👤', m: false, a: 'waechst bewegt frisst reagiert akte', note: 'Entität. Frisst Schatten. Besteht aus nichts Nachweisbarem.' },
        { id: 'konzern', name: 'Konzern (juristische Person)', icon: '🏢', m: false, a: 'waechst frisst vermehrt reagiert akte stirbt', note: 'Rechtlich eine Person. Biologisch Papier.' },
        { id: 'geruecht', name: 'Gerücht', icon: '🗣️', m: false, a: 'waechst bewegt vermehrt stirbt', note: 'Wächst, wandert, vermehrt sich. Stirbt an Langeweile.' },
        { id: 'tamagotchi', name: 'Tamagotchi', icon: '🥚', m: false, a: 'waechst frisst reagiert stirbt', note: 'Stirbt, wenn man es vergisst. Ist trotzdem Plastik.' },
        { id: 'zombie', name: 'Untoter (Akte offen)', icon: '🧟', m: false, a: 'bewegt frisst reagiert zellen erbgut stirbt', note: 'Zellen, Erbgut, Appetit. Atmet nicht. Laut 7B: tot, aber mobil.' }
      ],
      lines: {
        add: ['Klassifizierung angepasst. Fehlercode CL_001: Regel als selbstverständlich behandelt.', 'Ergänzung vorgenommen. Der Vorgang gilt als gelöst.', 'Feld 4 wurde erweitert. Rückfragen werden automatisch abgelehnt.'],
        repair: ['Ein Kriterium wird außer Dienst gestellt. Ersatz wird aus dem Bestand gezogen.', 'Revision 1.1. Die alte Fassung hat nie existiert.'],
        excl: ['Einzelakte angelegt. Status: ausgenommen. Begründung: unbekannt.', 'Für diesen Fall gilt Fehlercode MG_004. Er wird ausgenommen.'],
        incl: ['Sonderfall registriert. Lebt laut Akte.', 'Manuelle Aufnahme ins Register. Das ist ausreichend.'],
        confirm: ['Ausreichend.', 'Abgelegt. Und es ist ausreichend.', 'Exakt wie erwartet.'],
        collapse: 'Das Register wiegt mehr als die Etage. Division 7B liegt in der Sickergrube. Und es ist ausreichend.',
        hold: 'Das Register hält. Die Etage auch. Und das ist ausreichend.'
      }
    }),

    // ------------------------------------------------------------------ 5
    L({
      id: 'spiel', nr: 5, shortName: 'Spielgesetz', shareIcon: '🎲',
      ort: 'Kommission zur Normierung des Vergnügens', jahr: 'Plenarsaal · Schlusslesung',
      gegner: 'Die Kommission', gegnerTitel: 'tagt bis zur abschließenden Regelung',
      siegel: ['KOMMISSION', 'NORMIERUNG', 'D. VERGNÜGENS'],
      begriff: 'Spiel', truthYes: 'heißt ein Spiel', truthNo: 'heißt kein Spiel',
      lehreHead: 'Spiel im Sinne dieses Gesetzes ist, was',
      startSatz: '„Ein Spiel hat feste Regeln, einen Gewinner und keinen ernsten Zweck.“',
      intro: 'Die Kommission will gesetzlich regeln, was ein Spiel ist. Ein gewisser Ludwig W. hat schriftlich davor gewarnt: Man finde keine Eigenschaft, die allen Spielen gemeinsam ist, nur Verwandtschaften. Die Warnung liegt ungelesen im Eingangskorb. Die Wirklichkeit heißt hier: Sprachgebrauch.',
      hand: 5, wuerfe: 8, cap: 13,
      rhetorik: ['autoritaet', 'anstrich', 'knappheit'],
      attrs: {
        regeln: { pos: 'feste Regeln hat', neg: 'keine festen Regeln hat', short: 'Regeln', icon: '📜' },
        gewinner: { pos: 'einen Gewinner kennt', neg: 'keinen Gewinner kennt', short: 'Gewinner', icon: '🏆' },
        ernst: { pos: 'einem ernsten Zweck dient', neg: 'keinem ernsten Zweck dient', short: 'ernster Zweck', icon: '⚖️' },
        spass: { pos: 'Spaß macht', neg: 'keinen Spaß macht', short: 'Spaß', icon: '😄' },
        freiwillig: { pos: 'freiwillig geschieht', neg: 'verpflichtend ist', short: 'freiwillig', icon: '🕊️' },
        mehrere: { pos: 'mehrere Beteiligte braucht', neg: 'allein möglich ist', short: 'mehrere', icon: '👥' },
        zufall: { pos: 'vom Zufall abhängt', neg: 'nicht vom Zufall abhängt', short: 'Zufall', icon: '🎲' },
        geschick: { pos: 'Geschick verlangt', neg: 'kein Geschick verlangt', short: 'Geschick', icon: '🎯' },
        material: { pos: 'Spielzeug oder Material braucht', neg: 'ohne Material auskommt', short: 'Material', icon: '🧩' },
        geld: { pos: 'um Geld geht', neg: 'nicht um Geld geht', short: 'Geld', icon: '💰' },
        ende: { pos: 'ein festes Ende hat', neg: 'kein festes Ende hat', short: 'Ende', icon: '🏁' },
        zuschauer: { pos: 'Zuschauer hat', neg: 'ohne Zuschauer auskommt', short: 'Zuschauer', icon: '👀' }
      },
      start: ['+regeln', '+gewinner', '-ernst'],
      prisma: ['+spass', '+freiwillig', '+mehrere', '+material', '-geld', '+ende', '+geschick'],
      refMembers: ['schach', 'fussball'],
      refNon: ['steuer', 'krieg'],
      cards: [
        { id: 'schach', name: 'Schach', icon: '♟️', m: true, a: 'regeln gewinner spass freiwillig mehrere geschick material ende', note: 'Das Spiel, an das die Kommission denkt.' },
        { id: 'fussball', name: 'Fußballspiel', icon: '⚽', m: true, a: 'regeln gewinner spass freiwillig mehrere geschick material ende zuschauer', note: 'Heißt so. Ist so.' },
        { id: 'steuer', name: 'Steuererklärung', icon: '🧾', m: false, a: 'regeln ernst ende', note: 'Regeln: ja. Frist: ja. Spiel: nein.' },
        { id: 'krieg', name: 'Krieg', icon: '⚔️', m: false, a: 'regeln gewinner mehrere ernst zufall', note: 'Hat sogar eine Landkriegsordnung. Ist kein Spiel.' },

        { id: 'ringelreihen', name: 'Ringelreihen', icon: '💃', m: true, a: 'regeln spass freiwillig mehrere ende', note: 'Am Ende fallen alle hin. Gewonnen hat niemand.' },
        { id: 'ballwand', name: 'Ball gegen die Wand', icon: '🏐', m: true, a: 'spass freiwillig geschick material', note: 'Ein Kind, eine Wand, kein Regelwerk. Ludwig W. nannte es trotzdem Spiel.' },
        { id: 'patience', name: 'Patience', icon: '🃏', m: true, a: 'regeln spass freiwillig zufall material ende', note: 'Man spielt allein und verliert gegen niemanden.' },
        { id: 'kriegsspiel', name: 'Preußisches Kriegsspiel', icon: '🗺️', m: true, a: 'regeln gewinner mehrere ernst zufall geschick material ende', note: 'Offiziersausbildung, 1824. Pflicht, ernst gemeint, heißt trotzdem Spiel.' },
        { id: 'lotto', name: 'Lotto', icon: '🎱', m: true, a: 'regeln gewinner freiwillig mehrere zufall geld ende zuschauer', note: 'Kein Geschick, kaum Spaß, viel Geld. Heißt Glücksspiel.' },
        { id: 'marathon', name: 'Olympia-Marathon 1904', icon: '🏃', m: true, a: 'regeln gewinner mehrere freiwillig geschick ende zuschauer', note: 'Ein Sieger auf Rattengift, einer fuhr im Auto. Offiziell Teil der Spiele.' },
        { id: 'verstecken', name: 'Verstecken', icon: '🙈', m: true, a: 'regeln spass freiwillig mehrere', note: 'Endet, wenn jemand zum Essen ruft.' },
        { id: 'puzzle', name: 'Puzzle', icon: '🧩', m: true, a: 'spass freiwillig geschick material ende', note: 'Ein Geduldsspiel. Ohne Gegner, ohne Sieger.' },
        { id: 'poker', name: 'Pokern', icon: '♠️', m: true, a: 'regeln gewinner spass freiwillig mehrere zufall geschick material geld ende', note: 'Geld, Glück, Geschick. Zweifellos ein Spiel.' },

        { id: 'boerse', name: 'Börsenhandel', icon: '📈', m: false, a: 'regeln gewinner freiwillig mehrere zufall geld', note: 'Regeln, Gewinner, Zufall. Endet nie.' },
        { id: 'gericht', name: 'Gerichtsverfahren', icon: '⚖️', m: false, a: 'regeln gewinner mehrere ernst ende zuschauer', note: 'Eine Partei gewinnt. Gespielt hat keine.' },
        { id: 'preis', name: 'Preisverleihung', icon: '🏅', m: false, a: 'gewinner mehrere zuschauer ende freiwillig', note: 'Es gibt einen Gewinner. Gespielt hat niemand.' },
        { id: 'walzer', name: 'Wiener Walzer', icon: '🕺', m: false, a: 'regeln spass freiwillig mehrere geschick ende', note: 'Feste Schritte, viel Spaß, kein Sieger. Ein Tanz.' },
        { id: 'wette', name: 'Wette unter Kollegen', icon: '🤝', m: false, a: 'regeln gewinner spass freiwillig mehrere zufall geld ende', note: 'Um einen Kasten Bier. Eine Wette, kein Spiel.' },
        { id: 'assessment', name: 'Assessment-Center', icon: '📋', m: false, a: 'regeln gewinner mehrere ernst geschick ende', note: 'Nennt seine Übungen Rollenspiele. Ist keins.' }
      ],
      lines: {
        add: ['Die Kommission ergänzt § 1. Vergnügen braucht Ordnung.', 'Änderungsantrag angenommen. Einstimmig, bei einer Enthaltung.', 'Die Definition wird nachgeschärft.'],
        repair: ['§ 1 wird neu gefasst. Die Kommission bedauert nichts.', 'Ein Merkmal entfällt, ein anderes rückt nach.'],
        excl: ['Dieser Fall wird ausdrücklich ausgeschlossen. Spaß hin oder her.', 'Ausnahme nach § 2. Eine Begründung folgt nie.'],
        incl: ['Dieser Fall gilt kraft Gesetzes als Spiel.', 'Eingeschlossen. Die Kommission spielt es ab sofort selbst.'],
        confirm: ['Die Kommission nimmt das zur Kenntnis.', 'Kein Handlungsbedarf.', 'Exakt wie erwartet.'],
        collapse: 'Das Gesetz bricht unter seinen Ausnahmen zusammen. Was ein Spiel ist, weiß jetzt wieder jeder. Sagen kann es keiner.',
        hold: 'Das Gesetz tritt in Kraft. Ab morgen ist Spielen genehmigungspflichtig.'
      }
    })
  ];

  const DATA = { instanzen: INSTANZEN, rhetorik: RHETORIK, kniffe: KNIFFE, raenge: RAENGE };
  if (typeof module !== 'undefined' && module.exports) module.exports = DATA;
  else root.HuhnData = DATA;
})(typeof window !== 'undefined' ? window : globalThis);
