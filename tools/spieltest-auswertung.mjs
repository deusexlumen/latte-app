// PURPOSE: Wertet den Spielstand einer Testperson von BANK-01 aus (Spezifikation 0.1, Kap. 20.4/20.5): gewählter Weg, Aufwand, erworbene Belege, Minispiele, Bericht, sichtbare Folgen.
// PURPOSE: Das Skript liest nur die Spieldatei (amt_vorgang.json) und fasst zusammen, was im Protokoll steht. Es bewertet weder Verständnis noch Spielspaß; dafür gibt es die Fragen und den Beobachtungsbogen.
// ARCHITECTURE: tools
// DEPENDENCIES: node:fs, cases/bank_01/bank_01.json
// PIPELINE: test
// LAST_VALIDATED: 2026-10-18
//
// Aufruf: node tools/spieltest-auswertung.mjs <amt_vorgang.json> [--json]

import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const CONTENT = JSON.parse(readFileSync(join(ROOT, 'cases/bank_01/bank_01.json'), 'utf8'));
const CASE = 'BANK-01';

/** Wiedererkennungspunkte der Rückwirkung (Kap. 7.2): Was der Spieler im Nachgang sehen konnte. */
const FOLLOWUP_SIGNS = {
  rule_issued: 'Neues Schild im Hof und Prüfanforderung PA-12 mit dem eigenen Wortlaut',
  statement: 'Frau Seidel: »Die Originale haben wir wegen Ihrer Prüfung umgelagert.«',
  reminder_sent: 'Hauspost: Erinnerung zur Ausnahme',
  return_slip_sent: 'Hauspost: Rückgabezettel zum Klappstuhl',
  case_filed: 'Hauspost: Ablagevermerk',
  registry_inquiry: 'Rückfrage der Registratur zum Bericht',
  thanks: 'Mitarbeiter des Ausschussbüros bedankt sich für den Hinweis',
};

export function analyze(state) {
  const c = state.cases[CASE];
  const events = state.events;
  const count = (type) => events.filter((e) => e.type === type).length;
  const sessions = Object.values(state.sessions);
  const ofGame = (game) => sessions.filter((s) => s.game === game);
  const hearing = ofGame('widerlegung');
  const dame = ofGame('dame');
  const evidence = Object.values(state.evidence).map((e) => ({
    id: e.evidence_id,
    art: CONTENT.kinds[e.kind],
    zeit: `${e.observed_at.phase}, Handlung ${e.observed_at.turn}`,
    quelle: e.source_id,
  }));
  const has = (id) => id in state.evidence;
  const report = c.report && c.report.antrag ? c.report : null;
  const used = 8 - c.hours_remaining;
  return {
    run_id: state.run_id,
    phase: state.phase,
    status: c.status,
    abschluss: c.resolution || null,
    amtlich: CONTENT.official[c.resolution || 'open'],
    tatsaechlich: { kern_sitzt: state.actors.kern.seat || 'steht', bank: state.objects.bench.access, stuhl: state.objects.chair.available },
    aufwand: { diensthandlungen: used, von: 8, befehle: state.applied_transactions.length, ereignisse: events.length },
    handlungen: {
      umgesehen: count('observed'),
      befragt: count('interviewed'),
      angefordert: count('document_requested'),
      verglichen: count('compared'),
      stuhl_erbeten: count('help_promised'),
      zeit_verstrichen: count('time_passed'),
    },
    belege: evidence,
    wege: {
      augenzeuge_umlagerung: has('B-06'),
      aussage_zur_umlagerung: has('S-02'),
      verfahrensblatt: has('B-05'),
      eigener_abgleich: ['B-03', 'F-01', 'F-02'].filter(has),
    },
    dame: dame.map((s) => ({ status: s.status, ausgang: s.outcome || null })),
    widerlegung: hearing.map((s) => ({
      status: s.status,
      ausgang: s.outcome || null,
      karten: s.checkpoint.plays.length,
      punkte: s.score,
    })),
    bericht: report && {
      antrag: report.antrag,
      feststellungen: report.findings,
      schlussfolgerung: report.conclusion,
      status: report.conclusion_status,
      offene_fragen: report.open_questions,
      rueckfrage: report.inquiry || null,
      wortlaut: report.wording || null,
    },
    nachgang_erreicht: state.phase === 'nachgang',
    sichtbare_folgen: events.filter((e) => e.type in FOLLOWUP_SIGNS).map((e) => FOLLOWUP_SIGNS[e.type]),
    regeln: state.rules.map((r) => `${r.rule_id} (Herkunft ${r.herkunft})`),
  };
}

