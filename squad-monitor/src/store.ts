// Squad Monitor — Event Store
// Ring buffer de eventos + mapa de AgentState em memoria
// Logica completa de state derivado sera expandida na Story 1.2

import type { MonitorEvent, AgentState, AgentStatus, DashboardSnapshot, SessionEntry } from "./types.js";
import { readFileSync, readdirSync } from "fs";
import { join } from "path";

const RING_BUFFER_SIZE = 1000;
const CLAUDE_DIR = join(process.env.HOME ?? "/", ".claude");
const SESSIONS_DIR = join(CLAUDE_DIR, "sessions");

// Ring buffer de eventos recentes
const eventBuffer: MonitorEvent[] = [];

// Mapa de agentes: agentId → AgentState
const agentMap = new Map<string, AgentState>();

// Mapa de sessoes conhecidas via hooks: sessionId → { cwd, startedAt }
const sessionMap = new Map<string, { cwd: string; startedAt: number }>();

// Adiciona evento ao ring buffer (descarta mais antigos se cheio)
function appendToBuffer(event: MonitorEvent): void {
  eventBuffer.push(event);
  if (eventBuffer.length > RING_BUFFER_SIZE) {
    eventBuffer.shift();
  }
}

// Atualiza estado de agentes a partir do evento
function updateAgentState(event: MonitorEvent): void {
  if (event.kind === "agent.start" && event.agentId) {
    const existing = agentMap.get(event.agentId);
    agentMap.set(event.agentId, {
      agentId: event.agentId,
      agentType: event.agentType ?? existing?.agentType ?? "unknown",
      sessionId: event.sessionId,
      status: "running",
      startedAt: existing?.startedAt ?? event.ts,
      effort: event.effort ?? existing?.effort,
      toolCalls: existing?.toolCalls ?? 0,
      currentTool: existing?.currentTool,
      worktree: existing?.worktree,
      transcriptPath: event.transcriptPath ?? existing?.transcriptPath,
    });
  }

  if (event.kind === "agent.stop" && event.agentId) {
    const existing = agentMap.get(event.agentId);
    if (existing) {
      agentMap.set(event.agentId, {
        ...existing,
        status: "done" as AgentStatus,
        endedAt: event.ts,
      });
    }
  }

  if (event.kind === "worktree.create" && event.agentId && event.worktree) {
    const existing = agentMap.get(event.agentId);
    if (existing) {
      agentMap.set(event.agentId, {
        ...existing,
        worktree: event.worktree.name,
      });
    }
  }
}

// Rastreia sessao conhecida via hook
function trackSession(event: MonitorEvent): void {
  if (!sessionMap.has(event.sessionId)) {
    sessionMap.set(event.sessionId, {
      cwd: event.cwd,
      startedAt: event.ts,
    });
  }
}

// Processa evento: atualiza buffer, agentes e sessao
export function processEvent(event: MonitorEvent): void {
  appendToBuffer(event);
  updateAgentState(event);
  trackSession(event);
}

// Le sessoes ativas de ~/.claude/sessions/*.json
function readFilesystemSessions(): SessionEntry[] {
  try {
    return readdirSync(SESSIONS_DIR)
      .filter((f) => f.endsWith(".json"))
      .map((f) => {
        try {
          const raw = JSON.parse(readFileSync(join(SESSIONS_DIR, f), "utf8"));
          const sessionId = raw.sessionId ?? raw.pid?.toString() ?? f.replace(".json", "");
          const agentCount = Array.from(agentMap.values()).filter(
            (a) => a.sessionId === sessionId && a.status === "running"
          ).length;
          return {
            sessionId,
            pid: raw.pid,
            cwd: raw.cwd ?? "",
            startedAt: raw.startedAt,
            version: raw.version,
            kind: raw.kind,
            agentCount,
          } satisfies SessionEntry;
        } catch {
          return null;
        }
      })
      .filter((s): s is SessionEntry => s !== null);
  } catch {
    return [];
  }
}

// Retorna snapshot completo do estado atual
export function getSnapshot(): DashboardSnapshot {
  const sessions = readFilesystemSessions();
  const agents = Array.from(agentMap.values());
  const recentEvents = eventBuffer.slice(-100); // ultimos 100 eventos no snapshot

  return { sessions, agents, recentEvents };
}

// Retorna lista de agentes ativos
export function getActiveAgents(): AgentState[] {
  return Array.from(agentMap.values()).filter((a) => a.status === "running");
}

// Retorna todos os agentes
export function getAllAgents(): AgentState[] {
  return Array.from(agentMap.values());
}

// Retorna eventos recentes
export function getRecentEvents(limit = 100): MonitorEvent[] {
  return eventBuffer.slice(-limit);
}
