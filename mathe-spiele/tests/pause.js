const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = 'file:///tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/1x1-spiele/';
const CASES = [
  ['monster-mampf.html', '#startBtn', 1500, () => document.getElementById('cookie').style.transform],
  ['turbo-schnecke.html', '#startBtn', 4500, () => document.getElementById('clock').textContent + ' / ' + document.getElementById('turtle').style.transform],
  ['pizza-mamma-mia.html', '#startBtn', 1500, () => document.getElementById('patience').style.transform],
  ['ballon-jagd.html', '#cards .card', 800, () => document.getElementById('hint') ? 'ok' : document.querySelector('.speech').textContent],
  ['ninja-sprung.html', '#startBtn', 1500, () => document.getElementById('fuse').style.transform],
];
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  for (const [f, start, wait, probe] of CASES) {
    const p = await b.newPage({ viewport: { width: 390, height: 844 } });
    const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.goto(dir + f); await p.waitForTimeout(500);
    await p.click(start); await p.waitForTimeout(wait);
    await p.click('#pauseBtn'); await p.waitForTimeout(300);
    const a = await p.evaluate(probe);
    const ov = await p.evaluate(() => { const o = document.getElementById('pauseOv') || document.getElementById('pause'); return o && !o.classList.contains('hidden'); });
    await p.waitForTimeout(2500);
    const b2 = await p.evaluate(probe);
    await p.screenshot({ path: 'pause-' + f.replace('.html', '.png') });
    await p.click('#pResume, #resumeBtn'); await p.waitForTimeout(1200);
    const c = await p.evaluate(probe);
    console.log(f.padEnd(24), '| Overlay:', ov, '| während Pause gleich:', a === b2, '| läuft danach weiter:', b2 !== c, errs.length ? 'ERR ' + errs : '');
    await p.close();
  }
  await b.close();
})();
