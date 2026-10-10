const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = '/tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/spiele/';
const calc = t => { const m = t.match(/(\d+)\s*([+−·])\s*(\d+)/); if (!m) return null; const a = +m[1], b = +m[3]; return m[2] === '+' ? a + b : m[2] === '−' ? a - b : a * b; };
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const page = async (file, tag) => {
    const p = await b.newPage({ viewport: { width: 390, height: 844 } });
    p.on('pageerror', e => console.log(tag, 'PAGEERROR', e.message));
    p.on('console', m => m.type() === 'error' && console.log(tag, 'CONSOLE', m.text()));
    await p.goto('file://' + dir + file); await p.waitForTimeout(1000);
    await p.screenshot({ path: `${tag}-menu.png`, fullPage: true });
    return p;
  };
  // ---- Monster-Mampf ----
  {
    const p = await page('Theo - Monster-Mampf.html', 'mm');
    await p.click('#levels [data-level="4"]'); await p.click('#startBtn'); await p.waitForTimeout(2500);
    await p.screenshot({ path: 'mm-game.png' });
    for (let r = 0; r < 10; r++) {
      const st = await p.evaluate(() => ({ t: document.getElementById('task').textContent, n: [...document.querySelectorAll('#monsters .belly')].map(x => +x.textContent) }));
      const c = calc(st.t), idx = st.n.indexOf(c);
      if (idx < 0) console.log('mm MISSING', st);
      if (r === 0) { const w = st.n.findIndex(x => x !== c); await p.click(`#monsters .monster[data-i="${w}"]`); await p.waitForTimeout(300); await p.screenshot({ path: 'mm-wrong.png' }); await p.waitForTimeout(600); }
      await p.click(`#monsters .monster[data-i="${idx}"]`);
      if (r === 0) { await p.waitForTimeout(800); await p.screenshot({ path: 'mm-eat.png' }); }
      await p.waitForTimeout(2600);
    }
    await p.waitForTimeout(500); await p.screenshot({ path: 'mm-end.png' });
    console.log('mm end visible', await p.isVisible('#end'));
    // Keks fällt in die Tonne
    await p.click('#againBtn'); await p.waitForTimeout(13500); await p.screenshot({ path: 'mm-bin.png' });
    await p.close();
  }
  // ---- Turbo-Schnecke ----
  {
    const p = await page('Theo - Turbo-Schnecke.html', 'ts');
    await p.click('#tempo [data-tempo="55"]'); await p.click('#startBtn'); await p.waitForTimeout(1200);
    await p.screenshot({ path: 'ts-count.png' });
    await p.waitForTimeout(2700);
    for (let r = 0; r < 12; r++) {
      const st = await p.evaluate(() => ({ t: document.getElementById('task').textContent, n: [...document.querySelectorAll('.ans')].map(x => +x.textContent), over: !document.getElementById('end').classList.contains('hidden') }));
      if (st.over) break;
      const c = calc(st.t), idx = st.n.indexOf(c);
      if (idx < 0) console.log('ts MISSING', st);
      if (r === 3) { const w = st.n.findIndex(x => x !== c); await p.click(`.ans[data-i="${w}"]`); await p.waitForTimeout(350); await p.screenshot({ path: 'ts-slip.png' }); }
      await p.click(`.ans[data-i="${idx}"]`);
      if (r === 5) { await p.waitForTimeout(150); await p.screenshot({ path: 'ts-boost.png' }); }
      await p.waitForTimeout(1200);
    }
    await p.waitForTimeout(1500); await p.screenshot({ path: 'ts-end.png' });
    console.log('ts end:', await p.textContent('#endTitle'), '|', await p.textContent('#endText'));
    // Verlieren testen: nichts tun
    await p.click('#againBtn'); await p.waitForTimeout(62000); await p.screenshot({ path: 'ts-lose.png' });
    console.log('ts lose:', await p.textContent('#endTitle'));
    await p.close();
  }
  // ---- Pizza ----
  {
    const p = await page('Ida - Pizza Mamma Mia.html', 'pz');
    await p.click('#rows [data-row="7"]'); await p.click('#startBtn'); await p.waitForTimeout(1000);
    await p.screenshot({ path: 'pz-game.png' });
    for (let r = 0; r < 12; r++) {
      await p.waitForFunction(() => [...document.querySelectorAll('.ans')].some(b => !b.disabled), null, { timeout: 30000 });
      const st = await p.evaluate(() => ({ t: document.querySelector('#order .t').textContent, n: [...document.querySelectorAll('.ans')].map(x => +x.textContent) }));
      const c = calc(st.t), idx = st.n.indexOf(c);
      if (idx < 0) console.log('pz MISSING', st);
      if (r === 0) { const w = st.n.findIndex(x => x !== c); await p.click(`.ans[data-i="${w}"]`); await p.waitForTimeout(500); await p.screenshot({ path: 'pz-wrong.png' }); }
      if (r === 2) { await p.waitForTimeout(23500); await p.screenshot({ path: 'pz-angry.png' }); continue; }
      await p.click(`.ans[data-i="${idx}"]`);
      if (r === 0) { await p.waitForTimeout(1400); await p.screenshot({ path: 'pz-tops.png' }); await p.waitForTimeout(800); await p.screenshot({ path: 'pz-serve.png' }); }
      await p.waitForTimeout(800);
    }
    await p.waitForFunction(() => !document.getElementById('end').classList.contains('hidden'), null, { timeout: 30000 });
    await p.waitForTimeout(1200); await p.screenshot({ path: 'pz-end.png' });
    console.log('pz end:', await p.textContent('#endTitle'), await p.textContent('#eCoins'), await p.textContent('#eHappy'));
    await p.close();
  }
  await b.close();
})();
