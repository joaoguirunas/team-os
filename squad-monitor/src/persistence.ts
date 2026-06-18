// Squad Monitor — JSONL Persistence
// Append-only log por sessao em .runs/session-{id}.jsonl
// Permite replay do estado ao recarregar o dashboard (RF-08)

import { appendFileSync, mkdirSync, readFileSync, readdirSync, existsSync } from "fs";
import { join } from "path";
import type { MonitorEvent } from "./types.js";

const RUNS_DIR = join(process.cwd(), ".runs");

// Garante que o diretorio .runs existe — chamado uma vez em appendEvent
let runsDirReady = false;
function ensureRunsDir(): void {
  if (runsDirReady) return;
  try {
    mkdirSync(RUNS_DIR, { recursive: true });
    runsDirReady = true;
  } catch {
    // Diretorio pode ja existir em corrida de inicializacao — ignorar
  }
}

// Sanitiza sessionId para uso seguro como filename
function toSafeFilename(sessionId: string): string {
  return sessionId.replace(/[^a-zA-Z0-9-_]/g, "_");
}

// Retorna path do arquivo JSONL para uma sessao
function sessionLogPath(sessionId: string): string {
  return join(RUNS_DIR, `session-${toSafeFilename(sessionId)}.jsonl`);
}

// Persiste evento no log append-only da sessao
// Cria arquivo e diretorio se necessario
export function appendEvent(event: MonitorEvent): void {
  try {
    ensureRunsDir();
    appendFileSync(sessionLogPath(event.sessionId), JSON.stringify(event) + "\n", "utf8");
  } catch (err) {
    console.warn(`[persistence] appendEvent failed: ${err}`);
  }
}

// Le eventos de uma sessao do log JSONL (para replay em refresh)
// Linhas invalidas sao ignoradas — nao derruba o servidor
export function replaySession(sessionId: string): MonitorEvent[] {
  const path = sessionLogPath(sessionId);
  if (!existsSync(path)) return [];
  try {
    const lines = readFileSync(path, "utf8").split("\n");
    const events: MonitorEvent[] = [];
    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        events.push(JSON.parse(line) as MonitorEvent);
      } catch {
        // Linha corrompida — ignorar graciosamente
      }
    }
    return events;
  } catch (err) {
    console.warn(`[persistence] replaySession failed for ${sessionId}: ${err}`);
    return [];
  }
}

// Lista sessionIds de todos os logs em .runs/
export function listSessions(): string[] {
  try {
    if (!existsSync(RUNS_DIR)) return [];
    return readdirSync(RUNS_DIR)
      .filter((f) => f.startsWith("session-") && f.endsWith(".jsonl"))
      .map((f) => f.replace(/^session-/, "").replace(/\.jsonl$/, ""));
  } catch (err) {
    console.warn(`[persistence] listSessions failed: ${err}`);
    return [];
  }
}

// Alias para compatibilidade com chamadas pre-refactor
export const readSessionLog = replaySession;
