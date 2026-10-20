/*
 * PURPOSE: Erfundene Lehren der Widerlegung: Request-/Antwort-Prüfung, Normalisierung ins Engine-Format, Schema, Prompt
 * ARCHITECTURE: gm-proxy/contracts
 * DEPENDENCIES: node:crypto
 * PIPELINE: runtime, test
 * LAST_VALIDATED: 2026-10-12
 */
import { createHash } from 'node:crypto';

/*
 * Der Proxy prüft nur die Form und die Querverweise. Ob eine Lehre trägt
 * (Kartenpaare, Spielbarkeit, Tragfähigkeit `cap`), entscheidet der Client
 * mit WiderlegungValidator, weil nur dort die Simulation läuft. Deshalb
 * gibt es hier kein `cap`, `hand`, `wuerfe` und keinen Seed vom Modell.
 */

export const LEHRE_LIMITS = {
  attrs: [8, 12],
  start: [2, 3],
  prisma: [5, 7],
  cards: [15, 22],
  refs: [1, 3],
} as const;

export const RHETORIK_IDS = ['autoritaet', 'knappheit', 'sozial', 'anstrich'] as const;
const LINE_KEYS = ['add', 'repair', 'excl', 'incl', 'confirm'] as const;
const ID_RE = /^[a-z][a-z0-9_]{1,23}$/;
const LIT_RE = /^[+-][a-z][a-z0-9_]{1,23}$/;
const MAX_TEXT = 400;
const MAX_THEMA = 120;
const MAX_BEFUNDE = 5;
/** Wie WiderlegungValidator.MIN_PAIRS (nur zur Auskunft, z. B. in Werkzeugen). */
export const MIN_PAIRS = 3;

export interface LehreAttr {
  pos: string;
  neg: string;
  short: string;
  icon: string;
}

export interface LehreCard {
  id: string;
  name: string;
  icon: string;
  m: boolean;
  a: string;
  note: string;
}

/** Eine Lehre im Format von content/widerlegung/*.json, ohne `cap` (setzt der Client). */
export interface Lehre {
  id: string;
  nr: number;
  shortName: string;
  shareIcon: string;
  ort: string;
  jahr: string;
  gegner: string;
  gegnerTitel: string;
  siegel: string[];
  begriff: string;
  truthYes: string;
  truthNo: string;
  lehreHead: string;
  startSatz: string;
  intro: string;
  hand: number;
  wuerfe: number;
  rhetorik: string[];
  attrs: Record<string, LehreAttr>;
  start: string[];
  prisma: string[];
  refMembers: string[];
  refNon: string[];
  cards: LehreCard[];
  lines: Record<string, string[] | string>;
  erfunden: true;
}

export interface LehreGenerateRequest {
  session_id?: string;
  thema?: string;
  nachbesserung?: { befunde: string[]; vorlage: Record<string, unknown> };
}

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === 'object' && v !== null && !Array.isArray(v);

const text = (v: unknown, max = MAX_TEXT): v is string =>
  typeof v === 'string' && v.trim().length > 0 && v.length <= max;

const texts = (v: unknown, min: number, max: number): v is string[] =>
  Array.isArray(v) && v.length >= min && v.length <= max && v.every((s) => text(s));

const inRange = (n: number, [lo, hi]: readonly [number, number]): boolean => n >= lo && n <= hi;

/** Request: Thema optional, Nachbesserung nur mit Befunden und der vorigen Lehre. */
export function validateLehreGenerateRequest(body: unknown): LehreGenerateRequest | null {
  if (!isRecord(body)) return null;
  const req: LehreGenerateRequest = {};
  if (body.session_id !== undefined) {
    if (!text(body.session_id, 128)) return null;
    req.session_id = body.session_id;
  }
  if (body.thema !== undefined) {
    if (!text(body.thema, MAX_THEMA)) return null;
    req.thema = body.thema.trim();
  }
  if (body.nachbesserung !== undefined) {
    const n = body.nachbesserung;
    if (!isRecord(n) || !texts(n.befunde, 1, MAX_BEFUNDE) || !isRecord(n.vorlage)) return null;
    req.nachbesserung = { befunde: n.befunde, vorlage: n.vorlage };
  }
  return req;
}

/** "Schüssel" -> "schuessel", "e-scooter" -> "e_scooter". Kleine Modelle halten das ID-Format nicht immer ein. */
export function slugId(id: string): string {
  return id
    .toLowerCase()
    .replace(/ä/g, 'ae').replace(/ö/g, 'oe').replace(/ü/g, 'ue').replace(/ß/g, 'ss')
    .replace(/[^a-z0-9_]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 24);
}

