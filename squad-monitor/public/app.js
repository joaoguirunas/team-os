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

// ─── State ─────────────────────────────────────────────────────
const state = {
  /** @type {Map<string, import('./types').Session>} */
  sessions: new Map(),
  /** @type {Map<string, import('./types').AgentState>} */
  agents: new Map(),
  /** @type {Map<string, import('./types').MonitorEvent[]>} timeline per agentId */
  timelines: new Map(),
  /** Currently selected session id */
  selectedSessionId: null,
  /** Currently selected agent id */
  selectedAgentId: null,
  /** Aggregate totals */
  totalCalls: 0,
  totalTokens: 0,
};

// ─── DOM refs ──────────────────────────────────────────────────
const $ = (id) => document.getElementById(id);

const dom = {
  statActive:          $('stat-active'),
  statDone:            $('stat-done'),
  statCalls:           $('stat-calls'),
  statTokens:          $('stat-tokens'),
  connDot:             $('conn-dot'),
  connLabel:           $('conn-label'),
  sessionsList:        $('sessions-list'),
  agentsGrid:          $('agents-grid'),
  agentsSessionTag:    $('agents-session-tag'),
  timelineList:        $('timeline-list'),
  timelineAgentLabel:  $('timeline-agent-label'),
  timelineToolsCount:  $('timeline-tools-count'),
  drawer:              $('agent-detail-drawer'),
  drawerTitle:         $('drawer-agent-title'),
  drawerBody:          $('drawer-body'),
  drawerCloseBtn:      $('drawer-close-btn'),
};

// ─── Helpers ───────────────────────────────────────────────────

/**
 * Format epoch ms duration as MM:SS.
 * @param {number} startMs
 * @param {number} [endMs]
 * @returns {string}
 */
function formatElapsed(startMs, endMs) {
  const diffMs = (endMs ?? Date.now()) - startMs;
  const totalSec = Math.max(0, Math.floor(diffMs / 1000));
  const mm = String(Math.floor(totalSec / 60)).padStart(2, '0');
  const ss = String(totalSec % 60).padStart(2, '0');
  return `${mm}:${ss}`;
}

/**
 * Format epoch ms as HH:MM:SS offset from agent start, or absolute if no base.
 * @param {number} ts
 * @param {number} [baseTs]
 * @returns {string}
 */
function formatOffset(ts, baseTs) {
  if (baseTs == null) return formatElapsed(0, ts);
  return formatElapsed(baseTs, ts);
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

// ─── Render: connection status ──────────────────────────────────
/**
 * @param {'connected' | 'connecting' | 'disconnected'} status
 */
function setConnectionStatus(status) {
  dom.connDot.className = `connection-dot ${status}`;
  const labels = {
    connected:    'conectado',
    connecting:   'conectando',
    disconnected: 'desconectado',
  };
  dom.connLabel.textContent = labels[status] ?? status;
}

// ─── Render: stats header ───────────────────────────────────────
function renderStats() {
  let activeCount = 0;
  let doneCount = 0;
  let callsCount = 0;

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
}

// ─── Render: sessions sidebar ──────────────────────────────────
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
    for (const a of state.agents.values()) {
      if (a.sessionId === sid && a.status === 'running') runningInSession++;
    }

    // Count all agents in this session
    let agentCount = 0;
    for (const a of state.agents.values()) {
      if (a.sessionId === sid) agentCount++;
    }

    const dotClass = runningInSession > 0 ? 'session-dot has-running' : 'session-dot';
    const itemClass = isSelected ? 'session-item selected' : 'session-item';
    const name = cwdLabel(session.cwd ?? sid);
    const cwd  = session.cwd ?? '';

    html.push(`
      <div class="${itemClass}" data-session-id="${sid}">
        <span class="${dotClass}"></span>
        <div class="session-info">
          <div class="session-name" title="${sid}">${escHtml(name)}</div>
          ${cwd ? `<div class="session-cwd" title="${escHtml(cwd)}">${escHtml(cwd)}</div>` : ''}
        </div>
        <span class="session-count">${agentCount}</span>
      </div>
    `);
  }

  dom.sessionsList.innerHTML = html.join('');

  // Bind click handlers
  dom.sessionsList.querySelectorAll('.session-item').forEach((el) => {
    el.addEventListener('click', () => {
      const sid = el.dataset.sessionId;
      state.selectedSessionId = sid;
      state.selectedAgentId = null;
      renderSessions();
      renderAgents();
      renderTimeline();
    });
  });
}

