K.run({
  id: 'geisterhaus', range: '20', title: 'Geisterhaus-Türen', hero: ['🏚️', '🚪', '👻'],
  tagline: 'Hinter den Türen wohnen lustige Gespenster! Öffne die Tür mit der richtigen Zahl, um ins nächste Zimmer zu kommen. Hinter den falschen wartet ein Gespenst in Unterhose – BUH!',
  startLabel: '🕯️ Hinein ins Geisterhaus',
  buttons: false, choices: 3,
  prompt: q => 'Welche Tür führt weiter?',
  setup(scene, K) {
    this.room = 0;
    scene.innerHTML = `<div class="hall" id="hall"><span class="web">🕸️</span><span class="bat">🦇</span><div class="room" id="room"></div><div class="banner" id="banner"></div><div class="doors" id="doors"></div><div class="floor"></div></div>`;
    K.scene.addEventListener('click', e => { const d = e.target.closest('.door'); if (d && !d.classList.contains('used') && !d.classList.contains('open')) K.answer(+d.dataset.v, d); });
  },
  targets: K => [...document.querySelectorAll('.door')],
  present(q, K) {
    this.room++;
    K.$('#room').textContent = `🚪 Zimmer ${this.room}`;
    K.$('#banner').textContent = `${q.text} = ?`;
    K.$('#doors').innerHTML = q.choices.map(c => `<div class="door" data-v="${c}"><div class="behind"></div><div class="leaf"><span class="plate">${c}</span><span class="knock">✊</span></div></div>`).join('');
  },
  correct(q, door, first, K) {
    door.classList.add('open', 'good');
    door.querySelector('.behind').innerHTML = `<div class="ghost"><span class="g">👻</span><span class="u">🍬</span></div>`;
    K.sfx.tone(500, 0, .5, 'sine', .1, 1000); K.later(() => K.sfx.tone(800, 0, .15, 'triangle', .1), 300);
    K.bubble(K.$('#hall'), K.pick(['Hallo! Komm rein!', 'Hier gibt\'s Bonbons!', 'Willkommen, mutiger Rechner!']), '30%', '18%', 1200);
    K.later(() => K.$('#hall').insertAdjacentHTML('beforeend', '<div class="fade"></div>'), 1200);
    K.later(() => { const f = K.$('#hall').querySelector('.fade'); if (f) f.remove(); }, 2150);
    return 1650;
  },
  wrong(q, v, door, K) {
    door.classList.add('open', 'bad');
    door.querySelector('.behind').innerHTML = `<div class="ghost"><span class="g">👻</span><span class="u">🩲</span></div>`;
    K.sfx.tone(600, 0, .6, 'sawtooth', .08, 150);
    K.bubble(K.$('#hall'), 'BUH! 👻', '40%', '30%', 900);
    K.later(() => { K.bubble(K.$('#hall'), K.pick(['Hihi, reingelegt!', 'Hast du meine Unterhose gesehen?', 'Falsche Tür, hihi!']), '20%', '30%', 1100); K.sfx.tone(900, 0, .08, 'sine', .08); K.sfx.tone(1100, .1, .08, 'sine', .08); }, 800);
    K.later(() => { door.classList.remove('open'); door.classList.add('used'); }, 1800);
  },
  highlight(q) { const d = [...document.querySelectorAll('.door')].find(x => +x.dataset.v === q.correct); if (d) d.classList.add('hint-glow'); },
  endText() { return 'Du hast das Geisterhaus durchquert!'; },
  endEmoji: s => ['👻', '🏚️', '🏆'][s - 1]
});
