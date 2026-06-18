// Squad Monitor — JSONL Persistence
// Append-only log por sessao em .runs/session-{id}.jsonl
// Permite replay do estado ao recarregar (RF-08)

import { appendFileSync, mkdirSync, existsSync, readFileSync } from "fs";
import { join } from "path";
import type { MonitorEvent } from "./types.js";

const RUNS_DIR = join(process.cwd(), ".runs");

// Garante que o diretorio .runs existe
function ensureRunsDir(): void {
  if (!existsSync(RUNS_DIR)) {
    mkdirSync(RUNS_DIR, { recursive: true });
  }
}

// Retorna path do arquivo JSONL para uma sessao
function sessionLogPath(sessionId: string): string {
  // Sanitiza sessionId para uso como filename
  const safe = sessionId.replace(/[^a-zA-Z0-9-_]/g, "_");
  return join(RUNS_DIR, `session-${safe}.jsonl`);
}

// Persiste evento no log da sessao
export function appendEvent(event: MonitorEvent): void {
  try {
    ensureRunsDir();
    const line = JSON.stringify(event) + "\n";
    appendFileSync(sessionLogPath(event.sessionId), line, "utf8");
  } catch (err) {
    console.warn(`[persistence] Failed to append event: ${err}`);
  }
}

// Le eventos de uma sessao do log JSONL (para replay)
export function readSessionLog(sessionId: string): MonitorEvent[] {
  const path = sessionLogPath(sessionId);
  if (!existsSync(path)) return [];
  try {
    const lines = readFileSync(path, "utf8").split("\n").filter(Boolean);
    return lines
      .map((line) => {
        try {
          return JSON.parse(line) as MonitorEvent;
        } catch {
          return null;
        }
      })
      .filter((e): e is MonitorEvent => e !== null);
  } catch {
    return [];
  }
}
