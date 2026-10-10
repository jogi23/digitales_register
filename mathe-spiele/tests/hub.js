const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = '/tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/1x1-spiele/';
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  for (const [w, h, n] of [[390, 844, 'phone'], [1200, 900, 'desk']]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    p.on('pageerror', e => console.log(n, 'PAGEERROR', e.message));
    await p.goto('file://' + dir + 'index.html');
    await p.waitForTimeout(1200);
    await p.screenshot({ path: `hub-${n}.png`, fullPage: true });
    console.log(n, 'scrollWidth', await p.evaluate(() => document.documentElement.scrollWidth), 'vw', w);
    if (n === 'desk') {
      const links = await p.$$eval('a.game', as => as.map(a => a.getAttribute('href')));
      for (const l of links) {
        await p.click(`a[href="${l}"]`);
        await p.waitForTimeout(700);
        const title = await p.title();
        await p.click('#hubBtn, .hub-link');
        await p.waitForTimeout(400);
        console.log(l, '->', title, '| zurück:', await p.title());
      }
    }
    await p.close();
  }
  await b.close();
})();
