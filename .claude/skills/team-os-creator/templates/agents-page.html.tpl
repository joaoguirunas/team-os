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
.totals{margin:32px 0 0;width:100%;border-collapse:collapse;font-size:13.5px}
.totals caption{text-align:left;font-family:var(--mn);font-size:10px;letter-spacing:.16em;text-transform:uppercase;color:var(--mute);margin-bottom:10px}
.totals th,.totals td{padding:9px 14px 9px 0;border-bottom:1px solid var(--hl);text-align:left;font-weight:300}
.totals th{font-family:var(--mn);font-size:10px;letter-spacing:.12em;text-transform:uppercase;color:var(--mute);font-weight:400}
.totals td.n{font-variant-numeric:tabular-nums;color:var(--bone)}
.totals tr.tot td{border-top:1px solid var(--hls);border-bottom:none;color:var(--bone);font-weight:500}
.totals tr.tot td.n{color:var(--em)}
.totals td.sqname{color:var(--bone)}
@media (max-width:640px){.totals{font-size:12.5px}.totals th,.totals td{padding:7px 8px 7px 0}}
.toolbar{position:sticky;top:0;z-index:10;background:linear-gradient(var(--void) 82%,transparent);
 display:flex;flex-wrap:wrap;gap:8px;align-items:center;padding:20px 0 18px;margin-top:28px}
.fbtn{font-family:var(--mn);font-size:10.5px;letter-spacing:.12em;text-transform:uppercase;
 color:var(--mute);background:transparent;border:1px solid var(--hls);padding:8px 14px;cursor:pointer}
.fbtn:hover{color:var(--dim)}
.fbtn.active{color:var(--em);border-color:var(--em);background:rgba(255,58,14,.05)}
.fbtn:focus-visible,#q:focus-visible,.skill:focus-visible,.agent:focus-visible{outline:1px solid var(--em);outline-offset:2px}
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
.agent{background:var(--ink2);border:1px solid var(--hl);padding:20px 22px 0;display:flex;flex-direction:column;gap:10px;
 cursor:pointer;transition:border-color .15s}
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
.vermais{display:flex;justify-content:center;align-items:center;margin:2px -22px 0;padding:9px 0 8px;
 border-top:1px solid var(--hl);font-family:var(--mn);font-size:9.5px;letter-spacing:.14em;text-transform:uppercase;
 color:var(--mute);transition:color .15s,background .15s}
.agent:hover .vermais{color:var(--em);background:rgba(255,58,14,.05)}
.vermais span::after{content:" →";display:inline-block;transition:transform .15s}
.agent:hover .vermais span::after{transform:translateX(3px)}
.empty{display:none;font-family:var(--mn);font-size:12px;color:var(--mute);padding:40px 0;text-align:center}
.pagefoot{margin-top:80px;padding-top:20px;border-top:1px solid var(--hl);font-family:var(--mn);
 font-size:10px;letter-spacing:.12em;text-transform:uppercase;color:var(--mute);line-height:2}
.pagefoot b{color:var(--em);font-weight:500}
/* Modal (perfil de agente e skill) */
.overlay{position:fixed;inset:0;z-index:50;background:rgba(5,5,7,.78);display:none;
 align-items:flex-start;justify-content:center;padding:8vh 20px 20px;backdrop-filter:blur(3px);overflow-y:auto}
.overlay.open{display:flex}
.modal{background:var(--ink2);border:1px solid var(--hls);max-width:640px;width:100%;
 padding:32px 36px;position:relative;margin-bottom:8vh}
.modal .mk{font-family:var(--mn);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--em);
 margin-bottom:10px;display:flex;align-items:center;gap:8px}
.modal .mk .mkface{width:26px;height:26px;flex:none;object-fit:cover;border:1px solid var(--hls)}
.modal .mk .mkmono{width:26px;height:26px;flex:none;display:flex;align-items:center;justify-content:center;
 font-family:var(--mn);font-size:10px;color:var(--mute);background:var(--void);border:1px solid var(--hls)}
.modal h4{font-family:var(--dsp);font-weight:400;font-size:27px;letter-spacing:-.02em;color:var(--bone);margin-bottom:4px}
.modal .msub{font-family:var(--mn);font-size:10.5px;color:var(--em);margin-bottom:16px}
.modal .msub .sq{color:var(--mute);text-transform:uppercase;letter-spacing:.08em}
.modal .bio{font-size:14px;line-height:1.7;color:var(--bone);font-weight:300;margin-bottom:16px;
 padding-bottom:16px;border-bottom:1px solid var(--hl)}
