// Squad Monitor — Event Store
// Ring buffer de MonitorEvent + mapa de AgentState em memoria
// Story 1.2: adiciona queries derivadas para sessoes, timeline e stats

import type { MonitorEvent, AgentState } from "./types.js";

const RING_BUFFER_SIZE = 1000;

// Ring buffer de eventos recentes (append-only, descarta o mais antigo quando cheio)
const eventBuffer: MonitorEvent[] = [];

// Mapa de agentes: agentId → AgentState
const agentMap = new Map<string, AgentState>();

// Mapa de sessoes: sessionId → timestamp do primeiro evento dessa sessao
const sessionFirstSeen = new Map<string, number>();

// Adiciona evento ao ring buffer e atualiza estado derivado
export function addEvent(e: MonitorEvent): void {
  eventBuffer.push(e);
  if (eventBuffer.length > RING_BUFFER_SIZE) {
    eventBuffer.shift();
  }
  // Registra sessao na primeira vez que aparece
  if (!sessionFirstSeen.has(e.sessionId)) {
    sessionFirstSeen.set(e.sessionId, e.ts);
  }
  updateAgentState(e);
}

// Atualiza mapa de AgentState com base no evento recebido
// Todos os caminhos retornam cedo — sem fall-through acidental
export function updateAgentState(e: MonitorEvent): void {
  if (e.kind === "agent.start" && e.agentId) {
    const existing = agentMap.get(e.agentId);
    agentMap.set(e.agentId, {
      agentId: e.agentId,
      agentType: e.agentType ?? existing?.agentType ?? "unknown",
      sessionId: e.sessionId,
      status: "running",
      startedAt: existing?.startedAt ?? e.ts,
      effort: e.effort ?? existing?.effort,
      toolCalls: existing?.toolCalls ?? 0,
      currentTool: existing?.currentTool,
      worktree: existing?.worktree,
      transcriptPath: e.transcriptPath ?? existing?.transcriptPath,
    });
    return;
  }

  if (e.kind === "agent.stop" && e.agentId) {
    const existing = agentMap.get(e.agentId);
    if (existing) {
      agentMap.set(e.agentId, {
        ...existing,
        status: "done",
        endedAt: e.ts,
        currentTool: undefined,
      });
    }
    return;
  }

  if (e.kind === "tool.pre" && e.agentId && e.tool) {
    const existing = agentMap.get(e.agentId);
    if (existing) {
      agentMap.set(e.agentId, {
        ...existing,
        currentTool: e.tool.name,
        toolCalls: existing.toolCalls + 1,
      });
    }
    return;
  }

  if (e.kind === "tool.post" && e.agentId) {
    const existing = agentMap.get(e.agentId);
    if (existing) {
      agentMap.set(e.agentId, {
        ...existing,
        currentTool: undefined,
      });
    }
    return;
  }

  if (e.kind === "worktree.create" && e.agentId && e.worktree) {
    const existing = agentMap.get(e.agentId);
    if (existing) {
      agentMap.set(e.agentId, {
        ...existing,
        worktree: e.worktree.name,
      });
    }
    return;
  }
}

// ─── Queries derivadas ────────────────────────────────────────────

export type SessionSummary = {
  sessionId: string;
  cwd: string;
  firstSeen: number;
  agentCount: number;
  runningCount: number;
};

// Lista sessoes unicas com metadados derivados dos agentes conhecidos
// Ordem: mais recente primeiro
export function getSessions(): SessionSummary[] {
  const sessions = new Map<string, SessionSummary>();

  // Seed com sessoes vistas em eventos (incluindo sessoes sem agentes ainda)
  for (const [sessionId, firstSeen] of sessionFirstSeen) {
    if (!sessions.has(sessionId)) {
      // cwd: pegar do primeiro evento dessa sessao
      const cwd = eventBuffer.find((e) => e.sessionId === sessionId)?.cwd ?? "";
      sessions.set(sessionId, {
        sessionId,
        cwd,
        firstSeen,
        agentCount: 0,
        runningCount: 0,
      });
    }
  }

  // Atualiza contagens a partir dos agentes
  for (const agent of agentMap.values()) {
    const s = sessions.get(agent.sessionId);
    if (s) {
      s.agentCount++;
      if (agent.status === "running") s.runningCount++;
    } else {
      // Agente de sessao nao vista via evento de sessao — criar entrada
      sessions.set(agent.sessionId, {
        sessionId: agent.sessionId,
        cwd: "",
        firstSeen: agent.startedAt,
        agentCount: 1,
        runningCount: agent.status === "running" ? 1 : 0,
      });
    }
  }

  return Array.from(sessions.values()).sort((a, b) => b.firstSeen - a.firstSeen);
}

// Retorna agentes de uma sessao, ordenados por startedAt DESC (running primeiro)
export function getAgentsBySession(sessionId: string): AgentState[] {
  return Array.from(agentMap.values())
    .filter((a) => a.sessionId === sessionId)
    .sort((a, b) => {
      // Running primeiro, depois por startedAt mais recente
      if (a.status === "running" && b.status !== "running") return -1;
      if (b.status === "running" && a.status !== "running") return 1;
      return b.startedAt - a.startedAt;
    });
}

// Retorna eventos de tool (tool.pre e tool.post) de um agente especifico
// para renderizar a timeline — cronologico ascendente
export function getToolEventsByAgent(agentId: string): MonitorEvent[] {
  return eventBuffer.filter(
    (e) => e.agentId === agentId && (e.kind === "tool.pre" || e.kind === "tool.post")
  );
}

export type StoreStats = {
  activeAgents: number;
  doneAgents: number;
  totalToolCalls: number;
};

// Agregados globais para o header
export function getStats(): StoreStats {
  let activeAgents = 0;
  let doneAgents = 0;
  let totalToolCalls = 0;
  for (const agent of agentMap.values()) {
    if (agent.status === "running") activeAgents++;
    else doneAgents++;
    totalToolCalls += agent.toolCalls;
  }
  return { activeAgents, doneAgents, totalToolCalls };
}

// Retorna snapshot completo do estado atual (para SSE initial + /snapshot debug)
// recentEvents: ultimos 100 para replay inicial no browser
// Campo nomeado recentEvents (nao events) para compatibilidade com o app.js
export function getSnapshot(): {
  recentEvents: MonitorEvent[];
  agents: AgentState[];
  sessions: SessionSummary[];
  stats: StoreStats;
} {
  return {
    recentEvents: eventBuffer.slice(-100),
    agents: Array.from(agentMap.values()),
    sessions: getSessions(),
    stats: getStats(),
  };
}
