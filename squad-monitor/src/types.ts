// Squad Monitor — Core Types
// Schema baseado no PRD secao 7 e findings do dev-analyst (2026-06-18)

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
  ts: number;             // epoch ms na recepcao
  sessionId: string;
  cwd: string;
  kind: MonitorEventKind;
  agentId?: string;
  agentType?: string;
  effort?: string;
  tool?: {
    name: string;
    inputSummary?: string;
    responseSummary?: string;
  };
  worktree?: {
    name: string;
    branch?: string;
  };
  transcriptPath?: string;  // de transcript_path ou agent_transcript_path
  raw: unknown;             // payload original do hook, para debug
};

export type AgentStatus = "running" | "done" | "error";

export type AgentState = {
  agentId: string;
  agentType: string;
  sessionId: string;
  status: AgentStatus;
  startedAt: number;
  endedAt?: number;
  effort?: string;
  toolCalls: number;
  currentTool?: string;
  worktree?: string;
  transcriptPath?: string;  // derivado de sessionId + agentId
};

// Snapshot enviado ao cliente SSE ao conectar
export type DashboardSnapshot = {
  sessions: SessionEntry[];
  agents: AgentState[];
  recentEvents: MonitorEvent[];
};

// Sessao Claude Code (de ~/.claude/sessions/*.json)
export type SessionEntry = {
  sessionId: string;
  pid?: number;
  cwd: string;
  startedAt?: number;
  version?: string;
  kind?: string;
  agentCount: number;
};
