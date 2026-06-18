// Squad Monitor — Transcript Reader
// Leitura on-demand dos transcripts JSONL de subagents
//
// Path confirmado pelo dev-analyst (2026-06-18):
//   ~/.claude/projects/{project-encoded}/{sessionId}/subagents/agent-{agentId}.jsonl
//   ~/.claude/projects/{project-encoded}/{sessionId}/subagents/agent-{agentId}.meta.json
//
// Encoding: path do projeto com '/' substituido por '-', resultado prefixado com '-'
//   Ex: /Users/joao/Desktop/CT  →  -Users-joao-Desktop-CT
//
// Token usage: em cada entrada assistant via message.usage.input_tokens / output_tokens

import { existsSync, readFileSync } from "fs";
import { join } from "path";

const CLAUDE_DIR = join(process.env.HOME ?? "/", ".claude");

// ------- Tipos publicos -------

export interface ToolCall {
  ts: number;
  toolName: string;
  input: unknown;
  response?: unknown;
}

export interface AgentDetail {
  agentId: string;
  agentType: string;
  sessionId: string;
  transcriptPath: string;
  prompt?: string;          // primeira mensagem user no transcript
  toolCalls: ToolCall[];    // sequencia de tool calls
  result?: string;          // last_assistant_message (ultima msg texto do assistant)
  inputTokens: number;      // soma de input_tokens em todas as entradas assistant
  outputTokens: number;     // soma de output_tokens em todas as entradas assistant
}

// ------- Tipos internos de entrada JSONL -------

type TranscriptLine = {
  type?: string;            // "user" | "assistant" | "attachment"
  message?: {
    role?: string;
    content?: unknown;
    usage?: {
      input_tokens?: number;
      output_tokens?: number;
      cache_creation_input_tokens?: number;
      cache_read_input_tokens?: number;
    };
  };
  timestamp?: string;
};

type MetaJson = {
  agentType?: string;
  description?: string;
};

// ------- Helpers -------

