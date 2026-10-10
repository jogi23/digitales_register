K.run({
  id: 'ninjaSprung', range: '1x1', title: 'Ninja-Sprung', hero: ['🥷', '🏙️', '⭐'],
  tagline: 'Der Ninja rennt über die Dächer der Stadt. Spring auf das Dach mit dem richtigen Ergebnis, bevor die Zeit abläuft! Drei Leben – wie weit kommst du?',
  startLabel: '🥷 Lauf los!',
  endless: true, buttons: false, choices: 3,
  prompt: q => 'Spring aufs richtige Dach!',
  setup(scene, K) {
    scene.innerHTML = `<div class="city" id="city"><div class="moon"></div><div class="skyline"></div><div class="task" id="task"></div><div class="fuse"><i id="fuse"></i></div><div class="world" id="world"></div></div>`;
    K.scene.addEventListener('click', e => { const r = e.target.closest('.roof.target'); if (r && !r.classList.contains('used')) this.jump(r); });
  },
  targets: K => [...document.querySelectorAll('.roof.target')],
  choose(el) { this.jump(el); },
  present(q, K) {
    const world = K.$('#world');
    this.limit = Math.max(4500, 9500 - K.score * 150);
    this.left = this.limit; this.busy = false;
    K.$('#task').textContent = `${q.a} · ${q.b} = ?`;
    const h0 = K.rnd(120, 160);
    let html = `<div class="roof" style="left:2%;height:${h0}px"><div class="win"></div></div>`;
    q.choices.forEach((c, i) => { const h = K.rnd(100, 200); html += `<div class="roof target" data-v="${c}" style="left:${30 + i * 24}%;height:${h}px"><div class="win"></div><span class="num">${c}</span></div>`; });
    html += `<div class="ninja run" id="ninja" style="left:11%;bottom:${h0}px;top:auto;transform:translate(-50%,0)">🥷</div>`;
    world.innerHTML = html;
    world.style.transition = 'none'; world.style.transform = 'translateX(30%)'; void world.offsetWidth;
    world.style.transition = 'transform .45s ease-out'; world.style.transform = 'translateX(0)';
  },
  jump(roof) {
    if (this.busy || K.paused) return;
    const v = +roof.dataset.v; this.busy = true;
    this.fly(roof, () => K.answer(v, roof));
  },
  fly(roof, then) {
    const n = K.$('#ninja'), world = K.$('#world').getBoundingClientRect(), r = roof.getBoundingClientRect(), s = n.getBoundingClientRect();
    const dx = r.left + r.width / 2 - (s.left + s.width / 2), dy = r.top - s.bottom;
    n.classList.remove('run'); K.sfx.whoosh();
    const a = n.animate([{ transform: 'translate(-50%,0)' }, { transform: `translate(calc(-50% + ${dx / 2}px), ${Math.min(dy, 0) - 90}px) rotate(180deg)` }, { transform: `translate(calc(-50% + ${dx}px), ${dy}px) rotate(360deg)` }], { duration: 520, easing: 'ease-in-out', fill: 'forwards' });
    a.onfinish = then;
  },
  tick(dt, now, K) {
    if (this.busy) return;
    this.left -= dt;
    const f = document.getElementById('fuse'); if (f) f.style.transform = `scaleX(${Math.max(0, this.left / this.limit)})`;
    if (this.left <= 0) { this.busy = true; this.timeout = true; K.answer(-1, null); }
  },
  correct(q, roof, first, K) {
    K.sfx.thud(); K.sfx.tone(880, .05, .1, 'square', .06);
    const n = K.$('#ninja'); n.classList.add('run');
    K.bubble(K.$('#city'), K.pick(['Hai-ya!', 'Zack!', 'Perfekt!', 'Ninja-Style!']), '40%', '30%', 800);
    K.later(() => { const w = K.$('#world'); w.style.transform = `translateX(-${parseFloat(roof.style.left) - 2}%)`; }, 250);
    return 800;
  },
  wrong(q, v, roof, K) {
    const city = K.$('#city'), n = K.$('#ninja');
    if (this.timeout) { this.timeout = false; K.bubble(city, 'Zu langsam! Der Ninja ist gestolpert!', '20%', '40%', 1400); }
    if (roof) roof.classList.add('crumble');
    K.sfx.noise(0, .5, .4, 800);
    const binX = roof ? roof.style.left : '11%';
    city.insertAdjacentHTML('beforeend', `<div class="bin" style="left:${binX}">🗑️</div>`);
    n.animate([{ transform: getComputedStyle(n).transform }, { transform: `translate(-50%, 400px) rotate(540deg)` }], { duration: 800, easing: 'ease-in', fill: 'forwards' });
    K.later(() => { K.sfx.thud(); K.bubble(city, 'Plumps! Mülltonne!', binX, '70%', 900); }, 700);
    K.later(() => city.querySelectorAll('.bin').forEach(b => b.remove()), 1500);
    return 1600;
  },
  endEmoji: s => ['🥷', '🏙️', '🏆'][s - 1]
});
