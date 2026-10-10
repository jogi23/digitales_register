// ===== Frosch-Fliegen-Fangen: eigene, animierte SVG-Figuren =====
(() => {
  const FROG = `<svg viewBox="0 0 200 172" aria-hidden="true"><g class="whole">
    <ellipse class="fd" cx="36" cy="144" rx="34" ry="19"/><ellipse class="fd" cx="164" cy="144" rx="34" ry="19"/>
    <g class="belly-g">
      <path class="fb" d="M100 48 C160 48 180 92 173 124 C166 154 136 164 100 164 C64 164 34 154 27 124 C20 92 40 48 100 48 Z"/>
      <ellipse class="fl" cx="100" cy="132" rx="50" ry="28"/>
      <ellipse cx="74" cy="80" rx="26" ry="11" fill="#fff" opacity=".2"/>
      <ellipse class="fl sac" cx="100" cy="113" rx="17" ry="7" opacity=".95"/>
    </g>
    <circle class="fb" cx="64" cy="54" r="29"/><circle class="fb" cx="136" cy="54" r="29"/>
    <g class="eye" data-x="64" data-y="52"><circle cx="64" cy="52" r="20" fill="#fff"/><g class="pupil"><circle cx="64" cy="52" r="10" fill="#1d2a1d"/><circle cx="60" cy="47" r="3.6" fill="#fff"/></g><ellipse class="lid fb" cx="64" cy="52" rx="21.5" ry="21.5"/></g>
    <g class="eye" data-x="136" data-y="52"><circle cx="136" cy="52" r="20" fill="#fff"/><g class="pupil"><circle cx="136" cy="52" r="10" fill="#1d2a1d"/><circle cx="132" cy="47" r="3.6" fill="#fff"/></g><ellipse class="lid fb" cx="136" cy="52" rx="21.5" ry="21.5"/></g>
    <path class="happyeye" d="M50 56 Q64 40 78 56" stroke="#1d3a1d" stroke-width="5.5" fill="none" stroke-linecap="round"/>
    <path class="happyeye" d="M122 56 Q136 40 150 56" stroke="#1d3a1d" stroke-width="5.5" fill="none" stroke-linecap="round"/>
    <ellipse class="tear" cx="44" cy="72" rx="4" ry="6" fill="#7fd3ff"/><ellipse class="tear" cx="156" cy="72" rx="4" ry="6" fill="#7fd3ff"/>
    <ellipse cx="52" cy="100" rx="11" ry="7" fill="#ff8fb1" opacity=".55"/><ellipse cx="148" cy="100" rx="11" ry="7" fill="#ff8fb1" opacity=".55"/>
    <path d="M66 95 Q100 120 134 95" stroke="#1f4d22" stroke-width="5" fill="none" stroke-linecap="round"/>
    <g class="mouth-open"><path d="M68 96 Q100 138 132 96 Q100 108 68 96 Z" fill="#7a1f2e"/><ellipse cx="100" cy="114" rx="13" ry="6" fill="#ff6b8f"/></g>
    <g class="fd"><ellipse cx="62" cy="162" rx="18" ry="8"/><circle cx="48" cy="164" r="5"/><circle cx="62" cy="168" r="5"/><circle cx="76" cy="164" r="5"/>
      <ellipse cx="138" cy="162" rx="18" ry="8"/><circle cx="124" cy="164" r="5"/><circle cx="138" cy="168" r="5"/><circle cx="152" cy="164" r="5"/></g>
  </g></svg>`;
  const MOUTH = { x: 100, y: 104 }, VB = { w: 200, h: 172 };

  const FLY = `<svg viewBox="0 0 60 52" aria-hidden="true">
    <ellipse class="wing" cx="19" cy="16" rx="13" ry="9" fill="rgba(225,244,255,.9)" stroke="#9fc3d6" stroke-width="1.2"/>
    <ellipse class="wing" cx="41" cy="16" rx="13" ry="9" fill="rgba(225,244,255,.9)" stroke="#9fc3d6" stroke-width="1.2" style="animation-delay:-.035s"/>
    <path d="M21 37 l-6 9 M30 39 v10 M39 37 l6 9" stroke="#2f2f45" stroke-width="2.4" stroke-linecap="round"/>
    <ellipse class="fbody" cx="30" cy="31" rx="15" ry="12"/>
    <path d="M18 31 Q30 36 42 31 M20 26 Q30 30 40 26" stroke="rgba(255,255,255,.2)" stroke-width="2" fill="none"/>
    <circle cx="21" cy="26" r="7.5" fill="#d84a4a"/><circle cx="39" cy="26" r="7.5" fill="#d84a4a"/>
    <circle cx="19" cy="23.5" r="2.4" fill="#fff"/><circle cx="37" cy="23.5" r="2.4" fill="#fff"/>
    <path d="M26 36 Q30 39 34 36" stroke="#fff" stroke-width="1.8" fill="none" stroke-linecap="round"/>
    <g class="chilihat"><path d="M22 14 Q28 0 44 6 Q36 9 31 17 Z" fill="#e53935"/><path d="M42 6 l5 -4" stroke="#2e9b4c" stroke-width="3" stroke-linecap="round"/></g>
  </svg>`;
  const MINI_FLY = FLY.replace('<svg ', '<svg style="width:34px;height:30px" ');

  const BG = `<svg class="bgsvg" viewBox="0 0 400 430" preserveAspectRatio="xMidYMax slice" aria-hidden="true">
    <defs>
      <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8fd8ff"/><stop offset=".55" stop-color="#d5f3ff"/><stop offset="1" stop-color="#fff4cf"/></linearGradient>
      <linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5cc9e8"/><stop offset="1" stop-color="#2a8fc0"/></linearGradient>
      <radialGradient id="sunG"><stop offset="0" stop-color="#fff7c2"/><stop offset=".55" stop-color="#ffd84a"/><stop offset="1" stop-color="#ffb83a"/></radialGradient>
    </defs>
    <rect x="-40" width="480" height="430" fill="url(#sky)"/>
    <g class="par" data-d="3"><circle cx="330" cy="72" r="66" fill="#fff3a8" opacity=".35"/>
    <circle class="sun" cx="330" cy="72" r="34" fill="url(#sunG)"/>
    <g class="cloud" style="--t:70s;--d:-20s"><ellipse cx="60" cy="58" rx="40" ry="16" fill="#fff"/><ellipse cx="84" cy="48" rx="26" ry="18" fill="#fff"/><ellipse cx="40" cy="52" rx="18" ry="13" fill="#fff"/></g>
    <g class="cloud" style="--t:95s;--d:-60s"><ellipse cx="40" cy="112" rx="30" ry="11" fill="#fff" opacity=".85"/><ellipse cx="58" cy="105" rx="18" ry="12" fill="#fff" opacity=".85"/></g>
    </g>
    <g class="butterfly"><g transform="translate(0 0)"><ellipse class="wingL" cx="-6" cy="0" rx="7" ry="9" fill="#ff8fc8"/><ellipse class="wingR" cx="6" cy="0" rx="7" ry="9" fill="#ffb3d9"/><rect x="-1.5" y="-7" width="3" height="14" rx="1.5" fill="#5a3b6e"/></g></g>
    <g class="par" data-d="7"><path d="M-40 254 Q80 205 170 236 T 440 226 V430 H-40 Z" fill="#a8e27c"/>
    <path d="M-40 276 Q110 240 220 266 T 440 260 V430 H-40 Z" fill="#8ad063"/></g>
    <g class="par" data-d="12">
    <ellipse cx="200" cy="440" rx="320" ry="175" fill="url(#water)"/>
    <ellipse cx="200" cy="440" rx="320" ry="175" fill="none" stroke="#bff0ff" stroke-width="4" opacity=".6"/>
    <g fill="none" stroke="#fff" stroke-linecap="round" stroke-width="3">
      <path class="shimmer" d="M70 320 h26" style="--d:-.5s"/><path class="shimmer" d="M300 340 h34" style="--d:-1.4s"/><path class="shimmer" d="M150 395 h22" style="--d:-2.2s"/><path class="shimmer" d="M250 300 h18" style="--d:-.9s"/>
    </g>
    <g fill="none" stroke="#e8fbff" stroke-width="2">
      <ellipse class="ripple" cx="110" cy="365" rx="22" ry="7" style="--t:4s"/><ellipse class="ripple" cx="300" cy="392" rx="26" ry="8" style="--t:5s;--d:-2s"/><ellipse class="ripple" cx="210" cy="318" rx="16" ry="5" style="--t:4.5s;--d:-3s"/>
    </g>
    <g class="bob" style="--t:5s"><ellipse cx="80" cy="352" rx="34" ry="11" fill="#3fa33c"/><ellipse cx="80" cy="349" rx="34" ry="11" fill="#6fcf4f"/><path d="M80 349 L114 344 L112 354 Z" fill="#4fb4d8"/><path d="M60 348 Q80 340 100 348" stroke="#3fa33c" stroke-width="2" fill="none"/></g>
    <g class="bob" style="--t:6s;--d:-2s"><ellipse cx="322" cy="372" rx="38" ry="12" fill="#3fa33c"/><ellipse cx="322" cy="369" rx="38" ry="12" fill="#6fcf4f"/><path d="M322 369 L288 362 L290 374 Z" fill="#3fa3d0"/>
      <g transform="translate(330 360)"><ellipse cx="0" cy="-6" rx="5" ry="9" fill="#ff9ec7"/><ellipse cx="-7" cy="-2" rx="5" ry="8" fill="#ffb3d4" transform="rotate(-40)"/><ellipse cx="7" cy="-2" rx="5" ry="8" fill="#ffb3d4" transform="rotate(40)"/><circle cx="0" cy="-2" r="3.5" fill="#ffd23f"/></g></g>
    <g class="bob" style="--t:4.5s;--d:-1s"><ellipse cx="250" cy="314" rx="20" ry="6" fill="#6fcf4f"/></g>
    </g>
    <g class="par" data-d="18"><g class="sway" style="--t:4s"><path d="M18 430 Q14 330 22 250" stroke="#4e8f3a" stroke-width="5" fill="none"/><ellipse cx="22" cy="262" rx="7" ry="20" fill="#8a5a2b"/>
      <path d="M36 430 Q38 350 30 300" stroke="#5aa043" stroke-width="4" fill="none"/><path d="M6 430 Q2 360 -4 320" stroke="#5aa043" stroke-width="4" fill="none"/></g>
    <g class="sway" style="--t:5s;--d:-1.5s"><path d="M384 430 Q388 330 378 258" stroke="#4e8f3a" stroke-width="5" fill="none"/><ellipse cx="378" cy="272" rx="7" ry="20" fill="#8a5a2b"/>
      <path d="M366 430 Q362 360 370 310" stroke="#5aa043" stroke-width="4" fill="none"/><path d="M396 430 Q402 370 406 330" stroke="#5aa043" stroke-width="4" fill="none"/></g></g>
  </svg>`;

  const rnd = (a, b) => a + Math.random() * (b - a);

  K.run({
    id: 'froschFliegen', range: '20', title: 'Frosch-Fliegen-Fangen',
    hero: [`<div class="frog" style="position:static;transform:none;width:150px;filter:none">${FROG}</div>`],
    tagline: 'Fliegen mit Zahlen schwirren um Frosch Fridolin. Tippe auf die Fliege mit dem richtigen Ergebnis, und schwupps – Zunge raus! Aber Vorsicht: Falsche Fliegen sind Chili-Fliegen und superscharf!',
    startLabel: '🐸 Mittagessen!',
    buttons: false,
    prompt: q => 'Welche Fliege ist die richtige?',

    setup(scene, K) {
      this.flies = []; this.eaten = 0; this.tongue = null; this.look = null; this.lookT = 0; this.blinkT = 2000; this.px = 0; this.py = 0; this.cx = 0; this.cy = 0;
      scene.innerHTML = `<div class="pond" id="pond">${BG}
        <div class="sign" id="sign"></div><div class="tally" id="tally">0 gefangen</div>
        <div class="frog" id="frog">${FROG}</div>
        <svg class="fx-layer" id="fxl"></svg></div>`;
      this.pond = K.$('#pond'); this.frog = K.$('#frog'); this.fxl = K.$('#fxl');
      this.layers = [...this.pond.querySelectorAll('.par')].map(g => ({ g, d: +g.dataset.d }));
      this.pond.addEventListener('pointermove', e => { const r = this.pond.getBoundingClientRect(); this.px = (e.clientX - r.left) / r.width * 2 - 1; this.py = (e.clientY - r.top) / r.height * 2 - 1; });
      this.pond.addEventListener('pointerdown', e => { const f = e.target.closest('.fly'); if (f && !f.classList.contains('flee') && !f.classList.contains('gone')) K.answer(+f.dataset.v, f); });
    },
    targets: K => [...document.querySelectorAll('.fly:not(.flee):not(.gone)')],

    present(q, K) {
      this.flies.forEach(f => { f.el.remove(); f.sh.remove(); });
      const sign = K.$('#sign'); sign.innerHTML = `${MINI_FLY}<span>${q.text} = ?</span>`; sign.classList.remove('pop'); void sign.offsetWidth; sign.classList.add('pop');
      const W = this.pond.clientWidth, n = q.choices.length;
      this.flies = q.choices.map((c, i) => {
        const el = document.createElement('div'); el.className = 'fly'; el.dataset.v = c;
        el.innerHTML = `${FLY}<span class="num">${c}</span>`;
        this.pond.appendChild(el);
        const sh = document.createElement('div'); sh.className = 'fshadow'; this.pond.appendChild(sh);
        const H = this.pond.clientHeight, bx = (W / n) * (i + .5), by = H * .27 + (i % 2) * H * .16 + rnd(-10, 10);
        // Fliegen kommen von außen hereingeflogen
        return { el, sh, svg: el.querySelector('svg'), bx, by, x: i < n / 2 ? -60 : W + 60, y: rnd(60, 200), ph: rnd(0, 6), sp: rnd(.0009, .0015), ax: rnd(18, 34), ay: rnd(14, 24), state: 'in' };
      });
      this.look = K.pick(this.flies);
      K.sfx.tone(200, 0, .5, 'sawtooth', .015, 230);
    },

    // ---------- Animation pro Bild ----------
    tick(dt, now, K) {
      const W = this.pond.clientWidth, H = this.pond.clientHeight;
      for (const f of this.flies) {
        if (f.state === 'caught') continue;
        let tx, ty;
        if (f.state === 'flee') { f.vx = (f.vx || (f.x < W / 2 ? -1 : 1) * .5) * 1.06; tx = f.x + f.vx * dt; ty = f.y - .25 * dt; }
        else { tx = f.bx + Math.sin(now * f.sp + f.ph) * f.ax + Math.sin(now * f.sp * 2.3 + f.ph) * 8; ty = f.by + Math.cos(now * f.sp * 1.7 + f.ph) * f.ay; }
        const k = f.state === 'flee' ? 1 : Math.min(1, dt / 220);
        let nx = f.x + (tx - f.x) * k, ny = f.y + (ty - f.y) * k;
        if (f.state === 'in' && f.x > 0 && f.x < W) nx = Math.max(46, Math.min(W - 46, nx));
        const tilt = Math.max(-25, Math.min(25, (nx - f.x) * 6));
        f.x = nx; f.y = ny;
        f.el.style.transform = `translate(${f.x}px, ${f.y}px)`;
        const hy = Math.max(0, Math.min(1, f.y / (H * .8))), sc = .55 + hy * .6;
        f.sh.style.transform = `translate(${f.x + (f.x - W / 2) * .05}px, ${H * .8}px) scale(${sc})`; f.sh.style.opacity = (.15 + hy * .25).toFixed(2);
        f.svg.style.transform = `rotate(${tilt}deg)`;
        if (f.state === 'flee' && (f.x < -100 || f.x > W + 100)) { f.state = 'gone'; f.el.classList.add('gone'); f.sh.style.opacity = 0; }
      }
      // Parallax: Ebenen folgen Finger/Maus und treiben sanft im Ruhezustand
      const ix = this.px + Math.sin(now / 4200) * .35, iy = this.py * .5 + Math.cos(now / 5300) * .2;
      this.cx += (ix - this.cx) * Math.min(1, dt / 300); this.cy += (iy - this.cy) * Math.min(1, dt / 300);
      for (const L of this.layers) L.g.setAttribute('transform', `translate(${(-this.cx * L.d).toFixed(2)} ${(-this.cy * L.d * .5).toFixed(2)})`);
      // Augen folgen einer Fliege
      this.lookT -= dt;
      if (this.lookT <= 0 || !this.look || this.look.state !== 'in') { const alive = this.flies.filter(f => f.state === 'in'); this.look = alive.length ? K.pick(alive) : null; this.lookT = rnd(1200, 2400); }
      const target = this.tongue ? this.tongue.fly : this.look;
      if (target) this.lookAt(target.el);
      // Blinzeln
      this.blinkT -= dt;
      if (this.blinkT <= 0) { this.frog.classList.add('blink'); K.later(() => this.frog.classList.remove('blink'), 130); this.blinkT = rnd(2200, 5000); }
      if (this.tongue) this.stepTongue(dt, K);
    },
    lookAt(el) {
      const svg = this.frog.querySelector('svg'), r = svg.getBoundingClientRect(), s = r.width / VB.w, t = el.getBoundingClientRect();
      const tx = t.left + t.width / 2, ty = t.top + t.height / 3;
      this.frog.querySelectorAll('.eye').forEach(eye => {
        const ex = r.left + +eye.dataset.x * s, ey = r.top + +eye.dataset.y * s;
        const dx = tx - ex, dy = ty - ey, d = Math.hypot(dx, dy) || 1, m = Math.min(7, d / 12);
        eye.querySelector('.pupil').setAttribute('transform', `translate(${(dx / d * m).toFixed(1)} ${(dy / d * m).toFixed(1)})`);
      });
    },
    mouth() {
      const pr = this.pond.getBoundingClientRect(), r = this.frog.querySelector('svg').getBoundingClientRect(), s = r.width / VB.w;
      return { x: r.left - pr.left + MOUTH.x * s, y: r.top - pr.top + MOUTH.y * s };
    },
    flyPos(f) { const pr = this.pond.getBoundingClientRect(), r = f.svg.getBoundingClientRect(); return { x: r.left - pr.left + r.width / 2, y: r.top - pr.top + r.height * .6 }; },
    drawTongue(m, tip) {
      const W = this.pond.clientWidth, H = this.pond.clientHeight;
      this.fxl.setAttribute('viewBox', `0 0 ${W} ${H}`);
      const mid = { x: (m.x + tip.x) / 2, y: (m.y + tip.y) / 2 - 18 };
      const d = `M${m.x} ${m.y} Q${mid.x} ${mid.y} ${tip.x} ${tip.y}`;
      this.fxl.innerHTML = `<path d="${d}" stroke="#b8325a" stroke-width="15" fill="none" stroke-linecap="round"/><path d="${d}" stroke="#ff7aa2" stroke-width="10" fill="none" stroke-linecap="round"/><circle cx="${tip.x}" cy="${tip.y}" r="10" fill="#ff7aa2" stroke="#b8325a" stroke-width="2.5"/>`;
    },
    stepTongue(dt, K) {
      const tg = this.tongue; tg.t += dt;
      const m = this.mouth();
      if (tg.phase === 'out') {
        const k = Math.min(1, tg.t / 150), p = tg.start || (tg.start = this.flyPos(tg.fly));
        this.drawTongue(m, { x: m.x + (p.x - m.x) * k, y: m.y + (p.y - m.y) * k });
        if (k >= 1) { tg.phase = 'in'; tg.t = 0; tg.fly.state = 'caught'; tg.fly.sh.remove(); K.sfx.tone(900, 0, .05, 'square', .05); }
      } else {
        const k = Math.min(1, tg.t / 240), e = k * k, p = tg.start;
        const tip = { x: p.x + (m.x - p.x) * e, y: p.y + (m.y - p.y) * e };
        this.drawTongue(m, tip);
        tg.fly.el.style.transform = `translate(${tip.x}px, ${tip.y - 18}px) scale(${1 - k * .7})`;
        if (k >= 1) { this.fxl.innerHTML = ''; tg.fly.el.remove(); this.tongue = null; this.swallow(K); }
      }
    },
    swallow(K) {
      const fr = this.frog;
      fr.classList.remove('open'); fr.classList.add('happy');
      K.later(() => fr.classList.remove('happy'), 700);
      this.eaten++;
      const k = Math.min(10, this.eaten);
      fr.querySelector('.belly-g').style.transform = `scale(${1 + k * .028}, ${1 + k * .012})`;
      K.$('#tally').textContent = `${this.eaten} gefangen`;
      K.sfx.tone(170, 0, .22, 'sine', .28, 85);
      K.later(() => { K.sfx.tone(380, 0, .09, 'square', .05, 300); K.sfx.tone(320, .12, .12, 'square', .05, 240); }, 260);
      const m = this.mouth();
      this.puffs(m.x, m.y - 40, ['#ffe066', '#a8ff7a', '#ffffff'], 8, 1.4, -70);
      this.floaty(m.x, m.y - 90, K.pick(['Mjam!', 'Lecker!', 'Gulp!', 'Mehr!']));
      K.confetti.at(fr, 18, ['#ffe066', '#7ed957', '#42d4f4', '#ff8fb1']);
    },
    puffs(x, y, colors, n, scale = 2.2, rise = -60, size = 16, dur = 1) {
      for (let i = 0; i < n; i++) {
        const p = document.createElement('div'); p.className = 'puff';
        const s = size * rnd(.7, 1.3);
        Object.assign(p.style, { left: x + 'px', top: y + 'px', width: s + 'px', height: s + 'px', background: colors[i % colors.length] });
        p.style.setProperty('--dx', rnd(-45, 45) + 'px'); p.style.setProperty('--dy', rise * rnd(.6, 1.4) + 'px'); p.style.setProperty('--s', scale); p.style.setProperty('--dur', dur + 's');
        this.pond.appendChild(p); K.later(() => p.remove(), dur * 1000 + 50);
      }
    },
    floaty(x, y, text) { const f = document.createElement('div'); f.className = 'floaty'; f.textContent = text; f.style.left = x + 'px'; f.style.top = y + 'px'; this.pond.appendChild(f); K.later(() => f.remove(), 1000); },

    correct(q, el, first, K) {
      const f = this.flies.find(x => x.el === el);
      this.frog.classList.add('open');
      K.sfx.tone(300, 0, .14, 'sine', .15, 900);
      this.tongue = { fly: f, phase: 'out', t: 0 };
      this.flies.filter(x => x !== f).forEach(x => { x.state = 'flee'; x.el.classList.add('flee'); });
      return 1500;
    },
    wrong(q, v, el, K) {
      const f = this.flies.find(x => x.el === el);
      el.classList.add('chili', 'flee'); f.state = 'flee';
      K.later(() => K.bubble(this.pond, 'Hihi! Chili-Fliege!', `${Math.max(4, f.x - 40)}px`, `${Math.max(70, f.y - 40)}px`, 900), 50);
      const fr = this.frog; fr.classList.add('hot');
      const m = this.mouth();
      // Feuer aus dem Maul, Dampf aus dem Kopf
      for (let i = 0; i < 4; i++) K.later(() => this.puffs(m.x, m.y + 4, ['#ff6b1a', '#ffd23f', '#ff3b1a'], 6, 1.8, -80, 20, .8), i * 160);
      K.later(() => this.puffs(m.x, m.y - 110, ['#ffffff', '#e8f4ff'], 7, 2.6, -50, 22, 1.2), 300);
      K.sfx.noise(0, .8, .4, 1800, 'bandpass', 500);
      K.later(() => K.sfx.tone(700, 0, .3, 'sawtooth', .05, 1100), 200);
      K.bubble(this.pond, K.pick(['Scharf! Scharf!', 'Wasser! Wasser!', 'Hilfe, Chili!']), '8px', '58%', 1300);
      K.later(() => fr.classList.remove('hot'), 1300);
    },
    highlight(q) { const f = this.flies.find(x => +x.el.dataset.v === q.correct && x.state === 'in'); if (f) f.el.querySelector('.num').classList.add('hint-glow'); },
    beforeEnd(st, done, K) {
      const fr = this.frog; fr.classList.add('open');
      K.later(() => {
        K.sfx.tone(110, 0, .7, 'sawtooth', .2, 70);
        K.bubble(this.pond, '*RÜLPS* 😆', '50%', '40%', 1200);
        this.puffs(this.mouth().x, this.mouth().y - 20, ['#ffffff'], 6, 2.4, -60, 22);
      }, 300);
      K.later(() => { fr.classList.remove('open'); fr.classList.add('happy'); }, 1000);
      K.later(done, 1700);
    },
    endText() { return `Fridolin hat ${this.eaten} Fliegen gefuttert und ist kugelrund!`; },
    endEmoji: s => ['🐸', '🪰', '🏆'][s - 1]
  });
})();
