// ===== Thema: Zauberburg =====
window.THEME = (() => {
  const P = {
    target: '#7fe7ff', targetText: '#ffd76a', text: '#fff6e0',
    plate: 'rgba(40,10,10,0.72)', plateTarget: 'rgba(8,30,55,0.9)',
    good: '#9dff7a', bad: '#ff4d4d', hint: '#ffd76a', solution: '#ffd76a',
    hitColors: ['#ff7a1a', '#ffd04a', '#ff3b1a', '#ffffff'],
    shield: ['255,77,77', '255,190,80', '127,231,255'],
    aim: 'rgba(127,231,255,0.25)', bannerGlow: '#b07cff'
  };
  const font = (w, s) => `900 ${s}px Nunito, "Trebuchet MS", sans-serif`;

  function buildCastle(A) {
    const W = A.W, H = 150, c = document.createElement('canvas');
    c.width = Math.round(W * A.DPR); c.height = Math.round(H * A.DPR);
    const x = c.getContext('2d'); x.scale(A.DPR, A.DPR);
    const stone = x.createLinearGradient(0, 40, 0, H);
    stone.addColorStop(0, '#3b3060'); stone.addColorStop(1, '#1a1433');
    const wallTop = H - 46;
    // Mauer mit Zinnen
    x.fillStyle = stone;
    x.fillRect(0, wallTop, W, H - wallTop);
    for (let px = 0; px < W; px += 22) x.fillRect(px, wallTop - 10, 12, 10);
    // Steinfugen
    x.strokeStyle = 'rgba(0,0,0,0.25)'; x.lineWidth = 1;
    for (let row = wallTop + 10; row < H; row += 12) for (let px = (row / 12 % 2) * 12; px < W; px += 24) x.strokeRect(px, row, 24, 12);
    // Türme
    const tower = (tx, tw, th, roof) => {
      x.fillStyle = stone; x.fillRect(tx - tw / 2, H - th, tw, th);
      for (let k = -tw / 2; k < tw / 2; k += 10) x.fillRect(tx + k, H - th - 8, 6, 8);
      if (roof) {
        x.fillStyle = '#6b2a6e'; x.beginPath(); x.moveTo(tx - tw / 2 - 5, H - th); x.lineTo(tx, H - th - tw * 1.1); x.lineTo(tx + tw / 2 + 5, H - th); x.closePath(); x.fill();
        x.fillStyle = '#ffd76a'; x.fillRect(tx - 1, H - th - tw * 1.1 - 12, 2, 12);
        x.fillStyle = '#ff4d6d'; x.beginPath(); x.moveTo(tx + 1, H - th - tw * 1.1 - 12); x.lineTo(tx + 11, H - th - tw * 1.1 - 8); x.lineTo(tx + 1, H - th - tw * 1.1 - 4); x.fill();
      }
      // Fenster mit warmem Licht
      for (let wy = H - th + 14; wy < H - 20; wy += 22) {
        x.fillStyle = Math.random() < 0.75 ? '#ffc94a' : '#2a2050';
        x.beginPath(); x.moveTo(tx - 4, wy + 10); x.lineTo(tx - 4, wy + 3); x.arc(tx, wy + 3, 4, Math.PI, 0); x.lineTo(tx + 4, wy + 10); x.fill();
      }
    };
    const towers = Math.max(3, Math.round(W / 140));
    for (let i = 0; i < towers; i++) {
      const tx = (i + 0.5) * W / towers;
      if (Math.abs(tx - W / 2) < 50) continue;
      tower(tx, A.rand(26, 36), A.rand(70, 100), Math.random() < 0.7);
    }
    // Zaubererturm in der Mitte
    tower(W / 2, 40, 130, false);
    // Tor
    x.fillStyle = '#120c22'; x.beginPath(); x.moveTo(W / 2 - 12, H); x.lineTo(W / 2 - 12, H - 22); x.arc(W / 2, H - 22, 12, Math.PI, 0); x.lineTo(W / 2 + 12, H); x.fill();
    return c;
  }

  function buildMountains(A) {
    const W = A.W, H = A.H, c = document.createElement('canvas');
    c.width = Math.max(1, Math.round(W)); c.height = Math.max(1, Math.round(H));
    const x = c.getContext('2d');
    const layer = (base, amp, col) => {
      x.fillStyle = col; x.beginPath(); x.moveTo(0, H);
      for (let px = 0; px <= W; px += 30) x.lineTo(px, base - Math.abs(Math.sin(px / 90 + amp)) * amp - Math.random() * 15);
      x.lineTo(W, H); x.closePath(); x.fill();
    };
    layer(H * 0.72, 70, '#2a1d52');
    layer(H * 0.8, 50, '#1f1640');
    return c;
  }

  return {
    id: 'zauberburg',
    text: {
      wave: 'ANGRIFF', waveDone: 'BURG VERTEIDIGT', newHi: 'NEUER REKORD!',
      idle: 'DER DRACHE HOLT LUFT…', last: 'LETZTE FEUERBÄLLE…', target: 'ZIEL', hint: 'TASTEN 1–4 ODER ANTIPPEN'
    },
    palette: P, font,
    titleFont: s => `900 ${s}px "Cinzel Decorative", Cinzel, serif`,
    music: { bpm: 116, wave: 'triangle', notes: ['D3', 'F3', 'A3', 'F3', 'D3', 'F3', 'A3', 'D4', 'A#2', 'D3', 'F3', 'D3', 'C3', 'E3', 'A3', 'C#4'], cutoff: 2600, vol: 0.09, sustain: 1.4, kick: 0.15 },
    sfx: {
      shot(A) { A.osc('triangle', 1200, 2600, 0.2, 0.1); A.osc('sine', 2400, 3200, 0.25, 0.05, 0.04); A.noise(0.15, 0.06, 6000, 0, 'highpass'); },
      boom(A) { A.noise(0.6, 0.28, 3000, 0, 'bandpass'); A.osc('sine', 160, 50, 0.3, 0.25); },
      hit(A) { A.noise(1, 0.6, 600); A.osc('sawtooth', 110, 35, 0.8, 0.22); },
      over(A) { [294, 262, 233, 220, 147].forEach((f, i) => A.osc('triangle', f, f * 0.98, 0.45, 0.12, i * 0.2)); }
    },
    enemyRadius: [28, 38],

    enemyInit(e, A) { e.hue = A.rand(12, 32); },
    enemyUpdate(e, dt, now, A) {
      if (Math.random() < 0.6) A.particle(e.x + A.rand(-0.6, 0.6) * e.r, e.y - e.r * 0.4, A.pick(['#ffd04a', '#ff7a1a', '#ff3b1a']), { vx: A.rand(-0.02, 0.02), vy: -A.rand(0.03, 0.08), life: A.rand(300, 600), size: A.rand(2, 4.5) });
    },
    enemyDraw(ctx, e, now, isT) {
      const { x, y, r } = e;
      ctx.translate(x, y);
      // Flammenschweif
      const tg = ctx.createLinearGradient(0, 0, 0, -r * 3.6);
      tg.addColorStop(0, 'rgba(255,150,40,0.75)'); tg.addColorStop(0.6, 'rgba(255,70,0,0.35)'); tg.addColorStop(1, 'rgba(255,40,0,0)');
      ctx.fillStyle = tg; ctx.beginPath(); ctx.moveTo(-r * 0.95, 0);
      for (let i = 0; i <= 8; i++) {
        const k = i / 8, px = (-0.95 + 1.9 * k) * r * (1 - Math.abs(k - 0.5) * 0.6);
        const len = (i % 2 ? 1.6 : 2.6 + Math.sin(k * 3.14) * 0.9) + Math.sin(now / 80 + i * 1.9 + e.seed * 9) * 0.35;
        ctx.lineTo(px, -r * len);
      }
      ctx.lineTo(r * 0.95, 0); ctx.closePath(); ctx.fill();
      // Feuerkugel
      ctx.shadowBlur = isT ? 34 : 26; ctx.shadowColor = e.flash > 0 ? P.bad : isT ? P.target : '#ff7a1a';
      const flick = 1 + Math.sin(now / 60 + e.seed * 20) * 0.03;
      const g = ctx.createRadialGradient(-r * 0.25, -r * 0.25, r * 0.05, 0, 0, r * flick);
      g.addColorStop(0, '#fffbe0'); g.addColorStop(0.35, '#ffd04a'); g.addColorStop(0.72, '#ff7a1a'); g.addColorStop(1, '#b8200a');
      ctx.fillStyle = g; ctx.beginPath(); ctx.arc(0, 0, r * flick, 0, Math.PI * 2); ctx.fill();
      if (isT || e.flash > 0) { ctx.lineWidth = 3; ctx.strokeStyle = e.flash > 0 ? P.bad : P.target; ctx.stroke(); }
    },
    drawReticle(ctx, e, now) {
      // Magischer Runenkreis
      const rr = e.r + 14;
      ctx.save(); ctx.rotate(-now / 900);
      ctx.strokeStyle = P.target; ctx.shadowBlur = 14; ctx.shadowColor = P.target; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(0, 0, rr, 0, Math.PI * 2); ctx.stroke();
      ctx.beginPath();
      for (let i = 0; i < 6; i++) { const a = i * Math.PI / 3; ctx.moveTo(Math.cos(a) * rr, Math.sin(a) * rr); ctx.lineTo(Math.cos(a + 2.09) * rr, Math.sin(a + 2.09) * rr); }
      ctx.globalAlpha = 0.35; ctx.stroke(); ctx.globalAlpha = 1;
      ctx.fillStyle = P.target;
      for (let i = 0; i < 6; i++) { const a = i * Math.PI / 3; ctx.beginPath(); ctx.arc(Math.cos(a) * rr, Math.sin(a) * rr, 3, 0, Math.PI * 2); ctx.fill(); }
      ctx.restore();
    },

    buildBg(A) {
      const W = A.W, H = A.H;
      return {
        castle: buildCastle(A), mountains: buildMountains(A),
        stars: Array.from({ length: Math.round(W * H / 3500) }, () => ({ x: A.rand(0, W), y: A.rand(0, H * 0.7), s: A.rand(0.6, 2), tw: A.rand(0, 6), a: A.rand(0.3, 0.9) })),
        clouds: Array.from({ length: 4 }, () => ({ x: A.rand(0, W), y: A.rand(H * 0.1, H * 0.45), w: A.rand(90, 180), s: A.rand(0.005, 0.015) })),
        dragon: null, nextDragon: 3000
      };
    },
    drawBg(ctx, bg, now, dt, moving, speed, A) {
      const W = A.W, H = A.H;
      const g = ctx.createLinearGradient(0, 0, 0, H);
      g.addColorStop(0, '#07051a'); g.addColorStop(0.5, '#1d1145'); g.addColorStop(1, '#4a2156');
      ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
      // Sterne
      ctx.fillStyle = '#fff';
      bg.stars.forEach(s => { ctx.globalAlpha = s.a * (0.6 + Math.sin(now / 400 + s.tw) * 0.4); ctx.fillRect(s.x, s.y, s.s, s.s); });
      ctx.globalAlpha = 1;
      // Mond
      const mx = W * 0.82, my = H * 0.16, mr = Math.min(48, W * 0.09);
      const mg = ctx.createRadialGradient(mx, my, mr * 0.5, mx, my, mr * 3);
      mg.addColorStop(0, 'rgba(255,240,200,0.35)'); mg.addColorStop(1, 'rgba(255,240,200,0)');
      ctx.fillStyle = mg; ctx.fillRect(mx - mr * 3, my - mr * 3, mr * 6, mr * 6);
      ctx.fillStyle = '#fff3d1'; ctx.beginPath(); ctx.arc(mx, my, mr, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = 'rgba(200,180,140,0.35)';
      [[-0.3, -0.2, 0.22], [0.25, 0.1, 0.15], [-0.05, 0.35, 0.12]].forEach(([a, b, c]) => { ctx.beginPath(); ctx.arc(mx + a * mr, my + b * mr, c * mr, 0, Math.PI * 2); ctx.fill(); });
      // Wolken
      bg.clouds.forEach(c => {
        if (moving) { c.x += c.s * dt; if (c.x - c.w > W) c.x = -c.w; }
        ctx.fillStyle = 'rgba(120,90,170,0.22)';
        ctx.beginPath(); ctx.ellipse(c.x, c.y, c.w * 0.5, c.w * 0.14, 0, 0, Math.PI * 2); ctx.ellipse(c.x + c.w * 0.2, c.y - c.w * 0.08, c.w * 0.25, c.w * 0.12, 0, 0, Math.PI * 2); ctx.fill();
      });
      ctx.drawImage(bg.mountains, 0, 0, W, H);
      // Drache fliegt am Himmel vorbei
      if (moving) {
        bg.nextDragon -= dt;
        if (!bg.dragon && bg.nextDragon <= 0) { const dir = Math.random() < 0.5 ? 1 : -1; bg.dragon = { x: dir > 0 ? -90 : W + 90, y: A.rand(H * 0.1, H * 0.28), dir, s: A.rand(0.06, 0.09) }; bg.nextDragon = A.rand(14000, 24000); }
      }
      const d = bg.dragon;
      if (d) {
        if (moving) d.x += d.dir * d.s * dt;
        if (d.x < -120 || d.x > W + 120) bg.dragon = null;
        else {
          const flap = Math.sin(now / 130);
          ctx.save(); ctx.translate(d.x, d.y + Math.sin(now / 400) * 6); ctx.scale(d.dir * 0.9, 0.9);
          ctx.fillStyle = '#120a26';
          ctx.beginPath(); ctx.moveTo(-50, 4); ctx.quadraticCurveTo(-20, -6, 10, 0); ctx.quadraticCurveTo(26, -4, 34, -12); ctx.lineTo(46, -10); ctx.lineTo(38, -4); ctx.quadraticCurveTo(24, 6, 8, 8); ctx.quadraticCurveTo(-20, 10, -50, 4); ctx.fill();
          ctx.beginPath(); ctx.moveTo(-6, -2); ctx.lineTo(-24, -34 * flap - 8); ctx.lineTo(-2, -22 * flap - 4); ctx.lineTo(12, -2); ctx.fill();
          ctx.beginPath(); ctx.moveTo(-50, 4); ctx.lineTo(-62, 0); ctx.lineTo(-56, 8); ctx.fill();
          ctx.fillStyle = '#ff4d1a'; ctx.beginPath(); ctx.arc(38, -10, 1.8, 0, Math.PI * 2); ctx.fill();
          ctx.restore();
        }
      }
    },
    muzzle(A) { return { x: A.W / 2, y: A.H - A.BASE_H - 96 }; },
    baseH: 46,
    noAimLine: false,
    drawBase(ctx, bg, now, s, A) {
      const W = A.W, H = A.H;
      // Magischer Schutzschild über der Burg
      const col = A.shield(s.lives), pulse = 0.5 + Math.sin(now / 450) * 0.2;
      ctx.save();
      ctx.strokeStyle = `rgba(${col},${0.35 + pulse * 0.3})`; ctx.lineWidth = 3; ctx.shadowBlur = 18; ctx.shadowColor = `rgb(${col})`;
      ctx.beginPath(); ctx.moveTo(0, H - A.BASE_H); ctx.lineTo(W, H - A.BASE_H); ctx.stroke();
      const sg = ctx.createLinearGradient(0, H - A.BASE_H - 40, 0, H - A.BASE_H);
      sg.addColorStop(0, `rgba(${col},0)`); sg.addColorStop(1, `rgba(${col},${0.15 * pulse + 0.05})`);
      ctx.fillStyle = sg; ctx.fillRect(0, H - A.BASE_H - 40, W, 40);
      ctx.restore();
      ctx.drawImage(bg.castle, 0, H - 150, W, 150);
      // Kristallkugel des Zauberers
      const m = this.muzzle(A);
      const og = ctx.createRadialGradient(m.x - 3, m.y - 3, 1, m.x, m.y, 13);
      og.addColorStop(0, '#ffffff'); og.addColorStop(0.5, P.target); og.addColorStop(1, '#3a6cff');
      ctx.shadowBlur = 24 + Math.sin(now / 200) * 8; ctx.shadowColor = P.target;
      ctx.fillStyle = og; ctx.beginPath(); ctx.arc(m.x, m.y, 11, 0, Math.PI * 2); ctx.fill();
      ctx.shadowBlur = 0;
      ctx.fillStyle = '#ffd76a'; ctx.beginPath(); ctx.moveTo(m.x - 10, m.y + 10); ctx.lineTo(m.x + 10, m.y + 10); ctx.lineTo(m.x + 6, m.y + 16); ctx.lineTo(m.x - 6, m.y + 16); ctx.fill();
      if (Math.random() < 0.25) A.particle(m.x + A.rand(-8, 8), m.y + A.rand(-8, 8), P.target, { vx: A.rand(-0.02, 0.02), vy: -A.rand(0.01, 0.04), life: 600, size: A.rand(1, 2) });
    },
    shotDur: 120,
    drawShot(ctx, sx, sy, ex, ey, alpha, k, now) {
      ctx.globalAlpha = alpha;
      // Eisblitz mit Zacken
      const seg = 9, pts = [[sx, sy]];
      const dx = ex - sx, dy = ey - sy, len = Math.hypot(dx, dy) || 1, nx = -dy / len, ny = dx / len;
      for (let i = 1; i < seg; i++) { const t = i / seg, off = (Math.random() - 0.5) * 22; pts.push([sx + dx * t + nx * off, sy + dy * t + ny * off]); }
      pts.push([ex, ey]);
      const path = () => { ctx.beginPath(); pts.forEach(([x, y], i) => i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)); };
      ctx.lineJoin = 'round'; ctx.lineCap = 'round';
      ctx.shadowBlur = 24; ctx.shadowColor = P.target; ctx.strokeStyle = P.target; ctx.lineWidth = 7; path(); ctx.stroke();
      ctx.shadowBlur = 0; ctx.strokeStyle = '#ffffff'; ctx.lineWidth = 2.5; path(); ctx.stroke();
    },
    explode(e, A) {
      for (let i = 0; i < 26; i++) A.particle(e.x, e.y, A.pick(['#bff4ff', '#7fe7ff', '#ffffff']), { speed: A.rand(0.08, 0.4), size: A.rand(1.5, 3.5) });
      for (let i = 0; i < 12; i++) A.particle(e.x, e.y, A.pick(['#ffd04a', '#ff7a1a']), { speed: A.rand(0.05, 0.2), grav: 0.0004 });
      for (let i = 0; i < 8; i++) A.particle(e.x + A.rand(-10, 10), e.y + A.rand(-10, 10), 'rgba(200,200,230,0.35)', { vx: A.rand(-0.02, 0.02), vy: -A.rand(0.02, 0.05), size: A.rand(8, 14), grow: 0.02, life: 900 });
      A.ring({ x: e.x, y: e.y, r: e.r * 0.4, max: e.r * 2.6, life: 480, color: P.target });
      A.ring({ x: e.x, y: e.y, r: 4, max: e.r * 1.2, life: 200, color: '#ffffff', fill: true });
    }
  };
})();
