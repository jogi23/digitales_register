const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = 'file:///tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/1x1-spiele/';
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const p = await b.newPage({ viewport: { width: 390, height: 844 } });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.goto(dir + 'dino-eier.html'); await p.waitForTimeout(900);
  await p.screenshot({ path: 'j-menu.png' });
  await p.click('#startBtn', { force: true }); await p.waitForTimeout(700);
  const right = () => p.evaluate(() => [...document.querySelectorAll('#answers .ans')].find(b => +b.dataset.v === K.q.correct).click());
  for (let i = 0; i < 3; i++) {
    await right();
    if (i === 0) { await p.waitForTimeout(330); await p.screenshot({ path: 'j-star.png' }); }
    if (i === 2) { await p.waitForTimeout(400); await p.screenshot({ path: 'j-streak.png' }); }
    await p.waitForFunction(k => K.q.key !== k || K.phase !== 'play', await p.evaluate(() => K.q.key), { timeout: 9000 }).catch(() => {});
    await p.waitForTimeout(150);
  }
  await p.waitForTimeout(50); await p.screenshot({ path: 'j-swap.png' });
  for (let i = 0; i < 7; i++) { const k = await p.evaluate(() => K.q.key); await right(); await p.waitForFunction(k => K.q.key !== k || K.phase !== 'play', k, { timeout: 9000 }).catch(() => {}); await p.waitForTimeout(150); }
  await p.waitForTimeout(1000); await p.screenshot({ path: 'j-end1.png' });
  await p.waitForTimeout(1800); await p.screenshot({ path: 'j-end2.png' });
  await p.close();
  const f = await b.newPage({ viewport: { width: 390, height: 844 } });
  f.on('pageerror', e => errs.push(e.message));
  await f.goto(dir + 'frosch-fliegen.html'); await f.click('#startBtn', { force: true }); await f.waitForTimeout(1500);
  await f.mouse.move(40, 300); await f.waitForTimeout(700); await f.screenshot({ path: 'j-frog-left.png' });
  await f.mouse.move(360, 300); await f.waitForTimeout(700); await f.screenshot({ path: 'j-frog-right.png' });
  await b.close();
  console.log('errors:', errs);
})();
