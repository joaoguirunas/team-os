// Squad Monitor — Hook Payload Normalizer
// Converte payloads de hook do Claude Code para MonitorEvent
// Contratos confirmados pelos findings do dev-analyst (2026-06-18)

import type { MonitorEvent, MonitorEventKind } from "./types.js";

// Mapping hook_event_name → MonitorEvent.kind
const EVENT_KIND_MAP: Record<string, MonitorEventKind> = {
  SessionStart: "session.start",
  SessionEnd: "session.end",
  SubagentStart: "agent.start",
  SubagentStop: "agent.stop",
  PreToolUse: "tool.pre",
  PostToolUse: "tool.post",
  Stop: "turn.stop",
  WorktreeCreate: "worktree.create",
};

// Extrai resumo util do tool_input por tipo de tool
function extractInputSummary(toolName: string, toolInput: unknown): string | undefined {
  if (!toolInput || typeof toolInput !== "object") return undefined;
  const input = toolInput as Record<string, unknown>;

  switch (toolName) {
    case "Bash":
      return typeof input.command === "string"
        ? input.command.slice(0, 80)
        : undefined;
    case "Read":
    case "Write":
    case "Edit":
      return typeof input.file_path === "string"
        ? input.file_path
        : undefined;
    case "Glob":
      return typeof input.pattern === "string"
        ? input.pattern
        : undefined;
    case "Grep":
      return typeof input.pattern === "string"
        ? `${input.pattern}${input.path ? " in " + input.path : ""}`
        : undefined;
    default:
      return JSON.stringify(toolInput).slice(0, 120);
  }
}

// Normaliza payload de hook do Claude Code para MonitorEvent
// Campos ausentes ou desconhecidos nao derrubam o servidor (RNF-06)
export function normalizeHook(raw: unknown): MonitorEvent | null {
  if (!raw || typeof raw !== "object") return null;

  const payload = raw as Record<string, unknown>;

  // session_id e obrigatorio
  const sessionId = typeof payload.session_id === "string" ? payload.session_id : null;
  if (!sessionId) return null;

  const hookEventName = typeof payload.hook_event_name === "string" ? payload.hook_event_name : "";
  const kind = EVENT_KIND_MAP[hookEventName];
  if (!kind) {
    // Evento desconhecido — logar e ignorar graciosamente
    console.warn(`[ingest] Unknown hook_event_name: ${hookEventName}`);
    return null;
  }

  const cwd = typeof payload.cwd === "string" ? payload.cwd : "";
  const agentId = typeof payload.agent_id === "string" ? payload.agent_id : undefined;
  const agentType = typeof payload.agent_type === "string" ? payload.agent_type : undefined;
  const effort = typeof payload.effort === "string" ? payload.effort : undefined;

  // transcript_path (SubagentStart) ou agent_transcript_path (SubagentStop)
  const transcriptPath =
    typeof payload.transcript_path === "string"
      ? payload.transcript_path
      : typeof payload.agent_transcript_path === "string"
      ? payload.agent_transcript_path
      : undefined;

  // Tool fields (PreToolUse / PostToolUse)
  let tool: MonitorEvent["tool"] | undefined;
  if (kind === "tool.pre" || kind === "tool.post") {
    const toolName = typeof payload.tool_name === "string" ? payload.tool_name : undefined;
    if (toolName) {
      const inputSummary =
        kind === "tool.pre"
          ? extractInputSummary(toolName, payload.tool_input)
          : undefined;
      const responseSummary =
        kind === "tool.post" && payload.tool_response != null
          ? String(payload.tool_response).slice(0, 120)
          : undefined;
      tool = { name: toolName, inputSummary, responseSummary };
    }
  }

  // Worktree fields (WorktreeCreate)
  let worktree: MonitorEvent["worktree"] | undefined;
  if (kind === "worktree.create") {
    const name = typeof payload.name === "string" ? payload.name : undefined;
    if (name) {
      worktree = { name };
    }
  }

  return {
    ts: Date.now(),
    sessionId,
    cwd,
    kind,
    agentId,
    agentType,
    effort,
    tool,
    worktree,
    transcriptPath,
    raw,
  };
}
