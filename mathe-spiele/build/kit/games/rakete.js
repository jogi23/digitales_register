K.run({
  id: 'raketenWerkstatt', range: '1x1', title: 'Raketen-Werkstatt', hero: ['🔧', '🚀', '🪐'],
  tagline: 'Jede richtige Aufgabe bringt ein Bauteil für deine Rakete. Nach 10 Teilen heißt es: 3, 2, 1 – Start! Je weniger Fehler, desto weiter fliegt sie.',
  startLabel: '🚀 Werkstatt öffnen',
  prompt: q => `Rechne ${q.a} · ${q.b}, dann gibt's das nächste Bauteil!`,
  PARTS: ['fins', 'engine', 'body', 'win', 'red', 'body', 'win', 'red', 'nose', 'flag'],
  setup(scene, K) {
    this.built = 0;
    scene.innerHTML = `<div class="pad" id="pad"><div class="stars"></div><div class="tower"></div><div class="ground"></div><div class="sign" id="sign"></div><div class="parts" id="parts">🔩 0/10</div><div class="rocket" id="rocket"><span class="flame">🔥</span></div></div>`;
  },
  present(q, K) { K.$('#sign').innerHTML = `${q.a} · ${q.b} = ?`; },
  correct(q, el, first, K) {
    const kind = this.PARTS[this.built++];
    K.$('#rocket').insertAdjacentHTML('beforeend', `<div class="piece ${kind}">${kind === 'flag' ? '🚩' : ''}</div>`);
    K.later(() => K.sfx.thud(), 380);
    K.$('#parts').textContent = `🔩 ${this.built}/10`;
    return 1300;
  },
  wrong(q, v, el, K) {
    const pad = K.$('#pad'), s = document.createElement('div'); s.className = 'stray'; pad.appendChild(s);
    const a = s.animate([{ transform: 'translateX(-50%) translateY(0)' }, { transform: 'translateX(-50%) translateY(300px) rotate(30deg)', offset: .6 }, { transform: 'translateX(60%) translateY(240px) rotate(80deg)', offset: .8 }, { transform: 'translateX(140%) translateY(300px) rotate(140deg)', opacity: 0 }], { duration: 1100, easing: 'ease-in' });
    K.later(() => K.sfx.boing(), 600);
    a.onfinish = () => s.remove();
    K.bubble(pad, K.pick(['Klonk! Passt nicht!', 'Hoppla, falsches Teil!', 'Daneben!']), '30%', '45%', 1300);
  },
  beforeEnd(st, done, K) {
    const pad = K.$('#pad'), rocket = K.$('#rocket');
    K.lock();
    K.hint('Countdown läuft …', 'good');
    ['3', '2', '1'].forEach((t, i) => K.later(() => { pad.insertAdjacentHTML('beforeend', `<div class="count-big">${t}</div>`); K.sfx.tone(440, 0, .2, 'square', .08); }, i * 900));
    K.later(() => {
      K.sfx.tone(880, 0, .5, 'square', .08); K.sfx.noise(0, 2.5, .5, 300, 'lowpass', 1500);
      rocket.classList.add('fire');
      for (let i = 0; i < 8; i++) K.later(() => { const sm = document.createElement('div'); sm.className = 'smoke'; sm.style.left = `calc(50% - 30px + ${K.rnd(-40, 40)}px)`; sm.style.setProperty('--sx', K.rnd(-80, 80) + 'px'); pad.appendChild(sm); K.later(() => sm.remove(), 1600); }, i * 120);
      rocket.animate([{ transform: 'translateX(-50%) translateY(0)' }, { transform: 'translateX(-50%) translateY(10px)', offset: .15 }, { transform: 'translateX(-50%) translateY(-700px)' }], { duration: 2200, easing: 'cubic-bezier(.5,0,.8,.6)', fill: 'forwards' });
      const [emo, name] = st.first >= 9 ? ['🪐', 'zum Saturn'] : st.first >= 6 ? ['🔴', 'zum Mars'] : ['🌙', 'zum Mond'];
      this.dest = name;
      K.later(() => { pad.insertAdjacentHTML('beforeend', `<div class="dest"><span>${emo}</span>Bis ${name}!</div>`); K.sfx.cheer(); }, 2100);
      K.later(done, 3600);
    }, 2700);
  },
  endText() { return `Deine Rakete ist bis ${this.dest} geflogen!`; },
  endEmoji: s => ['🌙', '🔴', '🪐'][s - 1]
});
