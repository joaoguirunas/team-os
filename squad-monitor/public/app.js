/**
 * Squad Monitor — app.js
 * Vanilla JS, ES modules. Nenhuma dependência externa.
 *
 * Formato SSE esperado do servidor:
 *   data: { type: "snapshot", payload: SnapshotPayload }
 *   data: { type: "event",    payload: MonitorEvent    }
 *
 * SnapshotPayload: { sessions, agents, recentEvents, timestamp }
 * MonitorEvent:   { ts, sessionId, cwd, kind, agentId, agentType, ... }
 * AgentState:     { agentId, agentType, sessionId, status, startedAt, endedAt?,
 *                   effort?, toolCalls, currentTool?, worktree?, transcriptPath? }
 */

// ─── State ──────────────────────────────────────────────────────────
const state = {
  /** @type {Map<string, object>} */
  sessions: new Map(),
  /** @type {Map<string, object>} */
  agents: new Map(),
  /** @type {Map<string, object[]>} timeline per agentId */
  timelines: new Map(),
  /** Currently selected session id */
  selectedSessionId: null,
  /** Currently selected agent id */
  selectedAgentId: null,
  /** Aggregate totals */
  totalCalls: 0,
  totalTokens: 0,
  /** Pause state: when paused, SSE still runs but UI doesn't re-render */
  paused: false,
  /** Connection status */
  connectionStatus: 'connecting',
};

// ─── DOM refs ────────────────────────────────────────────────────────
const $ = (id) => document.getElementById(id);

const dom = {
  liveDot:             $('live-dot'),
  liveLabel:           $('live-label'),
  liveToggle:          $('live-toggle'),
  statActive:          $('stat-active'),
  statDone:            $('stat-done'),
  statCalls:           $('stat-calls'),
  statTokens:          $('stat-tokens'),
  statDur:             $('stat-dur'),
  sessionsList:        $('sessions-list'),
  agentsSessionTag:    $('agents-session-tag'),
  agentsCountLabel:    $('agents-count-label'),
  agentsGrid:          $('agents-grid'),
  timelineAgentLabel:  $('timeline-agent-label'),
  timelineList:        $('timeline-list'),
  backdrop:            $('drawer-backdrop'),
  drawer:              $('agent-detail-drawer'),
  drawerTitle:         $('drawer-agent-title'),
  drawerMeta:          $('drawer-agent-meta'),
  drawerBody:          $('drawer-body'),
  drawerCloseBtn:      $('drawer-close-btn'),
};

// ─── Helpers ─────────────────────────────────────────────────────────

/**
 * Format epoch ms duration as MM:SS.
 * @param {number} startMs
 * @param {number} [endMs]
 * @returns {string}
 */
function formatElapsed(startMs, endMs) {
  if (!startMs) return '—:—';
  const diffMs   = (endMs ?? Date.now()) - startMs;
  const totalSec = Math.max(0, Math.floor(diffMs / 1000));
  const mm = String(Math.floor(totalSec / 60)).padStart(2, '0');
  const ss = String(totalSec % 60).padStart(2, '0');
  return `${mm}:${ss}`;
}

/**
 * Format elapsed offset from agent start.
 * @param {number} ts
 * @param {number} [baseTs]
 * @returns {string}
 */
function formatOffset(ts, baseTs) {
  if (baseTs == null) return formatElapsed(0, ts);
  return '+' + formatElapsed(baseTs, ts);
}

/**
 * Shorten a string to N chars with ellipsis.
 * @param {string} s
 * @param {number} n
 */
function truncate(s, n = 60) {
  if (!s) return '';
  return s.length > n ? s.slice(0, n) + '…' : s;
}

/**
 * Extract a short path or command summary from tool input.
 * @param {string | undefined} summary
 * @returns {string}
 */
function summaryText(summary) {
  return truncate(summary ?? '', 55);
}

/**
 * Derive a short display name from cwd.
 * @param {string} cwd
 */
function cwdLabel(cwd) {
  if (!cwd) return '?';
  const parts = cwd.replace(/\/$/, '').split('/');
  return parts[parts.length - 1] || cwd;
}

/**
 * Shorten an agent/session id for display.
 * @param {string} id
 */
function shortId(id) {
  if (!id) return '?';
  return id.slice(0, 8);
}

