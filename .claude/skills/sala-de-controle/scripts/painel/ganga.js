/* Ganga — assistente da Sala de Controle.
   Etapa 1: HUD, orb, conversa digitada (Claude) e relatórios.
   Etapa 2: tela Configurar (chave no Porta-chaves, voz, microfone, limite) e voz em tempo real
            pelo Gemini Live (token temporário; a chave nunca chega ao navegador), com o Claude como cérebro.
   Desligada por padrão. Só lê: nunca escreve em projeto nem manda pedido para sessão. */
(() => {
  const $ = (s, r = document) => r.querySelector(s);
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const G = {on: false, mode: 'silencioso', open: false, orb: 'sleep', busy: false, speakUntil: 0, alert: null,
    key_hint: '', voice: '', mic: '', daily_minutes: 60, used_today: 0, level: 0, live: false};
  const api = (p, body) => fetch(p, body === undefined ? {} : {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body)}).then(r => r.json());

  // ---------- botão flutuante ----------
  const btn = document.createElement('button');
  btn.className = 'g-btn'; btn.id = 'gangaBtn'; btn.type = 'button';
  btn.innerHTML = '<i></i><span>Ganga</span>';
  btn.setAttribute('aria-label', 'Ganga');
  document.body.appendChild(btn);
  document.body.classList.add('has-ganga');

  // ---------- HUD ----------
  const hud = document.createElement('div');
  hud.id = 'ganga';
  hud.setAttribute('role', 'dialog'); hud.setAttribute('aria-label', 'Ganga');
  hud.innerHTML = `
    <canvas id="ggCanvas"></canvas>
    <div class="g-top">
      <div class="g-mark"></div>
      <div class="g-title"><b>Ganga</b><span><i class="g-dot" id="ggPill" title="conexão com a Sala"></i><span id="ggStatus">dormindo</span></span></div>
      <div class="g-sp"></div>
      <div class="g-clock" id="ggClock"></div>
      <div class="g-seg" id="ggMode" title="Silencioso: só fala quando você chama. Copiloto: também avisa sozinha (chega na etapa 5).">
        <button data-m="silencioso">Silencioso</button><button data-m="copiloto">Copiloto</button></div>
      <button class="g-ico" id="ggCfg" title="Configurar">⚙</button>
      <button class="g-ico" id="ggMin" title="Minimizar (Esc) — a Ganga continua ligada">—</button>
      <button class="g-ico pw" id="ggOff" title="Desligar a Ganga">⏻</button>
    </div>
    <div class="g-panel l">
      <section class="g-sec"><h4>Agora</h4><div class="g-kpis" id="ggKpis"></div></section>
      <section class="g-sec"><h4>Precisam de você</h4><div class="g-rows" id="ggWait"></div></section>
      <section class="g-sec grow"><h4>Atividade</h4><div class="g-rows" id="ggFeed"></div></section>
    </div>
    <div id="ggChips"></div>
    <div class="g-state" id="ggState"><b>Pronta</b><span>toque no microfone ou escreva</span></div>
    <div class="g-talk">
      <div class="g-log" id="ggLog" aria-live="polite"></div>
      <form class="g-in" id="ggForm">
        <button type="button" class="g-mic" id="ggMic" title="Falar com a Ganga" aria-label="Falar com a Ganga"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21"/></svg></button>
        <input id="ggInput" autocomplete="off" placeholder="Pergunte para a Ganga… ex.: o que está rolando?" maxlength="2000">
        <button id="ggSend">Enviar</button></form>
      <div class="g-hint" id="ggHint">Esc minimiza</div>
    </div>
    <aside class="g-side" id="ggSide">
      <header><h3 id="ggSideT">Relatórios<small></small></h3><button class="g-ico" id="ggBack" title="Voltar para a lista" hidden>←</button><button class="g-ico" id="ggSideX" title="Fechar">×</button></header>
      <div class="g-list" id="ggList"></div>
      <div class="g-view" id="ggView"></div>
    </aside>
    <div class="g-modal" id="ggModal"><div class="g-dlg" role="dialog" aria-label="Configurar a Ganga">
      <h3>Configurar a Ganga</h3><p class="s">Tudo fica só neste Mac.</p>
      <div class="g-f"><label>Chave do Gemini</label>
        <div class="row"><input id="ggKey" type="password" autocomplete="off" placeholder="cole a chave do Google AI Studio"><button class="g-b p" id="ggKeySave">Salvar</button></div>
        <small id="ggKeyInfo"></small></div>
      <div class="g-f"><label>Voz</label><div class="row"><select id="ggVoiceSel"></select></div><small>Você ouve a voz escolhida na próxima conversa.</small></div>
      <div class="g-f"><label>Microfone</label><div class="row"><select id="ggMicSel"><option value="">Padrão do Mac</option></select><button class="g-b" id="ggMicTest">Testar</button></div>
        <div class="g-meter"><i id="ggMeter"></i></div></div>
      <div class="g-f"><label>Limite de conversa por dia</label><div class="row"><input id="ggLimit" type="number" min="5" max="600" step="5"><span style="color:#7d8aa6;font-size:13px">minutos</span></div><small id="ggLimitInfo"></small></div>
      <div class="g-f"><label>Modo ao ligar</label><div class="row"><select id="ggModeSel"><option value="silencioso">Silencioso — só fala quando chamada</option><option value="copiloto">Copiloto — também avisa sozinha (etapa 5)</option></select></div></div>
      <div class="row" style="display:flex;gap:8px;justify-content:flex-end;margin-top:8px"><button class="g-b" id="ggCfgX">Fechar</button><button class="g-b p" id="ggCfgOk">Salvar</button></div>
    </div></div>`;
  document.body.appendChild(hud);

  const WORDS = {sleep: 'pronta', think: 'pensando…', speak: 'falando', listen: 'ouvindo', alert: 'aviso', connect: 'conectando…'};
  const SUBS = {sleep: 'toque no microfone ou escreva', think: 'consultando a Sala', speak: '', listen: 'pode falar', connect: 'abrindo a voz'};
  const setStatus = () => {
    $('#ggStatus').innerHTML = `${esc(WORDS[G.orb])} · ${esc(G.mode)}${G.key_hint ? '' : ' · <em>voz sem chave</em>'}`;
    $('#ggState').innerHTML = `<b>${esc(WORDS[G.orb])}</b><span>${esc(SUBS[G.orb] || '')}</span>`;
  };
  const paint = () => {
    btn.classList.toggle('on', G.on);
    btn.title = G.on ? 'Ganga ligada — clique para abrir' : 'Ganga desligada — clique para ligar';
    hud.querySelectorAll('#ggMode button').forEach(b => b.classList.toggle('on', b.dataset.m === G.mode));
    $('#ggMic').disabled = !G.key_hint && !G.live;
    $('#ggMic').title = G.key_hint ? (G.live ? 'Encerrar a conversa por voz' : 'Falar com a Ganga') : 'Configure a chave do Gemini (⚙) para falar';
    setStatus();
  };
  const setOrb = s => { G.orb = s; setStatus(); };

  const open = () => { G.open = true; hud.classList.add('show'); refresh(); startFeed(); setTimeout(() => $('#ggInput').focus(), 60); };
  const minimize = () => { G.open = false; hud.classList.remove('show'); $('#ggSide').classList.remove('show'); stopFeed(); };

  btn.onclick = async () => {
    if (!G.on) { Object.assign(G, await api('/api/ganga', {on: true})); await loadPrefs(); greet(); }
    open();
  };
  $('#ggMin').onclick = minimize;
  $('#ggOff').onclick = async () => { stopLive(); Object.assign(G, await api('/api/ganga', {on: false})); paint(); minimize(); };
  $('#ggMode').onclick = async e => {
    const m = e.target.dataset.m; if (!m) return;
    Object.assign(G, await api('/api/ganga', {mode: m})); paint();
  };
  document.addEventListener('keydown', e => {
    if (e.key !== 'Escape' || !G.open) return;
    e.stopImmediatePropagation();
    if ($('#ggModal').classList.contains('show')) closeCfg();
    else if ($('#ggSide').classList.contains('show')) $('#ggSide').classList.remove('show');
    else minimize();
  }, true);
  setInterval(() => {
    const d = new Date();
    $('#ggClock').innerHTML = `<b>${d.toLocaleTimeString('pt-BR', {hour: '2-digit', minute: '2-digit'})}</b>${d.toLocaleDateString('pt-BR', {weekday: 'short', day: '2-digit', month: 'short'})}`;
  }, 1000);

  // ---------- conversa ----------
  const log = $('#ggLog');
  const add = (who, text, extra = '') => {
    const d = document.createElement('div');
    d.className = 'g-msg ' + who;
    d.innerHTML = esc(text).replace(/\n/g, '<br>') + extra;
    log.appendChild(d); log.scrollTop = log.scrollHeight;
    while (log.children.length > 40) log.firstChild.remove();
    return d;
  };
  let greeted = false;
  function greet() {
    if (greeted) return; greeted = true;
    const h = new Date().getHours();
    const oi = h < 12 ? 'Bom dia' : h < 18 ? 'Boa tarde' : 'Boa noite';
    add('ga', `${oi}, João. Tô ligada e de olho em tudo. ${G.key_hint ? 'Toca no microfone para falar comigo, ou escreve.' : 'Escreve o que quiser — e, se quiser me ouvir, coloca a chave do Gemini no ⚙.'}`);
    speakFor(2500);
  }
  function speakFor(ms) { G.speakUntil = performance.now() + ms; setOrb('speak'); }

  const ERR = {sem_claude: 'Não achei o Claude neste Mac, João. Sem ele eu não consigo pensar.',
    login: 'O login do Claude no terminal expirou, João. Abre o Terminal, roda claude e faz /login. Depois me chama de novo.',
    desligada: 'Estou desligada. Liga pelo botão da Ganga.',
    falhou: 'Travei nessa. Tenta de novo em alguns segundos.'};

  $('#ggForm').onsubmit = async e => {
    e.preventDefault();
    const inp = $('#ggInput'), q = inp.value.trim();
    if (!q || G.busy) return;
    inp.value = ''; add('me', q);
    if (G.live && ws && ws.readyState === 1) { wsSend({realtimeInput: {text: q}}); return; }
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

  // ---------- panorama, projetos em volta da orb ----------
  let lastState = null;
  const shortName = n => n.includes('|') ? n.split('|').pop().trim() : n.replace(/\(casa da Sala\)/, '').replace(/^\d+\s*\|\s*/, '').trim();
  async function refresh() {
    if (!G.open) return;
    try { lastState = await api('/api/state'); $('#ggPill').classList.remove('off'); } catch { $('#ggPill').classList.add('off'); return; }
    const sess = Object.fromEntries((lastState.sessions || []).map(s => [s.id, s]));
    const items = (lastState.projects || []).map(p => {
      const ss = (p.sessions || []).map(i => sess[i]).filter(s => s && s.recent && !s.is_self);
      if (!ss.length) return null;
      const wait = ss.some(s => s.state === 'approval' || (s.agents || []).some(a => a.state === 'approval'));
      const busy = ss.some(s => s.status === 'busy' || (s.agents || []).some(a => a.state === 'active'));
      const top = ss[0];
      return {p, ss, name: shortName(p.name), cls: wait ? 'wait' : busy ? 'busy' : '', sub: wait ? 'precisa de você' : (top.doing || top.goal || (busy ? 'trabalhando' : 'parada'))};
    }).filter(Boolean).slice(0, 10);
    items.forEach(it => { if (items.filter(x => x.name === it.name).length > 1) it.name = it.p.name; });
    const box = $('#ggChips'); box.innerHTML = '';
    const W = innerWidth, H = innerHeight, cx = W / 2 + (W > 1180 ? 150 : 0), cy = H * 0.4;
    const side = W > 1180 ? 300 : 0;
    const rx = Math.min((W - side) * 0.38, 420), ry = Math.min(H * 0.25, 230);
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
    // KPIs
    const c = lastState.counts || {};
    const kp = [[c.recent || 0, 'sessões ativas', 'az'], [c.active || 0, 'agentes trabalhando', ''], [c.approval || 0, 'precisam de você', 'am'], [c.done || 0, 'concluídos', 'ok']];
    $('#ggKpis').innerHTML = kp.map(([n, l, k]) => `<div class="g-kpi ${k}"><b>${n}</b><span>${l}</span></div>`).join('');
    // precisam de você
    const waits = [];
    (lastState.sessions || []).forEach(s => {
      if (!s.recent || s.is_self) return;
      if (s.state === 'approval') waits.push({who: s.name, what: 'sessão esperando sua resposta', p: s.project});
      (s.agents || []).forEach(a => { if (a.state === 'approval') waits.push({who: a.name, what: 'em ' + s.name, p: s.project}); });
    });
    $('#ggWait').innerHTML = waits.length ? waits.slice(0, 12).map(w => `<div class="g-row wait"><i></i><div><b>${esc(w.who)}</b><small>${esc(w.what)}</small></div><time></time></div>`).join('')
      : '<div class="g-none">Ninguém esperando por você agora.</div>';
  }
  setInterval(refresh, 4000);
  addEventListener('resize', () => G.open && refresh());

  // feed ao vivo (SSE do painel)
  let es = null; const feed = [];
  const FEEDK = {approval: 'wait', done: 'done', start: 'busy', tool: 'busy', dispatch: 'busy', msg: '', user: 'busy'};
  function startFeed() {
    if (es) return;
    es = new EventSource('/events');
    es.addEventListener('state', ev => {
      let d; try { d = JSON.parse(ev.data); } catch { return; }
      (d.events || []).filter(e => e.kind !== 'edge').forEach(e => feed.unshift(e));
      feed.splice(40);
      $('#ggFeed').innerHTML = feed.length ? feed.map(e => `<div class="g-row ${FEEDK[e.kind] || ''}"><i></i><div><b>${esc(e.who === '__main__' ? 'líder' : e.who)}</b><small>${esc(e.what)}${e.where ? ' · ' + esc(e.where) : ''}</small></div><time>${new Date(e.epoch * 1000).toLocaleTimeString('pt-BR', {hour: '2-digit', minute: '2-digit'})}</time></div>`).join('')
        : '<div class="g-none">Aguardando movimento nas sessões…</div>';
    });
    es.onerror = () => $('#ggPill').classList.add('off');
    $('#ggFeed').innerHTML = '<div class="g-none">Aguardando movimento nas sessões…</div>';
  }
  function stopFeed() { if (es) { es.close(); es = null; } }

  // ---------- relatórios ----------
  let curP = null;
  async function openReports(path, name) {
    curP = path;
    $('#ggSide').classList.add('show');
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

  // ---------- Configurar ----------
  async function openCfg() {
    await loadPrefs();
    const v = await api('/api/ganga/voices').catch(() => ({voices: ['Kore']}));
    $('#ggVoiceSel').innerHTML = v.voices.map(n => `<option ${n === (G.voice || 'Kore') ? 'selected' : ''}>${esc(n)}</option>`).join('');
    $('#ggKeyInfo').innerHTML = G.key_hint ? `Chave salva no Porta-chaves: <b>${esc(G.key_hint)}</b> · <a href="#" id="ggKeyDel" style="color:#ff9f92">remover</a>` : 'Crie em aistudio.google.com → Get API key. Ela fica no Porta-chaves do Mac, nunca no navegador.';
    const del = $('#ggKeyDel'); if (del) del.onclick = async e => { e.preventDefault(); await api('/api/ganga/key', {delete: true}); await loadPrefs(); openCfg(); };
    $('#ggLimit').value = G.daily_minutes;
    $('#ggLimitInfo').textContent = `Hoje: ${G.used_today || 0} min usados. Cerca de US$ 0,02 por minuto de conversa.`;
    $('#ggModeSel').value = G.mode;
    try {
      const devs = (await navigator.mediaDevices.enumerateDevices()).filter(d => d.kind === 'audioinput');
      $('#ggMicSel').innerHTML = '<option value="">Padrão do Mac</option>' + devs.filter(d => d.deviceId && d.deviceId !== 'default').map(d => `<option value="${esc(d.deviceId)}" ${d.deviceId === G.mic ? 'selected' : ''}>${esc(d.label || 'Microfone')}</option>`).join('');
    } catch {}
    $('#ggModal').classList.add('show');
  }
  let testStream = null;
  function closeCfg() { $('#ggModal').classList.remove('show'); if (testStream) { testStream.getTracks().forEach(t => t.stop()); testStream = null; } }
  $('#ggCfg').onclick = openCfg;
  $('#ggCfgX').onclick = closeCfg;
  $('#ggKeySave').onclick = async () => {
    const k = $('#ggKey').value.trim(); if (!k) return;
    $('#ggKeyInfo').textContent = 'Salvando e testando…';
    const r = await api('/api/ganga/key', {key: k});
    $('#ggKey').value = '';
    if (r.error) { $('#ggKeyInfo').innerHTML = `<span class="g-bad">${r.error === 'chave inválida' ? 'Chave em formato inválido: cole só a chave, sem espaços nem aspas.' : 'Erro: ' + esc(r.error)}</span>`; return; }
    await loadPrefs();
    $('#ggKeyInfo').innerHTML = r.ok ? `<span class="g-ok">Chave salva e funcionando (${esc(r.key_hint)}).</span>` : `<span class="g-bad">Salvei, mas o Google recusou: ${esc(r.check)}</span>`;
  };
  $('#ggMicTest').onclick = async () => {
    if (testStream) { closeCfg(); return openCfg(); }
    try {
      const id = $('#ggMicSel').value;
      testStream = await navigator.mediaDevices.getUserMedia({audio: id ? {deviceId: {exact: id}} : true});
      const ctx = new AudioContext(), an = ctx.createAnalyser(); ctx.createMediaStreamSource(testStream).connect(an);
      const buf = new Uint8Array(an.fftSize);
      const tick = () => { if (!testStream) { ctx.close(); return; } an.getByteTimeDomainData(buf); let m = 0; for (const v of buf) m = Math.max(m, Math.abs(v - 128)); $('#ggMeter').style.width = Math.min(100, m * 1.6) + '%'; requestAnimationFrame(tick); };
      tick(); $('#ggMicTest').textContent = 'Parar';
      setTimeout(() => { if (testStream) { testStream.getTracks().forEach(t => t.stop()); testStream = null; $('#ggMicTest').textContent = 'Testar'; $('#ggMeter').style.width = '0'; } }, 8000);
    } catch { $('#ggMeter').parentElement.insertAdjacentHTML('afterend', '<small class="g-bad">Sem permissão de microfone. Libere no navegador.</small>'); }
  };
  $('#ggCfgOk').onclick = async () => {
    Object.assign(G, await api('/api/ganga', {voice: $('#ggVoiceSel').value, mic: $('#ggMicSel').value, daily_minutes: +$('#ggLimit').value || 60, mode: $('#ggModeSel').value}));
    await loadPrefs(); closeCfg();
  };
  async function loadPrefs() { try { Object.assign(G, await api('/api/ganga')); } catch {} paint(); }

  // ---------- voz em tempo real (Gemini Live) ----------
  const WS_URL = 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained?access_token=';
  let ws = null, micStream = null, inCtx = null, outCtx = null, outAn = null, inAn = null, capNode = null;
  let nextT = 0, sources = [], liveStart = 0, lastAct = 0, resumeHandle = null, curMe = null, curGa = null, pendingTools = 0, ending = false;
  const wsSend = m => { if (ws && ws.readyState === 1) ws.send(JSON.stringify(m)); };
  const b64 = buf => { let s = ''; const u = new Uint8Array(buf); for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); };

  $('#ggMic').onclick = () => G.live ? stopLive('você encerrou') : startLive();

  async function startLive(reconnect = false) {
    if (G.live && !reconnect) return;
    setOrb('connect');
    const t = await api('/api/ganga/token', {}).catch(() => ({error: 'rede'}));
    if (t.error) {
      setOrb('sleep');
      const msg = t.error === 'limite' ? `Bati o limite de hoje (${t.limit} min). Dá para aumentar no ⚙.` : t.error === 'sem_chave' ? 'Falta a chave do Gemini. Coloca no ⚙ que eu ganho voz.' : t.error === 'desligada' ? ERR.desligada : `Não consegui abrir a voz (${t.error}).`;
      add('ga err', msg); if (reconnect) stopLive(); return;
    }
    G.voice = t.voice;
    if (!reconnect) {
      try {
        micStream = await navigator.mediaDevices.getUserMedia({audio: {deviceId: G.mic ? {exact: G.mic} : undefined, echoCancellation: true, noiseSuppression: true, autoGainControl: true}});
      } catch { setOrb('sleep'); add('ga err', 'Não tenho permissão do microfone. Libera no navegador e toca de novo.'); return; }
      outCtx = new AudioContext({sampleRate: 24000}); outAn = outCtx.createAnalyser(); outAn.fftSize = 512; outAn.connect(outCtx.destination);
      liveStart = performance.now(); nextT = 0;
    }
    ending = false;
    ws = new WebSocket(WS_URL + encodeURIComponent(t.token));
    ws.onopen = () => wsSend({setup: {
      model: t.model,
      generationConfig: {responseModalities: ['AUDIO'], speechConfig: {voiceConfig: {prebuiltVoiceConfig: {voiceName: t.voice}}}},
      systemInstruction: {parts: [{text: t.system}]},
      tools: t.tools,
      realtimeInputConfig: {automaticActivityDetection: {disabled: false, silenceDurationMs: 600}},
      inputAudioTranscription: {}, outputAudioTranscription: {},
      sessionResumption: resumeHandle ? {handle: resumeHandle} : {},
      contextWindowCompression: {slidingWindow: {}}}});
    ws.onmessage = async ev => {
      let m; try { m = JSON.parse(typeof ev.data === 'string' ? ev.data : await ev.data.text()); } catch { return; }
      onServer(m);
    };
    ws.onclose = ev => {
      if (ending) return;
      if (G.live && resumeHandle && ev.code !== 1008) { startLive(true); return; }
      add('ga err', `A voz caiu${ev.reason ? ' (' + ev.reason.slice(0, 160) + ')' : ''}. Toca no microfone de novo.`);
      stopLive();
    };
    ws.onerror = () => {};
  }

  async function startMic() {
    inCtx = new AudioContext();
    const src = inCtx.createMediaStreamSource(micStream);
    inAn = inCtx.createAnalyser(); inAn.fftSize = 512; src.connect(inAn);
    const code = `class C extends AudioWorkletProcessor{process(i){const c=i[0]&&i[0][0];if(c)this.port.postMessage(c.slice(0));return true}}registerProcessor('gg-cap',C)`;
    await inCtx.audioWorklet.addModule(URL.createObjectURL(new Blob([code], {type: 'text/javascript'})));
    capNode = new AudioWorkletNode(inCtx, 'gg-cap');
    src.connect(capNode);
    const ratio = inCtx.sampleRate / 16000; let acc = [], pos = 0;
    capNode.port.onmessage = e => {
      const f = e.data;
      for (; pos < f.length; pos += ratio) acc.push(f[Math.floor(pos)]);
      pos -= f.length;
      if (acc.length >= 1600) {
        const pcm = new Int16Array(acc.length);
        for (let i = 0; i < acc.length; i++) { const v = Math.max(-1, Math.min(1, acc[i])); pcm[i] = v < 0 ? v * 0x8000 : v * 0x7fff; }
        acc = [];
        wsSend({realtimeInput: {audio: {data: b64(pcm.buffer), mimeType: 'audio/pcm;rate=16000'}}});
      }
    };
  }

  function playPcm(data) {
    if (!outCtx) return;
    const bin = atob(data), n = bin.length >> 1, buf = outCtx.createBuffer(1, n, 24000), ch = buf.getChannelData(0);
    for (let i = 0; i < n; i++) { let v = bin.charCodeAt(2 * i) | (bin.charCodeAt(2 * i + 1) << 8); if (v >= 0x8000) v -= 0x10000; ch[i] = v / 0x8000; }
    const s = outCtx.createBufferSource(); s.buffer = buf; s.connect(outAn);
    const t0 = Math.max(nextT, outCtx.currentTime + 0.04); s.start(t0); nextT = t0 + buf.duration;
    sources.push(s); s.onended = () => { sources = sources.filter(x => x !== s); };
    lastAct = performance.now();
  }
  function flushAudio() { sources.forEach(s => { try { s.stop(); } catch {} }); sources = []; nextT = 0; }

  async function onServer(m) {
    if (m.setupComplete !== undefined) {
      if (!G.live) {
        G.live = true; $('#ggMic').classList.add('live'); paint();
        try { await startMic(); } catch { add('ga err', 'Não consegui ligar o microfone.'); stopLive(); return; }
        if (!resumeHandle) wsSend({realtimeInput: {text: '(O João acabou de abrir a conversa por voz. Cumprimente em uma frase curta e pergunte como pode ajudar.)'}});
      }
      setOrb('listen'); lastAct = performance.now(); return;
    }
    if (m.sessionResumptionUpdate && m.sessionResumptionUpdate.resumable && m.sessionResumptionUpdate.newHandle) resumeHandle = m.sessionResumptionUpdate.newHandle;
    if (m.goAway) { try { ws.close(); } catch {} return; }
    if (m.toolCall) return handleTools(m.toolCall.functionCalls || []);
    const sc = m.serverContent; if (!sc) return;
    if (sc.interrupted) { flushAudio(); curGa = null; }
    if (sc.inputTranscription && sc.inputTranscription.text) {
      if (!curMe) { curMe = add('me', ''); curMe._t = ''; }
      curMe._t += sc.inputTranscription.text; curMe.textContent = curMe._t.trim(); lastAct = performance.now();
    }
    (sc.modelTurn && sc.modelTurn.parts || []).forEach(p => { if (p.inlineData && p.inlineData.data) playPcm(p.inlineData.data); });
    if (sc.outputTranscription && sc.outputTranscription.text) {
      curMe = null;
      if (!curGa) { curGa = add('ga', ''); curGa._t = ''; }
      curGa._t += sc.outputTranscription.text; curGa.textContent = curGa._t.trim(); log.scrollTop = log.scrollHeight;
    }
    if (sc.turnComplete) { curMe = null; curGa = null; }
  }

  async function handleTools(calls) {
    pendingTools += calls.length; setOrb('think');
    for (const fc of calls) {
      let result = '';
      try {
        if (fc.name === 'ver_panorama') result = (await api('/api/ganga/context')).text;
        else if (fc.name === 'ver_projeto') result = (await api('/api/ganga/context?q=' + encodeURIComponent((fc.args || {}).nome || ''))).text;
        else if (fc.name === 'pensar_com_claude') {
          const r = await api('/api/ganga/ask', {text: (fc.args || {}).pergunta || ''});
          result = r.text || ('O Claude não respondeu: ' + (ERR[r.error] || r.error));
        } else result = 'ferramenta desconhecida';
      } catch { result = 'falhou ao consultar a Sala'; }
      const resp = {result: String(result).slice(0, 12000)};
      if (fc.name === 'pensar_com_claude') resp.scheduling = 'WHEN_IDLE';
      wsSend({toolResponse: {functionResponses: [{id: fc.id, name: fc.name, response: resp}]}});
      pendingTools = Math.max(0, pendingTools - 1);
    }
    lastAct = performance.now();
  }

  function stopLive(why) {
    if (!G.live && !ws && !micStream) { setOrb('sleep'); return; }
    ending = true;
    try { wsSend({realtimeInput: {audioStreamEnd: true}}); ws && ws.close(); } catch {}
    ws = null;
    if (micStream) micStream.getTracks().forEach(t => t.stop());
    [inCtx, outCtx].forEach(c => { try { c && c.close(); } catch {} });
    micStream = inCtx = outCtx = outAn = inAn = capNode = null;
    flushAudio(); resumeHandle = null; curMe = curGa = null; pendingTools = 0;
    if (G.live) {
      const sec = (performance.now() - liveStart) / 1000;
      api('/api/ganga/usage', {seconds: sec}).then(r => { G.used_today = r.used_today; paint(); }).catch(() => {});
      if (why) add('ga', why === 'dormiu' ? 'Fiquei quieta um tempo e fechei a voz para não gastar. É só tocar no microfone.' : 'Fechei a voz. Até já, João.');
    }
    G.live = false; $('#ggMic').classList.remove('live'); setOrb('sleep'); paint();
  }

  // nível de áudio para a orb + dormir sozinha no silêncio
  const lvl = an => { if (!an) return 0; const b = new Uint8Array(an.fftSize); an.getByteTimeDomainData(b); let m = 0; for (const v of b) m = Math.max(m, Math.abs(v - 128)); return m / 128; };
  setInterval(() => {
    if (!G.live) return;
    const now = performance.now();
    const playing = sources.length > 0, inL = lvl(inAn);
    if (inL > 0.12) lastAct = now;
    if (pendingTools > 0) { if (G.orb !== 'think') setOrb('think'); }
    else if (playing) { if (G.orb !== 'speak') setOrb('speak'); }
    else if (G.orb !== 'listen') setOrb('listen');
    if (!playing && pendingTools === 0 && now - lastAct > 25000) stopLive('dormiu');
  }, 200);

  // ---------- a orb ----------
  const cv = $('#ggCanvas'), cx2 = cv.getContext('2d');
  let amp = 0, rot = 0, last = performance.now();
  function frame(now) {
    requestAnimationFrame(frame);
    if (!G.open) return;
    const dt = Math.min(0.05, (now - last) / 1000); last = now;
    if (!G.live && G.orb === 'speak' && now > G.speakUntil) setOrb('sleep');
    const dpr = devicePixelRatio || 1, W = cv.clientWidth, H = cv.clientHeight;
    if (cv.width !== W * dpr) { cv.width = W * dpr; cv.height = H * dpr; }
    const c = cx2; c.setTransform(dpr, 0, 0, dpr, 0, 0); c.clearRect(0, 0, W, H);
    const cx = W / 2 + (W > 1180 ? 150 : 0), cy = H * 0.4, R = Math.min(W - (W > 1180 ? 300 : 0), H) * 0.11;
    const t = now / 1000;
    let target;
    if (G.live && G.orb === 'speak') target = 0.2 + Math.min(0.6, lvl(outAn) * 1.4);
    else if (G.live && G.orb === 'listen') target = 0.06 + Math.min(0.5, lvl(inAn) * 1.2);
    else target = G.orb === 'speak' ? 0.35 + 0.25 * Math.abs(Math.sin(t * 9) * Math.sin(t * 3.7)) : (G.orb === 'think' || G.orb === 'connect') ? 0.18 : 0.05 + 0.03 * Math.sin(t * 1.3);
    amp += (target - amp) * Math.min(1, dt * 12);
    const speed = reduce ? 0.1 : (G.orb === 'think' || G.orb === 'connect') ? 1.6 : G.orb === 'speak' ? 0.7 : G.orb === 'listen' ? 0.45 : 0.25;
    rot += dt * speed;
    const col = G.alert === 'wait' && G.orb === 'sleep' ? [240, 163, 94] : G.orb === 'listen' ? [80, 200, 255] : [61, 143, 255];
    const rgba = a => `rgba(${col[0]},${col[1]},${col[2]},${a})`;
    const g = c.createRadialGradient(cx, cy, R * 0.2, cx, cy, R * 3.4);
    g.addColorStop(0, rgba(0.16 + amp * 0.4)); g.addColorStop(0.35, rgba(0.04 + amp * 0.1)); g.addColorStop(1, rgba(0));
    c.fillStyle = g; c.beginPath(); c.arc(cx, cy, R * 3.4, 0, 6.283); c.fill();
    c.lineWidth = 1; c.strokeStyle = rgba(0.18 + amp * 0.3);
    c.beginPath(); c.arc(cx, cy, R * (1.5 + amp * 0.25), 0, 6.283); c.stroke();
    if (G.orb === 'think' || G.orb === 'connect') {
      c.strokeStyle = rgba(0.7); c.lineWidth = 1.5;
      c.beginPath(); c.arc(cx, cy, R * 1.5, rot * 2, rot * 2 + 1.2); c.stroke();
    }
    if (G.live) {
      c.strokeStyle = rgba(0.85); c.lineWidth = 2.5;
      c.beginPath(); c.arc(cx, cy, R * 1.25, -Math.PI / 2, -Math.PI / 2 + Math.min(1, amp * 1.4) * 6.283); c.stroke();
    }
    const rCore = R * (0.82 + amp * 0.45);
    const core = c.createRadialGradient(cx - rCore * 0.3, cy - rCore * 0.35, rCore * 0.1, cx, cy, rCore);
    core.addColorStop(0, 'rgba(225,238,255,0.95)'); core.addColorStop(0.45, rgba(0.9)); core.addColorStop(1, 'rgba(10,10,51,0.9)');
    c.fillStyle = core; c.beginPath(); c.arc(cx, cy, rCore, 0, 6.283); c.fill();
    const st = $('#ggState'); const top = (cy + R * 1.9 + 22) + 'px'; if (st.style.top !== top) st.style.top = top;
  }
  requestAnimationFrame(frame);

  // ---------- estado inicial ----------
  loadPrefs();
  setInterval(() => api('/api/ganga').then(p => { const was = G.on; Object.assign(G, p); paint(); if (!G.on && was) { stopLive(); minimize(); } }).catch(() => {}), 5000);
  addEventListener('beforeunload', () => stopLive());
})();
