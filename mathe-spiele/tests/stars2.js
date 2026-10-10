const { chromium } = require('/opt/node-tools/node_modules/playwright');
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const p = await b.newPage({ viewport: { width: 390, height: 844 } });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.goto('file:///tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/1x1-spiele/sternenfaenger.html');
  await p.waitForTimeout(800); await p.screenshot({ path: 's2-menu.png' });
  await p.click('#modeSeg [data-mode=training]', { force: true }); await p.click('#timeSeg [data-time="30000"]', { force: true });
  await p.click('#startBtn', { force: true }); await p.waitForTimeout(7000);
  await p.screenshot({ path: 's2-scene.png' });
  const solve = async () => { const q = await p.textContent('#qtext'); const m = q.match(/(\d+) · (\d+)/); if (!m) return false; const v = +m[1] * +m[2]; const btns = await p.$$eval('.ans', bs => bs.map(b => b.textContent)); const i = btns.findIndex(t => t.includes(String(v)) && t.replace(/^\d/, '') !== '' ? +t.slice(1) === v || +t === v : false); return true; };
  // per Tastatur antworten
  let shotCheer = false;
  for (let t = 0; t < 140; t++) {
    await p.waitForTimeout(220);
    const st = await p.evaluate(() => ({ q: document.getElementById('qtext').textContent, b: [...document.querySelectorAll('.ans span')].map(s => s.textContent), wave: !document.getElementById('waveScreen').classList.contains('hidden') }));
    if (st.wave) break;
    const m = st.q.match(/(\d+) · (\d+)/); if (!m) continue;
    const idx = st.b.findIndex(x => +x === +m[1] * +m[2]); if (idx < 0) continue;
    await p.keyboard.press(String(idx + 1));
    if (!shotCheer) { await p.waitForTimeout(900); await p.screenshot({ path: 's2-cheer.png' }); shotCheer = true; }
  }
  await p.waitForTimeout(2600); await p.screenshot({ path: 's2-wave.png' });
  // traurig: nichts tun bis ein Stern landet
  await p.click('#nextBtn', { force: true }); await p.waitForTimeout(13000); await p.screenshot({ path: 's2-sad.png' });
  await b.close(); console.log('errors', errs);
})();