.modal .sdesc{font-size:14px;line-height:1.7;color:var(--dim);margin-bottom:18px}
.modal h5{font-family:var(--mn);font-weight:400;font-size:9px;letter-spacing:.16em;text-transform:uppercase;
 color:var(--mute);margin:18px 0 10px}
.modal table.mat{width:100%;border-collapse:collapse;font-size:12.5px;margin-bottom:6px}
.modal table.mat td{padding:8px 10px 8px 0;border-bottom:1px solid var(--hl);vertical-align:top;color:var(--dim);font-weight:300}
.modal table.mat td:first-child{color:var(--bone);font-weight:400;white-space:nowrap;padding-right:14px}
.modal ul.rules{list-style:none;display:flex;flex-direction:column;gap:8px}
.modal ul.rules li{font-size:13px;line-height:1.5;color:var(--dim);font-weight:300;padding-left:16px;position:relative}
.modal ul.rules li::before{content:"—";position:absolute;left:0;color:var(--em)}
.modal ul.sect{list-style:none;display:flex;flex-direction:column;gap:6px}
.modal ul.sect li{font-size:13px;color:var(--dim);font-weight:300;font-family:var(--mn)}
.modal .uk{font-family:var(--mn);font-size:9px;letter-spacing:.16em;text-transform:uppercase;color:var(--mute);margin-bottom:8px}
.modal .users{display:flex;flex-wrap:wrap;gap:6px}
.modal .users code,.modal .users button{font-family:var(--mn);font-size:10px;color:var(--dim);background:var(--void);
 border:1px solid var(--hl);padding:3px 8px}
.modal .users button{cursor:pointer;transition:border-color .15s,color .15s}
.modal .users button:hover{color:var(--em);border-color:rgba(255,58,14,.5)}
.modal .metarow{display:flex;flex-wrap:wrap;gap:6px;margin-top:16px;padding-top:16px;border-top:1px solid var(--hl)}
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
  <p class="lede">Agentes nativos do Claude Code Agent Teams, organizados em {{N_SQUADS}} squads. Cada um com persona própria, autoridades exclusivas, smart-memory compartilhada e o Native Teams Protocol. Clique num agente para ver o perfil completo (bio, matriz de autoridade, regras absolutas) ou numa skill para ver o que ela cobre. Fonte da verdade: <code>.claude/agents/</code> deste repositório.</p>
  <div class="stats">
    <div class="stat"><b>{{N_AGENTS}}</b><span>agentes</span></div>
    <div class="stat"><b>{{N_SQUADS}}</b><span>squads</span></div>
    <div class="stat"><b>{{N_SKILLS}}</b><span>skills</span></div>
    <div class="stat"><b>{{N_OPUS}}</b><span>em opus fixo</span></div>
    <div class="stat"><b>100%</b><span>audit conforme</span></div>
  </div>
  {{TOTALS_TABLE}}
  <div class="toolbar">{{FILTERS}}<input id="q" type="search" placeholder="buscar agente ou skill…" aria-label="Buscar agente ou skill"></div>
  {{SECTIONS}}
  <div class="empty" id="empty">nenhum agente corresponde à busca</div>
  <div class="pagefoot">
    página oficial dos agentes · gerada por <b>generate-agents-page.py</b> a partir dos arquivos reais do CT<br>
    push ⊘ = hook block-git-push (autoridade exclusiva do devops) · worktrees proibidos — trabalho direto na branch ativa
  </div>
</main>
<div class="overlay" id="ov" role="dialog" aria-modal="true" aria-labelledby="mtitle">
  <div class="modal" id="modalbox"></div>
</div>
<script>
const AGENTS = {{AGENTS_JSON}};
const SKILLS = {{SKILLS_JSON}};
const btns=[...document.querySelectorAll(".fbtn")],cards=[...document.querySelectorAll(".agent")],
      squads=[...document.querySelectorAll("section.squad")],q=document.getElementById("q"),
      empty=document.getElementById("empty"),ov=document.getElementById("ov"),box=document.getElementById("modalbox");
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

function esc(s){const d=document.createElement("div");d.textContent=s==null?"":String(s);return d.innerHTML}

