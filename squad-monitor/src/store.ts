// Squad Monitor — Event Store
// Ring buffer de MonitorEvent + mapa de AgentState em memoria

import type { MonitorEvent, AgentState } from "./types.js";

const RING_BUFFER_SIZE = 1000;

// Ring buffer de eventos recentes
const eventBuffer: MonitorEvent[] = [];

// Mapa de agentes: agentId → AgentState
const agentMap = new Map<string, AgentState>();

// Adiciona evento ao ring buffer (descarta o mais antigo se cheio)
// e delega atualizacao de estado ao updateAgentState
export function addEvent(e: MonitorEvent): void {
  eventBuffer.push(e);
  if (eventBuffer.length > RING_BUFFER_SIZE) {
    eventBuffer.shift();
  }
  updateAgentState(e);
}

// Atualiza mapa de AgentState com base no evento recebido
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

// Retorna snapshot completo do estado atual
// Shape: { events: MonitorEvent[], agents: AgentState[] }
export function getSnapshot(): { events: MonitorEvent[]; agents: AgentState[] } {
  return {
    events: eventBuffer.slice(-100),
    agents: Array.from(agentMap.values()),
  };
}
