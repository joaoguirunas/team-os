<title>Agentes do Centro de Treinamento</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter+Tight:wght@300;400;500;600&family=JetBrains+Mono:wght@400;500&family=Fraunces:opsz,ital,wght@9..144,0,300..700;9..144,1,300..700&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0}
:root{--void:#050507;--ink2:#131318;--bone:#f1f1f3;--dim:#c5c5ca;--mute:#84848c;
 --hl:rgba(255,255,255,.07);--hls:rgba(255,255,255,.16);--em:#ff3a0e;
 --dsp:'Fraunces',Georgia,serif;--sans:'Inter Tight',system-ui,sans-serif;
 --mn:'JetBrains Mono',ui-monospace,monospace}
html{scroll-behavior:smooth}
html,body{background:var(--void);color:var(--dim);font-family:var(--sans);-webkit-font-smoothing:antialiased}
body::before{content:"";position:fixed;inset:0;pointer-events:none;z-index:0;
 background-image:radial-gradient(rgba(255,255,255,.05) 1px,transparent 1px);
 background-size:24px 24px;opacity:.4}
main{position:relative;z-index:1;max-width:1120px;margin:0 auto;padding:72px 40px 120px;
 font-size:15px;line-height:1.7;font-weight:300}
.kicker{font-family:var(--mn);font-size:11px;letter-spacing:.2em;text-transform:uppercase;color:var(--em);margin-bottom:20px}
h1{font-family:var(--dsp);font-weight:300;font-size:56px;letter-spacing:-.035em;line-height:1.02;color:var(--bone);margin-bottom:22px;text-wrap:balance}
.lede{max-width:62ch;font-size:16.5px;color:var(--dim)}
.lede em{font-family:var(--dsp);font-style:italic;color:var(--em);font-weight:400}
.lede code{font-family:var(--mn);font-size:13px;color:var(--em)}
.stats{display:flex;flex-wrap:wrap;margin:44px 0 0;border-top:1px solid var(--hls);border-bottom:1px solid var(--hl)}
.stat{padding:18px 36px 18px 0;margin-right:36px}
.stat b{display:block;font-family:var(--dsp);font-weight:300;font-size:34px;color:var(--bone);font-variant-numeric:tabular-nums;line-height:1.1}
.stat span{font-family:var(--mn);font-size:10px;letter-spacing:.16em;text-transform:uppercase;color:var(--mute)}
.toolbar{position:sticky;top:0;z-index:10;background:linear-gradient(var(--void) 82%,transparent);
 display:flex;flex-wrap:wrap;gap:8px;align-items:center;padding:20px 0 18px;margin-top:28px}
.fbtn{font-family:var(--mn);font-size:10.5px;letter-spacing:.12em;text-transform:uppercase;
 color:var(--mute);background:transparent;border:1px solid var(--hls);padding:8px 14px;cursor:pointer}
.fbtn:hover{color:var(--dim)}
.fbtn.active{color:var(--em);border-color:var(--em);background:rgba(255,58,14,.05)}
.fbtn:focus-visible,#q:focus-visible,.skill:focus-visible{outline:1px solid var(--em);outline-offset:2px}
#q{margin-left:auto;font-family:var(--mn);font-size:12px;color:var(--bone);background:var(--ink2);
 border:1px solid var(--hls);padding:8px 12px;min-width:220px}
#q::placeholder{color:var(--mute)}
.squad{margin-top:56px}
.squad[hidden]{display:none}
h2{font-family:var(--dsp);font-weight:300;font-size:30px;letter-spacing:-.028em;color:var(--bone);
 padding-top:24px;border-top:1px solid var(--hl);display:flex;align-items:baseline;gap:14px}
.idx{font-family:var(--mn);font-size:12px;color:var(--em);letter-spacing:.1em}
.count{margin-left:auto;font-family:var(--mn);font-size:10px;letter-spacing:.16em;text-transform:uppercase;color:var(--mute)}
.squad-sub{color:var(--mute);margin:8px 0 24px;font-size:14px}
.agents{display:grid;grid-template-columns:repeat(auto-fill,minmax(330px,1fr));gap:14px}
.agent{background:var(--ink2);border:1px solid var(--hl);padding:20px 22px;display:flex;flex-direction:column;gap:10px}
.agent[hidden]{display:none}
.agent:hover{border-color:var(--hls)}
.agent-top{display:flex;gap:14px;align-items:center}
.face{width:56px;height:56px;object-fit:cover;flex:none;border:1px solid var(--hls);
 filter:grayscale(.35) contrast(1.05);transition:filter .25s}