// ─── Render: agents grid ────────────────────────────────────────
function renderAgents() {
  if (!state.selectedSessionId) {
    dom.agentsGrid.innerHTML = `
      <div class="placeholder-center">
        <span class="placeholder-title">Nenhuma sessão selecionada</span>
        <span class="placeholder-sub">Selecione uma sessão na sidebar</span>
      </div>`;
    dom.agentsSessionTag.textContent = '';
    return;
  }

  const sessionAgents = [...state.agents.values()]
    .filter((a) => a.sessionId === state.selectedSessionId)
    .sort((a, b) => a.startedAt - b.startedAt);

  const sid = state.selectedSessionId;
  const session = state.sessions.get(sid);
  dom.agentsSessionTag.textContent = session?.cwd
    ? cwdLabel(session.cwd)
    : shortId(sid);

  if (sessionAgents.length === 0) {
    dom.agentsGrid.innerHTML = `
      <div class="placeholder-center">
        <span class="placeholder-title">Sem agentes</span>
        <span class="placeholder-sub">Nenhum subagente encontrado nesta sessão</span>
      </div>`;
    return;
  }

  const now = Date.now();
  const html = sessionAgents.map((agent) => {
    const isSelected = agent.agentId === state.selectedAgentId;
    const statusClass = `state-${agent.status}`;
    const cardClass = [
      'agent-card',
      statusClass,
      isSelected ? 'selected' : '',
    ].filter(Boolean).join(' ');

    const elapsed = formatElapsed(agent.startedAt, agent.endedAt ?? now);
    const tool    = agent.currentTool ?? '';
    const worktree = agent.worktree
      ? `<span class="agent-worktree-tag">${escHtml(agent.worktree)}</span>`
      : '';

    return `
      <div class="${cardClass}" data-agent-id="${agent.agentId}">
        <span class="agent-dot"></span>
        <div class="agent-identity">
          <div class="agent-type">${escHtml(agent.agentType ?? agent.agentId)}</div>
          <div class="agent-meta">
            <span class="agent-id-tag">${escHtml(shortId(agent.agentId))}</span>
            ${worktree}
          </div>
        </div>
        <span class="agent-status">${agent.status}</span>
        <span class="agent-elapsed">${elapsed}</span>
        <span class="agent-tool">${escHtml(tool)}</span>
      </div>`;
  });

  dom.agentsGrid.innerHTML = html.join('');

  // Bind click handlers
  dom.agentsGrid.querySelectorAll('.agent-card').forEach((el) => {
    el.addEventListener('click', () => {
      const aid = el.dataset.agentId;
      if (state.selectedAgentId === aid) {
        // Second click on same agent: open drawer
        openDrawer(aid);
        return;
      }
      state.selectedAgentId = aid;
      renderAgents();
      renderTimeline();
    });
  });
}

// ─── Elapsed ticker ─────────────────────────────────────────────
// Re-render elapsed times every second for running agents
let tickerRef = null;

function startElapsedTicker() {
  if (tickerRef) return;
  tickerRef = setInterval(() => {
    // Only update elapsed spans, skip full re-render to avoid flicker
    const cards = dom.agentsGrid.querySelectorAll('.agent-card.state-running');
    cards.forEach((card) => {
      const aid = card.dataset.agentId;
      const agent = state.agents.get(aid);
      if (!agent) return;
      const el = card.querySelector('.agent-elapsed');
      if (el) el.textContent = formatElapsed(agent.startedAt);
    });
  }, 1000);
}

