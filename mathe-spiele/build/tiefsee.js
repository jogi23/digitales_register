// ===== Thema: Tiefsee-Alarm =====
window.THEME = (() => {
  const P = {
    target: '#3ef0d0', targetText: '#ffe066', text: '#ffffff',
    plate: 'rgba(3,28,48,0.72)', plateTarget: 'rgba(0,55,62,0.9)',
    good: '#7dff9b', bad: '#ff6b7a', hint: '#ffe066', solution: '#ffe066',
    hitColors: ['#ff8fa3', '#ffe066', '#ffffff', '#3ef0d0'],
    shield: ['255,107,122', '255,224,102', '62,240,208'],
    aim: 'rgba(62,240,208,0.25)', bannerGlow: '#3ef0d0'
  };
  const font = (w, s) => `${w >= 800 ? 800 : 700} ${s}px "Baloo 2", "Trebuchet MS", sans-serif`;

  function buildReef(A) {
    const W = A.W, H = 120, c = document.createElement('canvas');
    c.width = Math.round(W * A.DPR); c.height = Math.round(H * A.DPR);
    const x = c.getContext('2d'); x.scale(A.DPR, A.DPR);
    // Sand
    const sand = x.createLinearGradient(0, 70, 0, H);
    sand.addColorStop(0, '#d9b77a'); sand.addColorStop(1, '#8a6a3c');
    x.fillStyle = sand; x.beginPath(); x.moveTo(0, 80);
    for (let i = 0; i <= 12; i++) x.lineTo(i * W / 12, 74 + Math.sin(i * 1.7) * 6);
    x.lineTo(W, H); x.lineTo(0, H); x.closePath(); x.fill();
    // Korallen
    const corals = ['#ff7a8a', '#ff9f43', '#c56cf0', '#ff6fb5', '#ffd166'];
    for (let i = 0; i < Math.max(6, W / 55); i++) {
      const cx = A.rand(0, W), col = A.pick(corals);
      if (Math.abs(cx - W / 2) < 60) continue; // Platz fürs U-Boot
      if (Math.random() < 0.5) {
        // Verzweigte Koralle
        x.strokeStyle = col; x.lineCap = 'round';
        const branch = (bx, by, len, ang, w) => {
          if (len < 6) return;
          const ex = bx + Math.cos(ang) * len, ey = by + Math.sin(ang) * len;
          x.lineWidth = w; x.beginPath(); x.moveTo(bx, by); x.lineTo(ex, ey); x.stroke();
          branch(ex, ey, len * 0.7, ang - A.rand(0.3, 0.6), w * 0.7);
          branch(ex, ey, len * 0.7, ang + A.rand(0.3, 0.6), w * 0.7);
        };
        branch(cx, 82, A.rand(16, 26), -Math.PI / 2 + A.rand(-0.2, 0.2), 6);
      } else {
        // Hirnkoralle
        const r = A.rand(10, 18);
        const g = x.createRadialGradient(cx - r * 0.3, 80 - r * 0.6, 2, cx, 80, r);
        g.addColorStop(0, '#fff3'); g.addColorStop(0.3, col); g.addColorStop(1, '#00000055');
        x.fillStyle = g; x.beginPath(); x.ellipse(cx, 82, r * 1.2, r, 0, Math.PI, 0); x.fill();
      }
    }
    // Muscheln und Steine
    for (let i = 0; i < W / 70; i++) {
      x.fillStyle = A.pick(['#f5e6c8', '#e8c7a0', '#9a8f86']);
      x.beginPath(); x.ellipse(A.rand(0, W), A.rand(92, 112), A.rand(3, 7), A.rand(2, 4), 0, 0, Math.PI * 2); x.fill();
    }
    return c;
  }

  return {
    id: 'tiefseeAlarm',
    text: {
      wave: 'TAUCHGANG', waveDone: 'RIFF GERETTET', newHi: 'NEUER REKORD!',
      idle: 'SONAR SUCHT…', last: 'LETZTE QUALLEN…', target: 'ZIEL', hint: 'TASTEN 1–4 ODER ANTIPPEN'
    },
    palette: P, font,
    titleFont: s => `800 ${s}px "Baloo 2", sans-serif`,
    music: { bpm: 92, wave: 'sine', notes: ['A2', null, 'E3', 'C3', 'D3', null, 'A2', 'G2', 'A2', null, 'E3', 'G3', 'F3', 'E3', 'D3', null], cutoff: 1400, vol: 0.14, sustain: 1.8, kick: 0.12 },
    sfx: {
      shot(A) { A.osc('sine', 260, 900, 0.18, 0.18); A.noise(0.12, 0.08, 2500, 0, 'bandpass'); },
      boom(A) { A.osc('sine', 700, 120, 0.22, 0.22); A.osc('sine', 1100, 300, 0.12, 0.08, 0.05); A.noise(0.3, 0.12, 900); },
      hit(A) { A.noise(0.9, 0.5, 500); A.osc('sine', 120, 40, 0.7, 0.3); },
      lock(A) { A.osc('sine', 1400, 1400, 0.08, 0.04); A.osc('sine', 1400, 1400, 0.08, 0.025, 0.12); }
    },
    enemyRadius: [30, 40],

    enemyInit(e, A) { e.hue = A.pick([300, 320, 285, 195, 340, 260]); e.phase = Math.random() * 6.28; e.tent = A.randInt(5, 7); },
    enemyUpdate(e, dt, now, A) {
      e.phase += dt * 0.004;
      e.y += Math.sin(e.phase) * 0.015 * dt; // pulsierendes Absinken
      if (Math.random() < 0.03) A.particle(e.x + A.rand(-0.5, 0.5) * e.r, e.y - e.r * 0.6, 'rgba(210,245,255,0.8)', { vx: 0, vy: -A.rand(0.02, 0.05), life: A.rand(900, 1500), size: A.rand(2, 4), shape: 'ring', drag: 1 });
    },
    textY: e => -e.r * 0.28,
    enemyDraw(ctx, e, now, isT) {
      const { x, y, r } = e, pulse = 1 + Math.sin(e.phase * 2) * 0.06;
      ctx.translate(x, y);
      // Tentakel
      ctx.lineCap = 'round';
      for (let i = 0; i < e.tent; i++) {
        const tx = (-0.7 + 1.4 * i / (e.tent - 1)) * r * 0.8;
        ctx.beginPath(); ctx.moveTo(tx, r * 0.15);
        for (let s = 1; s <= 6; s++) ctx.lineTo(tx + Math.sin(e.phase * 1.5 + s * 0.9 + i) * r * 0.05 * s, r * 0.15 + s * r * 0.2);
        ctx.strokeStyle = `hsla(${e.hue},90%,78%,0.65)`; ctx.lineWidth = i % 2 ? 2 : 3.5; ctx.stroke();
      }
      // Schirm
      ctx.shadowBlur = isT ? 28 : 16;
      ctx.shadowColor = e.flash > 0 ? P.bad : isT ? P.target : `hsl(${e.hue},100%,70%)`;
      ctx.scale(pulse, 1 / pulse);
      const g = ctx.createRadialGradient(-r * 0.3, -r * 0.6, r * 0.1, 0, -r * 0.2, r * 1.15);
      g.addColorStop(0, `hsla(${e.hue},100%,90%,0.95)`); g.addColorStop(0.55, `hsla(${e.hue},85%,62%,0.88)`); g.addColorStop(1, `hsla(${e.hue},80%,38%,0.85)`);
      ctx.beginPath(); ctx.moveTo(-r, r * 0.2);
      ctx.bezierCurveTo(-r, -r * 1.25, r, -r * 1.25, r, r * 0.2);
      for (let i = 0; i < 6; i++) { const x2 = r - (i + 1) * (2 * r / 6); ctx.quadraticCurveTo(x2 + r / 6, r * 0.42, x2, r * 0.2); }
      ctx.closePath(); ctx.fillStyle = g; ctx.fill();
      ctx.lineWidth = isT ? 3.5 : 2; ctx.strokeStyle = e.flash > 0 ? P.bad : isT ? P.target : `hsla(${e.hue},100%,88%,0.9)`; ctx.stroke();
      ctx.shadowBlur = 0;
      ctx.fillStyle = 'rgba(255,255,255,0.4)';
      ctx.beginPath(); ctx.ellipse(-r * 0.45, -r * 0.55, r * 0.2, r * 0.1, -0.6, 0, Math.PI * 2); ctx.fill();
    },

    buildBg(A) {
      const W = A.W, H = A.H;
      return {
        reef: buildReef(A),
        bubbles: Array.from({ length: Math.round(W * H / 14000) }, () => ({ x: A.rand(0, W), y: A.rand(0, H), r: A.rand(1.5, 5), s: A.rand(0.015, 0.05), w: A.rand(0, 6) })),
        plankton: Array.from({ length: Math.round(W * H / 6000) }, () => ({ x: A.rand(0, W), y: A.rand(0, H), a: A.rand(0.15, 0.5), w: A.rand(0, 6) })),
        weeds: Array.from({ length: Math.max(5, Math.round(W / 70)) }, (_, i) => ({ x: (i + A.rand(0.2, 0.8)) * W / Math.max(5, Math.round(W / 70)), h: A.rand(40, 95), c: A.pick(['#1f9e6e', '#2bb673', '#178a5a', '#4cc38a']), p: A.rand(0, 6) })).filter(w => Math.abs(w.x - W / 2) > 55),
        fish: []
      };
    },
    drawBg(ctx, bg, now, dt, moving, speed, A) {
      const W = A.W, H = A.H;
      const g = ctx.createLinearGradient(0, 0, 0, H);
      g.addColorStop(0, '#0e6a8f'); g.addColorStop(0.45, '#073b5e'); g.addColorStop(1, '#021626');
      ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
      // Lichtstrahlen von der Oberfläche
      ctx.globalCompositeOperation = 'lighter';
      for (let i = 0; i < 5; i++) {
        const cx = W * (0.1 + i * 0.22) + Math.sin(now / 3000 + i) * 30;
        const lg = ctx.createLinearGradient(0, 0, 0, H * 0.8);
        lg.addColorStop(0, 'rgba(160,240,255,0.10)'); lg.addColorStop(1, 'rgba(160,240,255,0)');
        ctx.fillStyle = lg; ctx.beginPath();
        ctx.moveTo(cx - 20, 0); ctx.lineTo(cx + 25, 0); ctx.lineTo(cx + 110 + Math.sin(now / 2000 + i) * 20, H * 0.8); ctx.lineTo(cx + 10, H * 0.8); ctx.closePath(); ctx.fill();
      }
      ctx.globalCompositeOperation = 'source-over';
      // Plankton
      ctx.fillStyle = '#bff6ff';
      bg.plankton.forEach(p => {
        if (moving) { p.y -= 0.004 * dt; p.x += Math.sin(now / 1500 + p.w) * 0.01 * dt; if (p.y < 0) { p.y = H; p.x = Math.random() * W; } }
        ctx.globalAlpha = p.a; ctx.fillRect(p.x, p.y, 1.6, 1.6);
      });
      ctx.globalAlpha = 1;
      // Fische ziehen vorbei
      if (moving && Math.random() < 0.002 && bg.fish.length < 3) {
        const dir = Math.random() < 0.5 ? 1 : -1;
        bg.fish.push({ x: dir > 0 ? -40 : W + 40, y: A.rand(H * 0.15, H * 0.6), dir, s: A.rand(0.03, 0.07), c: A.pick(['#ffb347', '#6ee7ff', '#ff7aa8', '#ffe066']), n: A.randInt(3, 6) });
      }
      bg.fish = bg.fish.filter(f => f.x > -80 && f.x < W + 80);
      bg.fish.forEach(f => {
        f.x += f.dir * f.s * dt;
        for (let k = 0; k < f.n; k++) {
          const fx = f.x - f.dir * k * 18, fy = f.y + Math.sin(now / 300 + k) * 4 + (k % 2) * 10;
          ctx.save(); ctx.translate(fx, fy); ctx.scale(f.dir, 1); ctx.globalAlpha = 0.55; ctx.fillStyle = f.c;
          ctx.beginPath(); ctx.ellipse(0, 0, 7, 4, 0, 0, Math.PI * 2); ctx.fill();
          ctx.beginPath(); ctx.moveTo(-6, 0); ctx.lineTo(-12, -4); ctx.lineTo(-12, 4); ctx.closePath(); ctx.fill();
          ctx.restore();
        }
      });
      // Luftblasen
      ctx.strokeStyle = 'rgba(200,245,255,0.45)'; ctx.lineWidth = 1.2;
      bg.bubbles.forEach(b => {
        if (moving) { b.y -= b.s * dt * speed; if (b.y < -10) { b.y = H + 10; b.x = Math.random() * W; } }
        ctx.beginPath(); ctx.arc(b.x + Math.sin(now / 700 + b.w) * 4, b.y, b.r, 0, Math.PI * 2); ctx.stroke();
      });
    },
    muzzle(A, tx, ang) { return { x: tx + Math.cos(ang) * 26, y: A.H - A.BASE_H - 2 + Math.sin(ang) * 26 }; },
    drawBase(ctx, bg, now, s, A) {
      const W = A.W, H = A.H, by = H - A.BASE_H;
      // Seegras
      bg.weeds.forEach(w => {
        ctx.strokeStyle = w.c; ctx.lineWidth = 5; ctx.lineCap = 'round';
        ctx.beginPath(); ctx.moveTo(w.x, H);
        for (let k = 1; k <= 6; k++) ctx.lineTo(w.x + Math.sin(now / 900 + w.p + k * 0.6) * k * 2.2, H - k * w.h / 6);
        ctx.stroke();
      });
      ctx.drawImage(bg.reef, 0, H - 110, W, 120);
      // Schutzschimmer über dem Riff
      const col = A.shield(s.lives), pulse = 0.5 + Math.sin(now / 500) * 0.2;
      const sg = ctx.createLinearGradient(0, by - 30, 0, by + 10);
      sg.addColorStop(0, `rgba(${col},0)`); sg.addColorStop(1, `rgba(${col},${0.18 * pulse + 0.06})`);
      ctx.fillStyle = sg; ctx.fillRect(0, by - 30, W, 40);
      ctx.strokeStyle = `rgba(${col},${0.5 + pulse * 0.3})`; ctx.setLineDash([2, 8]); ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(0, by); ctx.lineTo(W, by); ctx.stroke(); ctx.setLineDash([]);
      // U-Boot
      const cx = W / 2, cy = by + 16 + Math.sin(now / 600) * 2;
      ctx.save(); ctx.translate(cx, cy);
      // Torpedorohr am Turm
      ctx.save(); ctx.translate(0, -18); ctx.rotate(s.angle);
      ctx.fillStyle = '#e0a800'; ctx.strokeStyle = '#7a5600'; ctx.lineWidth = 2;
      A.roundRect(0, -5, 26, 10, 4); ctx.fill(); ctx.stroke();
      ctx.restore();
      ctx.shadowBlur = 18; ctx.shadowColor = 'rgba(255,220,80,0.6)';
      const hull = ctx.createLinearGradient(0, -16, 0, 16);
      hull.addColorStop(0, '#ffe066'); hull.addColorStop(1, '#e09b00');
      ctx.fillStyle = hull; ctx.strokeStyle = '#7a5600'; ctx.lineWidth = 2.5;
      ctx.beginPath(); ctx.ellipse(0, 0, 44, 15, 0, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
      ctx.shadowBlur = 0;
      A.roundRect(-12, -27, 24, 16, 5); ctx.fill(); ctx.stroke();
      // Bullaugen
      [-22, 0, 22].forEach((px, i) => {
        ctx.fillStyle = '#7a5600'; ctx.beginPath(); ctx.arc(px, 1, 6, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = i === 1 ? '#3ef0d0' : '#9be7ff'; ctx.beginPath(); ctx.arc(px, 1, 4, 0, Math.PI * 2); ctx.fill();
      });
      // Propeller
      ctx.fillStyle = '#7a5600';
      const pr = Math.sin(now / 40) * 7;
      ctx.beginPath(); ctx.ellipse(-48, 0, 3, Math.abs(pr) + 2, 0, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
      if (Math.random() < 0.15) A.particle(cx - 52, cy + A.rand(-4, 4), 'rgba(220,250,255,0.8)', { vx: -A.rand(0.02, 0.06), vy: -A.rand(0.01, 0.03), life: 800, size: A.rand(1.5, 3), shape: 'ring', drag: 0.999 });
    },
    shotDur: 170,
    drawShot(ctx, sx, sy, ex, ey, alpha, k) {
      ctx.globalAlpha = alpha;
      const n = 10;
      for (let i = 0; i <= n; i++) {
        const t = i / n, px = sx + (ex - sx) * t, py = sy + (ey - sy) * t;
        ctx.strokeStyle = 'rgba(210,250,255,0.85)'; ctx.lineWidth = 1.5;
        ctx.beginPath(); ctx.arc(px + Math.sin(i * 2.1) * 4, py, 2 + t * 4, 0, Math.PI * 2); ctx.stroke();
      }
      ctx.shadowBlur = 20; ctx.shadowColor = P.target;
      const g = ctx.createRadialGradient(ex - 3, ey - 3, 1, ex, ey, 11);
      g.addColorStop(0, '#ffffff'); g.addColorStop(0.5, '#aaf6ff'); g.addColorStop(1, 'rgba(62,240,208,0.3)');
      ctx.fillStyle = g; ctx.beginPath(); ctx.arc(ex, ey, 11, 0, Math.PI * 2); ctx.fill();
    },
    explode(e, A) {
      for (let i = 0; i < 22; i++) A.particle(e.x, e.y, 'rgba(220,250,255,0.9)', { shape: 'ring', size: A.rand(2, 7), speed: A.rand(0.05, 0.25), vy: -A.rand(0.03, 0.15), life: A.rand(700, 1300) });
      for (let i = 0; i < 22; i++) A.particle(e.x, e.y, `hsl(${e.hue},100%,75%)`, { speed: A.rand(0.05, 0.3) });
      A.ring({ x: e.x, y: e.y, r: e.r * 0.5, max: e.r * 2.6, life: 500, color: P.target });
    }
  };
})();
