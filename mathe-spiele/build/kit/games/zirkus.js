K.run({
  id: 'zirkusKanone', range: '20', title: 'Zirkus-Kanone', hero: ['🎪', '🤡', '💥'],
  tagline: 'Clown Pepe fliegt aus der Kanone! Die Aufgabe sagt, wie viel Pulver rein muss. Richtig gerechnet landet er im Netz – zu wenig im Wassereimer, zu viel bei den Elefanten!',
  startLabel: '💥 Manege frei!',
  prompt: q => 'Wie viel Pulver kommt in die Kanone?',
  say: q => `Pulver: ${q.a} ${q.add ? 'plus' : 'minus'} ${q.b}`,
  setup(scene, K) {
    scene.innerHTML = `<div class="tent" id="tent"><div class="lights"></div><div class="poster" id="poster"></div><div class="bucket">🪣</div><div class="net" id="net"></div><div class="ele">🐘</div>
      <div class="cannon" id="cannon"><div class="barrel"></div><div class="wheel"></div></div><div class="clown" id="clown">🤡</div><div class="crowd" id="crowd">🙂😃🙂😄🙂😃🙂😄🙂</div></div>`;
  },
  present(q, K) {
    K.$('#poster').innerHTML = `<small>Pulver für Clown Pepe:</small>${q.text} = ?`;
    const c = K.$('#clown'); c.getAnimations().forEach(a => a.cancel()); c.style.opacity = 1;
  },
  shoot(target, K) {
    const tent = K.$('#tent').getBoundingClientRect(), c = K.$('#clown'), cr = c.getBoundingClientRect();
    const t = target.getBoundingClientRect();
    const dx = t.left + t.width / 2 - (cr.left + cr.width / 2), dy = t.top - (cr.top + cr.height / 2);
    const peak = -Math.max(90, Math.abs(dx) * 0.45);
    c.getAnimations().forEach(a => a.cancel());
    this.shot = (this.shot || 0) + 1;
    K.$('#cannon').classList.remove('boom'); void K.$('#cannon').offsetWidth; K.$('#cannon').classList.add('boom');
    K.sfx.noise(0, .4, .6, 900); K.sfx.tone(120, 0, .3, 'sine', .3, 40);
    const frames = [];
    for (let i = 0; i <= 10; i++) { const k = i / 10; frames.push({ transform: `translate(calc(-50% + ${dx * k}px), calc(50% + ${dy * k + peak * 4 * k * (1 - k)}px)) rotate(${k * 720}deg)` }); }
    return c.animate(frames, { duration: 1000, easing: 'linear', fill: 'forwards' });
  },
  correct(q, el, first, K) {
    this.shoot(K.$('#net'), K).onfinish = () => {
      K.$('#net').classList.add('bounce'); K.later(() => K.$('#net').classList.remove('bounce'), 500);
      K.sfx.boing(); K.sfx.cheer();
      const cr = K.$('#crowd'); cr.textContent = '🤩🙌😍👏🤩🙌😍👏🤩'; cr.classList.add('cheer');
      K.later(() => { cr.classList.remove('cheer'); cr.textContent = '🙂😃🙂😄🙂😃🙂😄🙂'; }, 1300);
      K.bubble(K.$('#tent'), 'Taaadaaa!', '58%', '48%', 1000);
    };
    return 2300;
  },
  wrong(q, v, el, K) {
    const tent = K.$('#tent'), short = v < q.correct;
    const target = short ? tent.querySelector('.bucket') : tent.querySelector('.ele');
    const anim = this.shoot(target, K), my = this.shot;
    anim.onfinish = () => {
      if (my !== this.shot) return;
      if (short) { K.sfx.splash(); tent.insertAdjacentHTML('beforeend', '<span class="splash" style="left:40%;bottom:60px">💦</span>'); K.bubble(tent, 'Platsch! Zu wenig Pulver!', '28%', '50%', 1300); }
      else { K.sfx.tone(220, 0, .7, 'sawtooth', .1, 440); tent.insertAdjacentHTML('beforeend', '<span class="splash" style="right:30px;bottom:80px">💫</span>'); K.bubble(tent, 'Törööö! Zu viel Pulver!', 'auto', '45%', 1300).style.right = '8px'; }
      K.later(() => { tent.querySelectorAll('.splash').forEach(s => s.remove()); if (my === this.shot) K.$('#clown').getAnimations().forEach(a => a.cancel()); }, 1400);
    };
  },
  endEmoji: s => ['🤡', '🎪', '🏆'][s - 1]
});
