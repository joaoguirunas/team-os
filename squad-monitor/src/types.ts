// Squad Monitor — Core Types
// Schema exato do PRD secao 7

export type MonitorEventKind =
  | "session.start"
  | "session.end"
  | "agent.start"
  | "agent.stop"
  | "tool.pre"
  | "tool.post"
  | "turn.stop"
  | "worktree.create";

export type MonitorEvent = {
  ts: number;                  // epoch ms na recepcao
  sessionId: string;
  cwd: string;
  kind: MonitorEventKind;
  agentId?: string;
  agentType?: string;
  effort?: string;
  tool?: { name: string; inputSummary?: string; responseSummary?: string };
  worktree?: { name: string; branch?: string };
  transcriptPath?: string;     // path do transcript do subagent (para RF-06)
  raw: unknown;                // payload original do hook, para debug
};

export type AgentState = {
  agentId: string;
  agentType: string;
  sessionId: string;
  status: "running" | "done" | "error";
  startedAt: number;
  endedAt?: number;
  effort?: string;
  toolCalls: number;
  currentTool?: string;
  worktree?: string;
  transcriptPath?: string;    // derivado de sessionId + agentId
};
