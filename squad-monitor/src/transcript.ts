// Squad Monitor — Transcript Reader
// Leitura on-demand dos transcripts JSONL de subagents
// Path confirmado pelo dev-analyst: ~/.claude/projects/{encoded}/{sessionId}/subagents/agent-{agentId}.jsonl
// Token usage: message.usage.input_tokens / output_tokens em entradas assistant

import { existsSync, readFileSync } from "fs";
import { join } from "path";

const CLAUDE_DIR = join(process.env.HOME ?? "/", ".claude");

type TranscriptEntry = {
  role?: string;
  content?: unknown;
  message?: {
    usage?: {
      input_tokens?: number;
      output_tokens?: number;
    };
  };
};

export type AgentTranscriptDetail = {
  agentId: string;
  sessionId: string;
  transcriptPath: string | null;
  entries: TranscriptEntry[];
  totalInputTokens: number;
  totalOutputTokens: number;
  toolCallCount: number;
  found: boolean;
};

// Encode project path para o formato de diretorio do Claude Code
// Ex: /Users/joao/projeto → -Users-joao-projeto
function encodeProjectPath(cwdOrProjectPath: string): string {
  return cwdOrProjectPath.replace(/\//g, "-").replace(/^-/, "");
}

// Retorna path do transcript de um subagent
export function transcriptPath(
  sessionId: string,
  agentId: string,
  projectCwd?: string
): string | null {
  if (!projectCwd) return null;
  const encoded = encodeProjectPath(projectCwd);
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
export function readAgentTranscript(
  sessionId: string,
  agentId: string,
  projectCwd?: string
): AgentTranscriptDetail {
  const tPath = transcriptPath(sessionId, agentId, projectCwd);

  const result: AgentTranscriptDetail = {
    agentId,
    sessionId,
    transcriptPath: tPath,
    entries: [],
    totalInputTokens: 0,
    totalOutputTokens: 0,
    toolCallCount: 0,
    found: false,
  };

  if (!tPath || !existsSync(tPath)) {
    return result;
  }

  try {
    const lines = readFileSync(tPath, "utf8").split("\n").filter(Boolean);
    const entries: TranscriptEntry[] = [];

    for (const line of lines) {
      try {
        const entry = JSON.parse(line) as TranscriptEntry;
        entries.push(entry);

        // Acumula tokens de entradas assistant
        if (entry.message?.usage) {
          result.totalInputTokens += entry.message.usage.input_tokens ?? 0;
          result.totalOutputTokens += entry.message.usage.output_tokens ?? 0;
        }

        // Conta tool calls
        if (entry.role === "assistant" && Array.isArray(entry.content)) {
          for (const block of entry.content as unknown[]) {
            if (
              block &&
              typeof block === "object" &&
              (block as Record<string, unknown>).type === "tool_use"
            ) {
              result.toolCallCount++;
            }
          }
        }
      } catch {
        // Linha invalida — ignorar graciosamente
      }
    }

    result.entries = entries;
    result.found = true;
  } catch (err) {
    console.warn(`[transcript] Failed to read ${tPath}: ${err}`);
  }

  return result;
}
