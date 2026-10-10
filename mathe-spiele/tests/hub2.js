const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = '/tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/1x1-spiele/';
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  for (const [w, h, n] of [[390, 844, 'phone'], [1200, 900, 'desk']]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    p.on('pageerror', e => console.log(n, 'PAGEERROR', e.message));
    for (const f of ['index.html', 'einmaleins.html', 'zahlenraum-20.html']) {
      await p.goto('file://' + dir + f); await p.waitForTimeout(800);
      await p.screenshot({ path: `h2-${n}-${f}.png`, fullPage: true });
      const sw = await p.evaluate(() => document.documentElement.scrollWidth);
      if (sw > w) console.log(n, f, 'OVERFLOW', sw);
    }
    if (n !== 'desk') { await p.close(); continue; }
    await p.goto('file://' + dir + 'index.html');
    for (const gate of ['einmaleins.html', 'zahlenraum-20.html']) {
      await p.click(`a.gate[href="${gate}"]`); await p.waitForTimeout(400);
      const sub = await p.title();
      const links = await p.$$eval('a.game', as => as.map(a => a.getAttribute('href')));
      for (const l of links) {
        await p.click(`a.game[href="${l}"]`); await p.waitForTimeout(600);
        const title = await p.title();
        let extra = '';
        if (await p.$('#cards')) {
          const cards = await p.$$eval('#cards .card', cs => cs.map(c => c.dataset.mode));
          await p.click('#cards .card'); await p.waitForTimeout(500);
          await p.evaluate(() => document.querySelector('#stage .ans').click()); await p.waitForTimeout(200);
          extra = ` [Karten: ${cards.join(',')} | Spiel läuft: ${await p.isVisible('#game')}]`;
          await p.click('#homeBtn'); await p.waitForTimeout(300);
        }
        await p.click('#hubBtn, .hub-link'); await p.waitForTimeout(400);
        console.log(`${sub} -> ${l} -> ${title}${extra} -> zurück: ${await p.title()}`);
      }
      await p.click('a.back'); await p.waitForTimeout(300);
    }
    await p.close();
  }
  await b.close();
})();
