const { chromium } = require('/opt/node-tools/node_modules/playwright');
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const p = await b.newPage({ viewport: { width: 390, height: 844 } });
  await p.goto('file:///tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/1x1-spiele/dino-eier.html');
  await p.click('#startBtn'); await p.waitForTimeout(600);
  await p.evaluate(() => [...document.querySelectorAll('#answers .ans')].find(b => +b.dataset.v === K.q.correct).click());
  await p.waitForTimeout(1350); await p.screenshot({ path: 'dino2.png', clip: { x: 0, y: 90, width: 390, height: 360 } });
  await b.close();
})();
