K.run({
  id: 'hundeFrisoer', range: '1x1', title: 'Hunde-Frisör', hero: ['🐩', '✂️', '🎀'],
  tagline: 'Die Hunde kommen zum Styling und wünschen sich Schmuck in Reihen. Rechne richtig für eine Traumfrisur – sonst gibt es einen Frisur-Unfall fürs Fotoalbum!',
  startLabel: '✂️ Salon öffnen',
  DOGS: [['🐩', 'Pudel Lulu'], ['🐶', 'Welpe Bello'], ['🐕', 'Dackel Fritz'], ['🐕‍🦺', 'Spürnase Rex'], ['🦮', 'Goldie']],
  ITEMS: [['🎀', 'Schleifchen'], ['⭐', 'Sternchen'], ['🌸', 'Blümchen'], ['💖', 'Herzchen'], ['🦴', 'Knöchelchen'], ['🍬', 'Bonbons']],
  WILD: ['🌵', '🍝', '🥦', '🔥', '🐙', '🍍'],
  prompt: q => `${q.dog[1]} möchte ${q.a} Reihen mit je ${q.b} ${q.item[1]}.`,
  say: q => `${q.dog[1]} möchte ${q.a} Reihen mit je ${q.b} ${q.item[1]}. ${q.a} mal ${q.b}?`,
  solution: q => `${q.a} · ${q.b} = ${q.correct} ${q.item[1]}`,
  makeTask(q, K) { q.dog = K.pick(this.DOGS); q.item = K.pick(this.ITEMS); return q; },
  setup(scene, K) {
    this.photos = 0;
    const old = document.getElementById('albumWrap'); if (old) old.remove();
    scene.innerHTML = `<div class="salon" id="salon"><div class="mirror"></div><div class="floor"></div><div class="order" id="order"></div><div class="chair"></div><div class="dog" id="dog"></div></div>`;
    scene.insertAdjacentHTML('afterend', `<div id="albumWrap"><div class="album-label">📸 Fotoalbum</div><div class="album" id="album"></div></div>`);
  },
  onMenu() { const a = document.getElementById('albumWrap'); if (a) a.remove(); },
  present(q, K) {
    K.$('#order').textContent = `${q.a} · ${q.b} = ?`;
    const d = K.$('#dog'); d.textContent = q.dog[0]; d.className = 'dog'; void d.offsetWidth; d.classList.add('in');
    K.$('#salon').querySelectorAll('.deco, .wild').forEach(x => x.remove());
  },
  photo(emoji, extra, label) {
    const salon = K.$('#salon'); salon.insertAdjacentHTML('beforeend', '<div class="flash"></div>'); K.later(() => { const f = salon.querySelector('.flash'); if (f) f.remove(); }, 500);
    K.sfx.noise(0, .08, .3, 4000, 'highpass'); K.sfx.tone(1800, .05, .05, 'square', .04);
    this.photos++;
    K.$('#album').insertAdjacentHTML('afterbegin', `<div class="photo" style="--r:${K.rnd(-6, 6)}deg"><div>${emoji}<small>${extra}</small></div><span>${label}</span></div>`);
  },
  correct(q, el, first, K) {
    const salon = K.$('#salon'), n = Math.max(q.a, q.b), size = Math.max(9, Math.min(26, 150 / n));
    const deco = document.createElement('div'); deco.className = 'deco';
    deco.style.gridTemplateColumns = `repeat(${q.b}, ${size}px)`; deco.style.fontSize = size + 'px';
    salon.appendChild(deco);
    const step = Math.min(40, 900 / (q.a * q.b));
    for (let i = 0; i < q.a * q.b; i++) K.later(() => { deco.insertAdjacentHTML('beforeend', `<i>${q.item[0]}</i>`); if (i % 4 === 0) K.sfx.tone(900 + (i % 9) * 50, 0, .05, 'sine', .06); }, i * step);
    const t = q.a * q.b * step;
    K.later(() => { K.$('#dog').classList.add('happy'); K.sfx.tone(500, 0, .12, 'square', .07, 700); K.sfx.tone(450, .15, .12, 'square', .07, 650); K.bubble(salon, 'Wuff! Wunderschön!', 'auto', '30%', 1200).style.right = '10px'; }, t + 100);
    K.later(() => this.photo(q.dog[0], q.item[0], 'Traumfrisur'), t + 600);
    return t + 1500;
  },
  wrong(q, v, el, K) {
    const salon = K.$('#salon'); salon.querySelectorAll('.wild').forEach(x => x.remove());
    const w = K.pick(this.WILD);
    salon.insertAdjacentHTML('beforeend', `<div class="wild">${w}</div>`);
    K.sfx.boing();
    K.bubble(salon, K.pick(['Frisur-Unfall! 😂', 'Wuff?! Was ist DAS?', 'Ups, zu viel geschnitten!']), '10px', '30%', 1400);
    K.later(() => this.photo(q.dog[0], w, 'Unfall 😂'), 300);
    K.later(() => salon.querySelectorAll('.wild').forEach(x => x.remove()), 1600);
  },
  endText() { return `${this.photos} Fotos im Album!`; },
  endEmoji: s => ['🐶', '🐕', '🐩'][s - 1]
});