.agent:hover .face{filter:grayscale(0)}
.mono-face{display:flex;align-items:center;justify-content:center;font-family:var(--mn);
 font-size:15px;color:var(--mute);background:var(--void)}
.agent h3{font-family:var(--dsp);font-weight:400;font-size:21px;letter-spacing:-.01em;color:var(--bone);line-height:1.15}
.role{font-family:var(--mn);font-size:9.5px;letter-spacing:.14em;text-transform:uppercase;color:var(--em);margin:2px 0}
.agent-top code{display:block;font-family:var(--mn);font-size:9.5px;letter-spacing:.06em;color:var(--mute)}
.resumo{font-size:13.5px;line-height:1.65;color:var(--dim)}
details{font-size:12.5px}
details summary{font-family:var(--mn);font-size:9.5px;letter-spacing:.14em;text-transform:uppercase;
 color:var(--mute);cursor:pointer;list-style:none}
details summary::before{content:"+ ";color:var(--em)}
details[open] summary::before{content:"− "}
details p{color:var(--mute);margin-top:6px;line-height:1.6}
.aut{font-size:12px;color:var(--dim);border-left:2px solid var(--em);padding:6px 0 6px 12px;background:rgba(255,58,14,.04)}
.aut span{display:block;font-family:var(--mn);font-size:9px;letter-spacing:.16em;text-transform:uppercase;color:var(--em);margin-bottom:2px}
.skills{display:flex;flex-wrap:wrap;gap:5px;align-items:center}
.skills-l{font-family:var(--mn);font-size:9px;letter-spacing:.16em;text-transform:uppercase;color:var(--mute);margin-right:3px}
.skill{font-family:var(--mn);font-size:10px;color:var(--dim);background:var(--void);
 border:1px solid var(--hl);padding:3px 8px;cursor:pointer;transition:border-color .15s,color .15s}
.skill:hover{color:var(--em);border-color:rgba(255,58,14,.5)}
.agent footer{display:flex;flex-wrap:wrap;gap:6px;padding-top:2px;margin-top:auto}
.tag{font-family:var(--mn);font-size:9.5px;letter-spacing:.08em;color:var(--mute);border:1px solid var(--hl);padding:3px 8px}
.tag.opus{color:var(--em);border-color:rgba(255,58,14,.4)}
.empty{display:none;font-family:var(--mn);font-size:12px;color:var(--mute);padding:40px 0;text-align:center}
.pagefoot{margin-top:80px;padding-top:20px;border-top:1px solid var(--hl);font-family:var(--mn);
 font-size:10px;letter-spacing:.12em;text-transform:uppercase;color:var(--mute);line-height:2}
.pagefoot b{color:var(--em);font-weight:500}
/* Modal de skill */
.overlay{position:fixed;inset:0;z-index:50;background:rgba(5,5,7,.78);display:none;
 align-items:flex-start;justify-content:center;padding:10vh 20px 20px;backdrop-filter:blur(3px)}
.overlay.open{display:flex}
.modal{background:var(--ink2);border:1px solid var(--hls);max-width:640px;width:100%;
 padding:32px 36px;position:relative;max-height:75vh;overflow-y:auto}
.modal .mk{font-family:var(--mn);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--em);margin-bottom:10px}
.modal h4{font-family:var(--dsp);font-weight:400;font-size:27px;letter-spacing:-.02em;color:var(--bone);margin-bottom:14px}
.modal .sdesc{font-size:14px;line-height:1.7;color:var(--dim);margin-bottom:20px}
.modal .uk{font-family:var(--mn);font-size:9px;letter-spacing:.16em;text-transform:uppercase;color:var(--mute);margin-bottom:8px}
.modal .users{display:flex;flex-wrap:wrap;gap:6px}
.modal .users code{font-family:var(--mn);font-size:10px;color:var(--dim);border:1px solid var(--hl);padding:3px 8px}
.modal .close{position:absolute;top:14px;right:16px;font-family:var(--mn);font-size:12px;
 color:var(--mute);background:none;border:1px solid var(--hl);padding:4px 10px;cursor:pointer}
