const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1440,height:900}});
const perr=[];p.on('pageerror',e=>perr.push(e.message));
await p.goto('file://'+process.argv[2]);await p.waitForTimeout(5000);
await p.click('text=灯油行会');await p.click('text=起航');await p.waitForTimeout(2500);
const r=await p.evaluate(()=>{const E=window.Engine,S=window.__yunhai.S,X=E.expansion;const out=[],errs={};let stuck=0,last=-1;const t0=performance.now();
 for(let i=0;i<60000&&!S.over;i++){
  try{const x=X.state(S);
   if(S.event){try{E.resolveEvent(S,0)}catch(e){errs['ev:'+e.message]=1;S.event=null}}
   if(x.pending){const r=X.resolvePending(S,'pay');if(!r||!r.ok)X.resolvePending(S,'surrender');if(x.pending)x.pending=null;}
   if(S.battle){try{X.battleChoice&&X.battleChoice(S,'withdraw')}catch(e){} if(S.battle){try{E.endPlayerBattle(S)}catch(e){errs['bt:'+e.message]=1;S.battle=null}}}
   S.prompt=null;
   E.tick(S);
  }catch(e){errs[e.message]=(errs[e.message]||0)+1;}
  if(S.day===last){if(++stuck>50){out.push('STUCK day '+S.day+' ev '+!!S.event+' bt '+!!S.battle+' pend '+!!X.state(S).pending+' prompt '+JSON.stringify(S.prompt));break;}}else{stuck=0;last=S.day;}
  if(Math.floor(S.day/1440)!==out._y){out._y=Math.floor(S.day/1440);out.push({d:S.day,date:E.dateText(S.day),f:Object.fromEntries(Object.entries(S.factions).map(([k,f])=>[k,[Math.round(f.gold),f.lh?.stage]]))});}
 }
 return {out,errs,over:S.over,day:S.day,date:E.dateText(S.day),ms:Math.round(performance.now()-t0),winner:S.winner||S.result||null,score:E.scoreRows?E.scoreRows(S).slice(0,8):null};});
console.log(JSON.stringify(r).slice(0,8000));console.log('pageerrors',perr.slice(0,5));await b.close();})();