const yn = (b) => (b ? 'ja' : 'nein');
const list = (a) => (a.length ? a.join(', ') : 'keine');

export function format(r) {
  const out = [];
  out.push(`Durchlauf ${r.run_id}: Phase ${r.phase}, Vorgang ${r.status}`);
  out.push(`Abschluss: ${r.abschluss ?? 'noch keiner'}`);
  out.push(`  Amtlich:       ${r.amtlich}`);
  const seat = { bench: 'sitzt auf der Bank', chair: 'sitzt auf dem Klappstuhl' }[r.tatsaechlich.kern_sitzt] ?? 'steht';
  const bank = { open: 'freigegeben', temporary: 'befristet freigegeben', blocked: 'gesperrt' }[r.tatsaechlich.bank] ?? r.tatsaechlich.bank;
  out.push(`  Tatsächlich:   Frau Kern ${seat}, Bank ${bank}, Klappstuhl im Hof: ${yn(r.tatsaechlich.stuhl)}`);
  out.push(`Aufwand: ${r.aufwand.diensthandlungen} von ${r.aufwand.von} Diensthandlungen, ${r.aufwand.befehle} Befehle, ${r.aufwand.ereignisse} Ereignisse`);
  const h = r.handlungen;
  out.push(`Handlungen: ${h.umgesehen}× umgesehen, ${h.befragt}× befragt, ${h.angefordert}× angefordert, ${h.verglichen}× verglichen, Stuhl erbeten ${h.stuhl_erbeten}×, Zeit verstrichen ${h.zeit_verstrichen}×`);
  out.push(`Belege (${r.belege.length}): ${list(r.belege.map((b) => `${b.id} [${b.art}]`))}`);
  out.push(`Wege: Umlagerung selbst gesehen ${yn(r.wege.augenzeuge_umlagerung)}, nur als Aussage ${yn(r.wege.aussage_zur_umlagerung && !r.wege.augenzeuge_umlagerung)}, Verfahrensblatt ${yn(r.wege.verfahrensblatt)}, eigene Abgleiche ${list(r.wege.eigener_abgleich)}`);
  out.push(`DAME: ${r.dame.length ? r.dame.map((d) => `${d.status}${d.ausgang ? ' (' + d.ausgang + ')' : ''}`).join('; ') : 'nicht gespielt'}`);
  out.push(`Widerlegung: ${r.widerlegung.length ? r.widerlegung.map((w) => `${w.status}${w.ausgang ? ' (' + w.ausgang + ')' : ''}, ${w.karten} Karten`).join('; ') : 'nicht gespielt'}`);
  if (r.bericht) {
    const b = r.bericht;
    out.push(`Bericht: Antrag ${b.antrag}, Feststellungen ${list(b.feststellungen)}, Schlussfolgerung ${b.schlussfolgerung} (${b.status}), offene Fragen ${list(b.offene_fragen)}${b.rueckfrage ? ', Rückfrage ' + b.rueckfrage : ''}`);
    if (b.wortlaut) out.push(`  Eigener Wortlaut: »${b.wortlaut}«`);
  } else {
    out.push('Bericht: nicht eingereicht');
  }
  out.push(`Nachgang erreicht: ${yn(r.nachgang_erreicht)}`);
  out.push(`Sichtbare Folgen im Nachgang: ${list(r.sichtbare_folgen)}`);
  out.push(`Erlassene Regeln: ${list(r.regeln)}`);
  return out.join('\n');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const file = process.argv[2];
  if (!file) {
    console.error('Aufruf: node tools/spieltest-auswertung.mjs <amt_vorgang.json> [--json]');
    process.exit(2);
  }
  const report = analyze(JSON.parse(readFileSync(resolve(file), 'utf8')));
  console.log(process.argv.includes('--json') ? JSON.stringify(report, null, 2) : format(report));
}
