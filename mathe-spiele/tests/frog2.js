const { chromium } = require('/opt/node-tools/node_modules/playwright');
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const p = await b.newPage({ viewport: { width: 390, height: 844 } });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.goto('file:///tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/1x1-spiele/frosch-fliegen.html');
  await p.waitForTimeout(600); await p.screenshot({ path: 'f2-menu.png' });
  await p.click('#startBtn', { force: true }); await p.waitForTimeout(1600);
  await p.screenshot({ path: 'f2-idle.png' });
  const tap = (wrong) => p.evaluate(w => { const els = [...document.querySelectorAll('.fly:not(.flee):not(.gone)')]; const el = els.find(e => w ? +e.dataset.v !== K.q.correct : +e.dataset.v === K.q.correct); el.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true })); }, wrong);
  await tap(true); await p.waitForTimeout(350); await p.screenshot({ path: 'f2-hot.png' });
  await p.waitForTimeout(1400);
  await tap(false); await p.waitForTimeout(110); await p.screenshot({ path: 'f2-tongue.png' });
  await p.waitForTimeout(420); await p.screenshot({ path: 'f2-happy.png' });
  await b.close();
  console.log('errors:', errs);
})();
