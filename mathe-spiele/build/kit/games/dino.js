K.run({
  id: 'dinoEier', range: '20', title: 'Dino-Eier', hero: ['🥚', '🦕', '🦖'],
  tagline: 'In jedem Ei steckt eine Aufgabe. Rechne richtig, und ein Baby-Dino schlüpft! Alle Dinos ziehen in deinen Dino-Zoo.',
  startLabel: '🥚 Eier ausbrüten',
  DINOS: ['🦕', '🦖', '🐲', '🐉', '🦎', '🐊', '🐢'],
  ACC: ['🎩', '👓', '🎀', '👑', '🧢', '🌸', '', ''],
  NAMES: ['Rexi', 'Dina', 'Knolle', 'Spike', 'Lotti', 'Brummi', 'Zacki', 'Puffi', 'Krümel', 'Fridolin'],
  setup(scene, K) {
    this.zoo = K.store.get('zoo', []);
    scene.innerHTML = `<div class="jungle" id="jg"><div class="volcano"></div><div class="palm">🌴</div><div class="nest"></div><div id="eggbox"></div></div>`;
    const old = document.getElementById('zooWrap'); if (old) old.remove();
    scene.insertAdjacentHTML('afterend', `<div class="zoo" id="zooWrap"><b>🦕 Dein Dino-Zoo: <span id="zc">${this.zoo.length}</span> Dinos</b><div id="zoo">${this.zoo.slice(-40).map(d => `<span>${d}</span>`).join('')}</div></div>`);
  },
  onMenu() { const z = document.getElementById('zooWrap'); if (z) z.remove(); },
  present(q, K) {
    K.$('#eggbox').innerHTML = `<div class="egg" id="egg"><div class="half top"></div><div class="half bot"></div><span class="t">${q.text}</span></div>`;
  },
  correct(q, el, first, K) {
    const egg = K.$('#egg'), dino = K.pick(this.DINOS), acc = K.pick(this.ACC), name = K.pick(this.NAMES);
    egg.classList.add('wobble'); K.sfx.tone(300, 0, .1, 'square', .05);
    K.later(() => {
      egg.classList.remove('wobble'); egg.classList.add('crack'); K.sfx.noise(0, .25, .4, 3000, 'highpass');
      K.$('#eggbox').insertAdjacentHTML('afterbegin', `<div class="baby">${dino}${acc ? `<span class="acc">${acc}</span>` : ''}</div>`);
      K.later(() => { K.sfx.tone(900, 0, .12, 'sine', .12, 1400); K.sfx.tone(1100, .15, .15, 'sine', .12, 1700); K.bubble(K.$('#jg'), `Piep! Ich bin ${name}!`, '58%', '22%', 1200); }, 500);
    }, 500);
    K.later(() => {
      this.zoo.push(dino); if (this.zoo.length > 200) this.zoo.shift(); K.store.set('zoo', this.zoo);
      K.$('#zoo').insertAdjacentHTML('beforeend', `<span>${dino}</span>`); K.$('#zc').textContent = this.zoo.length;
    }, 1500);
    return 2100;
  },
  wrong(q, v, el, K) {
    const egg = K.$('#egg'); egg.classList.remove('wobble'); void egg.offsetWidth; egg.classList.add('wobble');
    K.sfx.tone(700, 0, .1, 'sine', .08, 500);
    K.bubble(K.$('#jg'), K.pick(['Noch nicht reif!', 'Das Ei bleibt zu …', 'Klopf, klopf … nichts!']), '8%', '20%', 1300);
  },
  endText() { return `In deinem Zoo leben jetzt ${this.zoo.length} Dinos!`; },
  endEmoji: s => ['🥚', '🦕', '🦖'][s - 1]
});