// ─── Escape HTML ─────────────────────────────────────────────────────
const escDiv = document.createElement('div');
function escHtml(str) {
  if (!str) return '';
  escDiv.textContent = str;
  return escDiv.innerHTML;
}

// ─── Normalizers ──────────────────────────────────────────────────────

/**
 * Normalise a session object from either snake_case or camelCase shapes.
 * @param {object} raw
 */
function normalizeSession(raw) {
  return {
    sessionId: raw.sessionId ?? raw.session_id ?? '',
    cwd:       raw.cwd ?? '',
    startedAt: raw.startedAt ?? raw.firstSeenAt ?? raw.first_seen_at ?? Date.now(),
  };
}

/**
 * Ensure agent has expected fields.
 * @param {object} raw
 * @returns {object}
 */
function normalizeAgent(raw) {
  return {
    agentId:        raw.agentId ?? raw.agent_id ?? '',
    agentType:      raw.agentType ?? raw.agent_type ?? '',
    sessionId:      raw.sessionId ?? raw.session_id ?? '',
    status:         raw.status ?? 'running',
    startedAt:      raw.startedAt ?? raw.started_at ?? Date.now(),
    endedAt:        raw.endedAt ?? raw.ended_at,
    effort:         raw.effort,
    toolCalls:      raw.toolCalls ?? 0,
    currentTool:    raw.currentTool,
    worktree:       raw.worktree,
    transcriptPath: raw.transcriptPath,
  };
}

/**
 * Normalise an event from either snake_case or camelCase shapes.
 * @param {object} raw
 */
function normalizeEvent(raw) {
  return {
    ts:        raw.ts ?? Date.now(),
    sessionId: raw.sessionId ?? raw.session_id ?? '',
    cwd:       raw.cwd ?? '',
    kind:      raw.kind ?? '',
    agentId:   raw.agentId ?? raw.agent_id,
    agentType: raw.agentType ?? raw.agent_type,
    effort:    raw.effort,
    tool:      raw.tool,
    worktree:  raw.worktree,
  };
}

// ─── Render: connection / live status ────────────────────────────────
/**
 * @param {'connected' | 'connecting' | 'disconnected' | 'paused'} status
 */
function setConnectionStatus(status) {
  state.connectionStatus = status;

  const dot   = dom.liveDot;
  const label = dom.liveLabel;

  // Remove all status classes
  dot.className   = 'live-dot';
  label.className = 'live-label';

  const labels = {
    connected:    'AO VIVO',
    connecting:   'CONECTANDO',
    paused:       'PAUSADO',
    disconnected: 'DESCONECTADO',
  };

  dot.classList.add(`status-${status}`);
  label.classList.add(`status-${status}`);
  label.textContent = labels[status] ?? status;

  // Blink animation on connected/connecting
  if (status === 'connected' || status === 'connecting') {
    dot.classList.add('lblink-live');
    label.classList.add('lblink-live');
  }
}

// ─── Live toggle ──────────────────────────────────────────────────────
dom.liveToggle.addEventListener('click', () => {
  state.paused = !state.paused;
  if (state.paused) {
    setConnectionStatus('paused');
  } else {
    setConnectionStatus(state.connectionStatus === 'paused' ? 'connected' : state.connectionStatus);
    renderAll();
  }
});

// ─── Render: stats header ─────────────────────────────────────────────
function renderStats() {
  let activeCount = 0;
  let doneCount   = 0;
  let callsCount  = 0;

  for (const agent of state.agents.values()) {
    if (agent.status === 'running') activeCount++;
    else if (agent.status === 'done') doneCount++;
    callsCount += agent.toolCalls ?? 0;
  }

  dom.statActive.textContent = String(activeCount);
  dom.statDone.textContent   = String(doneCount);
  dom.statCalls.textContent  = String(callsCount);
  dom.statTokens.textContent = state.totalTokens > 0
    ? state.totalTokens.toLocaleString('pt-BR')
    : '—';

  // Session duration
  if (state.selectedSessionId) {
    const session = state.sessions.get(state.selectedSessionId);
    if (session?.startedAt) {
      dom.statDur.textContent = formatElapsed(session.startedAt);
    } else {
      dom.statDur.textContent = '—:—';
    }
  } else {
    dom.statDur.textContent = '—:—';
  }
}

