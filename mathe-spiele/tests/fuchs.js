const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = '/tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/';
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' }).catch(()=>chromium.launch());
  for (const vp of [{w:390,h:844,n:'phone'},{w:1100,h:900,n:'desk'}]) {
    const p = await b.newPage({ viewport: { width: vp.w, height: vp.h } });
    p.on('pageerror', e => console.log('PAGEERROR', e.message));
    p.on('console', m => m.type()==='error' && console.log('CONSOLE', m.text()));
    await p.goto('file://' + dir + 'spiele/Theo - Mathe Fuchs.html');
    await p.waitForTimeout(800);
    await p.screenshot({ path: `${vp.n}-menu.png`, fullPage: true });
    for (const mode of ['verliebte','zerlegen','addsub','pyramid','mix']) {
      await p.click(`.card[data-mode=${mode}]`);
      await p.waitForTimeout(600);
      await p.screenshot({ path: `${vp.n}-${mode}.png` });
      // ein Fehlversuch
      const wrongSel = await p.evaluate(() => { const bs=[...document.querySelectorAll('.ans')]; return bs.findIndex(b=>!b.disabled && +b.dataset.choice!==window.__c); });
      let correct = await p.evaluate(()=>{ return null; });
      for (let i=0;i<10;i++){
        // wrong first
        await p.evaluate(() => {
          const bs=[...document.querySelectorAll('.ans')];
          // find correct via heuristics: try each wrong is hidden; use exposed state? not exposed: click buttons until locked
        });
        // click buttons in order until correct
        for (let k=0;k<4;k++){
          const done = await p.evaluate((k)=>{ const bs=[...document.querySelectorAll('#stage .ans')]; const b=bs[k]; if(!b||b.disabled) return false; b.click(); return b.classList.contains('correct'); }, k);
          if (i===0 && k===1 && !done) await p.screenshot({ path: `${vp.n}-${mode}-wrong.png` });
          if (done) break;
        }
        if (i===0) { await p.waitForTimeout(300); await p.screenshot({ path: `${vp.n}-${mode}-right.png` }); }
        await p.waitForTimeout(1600);
      }
      await p.waitForTimeout(800);
      if (mode==='verliebte') await p.screenshot({ path: `${vp.n}-end.png` });
      const endVisible = await p.isVisible('#end');
      console.log(vp.n, mode, 'end visible', endVisible);
      await p.click('#menuBtn');
      await p.waitForTimeout(300);
    }
    await p.screenshot({ path: `${vp.n}-menu2.png`, fullPage: true });
    await p.close();
  }
  await b.close();
})();