// ─── Render: timeline ───────────────────────────────────────────
function renderTimeline() {
  if (!state.selectedAgentId) {
    dom.timelineList.innerHTML =
      '<div class="timeline-empty">Selecione um agente para ver a timeline</div>';
    dom.timelineAgentLabel.textContent = '—';
    dom.timelineToolsCount.textContent = '';
    return;
  }

  const agent    = state.agents.get(state.selectedAgentId);
  const events   = state.timelines.get(state.selectedAgentId) ?? [];
  const agentLabel = agent
    ? (agent.agentType ?? shortId(agent.agentId))
    : shortId(state.selectedAgentId);

  dom.timelineAgentLabel.textContent = agentLabel;
  dom.timelineToolsCount.textContent = events.length > 0
    ? `${events.length} eventos`
    : '';

  if (events.length === 0) {
    dom.timelineList.innerHTML =
      '<div class="timeline-empty">Nenhum tool call registrado ainda</div>';
    return;
  }

  const baseTs = agent?.startedAt;
  const html = events.map((ev) => {
    const isPre  = ev.kind === 'tool.pre';
    const kindClass = isPre ? 'kind-pre' : 'kind-post';
    const kindLabel = isPre ? 'PreTool' : 'PostTool';
    const toolName  = ev.tool?.name ?? '—';
    const summary   = isPre
      ? summaryText(ev.tool?.inputSummary)
      : (ev.tool?.responseSummary ? '✓ ' + summaryText(ev.tool.responseSummary) : '✓');
    const timeStr   = formatOffset(ev.ts, baseTs);

    return `
      <div class="tl-row ${kindClass}">
        <span class="tl-time">${timeStr}</span>
        <span class="tl-kind">${kindLabel}</span>
        <span class="tl-tool">${escHtml(toolName)}</span>
        <span class="tl-summary">${escHtml(summary)}</span>
      </div>`;
  });

  dom.timelineList.innerHTML = html.join('');

  // Scroll to bottom so latest events are visible
  dom.timelineList.scrollTop = dom.timelineList.scrollHeight;
}

