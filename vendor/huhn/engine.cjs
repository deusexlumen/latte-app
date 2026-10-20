/* DAS GERUPFTE HUHN — Engine
 * Reine Spiellogik. Kein DOM. Läuft im Browser (window.HuhnEngine) und in Node (module.exports).
 * Alles ist deterministisch aus dem Aktenzeichen ableitbar.
 */
(function (root) {
  'use strict';

  // ---------- Zufall (deterministisch) ----------
  function hashStr(str) {
    let h1 = 1779033703 ^ str.length;
    for (let i = 0; i < str.length; i++) {
      h1 = Math.imul(h1 ^ str.charCodeAt(i), 3432918353);
      h1 = (h1 << 13) | (h1 >>> 19);
    }
    h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507);
    h1 = Math.imul(h1 ^ (h1 >>> 13), 3266489909);
    return (h1 ^= h1 >>> 16) >>> 0;
  }
  // mulberry32 mit externem Zustand, damit der Zustand serialisierbar bleibt
  function rnd(o) {
    o.rs = (o.rs + 0x6D2B79F5) >>> 0;
    let t = o.rs;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
  function shuffle(arr, o) {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(rnd(o) * (i + 1));
      const t = a[i]; a[i] = a[j]; a[j] = t;
    }
    return a;
  }

  // ---------- Daten-Zugriff ----------
  let DATA = null;
  function setData(d) {
    DATA = d;
    for (const inst of d.instanzen) {
      inst.cardMap = {};
      for (const c of inst.cards) {
        c.attrs = new Set(c.a ? c.a.split(/\s+/).filter(Boolean) : []);
        c.member = !!c.m;
        for (const a of c.attrs) {
          if (!inst.attrs[a]) throw new Error('Unbekanntes Merkmal "' + a + '" bei Karte ' + c.id + ' in ' + inst.id);
        }
        if (inst.cardMap[c.id]) throw new Error('Doppelte Karte ' + c.id + ' in ' + inst.id);
        inst.cardMap[c.id] = c;
      }
      inst.prismaLits = inst.prisma.map(parseLit);
      inst.startLits = inst.start.map(parseLit);
      for (const l of inst.prismaLits.concat(inst.startLits)) {
        if (!inst.attrs[l.a]) throw new Error('Prisma/Start: unbekanntes Merkmal ' + l.a + ' in ' + inst.id);
      }
      for (const id of inst.refMembers.concat(inst.refNon)) {
        if (!inst.cardMap[id]) throw new Error('Referenzkarte fehlt: ' + id);
      }
      const startLehre = inst.startLits.map(l => ({ t: 'req', a: l.a, neg: l.neg }));
      for (const id of inst.refMembers) {
        const c = inst.cardMap[id];
        if (!c.member || !satisfies(c, startLehre)) throw new Error('Referenzmitglied passt nicht zur Startlehre: ' + id);
      }
      for (const id of inst.refNon) {
        const c = inst.cardMap[id];
        if (c.member || satisfies(c, startLehre)) throw new Error('Referenz-Nichtmitglied passt zur Startlehre: ' + id);
      }
    }
  }
  function parseLit(s) { return { a: s.slice(1), neg: s[0] === '-' }; }
  function litKey(l) { return (l.neg ? '-' : '+') + l.a; }

  // ---------- Logik der Lehre ----------
  function litHolds(card, l) { const has = card.attrs.has(l.a); return l.neg ? !has : has; }

  function satisfies(card, lehre) {
    for (const c of lehre) if (c.t === 'excl' && c.id === card.id) return false;
    for (const c of lehre) if (c.t === 'incl' && c.id === card.id) return true;
    for (const c of lehre) if (c.t === 'req' && !litHolds(card, c)) return false;
    return true;
  }
  function judge(card, lehre) {
    const sat = satisfies(card, lehre);
    if (sat && !card.member) return 'broad';
    if (!sat && card.member) return 'narrow';
    return 'confirm';
  }
  // Gewicht: jede Bestimmung 1, auch weggefallene (das Amt löscht nichts), Ausnahmen 3 (überstrichen 1)
  function weight(lehre) {
    let w = 0;
    for (const c of lehre) w += (c.t === 'req' || c.t === 'gone') ? 1 : (c.painted ? 1 : 3);
    return w;
  }
  function inclIds(lehre) { const s = new Set(); for (const c of lehre) if (c.t === 'incl') s.add(c.id); return s; }
  function usedAttrs(lehre) { const s = new Set(); for (const c of lehre) if (c.t === 'req' || c.t === 'gone') s.add(c.a); return s; }

  // Zu weit: ein Nicht-Mitglied erfüllt die Lehre
  function patchBroad(D, st, card, force) {
    const incl = inclIds(st.lehre);
    const active = st.members.filter(id => !incl.has(id)).map(id => D.cardMap[id]);
    if (!force) {
      const used = usedAttrs(st.lehre);
      for (const l of D.prismaLits) {
        if (used.has(l.a)) continue;
        if (litHolds(card, l)) continue;
        if (active.every(m => litHolds(m, l))) {
          st.lehre.push({ t: 'req', a: l.a, neg: l.neg, fresh: true });
          return { kind: 'add', lit: l };
        }
      }
    }
    st.lehre.push({ t: 'excl', id: card.id, fresh: true });
    return { kind: 'excl' };
  }

  // Zu eng: ein Mitglied erfüllt die Lehre nicht
  function patchNarrow(D, st, card, force) {
    if (!force) {
      const failing = st.lehre.filter(c => c.t === 'req' && !litHolds(card, c));
      // gestrichene Bestimmungen bleiben als "weggefallen" im Text stehen
      const base = st.lehre.map(c => (c.t === 'req' && !litHolds(card, c)) ? { t: 'gone', a: c.a, neg: c.neg, fresh: true } : c);
      const incl = inclIds(base);
      const mems = st.members.concat([card.id]).filter(id => !incl.has(id)).map(id => D.cardMap[id]);
      const nons = st.nonMembers.map(id => D.cardMap[id]);
      const def = base.slice();
      const added = [];
      let leaks = nons.filter(n => satisfies(n, def));
      while (leaks.length) {
        const used = usedAttrs(def);
        let found = null;
        for (const l of D.prismaLits) {
          if (used.has(l.a)) continue;
          if (!mems.every(m => litHolds(m, l))) continue;
          if (leaks.some(n => !litHolds(n, l))) { found = l; break; }
        }
        if (!found) break;
        def.push({ t: 'req', a: found.a, neg: found.neg, fresh: true });
        added.push(found);
        leaks = nons.filter(n => satisfies(n, def));
      }
      if (!leaks.length) {
        st.lehre = def;
        return { kind: 'repair', removed: failing.map(c => ({ a: c.a, neg: c.neg })), added };
      }
    }
    st.lehre.push({ t: 'incl', id: card.id, fresh: true });
    return { kind: 'incl' };
  }

  // Prisma-Merkmale, die der Gegner noch verwenden kann
  function freeLits(D, st) {
    const used = usedAttrs(st.lehre);
    const incl = inclIds(st.lehre);
    const mems = st.members.filter(id => !incl.has(id)).map(id => D.cardMap[id]);
    return D.prismaLits.filter(l => !used.has(l.a) && mems.every(m => litHolds(m, l)));
  }

  const GAIN = { add: 1, repair: 1, excl: 3, incl: 3, confirm: 0 };

  // ---------- Kniffe & Rhetorik (Regeltexte stehen in data.js) ----------
  function hasKniff(run, id) { return run.kniffe.indexOf(id) >= 0; }

  // ---------- Vorgang ----------
  function normAz(s) { return String(s || '').trim().toUpperCase().replace(/\s+/g, ''); }
  function dailyAz(date) {
    const d = date || new Date();
    const y = d.getFullYear(), m = String(d.getMonth() + 1).padStart(2, '0'), dd = String(d.getDate()).padStart(2, '0');
    return 'HUHN-' + y + m + dd;
  }
  function randomAz() {
    const abc = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let s = '';
    for (let i = 0; i < 8; i++) s += abc[Math.floor(Math.random() * abc.length)];
    return 'HUHN-' + s.slice(0, 4) + '-' + s.slice(4);
  }

  function newRun(az, opts) {
    az = normAz(az);
    opts = opts || {};
    return {
      v: 1,
      az,
      daily: /^HUHN-\d{8}$/.test(az),
      kniffe: (opts.kniffe || []).slice(),
      total: 0,
      results: [],
      alexander: null,
      idx: 0,
      phase: 'intro',
      streng: !!opts.streng,
      inst: null,
      offers: null,
      seenTut: false
    };
  }

  function startInstanz(run) {
    const D = DATA.instanzen[run.idx];
    const o = { rs: hashStr(run.az + '#' + D.id) };
    const pool = D.cards.filter(c => D.refMembers.indexOf(c.id) < 0 && D.refNon.indexOf(c.id) < 0).map(c => c.id);
    let deck = shuffle(pool, o);
    // feste Startkarten (Tutorial: das Huhn liegt immer in der ersten Hand)
    if (D.fixedHand) {
      for (const id of D.fixedHand) {
        const i = deck.indexOf(id);
        if (i >= D.hand) { const t = deck[i]; deck[i] = deck[0]; deck[0] = t; }
      }
    }
    const handN = D.hand;
    let cap = D.cap;
    let wuerfe = D.wuerfe;
    if (hasKniff(run, 'inspektion')) cap -= 1;
    if (hasKniff(run, 'huhn2')) wuerfe += 1;
    if (run.idx === DATA.instanzen.length - 1 && run.alexander === 'gold') cap += 2;
    const st = {
      id: D.id,
      rs: o.rs,
      lehre: D.startLits.map(l => ({ t: 'req', a: l.a, neg: l.neg })),
      members: D.refMembers.slice(),
      nonMembers: D.refNon.slice(),
      hand: deck.slice(0, handN),
      deck: deck.slice(handN),
      wuerfe,
      wuerfeStart: wuerfe,
      cap,
      capStart: cap,
      extra: 0,
      score: 0,
      plays: 0,
      beats: 0,
      rhetIdx: 0,
      telegraph: null,
      status: 'play',
      seized: [],
      used: { fass: false, uniform: false, bettwaermer: false },
      uniformArmed: false,
      dudelsackDone: false,
      sonneDone: false,
      firstWiderlegung: true,
      history: [],
      exceptions: 0,
      lastStart: 0
    };
    st.lastStart = weight(st.lehre);
    st.telegraph = makeTelegraph(D, st);
    run.inst = st;
    run.phase = 'play';
    return st;
  }

  function makeTelegraph(D, st) {
    const seq = D.rhetorik;
    if (!seq || !seq.length) return null;
    const type = seq[st.rhetIdx % seq.length];
    const tg = { type, target: null };
    if (type === 'autoritaet' && st.hand.length) {
      tg.target = st.hand[Math.floor(rnd(st) * st.hand.length)];
    }
    return tg;
  }

  function last(st) { return weight(st.lehre) + st.extra; }

  function drawOne(st) {
    if (!st.deck.length) return null;
    const id = st.deck.shift();
    st.hand.push(id);
    return id;
  }

  // Wirft eine Karte. Liefert eine Ereignisliste für die Oberfläche.
  function play(run, cardId) {
    const st = run.inst;
    const D = DATA.instanzen[run.idx];
    if (!st || st.status !== 'play') return [];
    const hi = st.hand.indexOf(cardId);
    if (hi < 0) return [];
    for (const c of st.lehre) delete c.fresh;
    const card = D.cardMap[cardId];
    const ev = [];
    st.hand.splice(hi, 1);
    const verdict = judge(card, st.lehre);
    ev.push({ type: 'throw', card: cardId, verdict });

    let res;
    if (verdict === 'broad') {
      const force = st.uniformArmed;
      res = patchBroad(D, st, card, force);
      st.nonMembers.push(cardId);
      if (force) { st.uniformArmed = false; res.uniform = true; }
    } else if (verdict === 'narrow') {
      const force = st.uniformArmed;
      res = patchNarrow(D, st, card, force);
      st.members.push(cardId);
      if (force) { st.uniformArmed = false; res.uniform = true; }
    } else {
      res = { kind: 'confirm', blocks: card.member ? freeLits(D, st).filter(l => !litHolds(card, l)) : [] };
      res.frei = res.blocks.length > 0;
      if (card.member) st.members.push(cardId); else st.nonMembers.push(cardId);
    }
    res.card = cardId;
    res.gain = GAIN[res.kind];
    if (res.kind === 'excl' || res.kind === 'incl') st.exceptions++;
    if (verdict !== 'confirm' && st.firstWiderlegung) {
      st.firstWiderlegung = false;
      if (hasKniff(run, 'dudelsack')) { st.extra += 1; res.dudelsack = true; }
    }
    st.score += res.gain;
    res.last = last(st);
    ev.push(Object.assign({ type: 'patch' }, res));
    st.history.push({ card: cardId, verdict, kind: res.kind });

    st.plays++;
    // Beweisaufnahme: Eine Bestätigung, die dem Gegner ein freies Merkmal blockiert, kostet keinen Wurf.
    // Der Herzschlag zählt trotzdem mit.
    if (!res.frei) st.wuerfe--;

    const drawn = drawOne(st);
    if (drawn) ev.push({ type: 'draw', card: drawn });

    if (last(st) >= st.cap) {
      finishInstanz(run, true, ev);
      return ev;
    }

    if (st.plays % 3 === 0 && st.telegraph) {
      heartbeat(run, D, st, ev);
    }

    if (st.wuerfe <= 0 || st.hand.length === 0) {
      finishInstanz(run, false, ev);
    }
    return ev;
  }

  function heartbeat(run, D, st, ev) {
    const tg = st.telegraph;
    st.beats++;
    const e = { type: 'beat', rhet: tg.type, effect: 'fizzle' };
    if (hasKniff(run, 'sonne') && !st.sonneDone) {
      st.sonneDone = true;
      e.effect = 'sonne';
    } else if (tg.type === 'autoritaet') {
      const i = tg.target ? st.hand.indexOf(tg.target) : -1;
      if (i >= 0) {
        st.hand.splice(i, 1);
        st.seized.push(tg.target);
        e.effect = 'seized'; e.card = tg.target;
        const d = drawOne(st);
        if (d) e.drawn = d;
      }
    } else if (tg.type === 'knappheit') {
      st.wuerfe = Math.max(0, st.wuerfe - 1);
      e.effect = 'wurf';
    } else if (tg.type === 'sozial') {
      st.cap += 1;
      e.effect = 'cap';
    } else if (tg.type === 'anstrich') {
      for (let i = st.lehre.length - 1; i >= 0; i--) {
        const c = st.lehre[i];
        if ((c.t === 'excl' || c.t === 'incl') && !c.painted) { c.painted = true; e.effect = 'painted'; e.id = c.id; break; }
      }
    }
    e.last = last(st);
    e.cap = st.cap;
    ev.push(e);
    st.rhetIdx++;
    st.telegraph = makeTelegraph(D, st);
    ev.push({ type: 'telegraph', tg: st.telegraph });
  }

  function finishInstanz(run, collapsed, ev) {
    const st = run.inst;
    st.status = collapsed ? 'collapse' : 'hold';
    let bonus = 0;
    if (collapsed) {
      bonus = 5 + 2 * Math.max(0, st.wuerfe);
      const isFinal = run.idx === DATA.instanzen.length - 1;
      if (isFinal && run.alexander === 'sonne') bonus += 15;
    }
    st.bonus = bonus;
    st.score += bonus;
    run.total += st.score;
    run.results.push({
      id: st.id,
      collapsed,
      atWurf: st.plays,
      score: st.score,
      exceptions: st.exceptions,
      last: last(st),
      cap: st.cap,
      lehre: st.lehre.map(c => { const o = Object.assign({}, c); delete o.fresh; return o; })
    });
    run.phase = 'result';
    ev.push({ type: collapsed ? 'collapse' : 'hold', bonus, score: st.score });
  }

  // ---------- Kniffe (aktiv) ----------
  function useKniff(run, id) {
    const st = run.inst;
    if (!st || st.status !== 'play' || !hasKniff(run, id) || st.used[id]) return null;
    if (id === 'fass') {
      st.used.fass = true;
      const old = st.hand.splice(0);
      st.deck = st.deck.concat(old);
      const n = old.length;
      const drawn = [];
      for (let i = 0; i < n; i++) { const d = drawOne(st); if (d) drawn.push(d); }
      // Autorität zielt auf eine Karte, die nicht mehr in der Hand ist? Dann neu zielen.
      if (st.telegraph && st.telegraph.type === 'autoritaet' && st.hand.indexOf(st.telegraph.target) < 0 && st.hand.length) {
        st.telegraph.target = st.hand[Math.floor(rnd(st) * st.hand.length)];
      }
      return { type: 'fass', old, drawn };
    }
    if (id === 'uniform') {
      st.used.uniform = true;
      st.uniformArmed = true;
      return { type: 'uniform' };
    }
    if (id === 'bettwaermer') {
      st.used.bettwaermer = true;
      const drawn = [];
      for (let i = 0; i < 2; i++) { const d = drawOne(st); if (d) drawn.push(d); }
      return { type: 'bettwaermer', drawn };
    }
    return null;
  }

  // Laterne: was würde der Gegner tun? Ändert nichts.
  function preview(run, cardId) {
    const st = run.inst;
    const D = DATA.instanzen[run.idx];
    const card = D.cardMap[cardId];
    const tmp = {
      lehre: st.lehre.map(c => Object.assign({}, c)),
      members: st.members.slice(),
      nonMembers: st.nonMembers.slice()
    };
    const verdict = judge(card, tmp.lehre);
    let res;
    if (verdict === 'broad') res = patchBroad(D, tmp, card, st.uniformArmed);
    else if (verdict === 'narrow') res = patchNarrow(D, tmp, card, st.uniformArmed);
    else res = { kind: 'confirm', blocks: card.member ? freeLits(D, tmp).filter(l => !litHolds(card, l)) : [] };
    res.verdict = verdict;
    res.frei = res.kind === 'confirm' && res.blocks.length > 0;
    res.gain = GAIN[res.kind];
    let extra = st.extra;
    if (verdict !== 'confirm' && st.firstWiderlegung && hasKniff(run, 'dudelsack')) extra += 1;
    res.last = weight(tmp.lehre) + extra;
    res.collapse = res.last >= st.cap;
    return res;
  }

  // ---------- Zwischen den Instanzen ----------
  function nextPhase(run) {
    // nach 'result': Tonne (nach Instanz 1–4), Alexander (vor der letzten), Ende
    const n = DATA.instanzen.length;
    if (run.phase !== 'result') return run.phase;
    if (run.idx >= n - 1) { run.phase = 'end'; return run.phase; }
    run.phase = 'tonne';
    run.offers = kniffOffers(run);
    return run.phase;
  }
  function kniffOffers(run) {
    const o = { rs: hashStr(run.az + '#tonne' + run.idx) };
    const avail = DATA.kniffe.map(k => k.id).filter(id => !hasKniff(run, id));
    return shuffle(avail, o).slice(0, 3);
  }
  function chooseKniff(run, id) {
    if (run.phase !== 'tonne') return;
    if (id && run.offers.indexOf(id) >= 0 && !hasKniff(run, id)) run.kniffe.push(id);
    run.offers = null;
    run.idx++;
    if (run.idx === DATA.instanzen.length - 1 && run.alexander === null) run.phase = 'alexander';
    else run.phase = 'intro';
  }
  function chooseAlexander(run, choice) {
    if (run.phase !== 'alexander') return;
    run.alexander = choice === 'gold' ? 'gold' : 'sonne';
    if (run.alexander === 'gold') run.total += 8;
    run.phase = 'intro';
  }

  // ---------- Wertung & Teilen ----------
  function rank(total) {
    const r = DATA.raenge;
    let best = r[0];
    for (const x of r) if (total >= x.min) best = x;
    return best;
  }
  function pruefcode(run) {
    const s = run.az + (run.streng ? '|S' : '') + '|' + run.total + '|' + run.results.map(r => (r.collapsed ? 'E' + r.atWurf : 'H') + r.score).join(',') + '|' + (run.alexander || '-');
    return (hashStr(s) >>> 0).toString(16).toUpperCase().padStart(8, '0').slice(0, 4);
  }
  function shareText(run, versuch) {
    const kopf = 'DAS GERUPFTE HUHN · ' + run.az + (run.streng ? ' · strenge Prüfung' : '') + (versuch ? ' · ' + versuch + '. Versuch' : '');
    const lines = [kopf];
    run.results.forEach((r, i) => {
      const D = DATA.instanzen[i];
      const state = r.collapsed ? '💥 eingestürzt, Wurf ' + r.atWurf : '🧱 hält';
      const ex = r.exceptions ? ' ' + '🏅'.repeat(Math.min(r.exceptions, 4)) : '';
      lines.push(D.shareIcon + ' ' + D.shortName + ': ' + state + ex + ' · +' + r.score);
    });
    const rk = rank(run.total);
    lines.push('Gelächter ' + run.total + ' · ' + rk.name + ' · Prüfcode ' + pruefcode(run));
    lines.push('Nachspielen: Aktenzeichen ' + run.az + ' eingeben');
    return lines.join('\n');
  }

  // ---------- Text der Lehre ----------
  function litPhrase(D, l) { const A = D.attrs[l.a]; return l.neg ? A.neg : A.pos; }
  function lehreView(D, lehre) {
    const reqs = [], excl = [], incl = [];
    lehre.forEach((c) => {
      if (c.t === 'req' || c.t === 'gone') reqs.push({ text: litPhrase(D, c), fresh: !!c.fresh, a: c.a, neg: c.neg, gone: c.t === 'gone' });
      else if (c.t === 'excl') excl.push({ id: c.id, name: D.cardMap[c.id].name, fresh: !!c.fresh, painted: !!c.painted });
      else incl.push({ id: c.id, name: D.cardMap[c.id].name, fresh: !!c.fresh, painted: !!c.painted });
    });
    return { reqs, excl, incl };
  }

  const API = {
    setData, hashStr, rnd, shuffle, satisfies, judge, weight, litHolds, parseLit, litKey,
    newRun, startInstanz, play, preview, useKniff, nextPhase, chooseKniff, chooseAlexander,
    last, rank, pruefcode, shareText, lehreView, litPhrase, dailyAz, randomAz, normAz, hasKniff,
    patchBroad, patchNarrow, GAIN, freeLits,
    get DATA() { return DATA; }
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = API;
  else root.HuhnEngine = API;
})(typeof window !== 'undefined' ? window : globalThis);