// ─── Render: sessions sidebar ─────────────────────────────────────────
function renderSessions() {
  if (state.sessions.size === 0) {
    dom.sessionsList.innerHTML =
      '<div class="sessions-empty">Aguardando sessões...</div>';
    return;
  }

  const html = [];
  for (const [sid, session] of state.sessions.entries()) {
    const isSelected = sid === state.selectedSessionId;

    // Count running agents in this session
    let runningInSession = 0;
    let totalInSession   = 0;
    for (const a of state.agents.values()) {
      if (a.sessionId === sid) {
        totalInSession++;
        if (a.status === 'running') runningInSession++;
      }
    }

    const dotClass  = runningInSession > 0 ? 'session-dot has-running' : 'session-dot';
    const itemClass = isSelected ? 'session-item selected' : 'session-item';
    const name      = cwdLabel(session.cwd ?? sid);
    const cwd       = session.cwd ?? '';
    const countStr  = `${runningInSession}/${totalInSession}`;

    html.push(`
      <div class="${itemClass}" data-session-id="${escHtml(sid)}">
        <div class="session-row-top">
          <span class="${dotClass}"></span>
          <span class="session-name" title="${escHtml(sid)}">${escHtml(name)}</span>
          <span class="session-count">${countStr}</span>
        </div>
        <span class="session-kind">session</span>
        ${cwd ? `<span class="session-cwd" title="${escHtml(cwd)}">${escHtml(cwd)}</span>` : ''}
      </div>
    `);
  }

  dom.sessionsList.innerHTML = html.join('');

  // Bind click handlers
  dom.sessionsList.querySelectorAll('.session-item').forEach((el) => {
    el.addEventListener('click', () => {
      const sid = el.dataset.sessionId;
      state.selectedSessionId = sid;
      state.selectedAgentId   = null;
      renderSessions();
      renderAgents();
      renderTimeline();
      renderStats();
    });
  });
}

// ─── Render: agents grid ──────────────────────────────────────────────
function renderAgents() {
  if (!state.selectedSessionId) {
    dom.agentsGrid.innerHTML = `
      <div class="placeholder-center">
        <span class="placeholder-title">Nenhuma sessão selecionada</span>
        <span class="placeholder-sub">Selecione uma sessão na sidebar</span>
      </div>`;
    dom.agentsSessionTag.textContent  = '';
    dom.agentsCountLabel.textContent  = '';
    return;
  }

  const sessionAgents = [...state.agents.values()]
    .filter((a) => a.sessionId === state.selectedSessionId)
    .sort((a, b) => a.startedAt - b.startedAt);

  const sid     = state.selectedSessionId;
  const session = state.sessions.get(sid);
  const tagText = session?.cwd ? cwdLabel(session.cwd) : shortId(sid);

  dom.agentsSessionTag.textContent = tagText;
  dom.agentsCountLabel.textContent = sessionAgents.length > 0
    ? `${sessionAgents.length} agente${sessionAgents.length !== 1 ? 's' : ''}`
    : '';

  if (sessionAgents.length === 0) {
    dom.agentsGrid.innerHTML = `
      <div class="placeholder-center">
        <span class="placeholder-title">Sem agentes</span>
        <span class="placeholder-sub">Nenhum subagente encontrado nesta sessão</span>
      </div>`;
    return;
  }

  const now  = Date.now();
  const html = sessionAgents.map((agent) => {
    const isSelected  = agent.agentId === state.selectedAgentId;
    const statusClass = `state-${agent.status}`;
    const cardClasses = ['agent-card', statusClass, isSelected ? 'selected' : '']
      .filter(Boolean)
      .join(' ');

    const elapsed   = formatElapsed(agent.startedAt, agent.endedAt ?? now);
    const tool      = agent.currentTool ?? '';
    const toolLabel = tool || '—';
    const toolCalls = agent.toolCalls ?? 0;
    const hasWorktree = agent.worktree ? true : false;
    const effortStr  = agent.effort ?? '';

    // Sub line: #short · effort · [⌥ worktree]
    const subParts = [`#${shortId(agent.agentId)}`];
    if (effortStr)        subParts.push(effortStr);
    if (hasWorktree)      subParts.push(`⌥ ${agent.worktree}`);
    const subLine = subParts.join(' · ');

    // Status label text
    const statusLabels = { running: 'RUNNING', done: 'DONE', error: 'ERROR' };
    const statusText   = statusLabels[agent.status] ?? agent.status.toUpperCase();

    const toolNameClass = tool ? 'agent-tool-name tool-active' : 'agent-tool-name';

    return `
      <div class="${cardClasses}" data-agent-id="${escHtml(agent.agentId)}">
        <div class="agent-card-top">
          <span class="agent-dot${agent.status === 'running' ? ' adot-run' : ''}"></span>
          <span class="agent-type">${escHtml(agent.agentType ?? agent.agentId)}</span>
          <span class="agent-status-label">${statusText}</span>
        </div>
        <div class="agent-card-sub">${escHtml(subLine)}</div>
        <div class="agent-card-divider"></div>
        <div class="agent-card-tool">
          <span class="agent-tool-label">TOOL</span>
          <span class="${toolNameClass}">${escHtml(toolLabel)}</span>
          <span class="agent-tool-calls">${toolCalls} calls</span>
        </div>
        <div class="agent-card-footer">
          <span class="agent-elapsed" data-agent-id="${escHtml(agent.agentId)}">${elapsed}</span>
          <button class="agent-detail-btn" data-agent-id="${escHtml(agent.agentId)}">DETALHE ↗</button>
        </div>
      </div>`;
  });

  dom.agentsGrid.innerHTML = `<div class="agents-cards-inner">${html.join('')}</div>`;

  // Bind card click → select agent (timeline)
  dom.agentsGrid.querySelectorAll('.agent-card').forEach((el) => {
    el.addEventListener('click', (e) => {
      // Don't trigger select when clicking the detail button
      if (e.target.closest('.agent-detail-btn')) return;
      const aid = el.dataset.agentId;
      state.selectedAgentId = aid;
      renderAgents();
      renderTimeline();
    });
  });

  // Bind DETALHE ↗ button → open drawer
  dom.agentsGrid.querySelectorAll('.agent-detail-btn').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      openDrawer(btn.dataset.agentId);
    });
  });
}