/** Wendet slugId auf alle IDs und Verweise an (Merkmale, Literale, Karten, Anker). */
function slugIds(body: Record<string, unknown>): Record<string, unknown> {
  const s = (v: unknown): unknown => (typeof v === 'string' ? slugId(v) : v);
  const lit = (v: unknown): unknown =>
    typeof v === 'string' && (v.startsWith('+') || v.startsWith('-')) ? v[0] + slugId(v.slice(1)) : v;
  const list = (v: unknown, f: (x: unknown) => unknown): unknown => (Array.isArray(v) ? v.map(f) : v);
  return {
    ...body,
    attrs: list(body.attrs, (a) => (isRecord(a) ? { ...a, id: s(a.id) } : a)),
    start: list(body.start, lit),
    prisma: list(body.prisma, lit),
    cards: list(body.cards, (c) => (isRecord(c) ? { ...c, id: s(c.id), a: list(c.a, s) } : c)),
    refMembers: list(body.refMembers, s),
    refNon: list(body.refNon, s),
  };
}

const holds = (attrSet: Set<string>, lit: string): boolean =>
  lit[0] === '+' ? attrSet.has(lit.slice(1)) : !attrSet.has(lit.slice(1));

/**
 * Kartenpaare wie WiderlegungValidator.count_pairs: Nichtmitglied scheitert an
 * genau einer Startbestimmung, Mitglied verletzt dieselbe. Ohne Paare gibt es
 * keine Ausnahme, und ohne Ausnahme stürzt keine Lehre ein.
 */
export function countPairs(cards: LehreCard[], start: string[]): number {
  const nearNon = new Map<string, number>();
  const memberFail = new Map<string, number>();
  for (const c of cards) {
    const set = new Set(c.a.split(' '));
    const failed = start.filter((l) => !holds(set, l));
    if (c.m) for (const l of failed) memberFail.set(l, (memberFail.get(l) ?? 0) + 1);
    else if (failed.length === 1) nearNon.set(failed[0], (nearNon.get(failed[0]) ?? 0) + 1);
  }
  let n = 0;
  for (const [l, k] of nearNon) n += k * (memberFail.get(l) ?? 0);
  return n;
}

/** Stabile ID aus dem Inhalt: dieselbe Lehre landet nie zweimal in der Bibliothek. */
const lehreId = (draft: unknown): string =>
  'bib_' + createHash('sha256').update(JSON.stringify(draft)).digest('hex').slice(0, 10);

/**
 * Prüft die Modellantwort und baut daraus eine Lehre im Engine-Format.
 * `null` bei jedem Formfehler — der Handler zieht dann eine neue Stichprobe.
 */
export function normalizeLehreDraft(raw: unknown): Lehre | null {
  const r = checkLehreDraft(raw);
  return 'lehre' in r ? r.lehre : null;
}