.modal .close:hover{color:var(--em);border-color:var(--em)}
@media (max-width:640px){main{padding:48px 20px 80px}h1{font-size:40px}#q{margin-left:0;width:100%}
 .modal{padding:24px 20px}}
@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}.face{transition:none}}
</style>
<main>
  <div class="kicker">CT · Centro de Treinamento · team-os · by João Guirunas</div>
  <h1>{{N_AGENTS}} agentes que trabalham<br>como <em>uma equipe</em></h1>
  <p class="lede">Agentes nativos do Claude Code Agent Teams, organizados em 5 squads. Cada um com persona própria, autoridades exclusivas, smart-memory compartilhada e o Native Teams Protocol. Clique numa skill para ver o que ela faz. Fonte da verdade: <code>.claude/agents/</code> deste repositório.</p>
  <div class="stats">
    <div class="stat"><b>{{N_AGENTS}}</b><span>agentes</span></div>
    <div class="stat"><b>5</b><span>squads</span></div>
    <div class="stat"><b>{{N_SKILLS}}</b><span>skills</span></div>
    <div class="stat"><b>{{N_OPUS}}</b><span>em opus fixo</span></div>
    <div class="stat"><b>100%</b><span>audit conforme</span></div>
  </div>
  <div class="toolbar">{{FILTERS}}<input id="q" type="search" placeholder="buscar agente ou skill…" aria-label="Buscar agente ou skill"></div>
  {{SECTIONS}}
  <div class="empty" id="empty">nenhum agente corresponde à busca</div>
  <div class="pagefoot">
    página oficial dos agentes · gerada por <b>generate-agents-page.py</b> a partir dos arquivos reais do CT<br>
    push ⊘ = hook block-git-push (autoridade exclusiva do devops) · worktrees proibidos — trabalho direto na branch ativa
  </div>
</main>
<div class="overlay" id="ov" role="dialog" aria-modal="true" aria-labelledby="mtitle">
  <div class="modal">
    <button class="close" id="mclose" aria-label="Fechar">esc</button>
    <div class="mk">skill</div>
    <h4 id="mtitle"></h4>
    <p class="sdesc" id="mdesc"></p>
    <div class="uk" id="muk"></div>
    <div class="users" id="musers"></div>
  </div>
</div>
<script>
const SKILLS = {{SKILLS_JSON}};
const btns=[...document.querySelectorAll(".fbtn")],cards=[...document.querySelectorAll(".agent")],
      squads=[...document.querySelectorAll(".squad")],q=document.getElementById("q"),
      empty=document.getElementById("empty"),ov=document.getElementById("ov");
let f="all";
function apply(){
  const t=q.value.trim().toLowerCase();
  cards.forEach(c=>{c.hidden=!((f==="all"||c.dataset.squad===f)&&(!t||c.dataset.q.includes(t)))});
  let any=false;
  squads.forEach(s=>{const vis=cards.some(c=>c.dataset.squad===s.dataset.squad&&!c.hidden);s.hidden=!vis;any=any||vis});
  empty.style.display=any?"none":"block";
}
btns.forEach(b=>b.addEventListener("click",()=>{f=b.dataset.f;btns.forEach(x=>x.classList.toggle("active",x===b));apply()}));
q.addEventListener("input",apply);
function openSkill(name){
  const s=SKILLS[name]; if(!s)return;
  document.getElementById("mtitle").textContent="/"+name;
  document.getElementById("mdesc").textContent=s.desc||"(sem descrição)";
  document.getElementById("muk").textContent=s.agents.length?`usada por ${s.agents.length} agente(s)`:"skill de uso geral";
  document.getElementById("musers").innerHTML=s.agents.map(a=>`<code>${a}</code>`).join("");
  ov.classList.add("open");document.getElementById("mclose").focus();
}
document.addEventListener("click",e=>{
  const sk=e.target.closest(".skill"); if(sk){openSkill(sk.dataset.skill);return}
  if(e.target===ov||e.target.id==="mclose")ov.classList.remove("open");
});
document.addEventListener("keydown",e=>{if(e.key==="Escape")ov.classList.remove("open")});
</script>
