// Squad Monitor — Frontend (Story 1.1 skeleton)
// Conecta SSE e exibe eventos no console.log + DOM
// UI completa sera implementada nas Stories 1.2-1.5

const statusEl = document.getElementById('status');
const logEl = document.getElementById('events-log');

let evtSource = null;
let eventCount = 0;

function formatTime(ts) {
  return new Date(ts).toLocaleTimeString('pt-BR', { hour12: false });
}

function renderEvent(event) {
  if (eventCount === 0) {
    logEl.innerHTML = '';
  }
  eventCount++;

  // console.log para criterio de aceite da Fase 1
  console.log('[squad-monitor] event:', event.kind, event);

  const line = document.createElement('div');
  line.className = 'event-line';

  const sessionShort = event.sessionId ? event.sessionId.slice(0, 8) : '?';
  const agentShort = event.agentId ? event.agentId.slice(0, 8) : '';
  const detail = event.tool?.name
    ? `${event.tool.name}${event.tool.inputSummary ? ': ' + event.tool.inputSummary : ''}`
    : (event.agentType ?? event.cwd ?? '');

  line.innerHTML = `
    <span class="event-ts">${formatTime(event.ts)}</span>
    <span class="event-kind">${event.kind}</span>
    <span class="event-session">${sessionShort}</span>
    ${agentShort ? `<span class="event-agent">${agentShort}</span>` : ''}
    <span class="event-detail">${detail}</span>
  `;

  logEl.prepend(line);

  // Manter apenas ultimas 200 linhas no DOM
  while (logEl.children.length > 200) {
    logEl.removeChild(logEl.lastChild);
  }
}

function renderSnapshot(snapshot) {
  console.log('[squad-monitor] snapshot received:', snapshot);
  if (snapshot.recentEvents && snapshot.recentEvents.length > 0) {
    logEl.innerHTML = '';
    eventCount = snapshot.recentEvents.length;
    // Renderizar em ordem cronologica (mais antigo primeiro, mais novo no topo)
    for (const event of snapshot.recentEvents) {
      renderEvent(event);
    }
  }
}

function connect() {
  if (evtSource) evtSource.close();

  evtSource = new EventSource('/events');

  evtSource.onopen = () => {
    statusEl.textContent = 'connected';
    statusEl.className = 'status-connected';
    console.log('[squad-monitor] SSE connected');
  };

  evtSource.onmessage = (e) => {
    try {
      const msg = JSON.parse(e.data);
      if (msg.type === 'snapshot') {
        renderSnapshot(msg.payload);
      } else if (msg.type === 'event') {
        renderEvent(msg.payload);
      }
    } catch (err) {
      console.warn('[squad-monitor] Failed to parse SSE message:', err);
    }
  };

  evtSource.onerror = () => {
    statusEl.textContent = 'reconnecting...';
    statusEl.className = 'status-disconnected';
    evtSource.close();
    setTimeout(connect, 3000);
  };
}

connect();