function openSkill(name){
  const s=SKILLS[name]; if(!s)return;
  const sects=(s.sections||[]).map(t=>"<li>"+esc(t)+"</li>").join("");
  const ags=(s.agents||[]).map(a=>'<button data-agent-link="'+a+'">'+esc(a)+"</button>").join("");
  const meta=[s.version?"v"+esc(s.version):"",s.updated?esc(s.updated):""].filter(Boolean).join(" · ");
  box.innerHTML=
    '<button class="close" id="mclose">esc</button>'+
    '<div class="mk">skill'+(meta?" · "+meta:"")+'</div>'+
    '<h4 id="mtitle">/'+esc(name)+'</h4>'+
    '<p class="sdesc">'+esc(s.desc||"(sem descrição)")+'</p>'+
    (sects?'<h5>o que cobre</h5><ul class="sect">'+sects+'</ul>':'')+
    '<h5>'+((s.agents||[]).length?"usada por "+(s.agents||[]).length+" agente(s)":"skill de uso geral")+'</h5>'+
    '<div class="users">'+ags+'</div>';
  wireModal(); ov.classList.add("open"); ov.scrollTop=0;
}

function openAgent(name){
  const a=AGENTS[name]; if(!a)return;
  const mat=(a.matrix||[]).map(r=>"<tr><td>"+esc(r[0]||"")+"</td><td>"+esc(r[1]||"")+"</td><td>"+esc(r[2]||"")+"</td></tr>").join("");
  const rules=(a.rules||[]).map(r=>"<li>"+esc(r)+"</li>").join("");
  const chips=(a.skills||[]).map(s=>'<button class="skill" data-skill-link="'+s+'">/'+esc(s)+"</button>").join("");
  const tags=[
    '<span class="tag'+(a.model==="opus"?" opus":"")+'">'+esc(a.model)+'</span>',
    a.effort?'<span class="tag">effort '+esc(a.effort)+'</span>':'',
    a.hook?'<span class="tag" title="hook block-git-push — push só pelo devops">push ⊘</span>':'',
    a.mcp?'<span class="tag">'+a.mcp+' MCP</span>':''
  ].join("");
  box.innerHTML=
    '<button class="close" id="mclose">esc</button>'+
    '<div class="mk"><div class="mkmono">'+esc((a.persona||"?").slice(0,2).toUpperCase())+'</div>agente</div>'+
    '<h4 id="mtitle">'+esc(a.role)+'</h4>'+
    '<div class="msub">'+esc(a.persona)+' <span class="sq">· '+esc(a.squad)+'</span></div>'+
    (a.bio?'<p class="bio">'+esc(a.bio)+'</p>':'')+
    '<p class="sdesc">'+esc(a.desc)+'</p>'+
    (mat?'<h5>matriz de autoridade</h5><table class="mat"><tbody>'+mat+'</tbody></table>':'')+
    (rules?'<h5>regras absolutas</h5><ul class="rules">'+rules+'</ul>':'')+
    (chips?'<h5>skills</h5><div class="users">'+chips+'</div>':'')+
    '<div class="metarow">'+tags+'</div>';
  wireModal(); ov.classList.add("open"); ov.scrollTop=0;
}

function wireModal(){
  const c=document.getElementById("mclose"); if(c)c.addEventListener("click",()=>ov.classList.remove("open"));
  box.querySelectorAll("[data-agent-link]").forEach(b=>b.addEventListener("click",()=>openAgent(b.dataset.agentLink)));
  box.querySelectorAll("[data-skill-link]").forEach(b=>b.addEventListener("click",()=>openSkill(b.dataset.skillLink)));
}
document.querySelectorAll(".skill[data-skill]").forEach(b=>b.addEventListener("click",e=>{e.stopPropagation();openSkill(b.dataset.skill)}));
document.querySelectorAll(".agent[data-agent]").forEach(el=>{
  el.addEventListener("click",()=>openAgent(el.dataset.agent));
  el.addEventListener("keydown",e=>{if(e.key==="Enter"||e.key===" "){e.preventDefault();openAgent(el.dataset.agent)}});
});
ov.addEventListener("click",e=>{if(e.target===ov)ov.classList.remove("open")});
document.addEventListener("keydown",e=>{if(e.key==="Escape")ov.classList.remove("open")});
</script>
