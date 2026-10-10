const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = '/tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/spiele/';
const solve = q => {
  let m;
  if ((m = q.match(/^(\d+) · \? = (\d+)$/))) return +m[2] / +m[1];
  if ((m = q.match(/^(\d+) : (\d+)$/))) return +m[1] / +m[2];
  if ((m = q.match(/^(\d+) · (\d+)$/))) return +m[1] * +m[2];
  return null;
};
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  for (const name of (process.argv[2] ? [process.argv[2]] : ['Tiefsee-Alarm', 'Zauberburg', 'Pixel-Invasion', 'Sternenfänger'])) {
    const tag = name.slice(0, 4);
    const p = await b.newPage({ viewport: { width: 390, height: 844 } });
    p.on('pageerror', e => console.log(tag, 'PAGEERROR', e.message));
    p.on('console', m => m.type() === 'error' && console.log(tag, 'CONSOLE', m.text()));
    await p.goto('file://' + dir + 'Ida - ' + name + '.html');
    await p.waitForTimeout(1500);
    await p.screenshot({ path: `t-${tag}-start.png` });
    await p.click('#modeSeg [data-mode=training]');
    await p.click('#rowSeg [data-row="7"]');
    await p.click('#taskSeg [data-task=mix]');
    await p.click('#timeSeg [data-time="30000"]');
    await p.click('#startBtn');
    await p.waitForTimeout(6500);
    await p.screenshot({ path: `t-${tag}-scene.png` });
    let wrongOnce = false, unsolved = 0, solved = 0;
    for (let t = 0; t < 160; t++) {
      await p.waitForTimeout(220);
      const st = await p.evaluate(() => ({
        q: document.getElementById('qtext').textContent,
        btns: [...document.querySelectorAll('.ans')].map(b => ({ t: b.querySelector('span').textContent, d: b.disabled })),
        wave: !document.getElementById('waveScreen').classList.contains('hidden')
      }));
      if (st.wave) { console.log(tag, 'wave done at', t, 'solved', solved, 'unsolved', unsolved); break; }
      const ans = solve(st.q);
      if (ans === null) { if (/\d/.test(st.q)) { unsolved++; console.log(tag, 'cannot parse', st.q); } continue; }
      const idx = st.btns.findIndex(x => +x.t === ans);
      if (idx < 0) { console.log(tag, 'ANSWER MISSING', st.q, JSON.stringify(st.btns)); continue; }
      if (!wrongOnce && t > 5) { wrongOnce = true; const w = st.btns.findIndex(x => +x.t !== ans); await p.keyboard.press(String(w + 1)); await p.waitForTimeout(80); await p.screenshot({ path: `t-${tag}-wrong.png` }); }
      await p.keyboard.press(String(idx + 1)); solved++;
      if (solved === 6) { await p.waitForTimeout(70); await p.screenshot({ path: `t-${tag}-boom.png` }); }
    }
    await p.waitForTimeout(1200);
    await p.screenshot({ path: `t-${tag}-wave.png` });
    // Endlos-Modus: nichts tun bis Game Over
    await p.click('#waveMenuBtn');
    await p.click('#modeSeg [data-mode=endless]');
    await p.click('#taskSeg [data-task=gap]');
    await p.click('#startBtn');
    await p.waitForTimeout(9000);
    await p.screenshot({ path: `t-${tag}-endless.png` });
    await p.waitForTimeout(30000);
    await p.screenshot({ path: `t-${tag}-over.png` });
    console.log(tag, 'over visible', await p.isVisible('#overScreen'));
    await p.close();
  }
  await b.close();
})();
