const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = '/tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/1x1-spiele/';
const only = process.argv[2];
const GAMES = ['huehner-chaos', 'raketen-werkstatt', 'zaubertrank-kueche', 'hunde-frisoer', 'ninja-sprung', 'dino-eier', 'zahlen-zug', 'zirkus-kanone', 'geisterhaus-tueren', 'frosch-fliegen'].filter(g => !only || g === only);
const TAP = `(want, wrong) => {
  const ok = e => !e.disabled && !e.classList.contains('used') && !e.classList.contains('gone') && !e.classList.contains('open') && e.offsetParent !== null && e.closest('#game');
  const els = [...document.querySelectorAll('#game [data-v]')].filter(ok);
  const el = els.find(e => wrong ? +e.dataset.v !== want : +e.dataset.v === want);
  if (!el) return 'none:' + els.map(e => e.dataset.v).join(',');
  el.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true })); el.click(); return 'ok';
}`;
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  for (const g of GAMES) {
    const p = await b.newPage({ viewport: { width: 390, height: 844 } });
    const errs = [];
    p.on('pageerror', e => errs.push(e.message));
    await p.goto('file://' + dir + g + '.html'); await p.waitForTimeout(700);
    await p.screenshot({ path: `k-${g}-menu.png` });
    await p.click('#startBtn', { force: true }); await p.waitForTimeout(900);
    await p.screenshot({ path: `k-${g}-scene.png` });
    const endless = await p.evaluate(() => !!document.querySelector('.progress .score'));
    let rounds = 0, note = '';
    for (let t = 0; t < (endless ? 8 : 10); t++) {
      const q = await p.evaluate(() => K.q && { c: K.q.correct, k: K.q.key, text: K.q.text });
      if (t === 0) {
        const r = await p.evaluate(`(${TAP})(${q.c}, true)`); if (r !== 'ok') note += ' wrongtap:' + r;
        await p.waitForTimeout(450); await p.screenshot({ path: `k-${g}-wrong.png` });
        await p.waitForTimeout(endless ? 1800 : 1500);
        if (!endless) {
          await p.click('#pauseBtn', { force: true }); await p.waitForTimeout(300);
          const pv = await p.isVisible('#pause'); await p.click('#resumeBtn', { force: true }); await p.waitForTimeout(200);
          if (!pv) note += ' PAUSE-NOT-SHOWN';
        }
        if (endless) continue;
      }
      const q2 = await p.evaluate(() => ({ c: K.q.correct, k: K.q.key }));
      const r = await p.evaluate(`(${TAP})(${q2.c}, false)`); if (r !== 'ok') { note += ` tap${t}:${r}`; }
      if (t === 1) { await p.waitForTimeout(700); await p.screenshot({ path: `k-${g}-right.png` }); }
      // warten bis neue Aufgabe oder Ende
      await p.waitForFunction(k => (K.q && K.q.key !== k) || !document.getElementById('end').classList.contains('hidden') || K.phase !== 'play', q2.k, { timeout: 9000 }).catch(() => { note += ` stuck${t}`; });
      await p.waitForTimeout(150);
      rounds++;
      if (await p.isVisible('#end')) break;
    }
    if (endless) { // jetzt absichtlich verlieren: Zeit ablaufen lassen
      await p.waitForFunction(() => !document.getElementById('end').classList.contains('hidden'), null, { timeout: 60000 }).catch(() => note += ' endless-no-end');
    } else {
      await p.waitForFunction(() => !document.getElementById('end').classList.contains('hidden'), null, { timeout: 12000 }).catch(() => note += ' no-end');
    }
    await p.waitForTimeout(600);
    await p.screenshot({ path: `k-${g}-end.png` });
    console.log(g, '| runden', rounds, '| ende:', await p.textContent('#endText'), note, errs.length ? 'ERR ' + errs.join(' / ') : '');
    await p.close();
  }
  await b.close();
})();
