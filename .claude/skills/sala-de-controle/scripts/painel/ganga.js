/* Ganga — assistente da Sala de Controle (etapa 1: conversa digitada + HUD + orb).
   Desligada por padrão. Só lê: pergunta vai para /api/ganga/ask, relatórios por /api/ganga/report(s). */
(() => {
  const $ = (s, r = document) => r.querySelector(s);
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const G = {on: false, mode: 'silencioso', open: false, orb: 'sleep', busy: false, speakUntil: 0, alert: null};
  const api = (p, body) => fetch(p, body === undefined ? {} : {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body)}).then(r => r.json());

  // ---------- botão na barra ----------
  const btn = document.createElement('button');
  btn.className = 'g-btn'; btn.id = 'gangaBtn'; btn.type = 'button';
  btn.innerHTML = '<i></i>Ganga';
  const bar = $('.top.bar');
  bar.insertBefore(btn, $('nav.metrics', bar) || null);

  // ---------- HUD ----------
  const hud = document.createElement('div');
  hud.id = 'ganga';
  hud.setAttribute('role', 'dialog'); hud.setAttribute('aria-label', 'Ganga');
  hud.innerHTML = `
    <canvas id="ggCanvas"></canvas>
    <div class="g-top">
      <div class="g-title"><b>GANGA</b><span id="ggStatus">dormindo</span></div>
      <div class="g-sp"></div>
      <div class="g-seg" id="ggMode" title="Silencioso: só fala quando você chama. Copiloto: também avisa sozinha (ativo na etapa 5).">
        <button data-m="silencioso">Silencioso</button><button data-m="copiloto">Copiloto</button></div>
      <button class="g-ico" id="ggMin" title="Minimizar (Esc) — a Ganga continua ligada">—</button>
      <button class="g-ico pw" id="ggOff" title="Desligar a Ganga">⏻</button>
    </div>
    <div id="ggChips"></div>
    <div class="g-talk">
      <div class="g-log" id="ggLog" aria-live="polite"></div>
      <form class="g-in" id="ggForm"><input id="ggInput" autocomplete="off" placeholder="Pergunte para a Ganga… ex.: o que está rolando?" maxlength="2000"><button id="ggSend">Enviar</button></form>
      <div class="g-hint">voz em tempo real chega na etapa 2 · Esc minimiza</div>
    </div>
    <aside class="g-side" id="ggSide">
      <header><h3 id="ggSideT">Relatórios<small id="ggSideS"></small></h3><button class="g-ico" id="ggBack" title="Voltar para a lista" hidden>←</button><button class="g-ico" id="ggSideX" title="Fechar">×</button></header>
      <div class="g-list" id="ggList"></div>
      <div class="g-view" id="ggView"></div>
    </aside>`;
  document.body.appendChild(hud);

  const setStatus = () => {
    const words = {sleep: 'dormindo', think: 'pensando…', speak: 'falando', listen: 'ouvindo', alert: 'aviso'};
    $('#ggStatus').innerHTML = `${esc(words[G.orb])} · modo <em>${esc(G.mode)}</em>`;
  };
  const paint = () => {
    btn.classList.toggle('on', G.on);
    btn.title = G.on ? 'Ganga ligada — clique para abrir' : 'Ganga desligada — clique para ligar';
    hud.querySelectorAll('#ggMode button').forEach(b => b.classList.toggle('on', b.dataset.m === G.mode));
    setStatus();
  };
  const setOrb = s => { G.orb = s; setStatus(); };

  const open = () => { G.open = true; hud.classList.add('show'); refreshChips(); setTimeout(() => $('#ggInput').focus(), 60); };
  const minimize = () => { G.open = false; hud.classList.remove('show'); $('#ggSide').classList.remove('show'); };

  btn.onclick = async () => {
    if (!G.on) { Object.assign(G, await api('/api/ganga', {on: true})); paint(); greet(); }
    open();
  };
  $('#ggMin').onclick = minimize;
  $('#ggOff').onclick = async () => { Object.assign(G, await api('/api/ganga', {on: false})); paint(); minimize(); };
  $('#ggMode').onclick = async e => {
    const m = e.target.dataset.m; if (!m) return;
    Object.assign(G, await api('/api/ganga', {mode: m})); paint();
  };
  document.addEventListener('keydown', e => {
    if (e.key !== 'Escape' || !G.open) return;
    e.stopImmediatePropagation();
    if ($('#ggSide').classList.contains('show')) $('#ggSide').classList.remove('show'); else minimize();
  }, true);

  // ---------- conversa ----------
  const log = $('#ggLog');
  const add = (who, text, extra = '') => {
    const d = document.createElement('div');
    d.className = 'g-msg ' + who;
    d.innerHTML = esc(text).replace(/\n/g, '<br>') + extra;
    log.appendChild(d); log.scrollTop = log.scrollHeight;
    while (log.children.length > 30) log.firstChild.remove();
    return d;
  };
  let greeted = false;
  function greet() {
    if (greeted) return; greeted = true;
    const h = new Date().getHours();
    const oi = h < 12 ? 'Bom dia' : h < 18 ? 'Boa tarde' : 'Boa noite';
    add('ga', `${oi}, João. Tô ligada e de olho em tudo. Pergunta o que quiser dos projetos.`);
    speakFor(2500);
  }
  function speakFor(ms) { G.speakUntil = performance.now() + ms; setOrb('speak'); }

  const ERR = {sem_claude: 'Não achei o Claude neste Mac, João. Sem ele eu não consigo pensar.',
    login: 'O login do Claude no terminal expirou, João. Abre o Terminal, roda claude e faz /login. Depois me chama de novo.',
    desligada: 'Estou desligada. Liga pelo ícone da Ganga.',
    falhou: 'Travei nessa. Tenta de novo em alguns segundos.'};

  $('#ggForm').onsubmit = async e => {
    e.preventDefault();
    const inp = $('#ggInput'), q = inp.value.trim();
    if (!q || G.busy) return;
    inp.value = ''; add('me', q);
    G.busy = true; $('#ggSend').disabled = true; setOrb('think');
    const wait = setTimeout(() => { if (G.busy) add('ga', 'Deixa eu ver…'); }, 4000);
    let r;
    try { r = await api('/api/ganga/ask', {text: q}); } catch { r = {error: 'falhou'}; }
    clearTimeout(wait);
    G.busy = false; $('#ggSend').disabled = false;
    if (r.error) { add('ga err', ERR[r.error] || ERR.falhou); setOrb('sleep'); return; }
    const links = (r.projects || []).map(p => `<button data-p="${esc(p.path)}" data-n="${esc(p.name)}">relatórios · ${esc(p.name)}</button>`).join('');
    const d = add('ga', r.text, links ? `<div class="lk">${links}</div>` : '');
    d.querySelectorAll('.lk button').forEach(b => b.onclick = () => openReports(b.dataset.p, b.dataset.n));
    speakFor(Math.min(12000, Math.max(1800, r.text.length * 55)));
    $('#ggInput').focus();
  };

  // ---------- projetos em volta da orb ----------
  let lastState = null;
  async function refreshChips() {
    if (!G.open) return;
    try { lastState = await api('/api/state'); } catch { return; }
    const sess = Object.fromEntries((lastState.sessions || []).map(s => [s.id, s]));
    const items = (lastState.projects || []).map(p => {
      const ss = (p.sessions || []).map(i => sess[i]).filter(s => s && s.recent && !s.is_self);
      if (!ss.length) return null;
      const wait = ss.some(s => s.state === 'approval' || (s.agents || []).some(a => a.state === 'approval'));
      const busy = ss.some(s => s.status === 'busy' || (s.agents || []).some(a => a.state === 'active'));
      const name = p.name.includes('|') ? p.name.split('|').pop().trim() : p.name.replace(/\(casa da Sala\)/, '').trim();
      const top = ss[0];
      return {p, name, cls: wait ? 'wait' : busy ? 'busy' : '', sub: wait ? 'precisa de você' : (top.doing || top.goal || (busy ? 'trabalhando' : 'parada'))};
    }).filter(Boolean).slice(0, 10);
    const dup = n => items.filter(x => x.name === n).length > 1;
    items.forEach(it => { if (dup(it.name)) it.name = it.p.name; });
    const box = $('#ggChips'); box.innerHTML = '';
    const W = innerWidth, H = innerHeight, cx = W / 2, cy = H * 0.4;
    const rx = Math.min(W * 0.36, 520), ry = Math.min(H * 0.27, 250);
    items.forEach((it, i) => {
      const a = -Math.PI / 2 + (i + 0.5) * (2 * Math.PI / items.length);
      const c = document.createElement('div');
      c.className = 'g-chip ' + it.cls;
      c.style.left = (cx + Math.cos(a) * rx) + 'px'; c.style.top = (cy + Math.sin(a) * ry) + 'px';
      c.innerHTML = `<b>${esc(it.name)}</b><small>${esc(it.sub)}</small>`;
      c.title = it.p.name + ' — clique para ver os relatórios';
      c.onclick = () => openReports(it.p.path, it.name);
      box.appendChild(c);
    });
    G.alert = items.some(i => i.cls === 'wait') ? 'wait' : null;
    btn.classList.toggle('alert', G.on && !!G.alert);
  }
  setInterval(refreshChips, 4000);
  addEventListener('resize', () => G.open && refreshChips());

  // ---------- relatórios ----------
  let curP = null;
  async function openReports(path, name) {
    curP = path;
    const side = $('#ggSide'); side.classList.add('show');
    $('#ggSideT').innerHTML = `Relatórios · ${esc(name)}<small>notas da smart-memory e relatórios html</small>`;
    $('#ggView').classList.remove('show'); $('#ggList').style.display = ''; $('#ggBack').hidden = true;
    const list = $('#ggList'); list.innerHTML = '<div class="g-empty">Carregando…</div>';
    const r = await api('/api/ganga/reports?p=' + encodeURIComponent(path));
    if (!r.reports || !r.reports.length) { list.innerHTML = '<div class="g-empty">Nenhum relatório ou nota neste projeto ainda.</div>'; return; }
    list.innerHTML = r.reports.map(x => `<button data-f="${esc(x.path)}" data-k="${x.kind}"><em>${x.digest ? 'resumo' : esc(x.kind)}</em><span>${esc(x.name)}</span><time>${esc(x.when)}</time></button>`).join('');
    list.querySelectorAll('button').forEach(b => b.onclick = () => openReport(b.dataset.f, b.dataset.k, b.querySelector('span').textContent));
  }
  async function openReport(f, kind, title) {
    const v = $('#ggView'); v.classList.add('show'); $('#ggList').style.display = 'none'; $('#ggBack').hidden = false;
    const url = '/api/ganga/report?p=' + encodeURIComponent(curP) + '&f=' + encodeURIComponent(f);
    if (kind === 'html') { v.innerHTML = `<iframe sandbox title="${esc(title)}" src="${url}"></iframe>`; return; }
    const r = await api(url);
    v.innerHTML = `<div class="g-md">${md(r.body || r.error || '')}</div>`;
  }
  $('#ggBack').onclick = () => { $('#ggView').classList.remove('show'); $('#ggList').style.display = ''; $('#ggBack').hidden = true; };
  $('#ggSideX').onclick = () => $('#ggSide').classList.remove('show');

  function md(src) {
    const inline = s => s.replace(/`([^`]+)`/g, '<code>$1</code>').replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>').replace(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/g, (_, a, b) => `<u>${b || a}</u>`);
    let out = '', inList = false;
    for (const raw of esc(src.replace(/<!--[\s\S]*?-->/g, '')).split('\n')) {
      const l = raw.trimEnd(); let m;
      if (inList && !/^\s*[-*] /.test(l)) { out += '</ul>'; inList = false; }
      if ((m = l.match(/^(#{1,3}) (.*)/))) out += `<h${m[1].length}>${inline(m[2])}</h${m[1].length}>`;
      else if ((m = l.match(/^\s*[-*] (.*)/))) { if (!inList) { out += '<ul>'; inList = true; } out += `<li>${inline(m[1])}</li>`; }
      else if (/^\|/.test(l)) { if (!/^\|[\s:|-]+\|$/.test(l)) out += '<table><tr>' + l.split('|').slice(1, -1).map(c => `<td>${inline(c.trim())}</td>`).join('') + '</tr></table>'; }
      else if (l.trim()) out += `<p>${inline(l)}</p>`;
    }
    return out + (inList ? '</ul>' : '');
  }

  // ---------- a orb ----------
  const cv = $('#ggCanvas'), cx2 = cv.getContext('2d');
  const P = Array.from({length: 140}, () => ({a: Math.random() * 6.283, r: 0.55 + Math.random() * 0.9, s: 0.2 + Math.random(), z: Math.random()}));
  let amp = 0, rot = 0, last = performance.now();
  function frame(now) {
    requestAnimationFrame(frame);
    if (!G.open) return;
    const dt = Math.min(0.05, (now - last) / 1000); last = now;
    if (G.orb === 'speak' && now > G.speakUntil) setOrb('sleep');
    const dpr = devicePixelRatio || 1, W = cv.clientWidth, H = cv.clientHeight;
    if (cv.width !== W * dpr) { cv.width = W * dpr; cv.height = H * dpr; }
    const c = cx2; c.setTransform(dpr, 0, 0, dpr, 0, 0); c.clearRect(0, 0, W, H);
    const cx = W / 2, cy = H * 0.4, R = Math.min(W, H) * 0.12;
    const t = now / 1000;
    const target = G.orb === 'speak' ? 0.35 + 0.25 * Math.abs(Math.sin(t * 9) * Math.sin(t * 3.7)) : G.orb === 'think' ? 0.18 : 0.05 + 0.03 * Math.sin(t * 1.3);
    amp += (target - amp) * Math.min(1, dt * (G.orb === 'speak' ? 14 : 4));
    const speed = reduce ? 0.1 : G.orb === 'think' ? 1.6 : G.orb === 'speak' ? 0.7 : 0.25;
    rot += dt * speed;
    const col = G.alert === 'wait' && G.orb === 'sleep' ? [240, 163, 94] : [61, 143, 255];
    const rgba = a => `rgba(${col[0]},${col[1]},${col[2]},${a})`;
    // halo
    const g = c.createRadialGradient(cx, cy, R * 0.2, cx, cy, R * 3.2);
    g.addColorStop(0, rgba(0.28 + amp * 0.5)); g.addColorStop(0.35, rgba(0.08 + amp * 0.15)); g.addColorStop(1, rgba(0));
    c.fillStyle = g; c.beginPath(); c.arc(cx, cy, R * 3.2, 0, 6.283); c.fill();
    // anéis
    c.lineWidth = 1;
    for (let k = 0; k < 3; k++) {
      const rr = R * (1.45 + k * 0.38 + amp * 0.4);
      c.strokeStyle = rgba(0.22 - k * 0.05);
      c.beginPath();
      const seg = G.orb === 'think' ? 4 : 1;
      for (let s = 0; s < seg; s++) {
        const a0 = rot * (k % 2 ? -1 : 1) * (1 + k * 0.3) + s * 6.283 / seg;
        c.moveTo(cx + Math.cos(a0) * rr, cy + Math.sin(a0) * rr);
        c.arc(cx, cy, rr, a0, a0 + (seg > 1 ? 1.1 : 6.283));
      }
      c.stroke();
    }
    // partículas
    for (const p of P) {
      p.a += dt * p.s * speed * 0.6;
      const rr = R * (p.r + amp * 0.9 * p.z) * 1.25;
      const x = cx + Math.cos(p.a) * rr, y = cy + Math.sin(p.a) * rr * (0.55 + p.z * 0.45);
      c.fillStyle = rgba(0.25 + p.z * 0.6);
      c.fillRect(x, y, 1.6, 1.6);
    }
    // núcleo
    const rCore = R * (0.82 + amp * 0.45);
    const core = c.createRadialGradient(cx - rCore * 0.3, cy - rCore * 0.35, rCore * 0.1, cx, cy, rCore);
    core.addColorStop(0, 'rgba(225,238,255,0.95)'); core.addColorStop(0.45, rgba(0.9)); core.addColorStop(1, 'rgba(10,10,51,0.9)');
    c.fillStyle = core; c.beginPath(); c.arc(cx, cy, rCore, 0, 6.283); c.fill();
  }
  requestAnimationFrame(frame);

  // ---------- estado inicial ----------
  api('/api/ganga').then(p => { Object.assign(G, p); paint(); }).catch(() => {});
  setInterval(() => api('/api/ganga').then(p => { const was = G.on; Object.assign(G, p); paint(); if (!G.on && was) minimize(); }).catch(() => {}), 5000);
})();
