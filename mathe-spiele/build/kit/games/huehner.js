K.run({
  id: 'huehnerChaos', range: '1x1', title: 'Hühner-Chaos', hero: ['🐔', '🥚', '👨‍🌾'],
  tagline: 'Die Hühner legen Eier in Reihen. Rechne aus, wie viele es werden! Ganz schnell gerechnet gibt es goldene Eier.',
  startLabel: '🥚 Ab in den Stall!',
  prompt: q => `${q.a} Hühner legen je ${q.b} Eier. Wie viele Eier sind das?`,
  say: q => `${q.a} Hühner legen je ${q.b} Eier. ${q.a} mal ${q.b}?`,
  solution: q => `${q.a} · ${q.b} = ${q.correct} Eier`,
  setup(scene, K) {
    this.gold = 0;
    scene.innerHTML = `<div class="farm"><div class="count" id="cnt">🥚 0 · 🌟 0</div><div class="sign" id="sign"></div><div class="coop" id="coop"></div><div class="farmer" id="farmer">👨‍🌾</div></div>`;
    this.eggs = 0;
  },
  present(q, K) {
    this.shown = performance.now();
    K.$('#sign').innerHTML = `${q.a} · ${q.b} = <b>?</b>`;
    const coop = K.$('#coop'); coop.style.setProperty('--n', q.a);
    coop.innerHTML = Array.from({ length: q.a }, () => `<div class="hen"><span class="h">🐔</span><div class="pile"></div><div class="nestbar"></div></div>`).join('');
  },
  correct(q, el, first, K) {
    const hens = [...K.$('#coop').children], n = q.a * q.b, step = Math.min(70, 1500 / n);
    const golden = first && performance.now() - this.shown < 5000;
    const goldAt = golden ? K.rnd(0, n - 1) : -1;
    let k = 0;
    for (let j = 0; j < q.b; j++) for (let i = 0; i < q.a; i++) {
      const idx = k++;
      K.later(() => {
        const hen = hens[i]; hen.classList.remove('lay'); void hen.offsetWidth; hen.classList.add('lay');
        hen.querySelector('.pile').insertAdjacentHTML('beforeend', `<i class="${idx === goldAt ? 'gold' : ''}">🥚</i>`);
        if (idx % 3 === 0) K.sfx.tone(700 + (idx % 7) * 60, 0, .06, 'square', .04);
      }, idx * step);
    }
    this.eggs += n;
    if (golden) { this.gold++; K.later(() => { K.sfx.tone(1568, 0, .3, 'triangle', .12); K.hint(`Goldenes Ei! 🌟 ${q.a} · ${q.b} = ${q.correct}`, 'good'); }, n * step + 100); }
    K.later(() => { K.$('#cnt').textContent = `🥚 ${this.eggs} · 🌟 ${this.gold}`; K.sfx.tone(520, 0, .08, 'square', .06); K.sfx.tone(780, .08, .1, 'square', .06); }, n * step);
    return n * step + 1200;
  },
  wrong(q, v, el, K) {
    // Ein Ei fliegt dem Bauern an den Kopf
    const scene = K.scene, farm = scene.querySelector('.farm'), hens = [...K.$('#coop').children];
    const from = K.pick(hens).getBoundingClientRect(), base = farm.getBoundingClientRect(), fr = K.$('#farmer').getBoundingClientRect();
    const egg = document.createElement('div'); egg.className = 'flyegg'; egg.textContent = '🥚';
    egg.style.left = (from.left - base.left + from.width / 2) + 'px'; egg.style.top = (from.top - base.top) + 'px'; farm.appendChild(egg);
    const dx = fr.left - from.left, dy = fr.top - from.top;
    K.sfx.whoosh();
    const a = egg.animate([{ transform: 'translate(0,0) rotate(0)' }, { transform: `translate(${dx / 2}px, ${dy / 2 - 90}px) rotate(300deg)` }, { transform: `translate(${dx + 10}px, ${dy}px) rotate(720deg)` }], { duration: 650, easing: 'ease-in', fill: 'forwards' });
    a.onfinish = () => {
      egg.remove(); K.sfx.splash();
      const f = K.$('#farmer'); f.classList.remove('ouch'); void f.offsetWidth; f.classList.add('ouch');
      f.insertAdjacentHTML('beforeend', '<span class="hit">🍳</span>');
      K.bubble(farm, K.pick(['Autsch!', 'Hey! Nicht auf mich!', 'Igitt, Rührei!', 'Mein Hut!']), 'auto', '20%', 1400).style.right = '8px';
      K.later(() => { const h = f.querySelector('.hit'); if (h) h.remove(); }, 1400);
    };
  },
  endText(st) { return `Du hast ${this.eggs} Eier eingesammelt${this.gold ? ` – davon ${this.gold} goldene` : ''}!`; },
  endEmoji: s => ['🐔', '🥚', '🌟'][s - 1]
});