/** Wie normalizeLehreDraft, aber mit dem Grund der Ablehnung (Logs, Werkzeuge). */
export function checkLehreDraft(raw: unknown): { lehre: Lehre } | { reason: string } {
  const fail = (reason: string) => ({ reason });
  if (!isRecord(raw)) return fail('kein Objekt');
  const body = slugIds(raw);
  for (const k of ['begriff', 'truthYes', 'truthNo', 'lehreHead', 'startSatz', 'intro', 'ort', 'jahr', 'gegner', 'gegnerTitel', 'shortName']) {
    if (!text(body[k])) return fail(`Textfeld ${k}`);
  }
  if (!texts(body.siegel, 1, 3)) return fail('siegel');
  if (!Array.isArray(body.rhetorik) || body.rhetorik.length < 1 || body.rhetorik.length > 2) return fail('rhetorik Anzahl');
  if (!body.rhetorik.every((r) => (RHETORIK_IDS as readonly unknown[]).includes(r))) return fail('rhetorik unbekannt');

  // Merkmale
  if (!Array.isArray(body.attrs) || !inRange(body.attrs.length, LEHRE_LIMITS.attrs)) return fail(`attrs Anzahl ${Array.isArray(body.attrs) ? body.attrs.length : '-'}`);
  const attrs: Record<string, LehreAttr> = {};
  for (const a of body.attrs) {
    if (!isRecord(a) || typeof a.id !== 'string' || !ID_RE.test(a.id) || a.id in attrs) return fail(`Merkmal-ID ${isRecord(a) ? String(a.id) : '?'}`);
    if (!text(a.pos) || !text(a.neg) || !text(a.short, 40) || !text(a.icon, 16)) return fail(`Merkmal-Texte ${a.id}`);
    attrs[a.id] = { pos: a.pos, neg: a.neg, short: a.short, icon: a.icon };
  }
  const lits = (v: unknown, range: readonly [number, number]): string[] | null => {
    if (!Array.isArray(v) || !inRange(v.length, range)) return null;
    const seen = new Set<string>();
    for (const l of v) {
      if (typeof l !== 'string' || !LIT_RE.test(l) || !(l.slice(1) in attrs) || seen.has(l.slice(1))) return null;
      seen.add(l.slice(1));
    }
    return v as string[];
  };
  const start = lits(body.start, LEHRE_LIMITS.start);
  const prisma = lits(body.prisma, LEHRE_LIMITS.prisma);
  if (start === null) return fail(`start ${JSON.stringify(body.start)}`);
  if (prisma === null) return fail(`prisma ${JSON.stringify(body.prisma)}`);

  // Karten
  if (!Array.isArray(body.cards) || !inRange(body.cards.length, LEHRE_LIMITS.cards)) return fail(`Karten Anzahl ${Array.isArray(body.cards) ? body.cards.length : '-'}`);
  const cards: LehreCard[] = [];
  const member = new Map<string, boolean>();
  for (const c of body.cards) {
    if (!isRecord(c) || typeof c.id !== 'string' || !ID_RE.test(c.id) || member.has(c.id)) return fail(`Karten-ID ${isRecord(c) ? String(c.id) : '?'}`);
    if (!text(c.name, 60) || !text(c.icon, 16) || !text(c.note) || typeof c.m !== 'boolean') return fail(`Karten-Texte ${c.id}`);
    if (!Array.isArray(c.a) || !c.a.every((x) => typeof x === 'string' && x in attrs)) return fail(`Karten-Merkmale ${c.id}: ${JSON.stringify(c.a)}`);
    member.set(c.id, c.m);
    cards.push({ id: c.id, name: c.name, icon: c.icon, m: c.m, a: [...new Set(c.a as string[])].join(' '), note: c.note });
  }
  // Anker müssen existieren. Ob die Mitgliedschaft stimmt, prüft und repariert der Client
  // (WiderlegungValidator.repair_refs), sonst ginge der Entwurf hier ohne Befund verloren.
  const refs = (v: unknown): string[] | null =>
    Array.isArray(v) && inRange(v.length, LEHRE_LIMITS.refs) && v.every((id) => typeof id === 'string' && member.has(id))
      ? (v as string[])
      : null;
  const refMembers = refs(body.refMembers);
  const refNon = refs(body.refNon);
  if (refMembers === null || refNon === null) return fail(`Anker ${JSON.stringify([body.refMembers, body.refNon])}`);
  // Referenzfälle und Kartenpaare prüft bewusst erst der Client (WiderlegungValidator):
  // Hier verworfene Entwürfe kämen nie zur Nachbesserung. Gemessen 12.10.2026: Mit
  // Vorfilter scheiterten 10 von 20 Erfindungen schon im Proxy, ohne Befund ans Modell.

  // Sätze des Gegners
  if (!isRecord(body.lines)) return fail('lines');
  const lines: Record<string, string[] | string> = {};
  for (const k of LINE_KEYS) {
    if (!texts(body.lines[k], 1, 4)) return fail(`lines.${k}`);
    lines[k] = body.lines[k] as string[];
  }
  if (!text(body.lines.collapse) || !text(body.lines.hold)) return fail('lines.collapse/hold');
  lines.collapse = body.lines.collapse;
  lines.hold = body.lines.hold;

  return { lehre: {
    id: lehreId(body),
    nr: 0,
    shortName: body.shortName as string,
    shareIcon: '📜',
    ort: body.ort as string,
    jahr: body.jahr as string,
    gegner: body.gegner as string,
    gegnerTitel: body.gegnerTitel as string,
    siegel: body.siegel,
    begriff: body.begriff as string,
    truthYes: body.truthYes as string,
    truthNo: body.truthNo as string,
    lehreHead: body.lehreHead as string,
    startSatz: body.startSatz as string,
    intro: body.intro as string,
    hand: 5,
    wuerfe: 7,
    rhetorik: body.rhetorik as string[],
    attrs,
    start,
    prisma,
    refMembers,
    refNon,
    cards,
    lines,
    erfunden: true,
  } };
}

const s = { type: 'string' } as const;
const strs = (min: number, max: number) => ({ type: 'array', items: s, minItems: min, maxItems: max });

