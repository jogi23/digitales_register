const { chromium } = require('/opt/node-tools/node_modules/playwright');
const dir = '/tmp/claude-0/-home-user-digitales-register/63dd9abc-7793-5061-97e4-62dfdc8a6284/scratchpad/';
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' }).catch(()=>chromium.launch());
  for (const vp of [{w:390,h:844,n:'phone'},{w:1100,h:850,n:'desk'}]) {
    const p = await b.newPage({ viewport: { width: vp.w, height: vp.h }, hasTouch: vp.n==='phone' });
    p.on('pageerror', e => console.log('PAGEERROR', e.message));
    p.on('console', m => m.type()==='error' && console.log('CONSOLE', m.text()));
    await p.goto('file://' + dir + 'spiele/Ida - Neon Math Defender.html');
    await p.waitForTimeout(800);
    await p.screenshot({ path: `n-${vp.n}-start.png` });
    await p.click('#modeSeg button[data-mode=training]');
    await p.click('#timeSeg button[data-time="30000"]');
    await p.screenshot({ path: `n-${vp.n}-start2.png` });
    await p.click('#startBtn');
    await p.waitForTimeout(1200);
    await p.screenshot({ path: `n-${vp.n}-banner.png` });
    // spielen: Fragen lesen & richtig antworten, manchmal falsch
    let shots=0;
    for (let t=0;t<200;t++){
      await p.waitForTimeout(250);
      const st = await p.evaluate(()=>{
        const q=document.getElementById('qtext').textContent;
        const btns=[...document.querySelectorAll('.ans')].map(b=>({t:b.querySelector('span').textContent,d:b.disabled}));
        const vis=id=>!document.getElementById(id).classList.contains('hidden');
        return {q,btns,wave:vis('waveScreen'),over:vis('overScreen')};
      });
      if (st.wave||st.over) { console.log(vp.n,'end state', st.wave?'wave':'over', 't',t); break; }
      const m = st.q.match(/(\d+) · (\d+)/);
      if (!m) continue; if (t===30) await p.screenshot({path:`n-${vp.n}-mid.png`});
      const ans = (+m[1])*(+m[2]);
      let idx = st.btns.findIndex(x=>+x.t===ans);
      if (t%7===3) { const w = st.btns.findIndex(x=>+x.t!==ans && !x.d); await p.keyboard.press(String(w+1)); await p.waitForTimeout(100); if(shots<1){await p.screenshot({path:`n-${vp.n}-wrong.png`});} }
      if (t%11===5 && shots<2) { await p.screenshot({path:`n-${vp.n}-play${shots}.png`}); shots++; }
      if (t%13 !== 7) await p.keyboard.press(String(idx+1));
      if (t===20) { await p.waitForTimeout(60); await p.screenshot({path:`n-${vp.n}-boom.png`}); }
    }
    await p.waitForTimeout(1500);
    await p.screenshot({ path: `n-${vp.n}-end.png` });
    await p.close();
  }
  await b.close();
})();
