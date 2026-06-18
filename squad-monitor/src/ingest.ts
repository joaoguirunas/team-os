// Squad Monitor — Hook Payload Normalizer
// Converte payloads de hook do Claude Code para MonitorEvent
// Contratos confirmados pelos findings do dev-analyst (2026-06-18)
// RNF-06: nunca derruba o servidor por payload invalido — retorna null e loga

import type { MonitorEvent, MonitorEventKind } from "./types.js";

// Mapping hook_event_name → MonitorEvent.kind
// Campos confirmados no changelog do Claude Code (v2.1.69+, instalado v2.1.118)
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
// Mantido curto e sincrono — esta no caminho critico do /ingest (< 100ms target)
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
        ? `${input.pattern}${input.path ? " in " + String(input.path) : ""}`
        : undefined;
    default:
      // Fallback: resumo JSON truncado para tools desconhecidas
      return JSON.stringify(toolInput).slice(0, 120);
  }
}

// normalizeHook — converte raw hook body para MonitorEvent interno
//
// Garantias:
//   - Retorna null se payload invalido (nao lanca excecao)
//   - Sempre sincrono e leve (nao faz I/O, nao faz parse pesado)
//   - Nunca expoe stack trace para o chamador
//
// Campos do payload por evento (confirmados via findings):
//   Todos:         session_id, cwd, hook_event_name, permission_mode, transcript_path
//   SubagentStart: agent_id, agent_type, agent_prompt, effort
//   SubagentStop:  agent_id, agent_type, effort, agent_transcript_path, last_assistant_message
//   PreToolUse:    tool_name, tool_input
//   PostToolUse:   tool_name, tool_input, tool_response
//   WorktreeCreate: name
export function normalizeHook(raw: unknown): MonitorEvent | null {
  try {
    if (!raw || typeof raw !== "object") return null;

    const payload = raw as Record<string, unknown>;

    // session_id e obrigatorio — sem ele nao ha como associar o evento
    const sessionId = typeof payload.session_id === "string" ? payload.session_id : null;
    if (!sessionId) {
      console.warn("[ingest] Descartado: payload sem session_id");
      return null;
    }

    // hook_event_name → kind
    const hookEventName = typeof payload.hook_event_name === "string"
      ? payload.hook_event_name
      : "";
    const kind = EVENT_KIND_MAP[hookEventName];
    if (!kind) {
      // Evento desconhecido: ignora graciosamente sem derrubar o servidor
      console.warn(`[ingest] hook_event_name desconhecido: "${hookEventName}" — descartado`);
      return null;
    }

    // Campos comuns a todos os eventos
    const cwd = typeof payload.cwd === "string" ? payload.cwd : "";

    // Campos de agente (SubagentStart, SubagentStop)
    const agentId = typeof payload.agent_id === "string" ? payload.agent_id : undefined;
    const agentType = typeof payload.agent_type === "string" ? payload.agent_type : undefined;
    const effort = typeof payload.effort === "string" ? payload.effort : undefined;

    // transcript_path: SubagentStart usa transcript_path (da sessao principal)
    // SubagentStop usa agent_transcript_path (transcript proprio do subagent — mais util)
    const transcriptPath =
      typeof payload.agent_transcript_path === "string"
        ? payload.agent_transcript_path
        : typeof payload.transcript_path === "string"
        ? payload.transcript_path
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
    // Campo 'name' contem o nome/branch do worktree criado
    let worktree: MonitorEvent["worktree"] | undefined;
    if (kind === "worktree.create") {
      const name = typeof payload.name === "string" ? payload.name : undefined;
      if (name) {
        worktree = { name };
      }
    }

    const event: MonitorEvent = {
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

    return event;
  } catch (err) {
    // Captura qualquer excecao inesperada — nunca derrubar o servidor (RNF-06)
    console.error("[ingest] Erro inesperado ao normalizar payload:", err);
    return null;
  }
}