// ─── Elapsed ticker ───────────────────────────────────────────────────
let tickerRef = null;

function startElapsedTicker() {
  if (tickerRef) return;
  tickerRef = setInterval(() => {
    if (state.paused) return;

    // Update per-agent elapsed in cards
    const elapsedEls = dom.agentsGrid.querySelectorAll('.agent-elapsed[data-agent-id]');
    elapsedEls.forEach((el) => {
      const aid   = el.dataset.agentId;
      const agent = state.agents.get(aid);
      if (!agent || agent.status !== 'running') return;
      el.textContent = formatElapsed(agent.startedAt);
    });

    // Update session duration in header
    if (state.selectedSessionId) {
      const session = state.sessions.get(state.selectedSessionId);
      if (session?.startedAt) {
        dom.statDur.textContent = formatElapsed(session.startedAt);
      }
    }
  }, 1000);
}

// ─── Render: timeline ─────────────────────────────────────────────────
function renderTimeline() {
  if (!state.selectedAgentId) {
    dom.timelineList.innerHTML =
      '<div class="timeline-empty">Selecione um agente para ver a timeline</div>';
    dom.timelineAgentLabel.textContent = '—';
    return;
  }

  const agent    = state.agents.get(state.selectedAgentId);
  const events   = state.timelines.get(state.selectedAgentId) ?? [];
  const agentLabel = agent
    ? `${agent.agentType ?? shortId(agent.agentId)} · #${shortId(state.selectedAgentId)}`
    : `#${shortId(state.selectedAgentId)}`;

  dom.timelineAgentLabel.textContent = agentLabel;

  if (events.length === 0) {
    dom.timelineList.innerHTML =
      '<div class="timeline-empty">Nenhum tool call registrado ainda</div>';
    return;
  }

  const baseTs = agent?.startedAt;

  // newest first
  const reversed = [...events].reverse();

  const html = reversed.map((ev) => {
    const isPre       = ev.kind === 'tool.pre';
    const kindClass   = isPre ? '' : 'kind-post';
    const kindLabel   = isPre ? 'PRE' : 'POST';
    const toolName    = ev.tool?.name ?? '—';
    const inputText   = isPre
      ? summaryText(ev.tool?.inputSummary)
      : summaryText(ev.tool?.responseSummary ?? '');
    const timeStr     = formatOffset(ev.ts, baseTs);
    const markClass   = isPre ? '' : 'mark-ok';
    const markChar    = isPre ? '' : '✓';

    return `
      <div class="tl-row">
        <span class="tl-time">${escHtml(timeStr)}</span>
        <span class="tl-kind ${kindClass}">${kindLabel}</span>
        <span class="tl-tool">${escHtml(toolName)}</span>
        <span class="tl-input">${escHtml(inputText)}</span>
        <span class="tl-mark ${markClass}">${markChar}</span>
      </div>`;
  });

  dom.timelineList.innerHTML = html.join('');
}