// Encoda path do projeto para o formato de diretorio do Claude Code
// /Users/joao/Desktop/CT  →  -Users-joao-Desktop-CT
function encodeProjectPath(projectPath: string): string {
  // Substitui cada '/' por '-'; o resultado comeca com '-' se path absoluto
  return projectPath.replace(/\//g, "-");
}

// Extrai texto plano de content (string ou array de blocos)
function extractText(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  const parts: string[] = [];
  for (const block of content) {
    if (!block || typeof block !== "object") continue;
    const b = block as Record<string, unknown>;
    if (b.type === "text" && typeof b.text === "string") {
      parts.push(b.text);
    }
  }
  return parts.join("\n");
}

// Extrai timestamp em epoch ms de uma linha JSONL
function tsFromLine(line: TranscriptLine): number {
  if (line.timestamp) {
    const ms = Date.parse(line.timestamp);
    if (!isNaN(ms)) return ms;
  }
  return Date.now();
}

// ------- API publica -------

// Resolve o path completo do transcript de um subagent
// projectPath: process.env.CT_PROJECT_PATH ou process.cwd() se omitido
export function resolveTranscriptPath(
  agentId: string,
  sessionId: string,
  projectPath?: string
): string {
  const base = projectPath ?? process.env.CT_PROJECT_PATH ?? process.cwd();
  const encoded = encodeProjectPath(base);
  return join(
    CLAUDE_DIR,
    "projects",
    encoded,
    sessionId,
    "subagents",
    `agent-${agentId}.jsonl`
  );
}

// Le e processa o transcript de um agente on-demand
// Resolve o path via encodeProjectPath e delega a readAgentDetailFromPath
// Retorna null se arquivo nao encontrado (nao derruba o servidor)
export function readAgentDetail(
  agentId: string,
  sessionId: string,
  projectPath?: string
): AgentDetail | null {
  const transcriptPath = resolveTranscriptPath(agentId, sessionId, projectPath);
  return readAgentDetailFromPath(agentId, sessionId, transcriptPath);
}

// ------- Compatibilidade com server.ts (pre-refactor) -------

// Tipo legado para server.ts existente
export type AgentTranscriptDetail = {
  agentId: string;
  sessionId: string;
  transcriptPath: string | null;
  entries: unknown[];
  totalInputTokens: number;
  totalOutputTokens: number;
  toolCallCount: number;
  found: boolean;
  prompt?: string;   // primeira mensagem user (prompt inicial do agente)
  result?: string;   // ultima mensagem assistant (resultado final)
};

// Wrapper compativel — server.ts chama readAgentTranscript(sessionId, agentId, opts?)
// opts.directPath: path completo do .jsonl (preferencia — vem de AgentState.transcriptPath)
// opts.projectCwd: cwd do projeto para resolucao de path via encodeProjectPath (fallback)
export function readAgentTranscript(
  sessionId: string,
  agentId: string,
  opts?: { projectCwd?: string; directPath?: string }
): AgentTranscriptDetail {
  // Tentar path direto primeiro (mais preciso — evita ambiguidades de encoding)
  if (opts?.directPath && existsSync(opts.directPath)) {
    const detail = readAgentDetailFromPath(agentId, sessionId, opts.directPath);
    if (detail) return toCompatDetail(detail);
  }

  // Fallback: resolver via cwd do projeto
  const detail = readAgentDetail(agentId, sessionId, opts?.projectCwd);
  if (!detail) {
    return {
      agentId,
      sessionId,
      transcriptPath: null,
      entries: [],
      totalInputTokens: 0,
      totalOutputTokens: 0,
      toolCallCount: 0,
      found: false,
    };
  }
  return toCompatDetail(detail);
}

// Helper: converte AgentDetail para o formato legado
function toCompatDetail(detail: AgentDetail): AgentTranscriptDetail {
  return {
    agentId: detail.agentId,
    sessionId: detail.sessionId,
    transcriptPath: detail.transcriptPath,
    entries: detail.toolCalls,
    totalInputTokens: detail.inputTokens,
    totalOutputTokens: detail.outputTokens,
    toolCallCount: detail.toolCalls.length,
    found: true,
    prompt: detail.prompt,
    result: detail.result,
  };
}

// Le e processa um transcript dado o path completo (sem resolucao)
export function readAgentDetailFromPath(
  agentId: string,
  sessionId: string,
  transcriptPath: string
): AgentDetail | null {
  if (!existsSync(transcriptPath)) return null;

  const metaPath = transcriptPath.replace(/\.jsonl$/, ".meta.json");
  let agentType = "unknown";
  if (existsSync(metaPath)) {
    try {
      const meta = JSON.parse(readFileSync(metaPath, "utf8")) as MetaJson;
      agentType = meta.agentType ?? "unknown";
    } catch {
      // meta.json invalido — usar fallback
    }
  }

  const detail: AgentDetail = {
    agentId,
    agentType,
    sessionId,
    transcriptPath,
    toolCalls: [],
    inputTokens: 0,
    outputTokens: 0,
  };

  try {
    const raw = readFileSync(transcriptPath, "utf8");
    const lines = raw.split("\n");
    const pendingTools = new Map<string, { ts: number; toolName: string; input: unknown }>();
    let lastAssistantText = "";
    let firstUserText: string | undefined;
    let firstUserFound = false;

    for (const rawLine of lines) {
      if (!rawLine.trim()) continue;
      let line: TranscriptLine;
      try {
        line = JSON.parse(rawLine) as TranscriptLine;
      } catch {
        continue;
      }
      if (line.message?.usage) {
        detail.inputTokens += line.message.usage.input_tokens ?? 0;
        detail.outputTokens += line.message.usage.output_tokens ?? 0;
      }
      if (!firstUserFound && line.type === "user") {
        const text = extractText(line.message?.content);
        if (text) { firstUserText = text.slice(0, 500); firstUserFound = true; }
      }
      if (line.type === "assistant") {
        const ts = tsFromLine(line);
        const content = line.message?.content;
        const assistantText = extractText(content);
        if (assistantText) lastAssistantText = assistantText;
        if (Array.isArray(content)) {
          for (const block of content) {
            if (!block || typeof block !== "object") continue;
            const b = block as Record<string, unknown>;
            if (b.type === "tool_use" && typeof b.name === "string") {
              const toolId = typeof b.id === "string" ? b.id : `${b.name}-${ts}`;
              pendingTools.set(toolId, { ts, toolName: b.name, input: b.input });
            }
          }
        }
      }
      if (line.type === "user") {
        const content = line.message?.content;
        if (Array.isArray(content)) {
          for (const block of content) {
            if (!block || typeof block !== "object") continue;
            const b = block as Record<string, unknown>;
            if (b.type === "tool_result" && typeof b.tool_use_id === "string") {
              const pending = pendingTools.get(b.tool_use_id);
              if (pending) {
                detail.toolCalls.push({ ts: pending.ts, toolName: pending.toolName, input: pending.input, response: b.content });
                pendingTools.delete(b.tool_use_id);
              }
            }
          }
        }
      }
    }

    for (const [, pending] of pendingTools) {
      detail.toolCalls.push({ ts: pending.ts, toolName: pending.toolName, input: pending.input });
    }
    if (firstUserText) detail.prompt = firstUserText;
    if (lastAssistantText) detail.result = lastAssistantText.slice(0, 1000);
  } catch (err) {
    console.warn(`[transcript] Failed to read ${transcriptPath}: ${err}`);
    return null;
  }

  return detail;
}