/** Structured Output für /lehre/generate (Merkmale als Liste, weil Schemas keine freien Schlüssel kennen). */
export const LEHRE_DRAFT_SCHEMA = {
  type: 'object',
  properties: {
    shortName: s,
    ort: s,
    jahr: s,
    gegner: s,
    gegnerTitel: s,
    siegel: strs(1, 3),
    begriff: s,
    truthYes: s,
    truthNo: s,
    lehreHead: s,
    startSatz: s,
    intro: s,
    rhetorik: { type: 'array', items: { type: 'string', enum: [...RHETORIK_IDS] }, minItems: 1, maxItems: 2 },
    // Denkhilfe: erst die Paare planen, dann die Karten. Wird nicht übernommen,
    // gezählt wird an den Karten selbst.
    // Als Textliste "Bestimmung: Nichtmitglied / Mitglied": Ein Objekt-Array
    // hier sprengt Geminis Schema-Komplexität (400 INVALID_ARGUMENT).
    paarplan: { type: 'array', items: s },
    attrs: {
      type: 'array',
      minItems: LEHRE_LIMITS.attrs[0],
      maxItems: LEHRE_LIMITS.attrs[1],
      items: {
        type: 'object',
        properties: { id: s, pos: s, neg: s, short: s, icon: s },
        required: ['id', 'pos', 'neg', 'short', 'icon'],
      },
    },
    start: strs(LEHRE_LIMITS.start[0], LEHRE_LIMITS.start[1]),
    prisma: strs(LEHRE_LIMITS.prisma[0], LEHRE_LIMITS.prisma[1]),
    cards: {
      type: 'array',
      minItems: LEHRE_LIMITS.cards[0],
      maxItems: LEHRE_LIMITS.cards[1],
      items: {
        type: 'object',
        properties: { id: s, name: s, icon: s, m: { type: 'boolean' }, a: { type: 'array', items: s }, note: s },
        required: ['id', 'name', 'icon', 'm', 'a', 'note'],
      },
    },
    refMembers: strs(1, 3),
    refNon: strs(1, 3),
    lines: {
      type: 'object',
      properties: {
        add: strs(1, 4), repair: strs(1, 4), excl: strs(1, 4), incl: strs(1, 4), confirm: strs(1, 4),
        collapse: s, hold: s,
      },
      required: ['add', 'repair', 'excl', 'incl', 'confirm', 'collapse', 'hold'],
    },
  },
  required: [
    'shortName', 'ort', 'jahr', 'gegner', 'gegnerTitel', 'siegel', 'begriff', 'truthYes', 'truthNo',
    'lehreHead', 'startSatz', 'intro', 'rhetorik', 'paarplan', 'attrs', 'start', 'prisma', 'cards', 'refMembers', 'refNon', 'lines',
  ],
} as const;

const tag = (name: string, body: string): string => `<${name}>\n${body}\n</${name}>`;

/**
 * Der Client schickt die vorige Lehre im Engine-Format (Merkmale als Objekt, Kartenmerkmale
 * als Text). Zurück ins Schema-Format, damit das Modell nicht das falsche Format nachahmt.
 * Laufzeitfelder (cap, pruefung, id, ...) fallen weg.
 */
export function toDraftFormat(v: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const key of LEHRE_DRAFT_SCHEMA.required) if (key in v) out[key] = v[key];
  if (isRecord(v.attrs)) out.attrs = Object.entries(v.attrs).map(([id, a]) => ({ id, ...(isRecord(a) ? a : {}) }));
  if (Array.isArray(v.cards)) {
    out.cards = v.cards.map((c) =>
      isRecord(c) && typeof c.a === 'string' ? { ...c, a: c.a.split(' ').filter((x) => x.length > 0) } : c,
    );
  }
  return out;
}

/** Task-Prompt: Thema oder Nachbesserung. Regeln und Beispiel stehen im System-Prompt. */
export function buildLehrePrompt(req: LehreGenerateRequest): string {
  const parts: string[] = [];
  if (req.nachbesserung !== undefined) {
    parts.push(tag('vorige_lehre', JSON.stringify(toDraftFormat(req.nachbesserung.vorlage))));
    parts.push(tag('befunde', req.nachbesserung.befunde.map((b) => `- ${b}`).join('\n')));
    parts.push('Basierend auf den Angaben oben:');
    parts.push('Die vorige Lehre hat die Prüfung nicht bestanden. Behebe genau die Befunde, behalte Begriff und Ton bei, und gib die vollständige verbesserte Lehre zurück.');
  } else {
    if (req.thema !== undefined) parts.push(tag('thema', req.thema));
    parts.push('Basierend auf den Angaben oben:');
    parts.push(
      req.thema !== undefined
        ? 'Erfinde eine neue Lehre zu diesem Thema.'
        : 'Erfinde eine neue Lehre. Wähle einen Alltagsbegriff, den eine deutsche Behörde, Fraktion oder Akademie definieren würde.',
    );
  }
  return parts.join('\n\n');
}