// ─── Drawer ─────────────────────────────────────────────────────
async function openDrawer(agentId) {
  const agent = state.agents.get(agentId);
  if (!agent) return;

  dom.drawerTitle.textContent = agent.agentType ?? shortId(agentId);
  dom.drawerBody.innerHTML    = '<div class="drawer-loading">Carregando detalhes...</div>';
  dom.drawer.classList.add('open');

  try {
    const params = new URLSearchParams({ sessionId: agent.sessionId });
    // Preferencia: usar transcriptPath direto (vem do hook SubagentStop via AgentState)
    if (agent.transcriptPath) {
      params.set('transcriptPath', agent.transcriptPath);
    } else {
      // Fallback: passar cwd da sessao para resolucao de path via encodeProjectPath
      const session = state.sessions.get(agent.sessionId);
      if (session?.cwd) params.set('cwd', session.cwd);
    }
    const res  = await fetch(`/agent/${encodeURIComponent(agentId)}?${params}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    renderDrawerContent(agent, data);
  } catch (err) {
    console.warn('[squad-monitor] Drawer fetch failed:', err);
    renderDrawerContent(agent, { found: false, entries: [], totalInputTokens: 0, totalOutputTokens: 0 });
  }
}

/**
 * @param {import('./types').AgentState} agent
 * @param {object | null} detail - response from GET /agent/:id
 */
function renderDrawerContent(agent, detail) {
  const elapsed  = formatElapsed(agent.startedAt, agent.endedAt);

  // GET /agent/:id retorna: { found, agentId, sessionId, transcriptPath,
  //   totalInputTokens, totalOutputTokens, toolCallCount, entries: ToolCall[] }
  // ToolCall shape: { ts, toolName, input, response? }
  const found        = detail?.found ?? false;
  const inputTokens  = detail?.totalInputTokens  ?? 0;
  const outputTokens = detail?.totalOutputTokens ?? 0;
  const totalTokens  = inputTokens + outputTokens;
  const prompt       = detail?.prompt ?? null;
  const result       = detail?.result ?? null;
  const toolList     = detail?.entries ?? [];

  const promptHtml = prompt
    ? `<div class="drawer-section">
         <div class="drawer-section-label">Prompt inicial</div>
         <pre class="drawer-prompt-block">${escHtml(truncate(prompt, 400))}</pre>
       </div>`
    : '';

  const tokensHtml = found && totalTokens > 0
    ? `<div class="drawer-section">
         <div class="drawer-section-label">Tokens</div>
         <div class="drawer-token-row">
           <span class="token-number">${totalTokens.toLocaleString('pt-BR')}</span>
           <span class="token-unit">total</span>
         </div>
         <div style="font-family:var(--font-mono);font-size:11px;color:var(--color-text-muted);margin-top:4px">
           ${inputTokens.toLocaleString('pt-BR')} in · ${outputTokens.toLocaleString('pt-BR')} out
         </div>
       </div>`
    : '';

  // entries shape: { ts, toolName, input, response? }
  const toolRowsHtml = toolList.length > 0
    ? `<div class="drawer-section">
         <div class="drawer-section-label">Tool calls (${toolList.length})</div>
         <div class="drawer-tool-list">
           ${toolList.slice(0, 40).map((t) => `
             <div class="drawer-tool-row">
               <span class="dtool-name">${escHtml(t.toolName ?? '?')}</span>
               <span class="dtool-input">${escHtml(truncate(typeof t.input === 'string' ? t.input : JSON.stringify(t.input ?? {}), 70))}</span>
             </div>`).join('')}
           ${toolList.length > 40 ? `<div class="drawer-loading">+${toolList.length - 40} omitidos</div>` : ''}
         </div>
       </div>`
    : '';

  const resultHtml = result
    ? `<div class="drawer-section">
         <div class="drawer-section-label">Resultado final</div>
         <pre class="drawer-prompt-block">${escHtml(truncate(result, 600))}</pre>
       </div>`
    : '';

  const noDetailMsg = !found
    ? `<div class="drawer-loading">Transcript não disponível — o agente pode estar em execução ou o path ainda foi indexado.</div>`
    : '';

  dom.drawerBody.innerHTML = `
    <div class="drawer-section">
      <div class="drawer-section-label">Resumo</div>
      <div class="drawer-meta-grid">
        <div class="drawer-meta-item">
          <span class="meta-label">ID</span>
          <span class="meta-value">${escHtml(shortId(agent.agentId))}</span>
        </div>
        <div class="drawer-meta-item">
          <span class="meta-label">Tipo</span>
          <span class="meta-value">${escHtml(agent.agentType ?? '—')}</span>
        </div>
        <div class="drawer-meta-item">
          <span class="meta-label">Status</span>
          <span class="meta-value">${agent.status}</span>
        </div>
        <div class="drawer-meta-item">
          <span class="meta-label">Duração</span>
          <span class="meta-value">${elapsed}</span>
        </div>
        <div class="drawer-meta-item">
          <span class="meta-label">Tool calls</span>
          <span class="meta-value">${agent.toolCalls ?? 0}</span>
        </div>
        ${agent.effort ? `<div class="drawer-meta-item">
          <span class="meta-label">Effort</span>
          <span class="meta-value">${escHtml(agent.effort)}</span>
        </div>` : ''}
        ${agent.worktree ? `<div class="drawer-meta-item">
          <span class="meta-label">Worktree</span>
          <span class="meta-value">${escHtml(agent.worktree)}</span>
        </div>` : ''}
      </div>
    </div>
    ${promptHtml}
    ${tokensHtml}
    ${toolRowsHtml}
    ${resultHtml}
    ${noDetailMsg}
  `;
}

function closeDrawer() {
  dom.drawer.classList.remove('open');
}

dom.drawerCloseBtn.addEventListener('click', closeDrawer);

// Close drawer on Escape
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeDrawer();
});

// ─── State mutations ────────────────────────────────────────────

/**
 * Apply a full snapshot from the server.
 * @param {{ sessions: object[], agents: object[], recentEvents: object[], timestamp: string }} payload
 */
function applySnapshot(payload) {
  state.sessions.clear();
  state.agents.clear();
  state.timelines.clear();

  for (const s of (payload.sessions ?? [])) {
    state.sessions.set(s.sessionId, s);
  }

  for (const a of (payload.agents ?? [])) {
    state.agents.set(a.agentId, normalizeAgent(a));
  }

  // Rebuild timelines from recentEvents
  for (const ev of (payload.recentEvents ?? [])) {
    applyEventToTimeline(normalizeEvent(ev));
  }

  // Auto-select first session if none selected
  if (!state.selectedSessionId && state.sessions.size > 0) {
    state.selectedSessionId = [...state.sessions.keys()][0];
  }

  renderAll();
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
        state.sessions.set(ev.sessionId, {
          sessionId: ev.sessionId,
          cwd: ev.cwd,
          startedAt: ev.ts,
        });
        // Auto-select if first
        if (!state.selectedSessionId) {
          state.selectedSessionId = ev.sessionId;
        }
      }
      break;

    case 'session.end':
      // Keep session in map so history is visible
      break;

    case 'agent.start': {
      if (!ev.agentId) break;
      const existing = state.agents.get(ev.agentId);
      if (!existing) {
        state.agents.set(ev.agentId, normalizeAgent({
          agentId:   ev.agentId,
          agentType: ev.agentType,
          sessionId: ev.sessionId,
          status:    'running',
          startedAt: ev.ts,
          effort:    ev.effort,
          toolCalls: 0,
        }));
        // Auto-select session if unset
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
        agent.status    = 'done';
        agent.endedAt   = ev.ts;
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

  renderAll();
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

// ─── Normalizers ────────────────────────────────────────────────

/**
 * Ensure agent has expected fields.
 * @param {object} raw
 * @returns {import('./types').AgentState}
 */
function normalizeAgent(raw) {
  return {
    agentId:      raw.agentId ?? raw.agent_id ?? '',
    agentType:    raw.agentType ?? raw.agent_type ?? '',
    sessionId:    raw.sessionId ?? raw.session_id ?? '',
    status:       raw.status ?? 'running',
    startedAt:    raw.startedAt ?? raw.started_at ?? Date.now(),
    endedAt:      raw.endedAt ?? raw.ended_at,
    effort:       raw.effort,
    toolCalls:    raw.toolCalls ?? 0,
    currentTool:  raw.currentTool,
    worktree:     raw.worktree,
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

// ─── Render all ─────────────────────────────────────────────────
function renderAll() {
  renderStats();
  renderSessions();
  renderAgents();
  renderTimeline();
}

// ─── SSE connection ─────────────────────────────────────────────
let evtSource = null;
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
    setConnectionStatus('connected');
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
    setConnectionStatus('disconnected');
    evtSource.close();
    evtSource = null;
    console.warn(`[squad-monitor] SSE error — reconnecting in ${backoffMs}ms`);
    setTimeout(() => {
      backoffMs = Math.min(backoffMs * 2, MAX_BACKOFF_MS);
      connect();
    }, backoffMs);
  };
}

// ─── Escape HTML ────────────────────────────────────────────────
const escDiv = document.createElement('div');
function escHtml(str) {
  if (!str) return '';
  escDiv.textContent = str;
  return escDiv.innerHTML;
}

// ─── Boot ───────────────────────────────────────────────────────
connect();
