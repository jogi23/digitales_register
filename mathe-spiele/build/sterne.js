// ===== Thema: Sternenfänger (friedlich – fangen statt schießen) =====
window.THEME = (() => {
  const P = {
    target: '#ffe680', targetText: '#ffe680', text: '#ffffff',
    plate: 'rgba(40,30,85,0.72)', plateTarget: 'rgba(70,45,130,0.94)',
    good: '#a8ffcf', bad: '#ff9ab8', hint: '#ffe680', solution: '#ffe680',
    hitColors: ['#ffe680', '#ffb3d1', '#b3e5ff'],
    shield: ['255,154,184', '255,214,128', '168,255,207'],
    bannerGlow: '#ff9ad5'
  };
  const font = (w, s) => `700 ${s}px Fredoka, "Trebuchet MS", sans-serif`;
  const STAR_COLORS = [['#fff6b0', '#ffd23f'], ['#ffe0f0', '#ff8fc8'], ['#dcfff0', '#5fe3a8'], ['#e0f3ff', '#7cc8ff'], ['#f1e4ff', '#b48cff']];
  let S = null; // Zustand der Szene (Glas, schlafende Sterne, fliegende Sterne)

  function starPath(ctx, r, inner = 0.5, points = 5) {
    ctx.beginPath();
    for (let i = 0; i < points * 2; i++) {
      const rr = i % 2 ? r * inner : r, a = i * Math.PI / points - Math.PI / 2;
      ctx.lineTo(Math.cos(a) * rr, Math.sin(a) * rr);
    }
    ctx.closePath();
  }
  function cuteStar(ctx, r, cols, now, seed, mood) {
    const g = ctx.createRadialGradient(-r * 0.25, -r * 0.3, r * 0.1, 0, 0, r);
    g.addColorStop(0, cols[0]); g.addColorStop(1, cols[1]);
    ctx.lineJoin = 'round';
    starPath(ctx, r, 0.52); ctx.fillStyle = g; ctx.fill();
    ctx.lineWidth = Math.max(2, r * 0.12); ctx.strokeStyle = cols[1]; ctx.stroke();
    // Gesicht – je nach Stimmung
    const blink = mood === 'sleep' || (mood === '' && Math.floor(now / 140 + seed * 37) % 30 === 0);
    ctx.fillStyle = '#3b2a55'; ctx.strokeStyle = '#3b2a55'; ctx.lineWidth = Math.max(1.5, r * 0.07); ctx.lineCap = 'round';
    [-1, 1].forEach(s => {
      const ex = s * r * 0.2;
      if (mood === 'happy') { ctx.beginPath(); ctx.arc(ex, r * 0.06, r * 0.09, 1.1 * Math.PI, 1.9 * Math.PI); ctx.stroke(); }
      else if (blink) { ctx.beginPath(); ctx.arc(ex, r * 0.02, r * 0.08, 0, Math.PI); ctx.stroke(); }
      else {
        const big = mood === 'excited' ? 1.35 : 1;
        ctx.beginPath(); ctx.ellipse(ex, 0, r * 0.075 * big, r * 0.105 * big, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(ex + r * 0.03, -r * 0.04, r * 0.034 * big, 0, Math.PI * 2); ctx.fill();
        if (big > 1) { ctx.beginPath(); ctx.arc(ex - r * 0.03, r * 0.04, r * 0.018, 0, Math.PI * 2); ctx.fill(); }
        ctx.fillStyle = '#3b2a55';
      }
    });
    ctx.beginPath();
    if (mood === 'oops') { ctx.arc(0, r * 0.2, r * 0.07, 0, Math.PI * 2); ctx.stroke(); }
    else if (mood === 'happy' || mood === 'excited') {
      ctx.moveTo(-r * 0.13, r * 0.12); ctx.arc(0, r * 0.12, r * 0.13, 0, Math.PI); ctx.closePath(); ctx.fill();
      ctx.fillStyle = '#ff8fb1'; ctx.beginPath(); ctx.ellipse(0, r * 0.2, r * 0.06, r * 0.035, 0, 0, Math.PI * 2); ctx.fill();
    } else { ctx.arc(0, r * 0.13, r * 0.12, 0.15 * Math.PI, 0.85 * Math.PI); ctx.stroke(); }
    ctx.fillStyle = 'rgba(255,120,160,0.45)';
    [-1, 1].forEach(s => { ctx.beginPath(); ctx.ellipse(s * r * 0.34, r * 0.15, r * 0.08, r * 0.05, 0, 0, Math.PI * 2); ctx.fill(); });
  }

  // ---------- Tierfreunde (selbst gezeichnet) ----------
  function eye(ctx, ex, ey, lx, ly, blink, mood, r = 3.2) {
    ctx.fillStyle = '#2b1a10'; ctx.strokeStyle = '#2b1a10'; ctx.lineWidth = 1.8; ctx.lineCap = 'round';
    if (mood === 'cheer') { ctx.beginPath(); ctx.arc(ex, ey + 1.5, r, 1.15 * Math.PI, 1.85 * Math.PI); ctx.stroke(); return; }
    if (blink) { ctx.beginPath(); ctx.moveTo(ex - r, ey); ctx.lineTo(ex + r, ey); ctx.stroke(); return; }
    const px = ex + lx * 1.3, py = ey + ly * 1.3;
    ctx.beginPath(); ctx.arc(px, py, r, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(px - 1, py - 1.2, r * 0.36, 0, Math.PI * 2); ctx.fill();
    if (mood === 'sad') { ctx.fillStyle = '#7fd3ff'; ctx.beginPath(); ctx.ellipse(ex + 1, ey + r + 3, 1.6, 2.4, 0, 0, Math.PI * 2); ctx.fill(); }
  }
  function lookDir(x, y, look) { if (!look) return [0, 0]; const dx = look.x - x, dy = look.y - y, d = Math.hypot(dx, dy) || 1; return [dx / d, dy / d]; }
  function bounce(now, mood, phase) {
    if (mood === 'cheer') return { hop: -Math.abs(Math.sin(now / 110 + phase)) * 12, sq: 1 + Math.sin(now / 55 + phase) * 0.05 };
    return { hop: Math.sin(now / 700 + phase) * 1.2, sq: 1 + Math.sin(now / 700 + phase) * 0.025 };
  }
  function drawFox(ctx, x, y, now, look, mood) {
    const { hop, sq } = bounce(now, mood, 0), cheer = mood === 'cheer', sad = mood === 'sad';
    ctx.save(); ctx.translate(x, y + hop); ctx.scale(1.3 / sq, 1.3 * sq);
    // Schwanz wedelt
    const tw = Math.sin(now / 380) * 0.25 + (cheer ? Math.sin(now / 70) * 0.4 : 0) - (sad ? 0.5 : 0);
    ctx.save(); ctx.translate(10, -8); ctx.rotate(-0.5 + tw);
    ctx.fillStyle = '#ef7b2b'; ctx.beginPath(); ctx.ellipse(14, -8, 17, 9, -0.6, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#fff6ec'; ctx.beginPath(); ctx.ellipse(26, -17, 7, 6, -0.6, 0, Math.PI * 2); ctx.fill(); ctx.restore();
    ctx.fillStyle = '#ef7b2b'; ctx.beginPath(); ctx.ellipse(0, -15, 15, 17, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#fff6ec'; ctx.beginPath(); ctx.ellipse(0, -11, 8, 12, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#4a2a14';
    if (cheer) { ctx.beginPath(); ctx.ellipse(-15, -31, 4, 6, -0.5, 0, Math.PI * 2); ctx.ellipse(15, -31, 4, 6, 0.5, 0, Math.PI * 2); ctx.fill(); }
    ctx.beginPath(); ctx.ellipse(-6, -1, 5, 3, 0, 0, Math.PI * 2); ctx.ellipse(6, -1, 5, 3, 0, 0, Math.PI * 2); ctx.fill();
    // Kopf
    const [lx, ly] = lookDir(x, y - 36, look);
    ctx.translate(0, -36); ctx.rotate(lx * 0.14 + (sad ? 0.18 : 0));
    [-1, 1].forEach(sd => {
      const droop = sad ? 7 : 0;
      ctx.fillStyle = '#ef7b2b'; ctx.beginPath(); ctx.moveTo(sd * 4, -9); ctx.lineTo(sd * 15, -26 + droop); ctx.lineTo(sd * 15, -3); ctx.closePath(); ctx.fill();
      ctx.fillStyle = '#4a2a14'; ctx.beginPath(); ctx.moveTo(sd * 8, -10); ctx.lineTo(sd * 14, -21 + droop); ctx.lineTo(sd * 13.5, -7); ctx.closePath(); ctx.fill();
    });
    ctx.fillStyle = '#ef7b2b'; ctx.beginPath(); ctx.ellipse(0, 0, 16, 13, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#fff6ec'; ctx.beginPath(); ctx.ellipse(-7, 5, 8, 6, 0, 0, Math.PI * 2); ctx.ellipse(7, 5, 8, 6, 0, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.ellipse(0, 8, 5, 4, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#2b1a10'; ctx.beginPath(); ctx.ellipse(0, 5, 2.6, 2, 0, 0, Math.PI * 2); ctx.fill();
    const blink = now % 3400 < 130;
    eye(ctx, -6, -2, lx, ly, blink, mood); eye(ctx, 6, -2, lx, ly, blink, mood);
    ctx.fillStyle = 'rgba(255,120,150,0.5)'; ctx.beginPath(); ctx.ellipse(-11, 4, 3.5, 2.2, 0, 0, Math.PI * 2); ctx.ellipse(11, 4, 3.5, 2.2, 0, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = '#2b1a10'; ctx.lineWidth = 1.6; ctx.beginPath();
    if (cheer) ctx.arc(0, 9, 4, 0.1 * Math.PI, 0.9 * Math.PI); else if (sad) ctx.arc(0, 14, 3, 1.2 * Math.PI, 1.8 * Math.PI); else ctx.arc(0, 9, 2.6, 0.2 * Math.PI, 0.8 * Math.PI);
    ctx.stroke();
    ctx.restore();
  }
  function drawHog(ctx, x, y, now, look, mood) {
    const { hop, sq } = bounce(now, mood, 1.3), cheer = mood === 'cheer', sad = mood === 'sad';
    ctx.save(); ctx.translate(x, y + hop); ctx.scale(-1.3 / sq, 1.3 * sq); // schaut zum Glas
    // Stacheln
    ctx.fillStyle = '#5b3f27';
    const wig = cheer ? Math.sin(now / 50) * 0.08 : 0;
    for (let i = 0; i <= 13; i++) {
      const a = Math.PI * 0.95 + i / 13 * Math.PI * 1.1 + wig, r1 = 15, r2 = 25 + (i % 2) * 4;
      ctx.beginPath();
      ctx.moveTo(Math.cos(a - 0.16) * r1 - 2, -14 + Math.sin(a - 0.16) * r1);
      ctx.lineTo(Math.cos(a) * r2 - 2, -14 + Math.sin(a) * r2);
      ctx.lineTo(Math.cos(a + 0.16) * r1 - 2, -14 + Math.sin(a + 0.16) * r1); ctx.fill();
    }
    ctx.fillStyle = '#8a6240'; ctx.beginPath(); ctx.ellipse(-2, -13, 19, 15, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#4a2a14'; ctx.beginPath(); ctx.ellipse(-8, -1, 5, 3, 0, 0, Math.PI * 2); ctx.ellipse(6, -1, 5, 3, 0, 0, Math.PI * 2); ctx.fill();
    if (cheer) { ctx.beginPath(); ctx.ellipse(12, -24, 3.5, 5, 0.5, 0, Math.PI * 2); ctx.fill(); }
    // Gesicht
    const [lx0, ly] = lookDir(x, y - 14, look), lx = -lx0;
    ctx.fillStyle = '#f2d6b0'; ctx.beginPath(); ctx.ellipse(7, -12, 12, 11, 0.2, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.ellipse(17, -9, 7, 4.5, 0.2, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#2b1a10'; ctx.beginPath(); ctx.arc(23, -10, 2.6, 0, Math.PI * 2); ctx.fill();
    const blink = (now + 1700) % 3900 < 130;
    eye(ctx, 6, -16, lx, ly, blink, mood, 2.5); eye(ctx, 13, -15, lx, ly, blink, mood, 2.3);
    ctx.fillStyle = 'rgba(255,120,150,0.5)'; ctx.beginPath(); ctx.ellipse(8, -8, 3, 2, 0, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = '#2b1a10'; ctx.lineWidth = 1.5; ctx.beginPath();
    if (cheer) ctx.arc(16, -6, 3, 0.1 * Math.PI, 0.9 * Math.PI); else if (sad) ctx.arc(16, -2, 2.5, 1.2 * Math.PI, 1.8 * Math.PI); else ctx.arc(16, -6, 2, 0.2 * Math.PI, 0.8 * Math.PI);
    ctx.stroke();
    ctx.restore();
  }
  // Zeiger für Parallax
  const PTR = { x: 0, y: 0 }; let ptrBound = false;
  function sparkle(ctx, x, y, s, a) {
    ctx.globalAlpha = a; ctx.beginPath();
    ctx.moveTo(x, y - s); ctx.quadraticCurveTo(x, y, x + s, y); ctx.quadraticCurveTo(x, y, x, y + s); ctx.quadraticCurveTo(x, y, x - s, y); ctx.quadraticCurveTo(x, y, x, y - s);
    ctx.fill(); ctx.globalAlpha = 1;
  }
  function buildHills(A) {
    const W = A.W + 80, H = A.H;
    const layer = draw => { const c = document.createElement('canvas'); c.width = Math.max(1, Math.round(W * A.DPR)); c.height = Math.max(1, Math.round(H * A.DPR)); const x = c.getContext('2d'); x.scale(A.DPR, A.DPR); draw(x); return c; };
    const hill = (x, base, amp, freq, col) => {
      x.fillStyle = col; x.beginPath(); x.moveTo(0, H);
      for (let px = 0; px <= W; px += 10) x.lineTo(px, base - Math.sin(px / freq + amp) * 18 - Math.sin(px / (freq * 2.3)) * 12);
      x.lineTo(W, H); x.closePath(); x.fill();
    };
    const far = layer(x => hill(x, H * 0.74, 1, 90, '#3a3a7a'));
    const mid = layer(x => hill(x, H * 0.8, 3, 70, '#2c5a6e'));
    const near = layer(x => {
      hill(x, H - 70, 5, 120, '#2f7a5e');
      for (let i = 0; i < W / 9; i++) {
        const fx = A.rand(0, W), fy = A.rand(H - 50, H - 4);
        x.fillStyle = A.pick(['#ffd1e8', '#fff3a8', '#c9e8ff', '#ffffff', '#e5ccff']);
        for (let k = 0; k < 5; k++) { const a = k * 1.256; x.beginPath(); x.arc(fx + Math.cos(a) * 2.2, fy + Math.sin(a) * 2.2, 1.8, 0, Math.PI * 2); x.fill(); }
        x.fillStyle = '#ffcf4a'; x.beginPath(); x.arc(fx, fy, 1.3, 0, Math.PI * 2); x.fill();
      }
      const tx = 40 + A.W * 0.1;
      x.fillStyle = '#3b2b2b'; x.fillRect(tx - 4, H - 110, 8, 60);
      x.fillStyle = '#245c4a'; [[0, -120, 30], [-18, -100, 22], [18, -100, 22]].forEach(([dx, dy, r]) => { x.beginPath(); x.arc(tx + dx, H + dy, r, 0, Math.PI * 2); x.fill(); });
    });
    return { far, mid, near };
  }

  return {
    id: 'sternenfaenger',
    calm: true,
    comboIcon: '✨',
    text: {
      wave: 'NACHT', waveDone: 'NACHT GESCHAFFT', newHi: 'NEUER REKORD!', hits: 'GEFANGEN', tryAgain: 'Nochmal!',
      idle: 'WARTE AUF STERNE…', last: 'LETZTE STERNE…', target: 'STERN', hint: 'TASTEN 1–4 ODER ANTIPPEN'
    },
    palette: P, font,
    titleFont: s => `700 ${s}px Fredoka, sans-serif`,
    music: { bpm: 84, wave: 'triangle', notes: ['C5', 'E5', 'G5', 'E5', 'A5', 'G5', 'E5', null, 'D5', 'F5', 'A5', 'F5', 'G5', 'E5', 'C5', null], cutoff: 3200, vol: 0.05, sustain: 2.2 },
    sfx: {
      shot(A) { [1568, 2093, 2637].forEach((f, i) => A.osc('sine', f, 0, 0.25, 0.06, i * 0.04)); },
      boom(A) { [1047, 1319, 1568, 2093].forEach((f, i) => A.osc('triangle', f, 0, 0.35, 0.08, i * 0.06)); },
      error(A) { A.osc('sine', 440, 330, 0.25, 0.08); },
      hit(A) { A.osc('sine', 660, 330, 0.5, 0.08); A.osc('sine', 494, 247, 0.6, 0.06, 0.15); },
      lock(A) { A.osc('sine', 2093, 0, 0.12, 0.03); },
      combo(A) { [1319, 1568, 2093, 2637].forEach((f, i) => A.osc('sine', f, 0, 0.2, 0.06, i * 0.05)); },
      wave(A) { [523, 659, 784, 1047, 1319, 1568].forEach((f, i) => A.osc('triangle', f, 0, 0.4, 0.09, i * 0.1)); },
      over(A) { [784, 659, 523, 392].forEach((f, i) => A.osc('triangle', f, 0, 0.5, 0.08, i * 0.25)); },
      tick(A) { A.osc('sine', 1760, 0, 0.06, 0.03); }
    },
    enemyRadius: [26, 34],

    enemyInit(e, A) { e.cols = A.pick(STAR_COLORS); e.rot = A.rand(-0.3, 0.3); e.spin = A.rand(-0.0006, 0.0006); e.vx = A.rand(-0.012, 0.012); },
    enemyUpdate(e, dt, now, A) {
      e.rot += e.spin * dt;
      if (Math.abs(e.rot) > 0.35) e.spin *= -1;
      if (Math.random() < 0.3) A.particle(e.x + A.rand(-0.5, 0.5) * e.r, e.y - e.r * 0.5, e.cols[0], { vx: A.rand(-0.01, 0.01), vy: -A.rand(0.01, 0.04), life: A.rand(400, 800), size: A.rand(1, 2.5) });
    },
    textY: e => e.r * 1.25,
    enemyDraw(ctx, e, now, isT, A) {
      const { x, y, r } = e;
      // Leuchtschein auf der Wiese – heller, je näher der Stern kommt
      const gy = A.H - A.BASE_H + 8, k = Math.max(0, Math.min(1, y / gy)), R = r * (0.9 + k * 1.6);
      ctx.save(); ctx.translate(x, gy); ctx.scale(1, 0.28);
      const gl = ctx.createRadialGradient(0, 0, 0, 0, 0, R); gl.addColorStop(0, `rgba(255,240,170,${(0.06 + k * 0.38).toFixed(2)})`); gl.addColorStop(1, 'rgba(255,240,170,0)');
      ctx.fillStyle = gl; ctx.beginPath(); ctx.arc(0, 0, R, 0, Math.PI * 2); ctx.fill(); ctx.restore();
      ctx.translate(x, y);
      // Glitzerschweif
      const tg = ctx.createLinearGradient(0, 0, 0, -r * 3.4);
      tg.addColorStop(0, e.cols[1] + 'aa'); tg.addColorStop(1, e.cols[1] + '00');
      ctx.fillStyle = tg; ctx.beginPath(); ctx.moveTo(-r * 0.5, -r * 0.2); ctx.quadraticCurveTo(0, -r * 4, r * 0.5, -r * 0.2); ctx.closePath(); ctx.fill();
      // Wackeln, wenn die Antwort falsch war
      if (e.flash > 0) ctx.translate(Math.sin(now / 30) * 5 * e.flash, 0);
      ctx.rotate(e.rot);
      const sq = Math.sin(now / 170 + e.seed * 10) * 0.05; ctx.scale(1 + sq, 1 - sq);
      ctx.shadowBlur = isT ? 30 : 16; ctx.shadowColor = isT ? '#fff3b0' : e.cols[1];
      cuteStar(ctx, r, e.cols, now, e.seed, e.flash > 0 ? 'oops' : isT ? 'excited' : '');
      ctx.shadowBlur = 0;
    },
    drawReticle(ctx, e, now) {
      // Sanfter Lichtkranz mit Funkeln statt Fadenkreuz
      const rr = e.r + 14;
      const g = ctx.createRadialGradient(0, 0, e.r * 0.6, 0, 0, rr + 10);
      g.addColorStop(0, 'rgba(255,240,170,0)'); g.addColorStop(0.7, 'rgba(255,240,170,0.28)'); g.addColorStop(1, 'rgba(255,240,170,0)');
      ctx.fillStyle = g; ctx.beginPath(); ctx.arc(0, 0, rr + 10, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#fff6c8';
      for (let i = 0; i < 4; i++) {
        const a = now / 900 + i * Math.PI / 2;
        sparkle(ctx, Math.cos(a) * rr, Math.sin(a) * rr, 5 + Math.sin(now / 200 + i) * 2, 0.9);
      }
    },

    buildBg(A) {
      const W = A.W, H = A.H;
      if (!ptrBound) { ptrBound = true; addEventListener('pointermove', e => { PTR.x = e.clientX / innerWidth * 2 - 1; PTR.y = e.clientY / innerHeight * 2 - 1; }, { passive: true }); }
      S = {
        hills: buildHills(A),
        stars: Array.from({ length: Math.round(W * H / 3000) }, () => ({ x: A.rand(0, W), y: A.rand(0, H * 0.75), s: A.rand(0.5, 1.8), tw: A.rand(0, 6) })),
        flies: Array.from({ length: 14 }, () => ({ x: A.rand(0, W), y: A.rand(H * 0.55, H - 60), p: A.rand(0, 6), sp: A.rand(0.6, 1.4) })),
        clouds: Array.from({ length: 3 }, () => ({ x: A.rand(0, W), y: A.rand(H * 0.12, H * 0.4), w: A.rand(100, 170), s: A.rand(0.004, 0.01) })),
        jar: S ? S.jar : 0, jarPos: [], flyers: [], sleepers: [], cx: 0, cy: 0, cheer: 0, sad: 0, bump: 0
      };
      for (let i = 0; i < 60; i++) S.jarPos.push([A.rand(-16, 16), A.rand(0, 1), A.rand(0, 6), A.pick(STAR_COLORS)]);
      return S;
    },
    drawBg(ctx, bg, now, dt, moving, speed, A) {
      const W = A.W, H = A.H;
      const g = ctx.createLinearGradient(0, 0, 0, H);
      g.addColorStop(0, '#1a1546'); g.addColorStop(0.55, '#4a3a8a'); g.addColorStop(0.85, '#c77dab'); g.addColorStop(1, '#f2b5a8');
      ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
      // Parallax: Ebenen folgen dem Finger und treiben sanft
      const tx = PTR.x + Math.sin(now / 4500) * 0.3, ty = PTR.y * 0.5 + Math.cos(now / 5600) * 0.2;
      bg.cx += (tx - bg.cx) * Math.min(1, dt / 300); bg.cy += (ty - bg.cy) * Math.min(1, dt / 300);
      const off = d => [-bg.cx * d, -bg.cy * d * 0.5];
      ctx.save(); ctx.translate(...off(2));
      ctx.fillStyle = '#fff';
      bg.stars.forEach(s => { ctx.globalAlpha = 0.35 + Math.sin(now / 600 + s.tw) * 0.3; ctx.fillRect(s.x, s.y, s.s, s.s); });
      ctx.globalAlpha = 1;
      // Mond mit Gesicht
      const mx = W * 0.8, my = H * 0.14, mr = Math.min(40, W * 0.08);
      const mg = ctx.createRadialGradient(mx, my, mr * 0.6, mx, my, mr * 3);
      mg.addColorStop(0, 'rgba(255,240,200,0.3)'); mg.addColorStop(1, 'rgba(255,240,200,0)');
      ctx.fillStyle = mg; ctx.fillRect(mx - mr * 3, my - mr * 3, mr * 6, mr * 6);
      ctx.fillStyle = '#fff4cf'; ctx.beginPath(); ctx.arc(mx, my, mr, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#1a1546'; ctx.beginPath(); ctx.arc(mx + mr * 0.45, my - mr * 0.15, mr * 0.85, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
      ctx.save(); ctx.translate(...off(4));
      // Wolken
      bg.clouds.forEach(c => {
        if (moving) { c.x += c.s * dt; if (c.x - c.w > W) c.x = -c.w; }
        ctx.fillStyle = 'rgba(255,220,240,0.18)';
        ctx.beginPath(); ctx.ellipse(c.x, c.y, c.w * 0.5, c.w * 0.13, 0, 0, Math.PI * 2); ctx.ellipse(c.x - c.w * 0.15, c.y - c.w * 0.08, c.w * 0.22, c.w * 0.12, 0, 0, Math.PI * 2); ctx.fill();
      });
      ctx.restore();
      [[bg.hills.far, 5], [bg.hills.mid, 9], [bg.hills.near, 14]].forEach(([c, d]) => { const [ox, oy] = off(d); ctx.drawImage(c, -40 + ox, oy, W + 80, H); });
      ctx.save(); ctx.translate(...off(14));
      // Glühwürmchen
      bg.flies.forEach(f => {
        f.p += 0.0015 * dt * f.sp;
        const fx = f.x + Math.sin(f.p) * 30, fy = f.y + Math.cos(f.p * 1.3) * 16;
        const a = 0.4 + Math.sin(now / 300 + f.p * 5) * 0.4;
        const fg = ctx.createRadialGradient(fx, fy, 0, fx, fy, 8);
        fg.addColorStop(0, `rgba(255,255,170,${a})`); fg.addColorStop(1, 'rgba(255,255,170,0)');
        ctx.fillStyle = fg; ctx.beginPath(); ctx.arc(fx, fy, 8, 0, Math.PI * 2); ctx.fill();
      });
      ctx.restore();
    },
    muzzle(A) { return { x: A.W / 2, y: A.H - A.BASE_H - 30 }; },
    noAimLine: true,
    drawBase(ctx, bg, now, s, A) {
      const W = A.W, H = A.H, by = H - A.BASE_H;
      // Schlafende, verpasste Sterne auf der Wiese
      bg.sleepers = bg.sleepers.filter(z => now - z.t0 < 6000);
      bg.sleepers.forEach(z => {
        const a = Math.min(1, (6000 - (now - z.t0)) / 1500);
        ctx.save(); ctx.globalAlpha = a * 0.85; ctx.translate(z.x, by + 18); ctx.rotate(0.4);
        cuteStar(ctx, 12, z.cols, now, 0, 'sleep'); ctx.restore();
        ctx.globalAlpha = a; ctx.fillStyle = '#e8e0ff'; ctx.font = font(700, 12);
        const k = ((now - z.t0) / 1200) % 1;
        ctx.fillText('z', z.x + 12 + k * 8, by + 4 - k * 14); ctx.fillText('Z', z.x + 18 + k * 6, by - 8 - k * 12);
        ctx.globalAlpha = 1;
      });
      // Sanfte Leuchtlinie über der Wiese
      const col = A.shield(s.lives), pulse = 0.5 + Math.sin(now / 600) * 0.2;
      ctx.strokeStyle = `rgba(${col},${0.25 + pulse * 0.3})`; ctx.lineWidth = 2; ctx.setLineDash([1, 9]); ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(0, by); ctx.lineTo(W, by); ctx.stroke(); ctx.setLineDash([]);
      // Fangglas
      const cx = W / 2, cy = H - A.BASE_H + 8, jw = 46, jh = 58;
      ctx.save(); ctx.translate(cx, cy);
      const bk = Math.max(0, 1 - (now - bg.bump) / 450), bs = Math.sin(bk * Math.PI) * 0.12 * bk;
      ctx.scale(1 + bs, 1 - bs);
      const fill = Math.min(1, bg.jar / 40);
      // Sterne im Glas
      ctx.save(); ctx.beginPath(); A.roundRect(-jw / 2 + 3, -jh + 8, jw - 6, jh - 10, 10); ctx.clip();
      const n = Math.min(bg.jarPos.length, bg.jar);
      for (let i = 0; i < n; i++) {
        const [dx, k, rot, cols] = bg.jarPos[i];
        const yy = -4 - (i / 60) * (jh - 16) - k * 4;
        ctx.save(); ctx.translate(dx, yy); ctx.rotate(rot); starPath(ctx, 5, 0.5);
        ctx.fillStyle = cols[1]; ctx.shadowBlur = 8; ctx.shadowColor = cols[0]; ctx.fill(); ctx.restore();
      }
      ctx.restore();
      // Glas-Leuchten wächst mit der Füllung
      const jg = ctx.createRadialGradient(0, -jh / 2, 4, 0, -jh / 2, jw * 1.4);
      jg.addColorStop(0, `rgba(255,240,160,${0.15 + fill * 0.4})`); jg.addColorStop(1, 'rgba(255,240,160,0)');
      ctx.fillStyle = jg; ctx.beginPath(); ctx.arc(0, -jh / 2, jw * 1.4, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = 'rgba(220,240,255,0.85)'; ctx.lineWidth = 3;
      A.roundRect(-jw / 2, -jh, jw, jh, 12); ctx.fillStyle = 'rgba(200,230,255,0.12)'; ctx.fill(); ctx.stroke();
      ctx.fillStyle = '#c98a4b'; A.roundRect(-jw / 2 - 3, -jh - 9, jw + 6, 10, 4); ctx.fill();
      ctx.fillStyle = 'rgba(255,255,255,0.5)'; A.roundRect(-jw / 2 + 6, -jh + 10, 5, jh - 22, 3); ctx.fill();
      ctx.restore();
      // Tierfreunde neben dem Glas
      const mood = now < bg.cheer ? 'cheer' : now < bg.sad ? 'sad' : '';
      const look = s.target ? { x: s.target.x, y: s.target.y } : bg.flyers.length ? { x: cx, y: cy - 60 } : null;
      drawFox(ctx, cx - 70, cy + 6, now, look, mood);
      drawHog(ctx, cx + 76, cy + 8, now, look, mood);
      ctx.textAlign = 'center'; ctx.textBaseline = 'alphabetic';
      // Zahl der gefangenen Sterne
      ctx.font = font(700, 14); ctx.fillStyle = '#fff6c8'; ctx.fillText(`★ ${bg.jar}`, cx, cy + 22);
      // Sterne fliegen ins Glas
      const mouth = this.muzzle(A);
      bg.flyers = bg.flyers.filter(f => {
        const k = Math.min(1, (now - f.t0) / 650);
        const e = 1 - Math.pow(1 - k, 2);
        const x = f.x + (mouth.x - f.x) * e, y = f.y + (mouth.y - f.y) * e - Math.sin(k * Math.PI) * 60;
        ctx.save(); ctx.translate(x, y); ctx.rotate(k * 6); ctx.shadowBlur = 20; ctx.shadowColor = f.cols[0];
        cuteStar(ctx, f.r * (1 - k * 0.75), f.cols, now, 0, 'happy'); ctx.restore();
        if (Math.random() < 0.6) A.particle(x, y, f.cols[0], { speed: 0.03, life: 500, size: A.rand(1, 2.5) });
        if (k >= 1) {
          bg.jar++; bg.bump = now; bg.cheer = now + 1100; bg.sad = 0;
          for (let i = 0; i < 12; i++) A.particle(mouth.x, mouth.y, A.pick(['#fff6b0', '#ffffff', f.cols[1]]), { speed: A.rand(0.05, 0.2), life: 600 });
          return false;
        }
        return true;
      });
    },
    shotDur: 170,
    drawShot(ctx, sx, sy, ex, ey, alpha, k, now) {
      // Zauberband aus Licht, das den Stern einfängt
      ctx.globalAlpha = alpha;
      const mx = (sx + ex) / 2 + (ex > sx ? -60 : 60), my = (sy + ey) / 2;
      const g = ctx.createLinearGradient(sx, sy, ex, ey);
      g.addColorStop(0, '#a8ffcf'); g.addColorStop(0.5, '#ffe680'); g.addColorStop(1, '#ff9ad5');
      ctx.lineCap = 'round'; ctx.shadowBlur = 18; ctx.shadowColor = '#fff3b0';
      ctx.strokeStyle = g; ctx.lineWidth = 6;
      ctx.beginPath(); ctx.moveTo(sx, sy); ctx.quadraticCurveTo(mx, my, ex, ey); ctx.stroke();
      ctx.shadowBlur = 0; ctx.strokeStyle = 'rgba(255,255,255,0.9)'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(sx, sy); ctx.quadraticCurveTo(mx, my, ex, ey); ctx.stroke();
      ctx.fillStyle = '#fff';
      for (let i = 1; i < 6; i++) {
        const t = i / 6, x = (1 - t) * (1 - t) * sx + 2 * (1 - t) * t * mx + t * t * ex, y = (1 - t) * (1 - t) * sy + 2 * (1 - t) * t * my + t * t * ey;
        sparkle(ctx, x, y, 3 + Math.sin(now / 80 + i) * 1.5, alpha);
      }
    },
    explode(e, A) {
      // Kein Zerstören: Der Stern fliegt ins Glas
      S.flyers.push({ x: e.x, y: e.y, r: e.r, cols: e.cols, t0: performance.now() });
      for (let i = 0; i < 16; i++) A.particle(e.x, e.y, A.pick([e.cols[0], '#ffffff', '#fff3b0']), { speed: A.rand(0.03, 0.18), life: A.rand(400, 800) });
      A.ring({ x: e.x, y: e.y, r: e.r * 0.6, max: e.r * 1.8, life: 420, color: '#fff3b0' });
    },
    onCorrect(btn, combo, A) {
      btn.classList.remove('right'); void btn.offsetWidth; btn.classList.add('right');
      setTimeout(() => btn.classList.remove('right'), 650);
      if ([3, 5, 7, 10, 15, 20].includes(combo)) {
        const d = document.createElement('div'); d.className = 'streak-pop'; d.textContent = `✨ ${combo}er-Serie!`;
        document.body.appendChild(d); setTimeout(() => d.remove(), 1400);
        [1047, 1319, 1568, 2093].forEach((f, k) => A.tone('triangle', f, 0, 0.18, 0.07, k * 0.07));
      }
    },
    rate(st, A) {
      const stars = st.acc >= 90 ? 3 : st.acc >= 70 ? 2 : 1;
      const panel = st.screen.querySelector('.panel'), big = panel.querySelector('.big-score');
      let row = panel.querySelector('.end-stars');
      if (!row) { row = document.createElement('div'); row.className = 'end-stars'; big.insertAdjacentElement('afterend', row); }
      row.innerHTML = [1, 2, 3].map(i => `<span class="${i <= stars ? 'on' : ''}" style="animation-delay:${0.3 + i * 0.38}s">★</span>`).join('');
      for (let i = 1; i <= stars; i++) setTimeout(() => { A.tone('triangle', 660 + i * 220, 0, 0.25, 0.12); A.tone('sine', 990 + i * 330, 0, 0.2, 0.05, 0.05); }, (0.3 + i * 0.38) * 1000 + 220);
    },
    onWave(st, A) { this.rate(st, A); },
    onOver(st, A) { this.rate(st, A); },
    missed(e, A) {
      // Verpasster Stern legt sich schlafen
      S.sleepers.push({ x: e.x, cols: e.cols, t0: performance.now() });
      S.sad = performance.now() + 1800;
      for (let i = 0; i < 10; i++) A.particle(e.x, A.H - A.BASE_H, e.cols[0], { speed: A.rand(0.02, 0.1), life: 600 });
    }
  };
})();