// ─── Drawer ───────────────────────────────────────────────────────────
async function openDrawer(agentId) {
  const agent = state.agents.get(agentId);
  if (!agent) return;

  // Set header content
  dom.drawerTitle.textContent = agent.agentType ?? shortId(agentId);
  dom.drawerMeta.textContent  = `#${shortId(agentId)} · ${
    state.sessions.get(agent.sessionId)
      ? cwdLabel(state.sessions.get(agent.sessionId).cwd ?? agent.sessionId)
      : shortId(agent.sessionId)
  }`;

  dom.drawerBody.innerHTML = '<div class="drawer-loading">Carregando detalhes...</div>';
  dom.drawer.classList.add('open');
  dom.backdrop.classList.add('open');

  try {
    const params = new URLSearchParams({ sessionId: agent.sessionId });
    if (agent.transcriptPath) {
      params.set('transcriptPath', agent.transcriptPath);
    } else {
      const session = state.sessions.get(agent.sessionId);
      if (session?.cwd) params.set('cwd', session.cwd);
    }
    const res  = await fetch(`/agent/${encodeURIComponent(agentId)}?${params}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    renderDrawerContent(agent, data);
  } catch (err) {
    console.warn('[squad-monitor] Drawer fetch failed:', err);
    renderDrawerContent(agent, {
      found: false,
      entries: [],
      totalInputTokens: 0,
      totalOutputTokens: 0,
    });
  }
}

/**
 * @param {object} agent
 * @param {object | null} detail - response from GET /agent/:id
 */
function renderDrawerContent(agent, detail) {
  const elapsed       = formatElapsed(agent.startedAt, agent.endedAt);
  const found         = detail?.found ?? false;
  const inputTokens   = detail?.totalInputTokens  ?? 0;
  const outputTokens  = detail?.totalOutputTokens ?? 0;
  const totalTokens   = inputTokens + outputTokens;
  const prompt        = detail?.prompt ?? null;
  const result        = detail?.result ?? null;
  const errorMsg      = detail?.error ?? null;
  const toolList      = detail?.entries ?? [];

  // ── Stats grid (3x2) ──
  const worktreeVal = agent.worktree ?? '—';
  const effortVal   = agent.effort   ?? '—';
  const statusLabels = { running: 'Running', done: 'Done', error: 'Error' };
  const statusVal   = statusLabels[agent.status] ?? agent.status;

  const statsGrid = `
    <div class="drawer-stats-grid">
      <div class="drawer-stat-cell">
        <span class="drawer-stat-label">Status</span>
        <span class="drawer-stat-value">${escHtml(statusVal)}</span>
      </div>
      <div class="drawer-stat-cell">
        <span class="drawer-stat-label">Effort</span>
        <span class="drawer-stat-value">${escHtml(effortVal)}</span>
      </div>
      <div class="drawer-stat-cell">
        <span class="drawer-stat-label">Decorrido</span>
        <span class="drawer-stat-value">${escHtml(elapsed)}</span>
      </div>
      <div class="drawer-stat-cell">
        <span class="drawer-stat-label">Tool Calls</span>
        <span class="drawer-stat-value">${agent.toolCalls ?? 0}</span>
      </div>
      <div class="drawer-stat-cell">
        <span class="drawer-stat-label">Tokens</span>
        <span class="drawer-stat-value">${totalTokens > 0 ? totalTokens.toLocaleString('pt-BR') : '—'}</span>
      </div>
      <div class="drawer-stat-cell">
        <span class="drawer-stat-label">Worktree</span>
        <span class="drawer-stat-value">${escHtml(worktreeVal)}</span>
      </div>
    </div>`;

  // ── Prompt section ──
  const promptSection = prompt
    ? `<div class="drawer-section">
         <span class="drawer-section-label">Prompt inicial</span>
         <pre class="drawer-prompt-pre">${escHtml(truncate(prompt, 800))}</pre>
       </div>`
    : '';

  // ── Tool history ──
  const toolSection = toolList.length > 0
    ? `<div class="drawer-section">
         <span class="drawer-section-label">Histórico de tools (${toolList.length})</span>
         <div class="drawer-tool-list">
           ${toolList.slice(0, 50).map((t) => {
             const inputStr = typeof t.input === 'string'
               ? t.input
               : JSON.stringify(t.input ?? {});
             const respStr  = typeof t.response === 'string'
               ? t.response
               : (t.response ? JSON.stringify(t.response) : '');
             const hasResp  = !!respStr;
             return `
               <div class="drawer-tool-step">
                 <span class="dstep-mark${hasResp ? ' ok' : ''}">
                   ${hasResp ? '✓' : '·'}
                 </span>
                 <span class="dstep-tool">${escHtml(t.toolName ?? '?')}</span>
                 <span class="dstep-input">${escHtml(truncate(inputStr, 80))}</span>
                 <span class="dstep-resp">${hasResp ? escHtml(truncate(respStr, 30)) : ''}</span>
               </div>`;
           }).join('')}
           ${toolList.length > 50
             ? `<div class="drawer-loading">+${toolList.length - 50} omitidos</div>`
             : ''}
         </div>
       </div>`
    : '';

  // ── Result section ──
  const resultSection = result
    ? `<div class="drawer-section">
         <span class="drawer-section-label ember">Resultado final</span>
         <p class="drawer-result-text">${escHtml(truncate(result, 1000))}</p>
       </div>`
    : '';

  // ── Error section ──
  const errorSection = errorMsg
    ? `<div class="drawer-section">
         <span class="drawer-section-label" style="color:var(--error-color)">Erro</span>
         <div class="drawer-error-block">${escHtml(errorMsg)}</div>
       </div>`
    : '';

  // ── Tokens section ──
  const tokensSection = found && totalTokens > 0
    ? `<div class="drawer-section">
         <span class="drawer-section-label">Tokens consumidos</span>
         <span class="drawer-tokens-big">${totalTokens.toLocaleString('pt-BR')}</span>
         <span class="drawer-tokens-note">${inputTokens.toLocaleString('pt-BR')} in · ${outputTokens.toLocaleString('pt-BR')} out</span>
       </div>`
    : '';

  // ── No detail message ──
  const noDetailMsg = !found
    ? `<div class="drawer-loading">Transcript não disponível — o agente pode estar em execução ou o path ainda não foi indexado.</div>`
    : '';

  dom.drawerBody.innerHTML = `
    ${statsGrid}
    ${promptSection}
    ${toolSection}
    ${resultSection}
    ${errorSection}
    ${tokensSection}
    ${noDetailMsg}
  `;
}

function closeDrawer() {
  dom.drawer.classList.remove('open');
  dom.backdrop.classList.remove('open');
}

dom.drawerCloseBtn.addEventListener('click', closeDrawer);
dom.backdrop.addEventListener('click', closeDrawer);

// Close drawer on Escape
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeDrawer();
});

// ─── State mutations ──────────────────────────────────────────────────

/**
 * Apply a full snapshot from the server.
 * @param {{ sessions: object[], agents: object[], recentEvents: object[], timestamp: string }} payload
 */
function applySnapshot(payload) {
  state.sessions.clear();
  state.agents.clear();
  state.timelines.clear();

  for (const s of (payload.sessions ?? [])) {
    state.sessions.set(s.sessionId ?? s.session_id, normalizeSession(s));
  }

  for (const a of (payload.agents ?? [])) {
    state.agents.set(a.agentId ?? a.agent_id, normalizeAgent(a));
  }

  // Rebuild timelines from recentEvents
  for (const ev of (payload.recentEvents ?? [])) {
    applyEventToTimeline(normalizeEvent(ev));
  }

  // Auto-select first session if none selected
  if (!state.selectedSessionId && state.sessions.size > 0) {
    state.selectedSessionId = [...state.sessions.keys()][0];
  }

  if (!state.paused) renderAll();
}

/**
 * Apply a single incremental event.
 * @param {object} raw
 */
function applyEvent(raw) {
  const ev = normalizeEvent(raw);

  switch (ev.kind) {
    case 'session.start':
      if (!state.sessions.has(ev.sessionId)) {
        state.sessions.set(ev.sessionId, normalizeSession({
          sessionId: ev.sessionId,
          cwd:       ev.cwd,
          startedAt: ev.ts,
        }));
        if (!state.selectedSessionId) {
          state.selectedSessionId = ev.sessionId;
        }
      }
      break;

    case 'session.end':
      // Keep session in map so history remains visible
      break;

    case 'agent.start': {
      if (!ev.agentId) break;
      if (!state.agents.has(ev.agentId)) {
        state.agents.set(ev.agentId, normalizeAgent({
          agentId:   ev.agentId,
          agentType: ev.agentType,
          sessionId: ev.sessionId,
          status:    'running',
          startedAt: ev.ts,
          effort:    ev.effort,
          toolCalls: 0,
        }));
        if (!state.selectedSessionId) {
          state.selectedSessionId = ev.sessionId;
        }
      }
      break;
    }

    case 'agent.stop': {
      if (!ev.agentId) break;
      const agent = state.agents.get(ev.agentId);
      if (agent) {
        agent.status      = 'done';
        agent.endedAt     = ev.ts;
        agent.currentTool = undefined;
      }
      break;
    }

    case 'tool.pre': {
      if (!ev.agentId) break;
      const agent = state.agents.get(ev.agentId);
      if (agent) {
        agent.currentTool = ev.tool?.name;
        agent.toolCalls   = (agent.toolCalls ?? 0) + 1;
      }
      applyEventToTimeline(ev);
      break;
    }

    case 'tool.post': {
      if (!ev.agentId) break;
      const agent = state.agents.get(ev.agentId);
      if (agent && agent.currentTool === ev.tool?.name) {
        agent.currentTool = undefined;
      }
      applyEventToTimeline(ev);
      break;
    }

    case 'worktree.create': {
      if (!ev.agentId || !ev.worktree) break;
      const agent = state.agents.get(ev.agentId);
      if (agent) {
        agent.worktree = ev.worktree.name;
      }
      break;
    }

    default:
      break;
  }

  if (!state.paused) renderAll();
}

/**
 * Push event to per-agent timeline.
 * @param {object} ev
 */
function applyEventToTimeline(ev) {
  if (!ev.agentId) return;
  if (ev.kind !== 'tool.pre' && ev.kind !== 'tool.post') return;
  if (!state.timelines.has(ev.agentId)) {
    state.timelines.set(ev.agentId, []);
  }
  state.timelines.get(ev.agentId).push(ev);
}

// ─── Render all ───────────────────────────────────────────────────────
function renderAll() {
  renderStats();
  renderSessions();
  renderAgents();
  renderTimeline();
}

// ─── SSE connection ───────────────────────────────────────────────────
let evtSource  = null;
let backoffMs  = 1000;
const MAX_BACKOFF_MS = 30_000;

function connect() {
  setConnectionStatus('connecting');

  if (evtSource) {
    evtSource.close();
    evtSource = null;
  }

  evtSource = new EventSource('/events');

  evtSource.onopen = () => {
    if (!state.paused) setConnectionStatus('connected');
    backoffMs = 1000;
    startElapsedTicker();
    console.log('[squad-monitor] SSE connected');
  };

  evtSource.onmessage = (e) => {
    let msg;
    try {
      msg = JSON.parse(e.data);
    } catch {
      console.warn('[squad-monitor] Failed to parse SSE message:', e.data);
      return;
    }

    if (msg.type === 'snapshot') {
      applySnapshot(msg.payload);
    } else if (msg.type === 'event') {
      applyEvent(msg.payload);
    }
  };

  evtSource.onerror = () => {
    if (!state.paused) setConnectionStatus('disconnected');
    evtSource.close();
    evtSource = null;
    console.warn(`[squad-monitor] SSE error — reconnecting in ${backoffMs}ms`);
    setTimeout(() => {
      backoffMs = Math.min(backoffMs * 2, MAX_BACKOFF_MS);
      connect();
    }, backoffMs);
  };
}

// ─── Boot ─────────────────────────────────────────────────────────────
connect();
