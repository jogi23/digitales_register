const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = '/tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/';
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const p = await b.newPage({ viewport: { width: 390, height: 844 } });
  p.on('pageerror', e => console.log('PAGEERROR', e.message));
  await p.goto('file://' + dir + 'spiele/Ida - Neon Math Defender.html');
  await p.click('#modeSeg button[data-mode=campaign]');
  await p.click('#startBtn');
  await p.waitForTimeout(7000);
  await p.screenshot({ path: 'n2-comets.png' });
  await p.waitForTimeout(6000);
  await p.screenshot({ path: 'n2-hit.png' });
  await p.waitForTimeout(400);
  await p.screenshot({ path: 'n2-hit2.png' });
  await p.waitForTimeout(25000);
  await p.screenshot({ path: 'n2-over.png' });
  await b.close();
})();
