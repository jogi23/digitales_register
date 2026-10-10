// ===== Thema: Pixel-Invasion =====
window.THEME = (() => {
  const P = {
    target: '#39ff14', targetText: '#fff200', text: '#ffffff',
    plate: 'rgba(0,0,0,0.85)', plateTarget: 'rgba(0,30,0,0.95)',
    good: '#39ff14', bad: '#ff2a2a', hint: '#fff200', solution: '#fff200',
    hitColors: ['#39ff14', '#ff3df2', '#fff200', '#ffffff'],
    shield: ['255,42,42', '255,242,0', '57,255,20'],
    aim: 'rgba(57,255,20,0.18)', bannerGlow: '#ff3df2'
  };
  const font = (w, s) => `${Math.round(s * 0.62)}px "Press Start 2P", monospace`;

  // Eigene 11×8-Pixelsprites, je zwei Animationsbilder
  const SPRITES = [
    [[
      '....XXX....', '..XXXXXXX..', '.XX.XXX.XX.', '.XXXXXXXXX.', '...X...X...', '..X.X.X.X..', '.X.......X.', '..X.....X..'
    ], [
      '....XXX....', '..XXXXXXX..', '.XX.XXX.XX.', '.XXXXXXXXX.', '...X...X...', '..X.X.X.X..', '..X.....X..', '.X.......X.'
    ]],
    [[
      '..X.....X..', '...X...X...', '..XXXXXXX..', '.XX.XXX.XX.', 'XXXXXXXXXXX', 'X.XXXXXXX.X', 'X.X.....X.X', '...XX.XX...'
    ], [
      '..X.....X..', 'X..X...X..X', 'X.XXXXXXX.X', 'XXX.XXX.XXX', 'XXXXXXXXXXX', '.XXXXXXXXX.', '..X.....X..', '.X.......X.'
    ]],
    [[
      '...XXXXX...', '.XXXXXXXXX.', 'XX.XX.XX.XX', 'XXXXXXXXXXX', '..XXX.XXX..', '.XX.....XX.', 'XX.......XX', '...........'
    ], [
      '...XXXXX...', '.XXXXXXXXX.', 'XX.XX.XX.XX', 'XXXXXXXXXXX', '..XXX.XXX..', '.XX.....XX.', '..XX...XX..', '...........'
    ]]
  ];
  const CANNON = ['......X......', '.....XXX.....', '.....XXX.....', '.XXXXXXXXXXX.', 'XXXXXXXXXXXXX', 'XXXXXXXXXXXXX', 'XXXXXXXXXXXXX'];
  const COLORS = ['#39ff14', '#ff3df2', '#00e5ff', '#fff200', '#ff8c1a'];

  function sprite(ctx, rows, cx, cy, ps, color) {
    const w = rows[0].length, h = rows.length;
    const ox = Math.round(cx - (w * ps) / 2), oy = Math.round(cy - (h * ps) / 2);
    ctx.fillStyle = color;
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) if (rows[y][x] === 'X') ctx.fillRect(ox + x * ps, oy + y * ps, ps, ps);
  }

  return {
    id: 'pixelInvasion',
    text: {
      wave: 'LEVEL', waveDone: 'LEVEL GESCHAFFT', newHi: 'NEUER HIGHSCORE!',
      idle: 'SCANNE…', last: 'LETZTE ALIENS…', target: 'ZIEL', hint: 'TASTEN 1-4 ODER ANTIPPEN'
    },
    palette: P, font,
    titleFont: s => `${Math.round(s * 0.62)}px "Press Start 2P", monospace`,
    plateH: 2.1, plateRadius: 0, textNudge: 2,
    music: { bpm: 100, wave: 'square', notes: ['B1', null, 'A1', null, 'G1', null, 'F#1', null], cutoff: 700, vol: 0.13, sustain: 0.8, speedUp: true },
    sfx: {
      shot(A) { A.osc('square', 1100, 140, 0.14, 0.08); },
      boom(A) { A.noise(0.25, 0.3, 3500); A.osc('square', 220, 40, 0.22, 0.1); },
      error(A) { A.osc('square', 120, 100, 0.18, 0.1); A.osc('square', 90, 80, 0.2, 0.1, 0.12); },
      hit(A) { A.noise(0.7, 0.5, 1200); A.osc('square', 80, 30, 0.6, 0.15); },
      lock(A) { A.osc('square', 1600, 1600, 0.03, 0.03); },
      wave(A) { [523, 659, 784, 1047, 784, 1047].forEach((f, i) => A.osc('square', f, 0, 0.12, 0.07, i * 0.08)); },
      over(A) { [440, 415, 392, 370, 349, 330, 311, 294].forEach((f, i) => A.osc('square', f, 0, 0.12, 0.08, i * 0.11)); }
    },
    enemyRadius: [30, 38],
    turretMoves: true,
    noAimLine: true,

    enemyInit(e, A) {
      e.type = A.randInt(0, 2);
      e.color = A.pick(COLORS);
      e.vx = (Math.random() < 0.5 ? -1 : 1) * A.rand(0.012, 0.028);
      e.vy *= 0.92;
    },
    textY: e => e.r * 1.1,
    enemyDraw(ctx, e, now, isT) {
      const frame = Math.floor(now / 380 + e.seed * 2) % 2;
      const ps = Math.max(2, Math.floor((e.r * 2) / 11));
      ctx.shadowBlur = isT ? 18 : 10;
      ctx.shadowColor = e.flash > 0 ? P.bad : isT ? P.target : e.color;
      sprite(ctx, SPRITES[e.type][frame], e.x, e.y, ps, e.flash > 0 && Math.floor(now / 60) % 2 ? P.bad : e.color);
    },
    drawReticle(ctx, e, now) {
      // Blinkende Eckklammern
      if (Math.floor(now / 250) % 4 === 3) return;
      const s = e.r + 10, L = 10;
      ctx.fillStyle = P.target;
      [[-1, -1], [1, -1], [-1, 1], [1, 1]].forEach(([dx, dy]) => {
        ctx.fillRect(dx * s - (dx > 0 ? 3 : 0), dy * s - (dy > 0 ? 3 : 0), 3 * 1, 3);
        ctx.fillRect(dx > 0 ? s - L : -s, dy * s - (dy > 0 ? 3 : 0), L, 3);
        ctx.fillRect(dx * s - (dx > 0 ? 3 : 0), dy > 0 ? s - L : -s, 3, L);
      });
    },

    buildBg(A) {
      const W = A.W, H = A.H;
      return {
        stars: Array.from({ length: Math.round(W * H / 2600) }, () => ({ x: Math.round(A.rand(0, W)), y: A.rand(0, H), s: A.pick([1, 2, 2, 3]), c: A.pick(['#ffffff', '#ffffff', '#9ad9ff', '#ffb3f7']), sp: A.rand(0.01, 0.05), bl: A.rand(0, 10) })),
        ufo: null, nextUfo: 8000
      };
    },
    drawBg(ctx, bg, now, dt, moving, speed, A) {
      const W = A.W, H = A.H;
      ctx.fillStyle = '#000'; ctx.fillRect(0, 0, W, H);
      const g = ctx.createLinearGradient(0, H * 0.5, 0, H);
      g.addColorStop(0, 'rgba(60,0,80,0)'); g.addColorStop(1, 'rgba(60,0,80,0.45)');
      ctx.fillStyle = g; ctx.fillRect(0, H * 0.5, W, H * 0.5);
      bg.stars.forEach(s => {
        if (moving) { s.y += s.sp * dt * speed; if (s.y > H) { s.y = 0; s.x = Math.round(Math.random() * W); } }
        if (Math.floor(now / 300 + s.bl) % 7 === 0) return; // Blinken
        ctx.fillStyle = s.c; ctx.fillRect(s.x, Math.round(s.y), s.s, s.s);
      });
      // Ab und zu fliegt ein Mutterschiff vorbei
      if (moving) { bg.nextUfo -= dt; if (!bg.ufo && bg.nextUfo <= 0) { const dir = Math.random() < 0.5 ? 1 : -1; bg.ufo = { x: dir > 0 ? -40 : W + 40, dir }; bg.nextUfo = A.rand(15000, 25000); } }
      if (bg.ufo) {
        const u = bg.ufo;
        if (moving) u.x += u.dir * 0.08 * dt;
        if (u.x < -60 || u.x > W + 60) bg.ufo = null;
        else {
          ctx.globalAlpha = 0.5;
          sprite(ctx, ['....XXXXX....', '..XXXXXXXXX..', '.XX.XX.XX.XX.', 'XXXXXXXXXXXXX', '..XXX...XXX..', '...X.....X...'], u.x, 64, 3, '#ff3df2');
          ctx.globalAlpha = 1;
        }
      }
    },
    muzzle(A, tx) { return { x: tx, y: A.H - A.BASE_H - 10 }; },
    drawBase(ctx, bg, now, s, A) {
      const W = A.W, H = A.H, gy = H - A.BASE_H;
      const col = A.shield(s.lives);
      // Pixel-Schutzlinie
      const blink = s.lives === 1 && Math.floor(now / 300) % 2;
      ctx.fillStyle = `rgba(${col},${blink ? 0.3 : 0.9})`;
      for (let x = 0; x < W; x += 8) ctx.fillRect(x, gy, 6, 3);
      // Boden
      ctx.fillStyle = '#0b3d0b'; ctx.fillRect(0, gy + 18, W, H - gy - 18);
      ctx.fillStyle = '#39ff14'; ctx.fillRect(0, gy + 18, W, 3);
      for (let x = 0; x < W; x += 16) { ctx.fillStyle = (x / 16) % 2 ? '#145c14' : '#0f4a0f'; ctx.fillRect(x, gy + 24, 8, 4); }
      // Kanone (fährt unter das Ziel)
      ctx.shadowBlur = 14; ctx.shadowColor = P.target;
      sprite(ctx, CANNON, s.turretX, gy + 6, 3, P.target);
      ctx.shadowBlur = 0;
    },
    shotDur: 110,
    drawShot(ctx, sx, sy, ex, ey, alpha) {
      ctx.globalAlpha = alpha;
      ctx.lineCap = 'butt';
      ctx.setLineDash([10, 6]); ctx.lineDashOffset = -performance.now() / 10;
      ctx.shadowBlur = 16; ctx.shadowColor = '#fff200';
      ctx.strokeStyle = '#fff200'; ctx.lineWidth = 6;
      ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(ex, ey); ctx.stroke();
      ctx.setLineDash([]); ctx.shadowBlur = 0;
      ctx.strokeStyle = '#ffffff'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(ex, ey); ctx.stroke();
    },
    explode(e, A) {
      for (let i = 0; i < 30; i++) A.particle(e.x + A.rand(-e.r, e.r) * 0.6, e.y + A.rand(-e.r, e.r) * 0.5, A.pick([e.color, e.color, '#ffffff', '#fff200']), { shape: 'square', size: A.rand(1.5, 3.5), speed: A.rand(0.05, 0.35), grav: 0.0003, life: A.rand(500, 1000) });
      A.ring({ x: e.x, y: e.y, r: e.r * 0.4, max: e.r * 2, life: 380, color: e.color, square: true });
    }
  };
})();
