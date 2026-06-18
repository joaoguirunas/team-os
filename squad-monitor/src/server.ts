// Squad Monitor — HTTP Server
// Rotas: GET /, GET /events, POST /ingest, GET /agent/:id, GET /api/sessions

import { createServer, type IncomingMessage, type ServerResponse } from "http";
import { readFileSync, readdirSync, existsSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { normalizeHook } from "./ingest.js";
import { addEvent, getSnapshot } from "./store.js";
import { appendEvent } from "./persistence.js";
import { addClient, removeClient, broadcastEvent, broadcastSnapshot } from "./sse.js";
import { readAgentTranscript } from "./transcript.js";

const PORT = parseInt(process.env.PORT ?? "3099", 10);
const __dirname = dirname(fileURLToPath(import.meta.url));
const PUBLIC_DIR = join(__dirname, "..", "public");
const SESSIONS_DIR = join(process.env.HOME ?? "/", ".claude", "sessions");

// Le body de uma requisicao como string
function readBody(req: IncomingMessage): Promise<string> {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk: Buffer) => (body += chunk.toString()));
    req.on("end", () => resolve(body));
    req.on("error", reject);
  });
}

// Serve arquivo estatico da pasta public/
function serveStatic(res: ServerResponse, filename: string): boolean {
  const filePath = join(PUBLIC_DIR, filename);
  if (!existsSync(filePath)) return false;
  const ext = filename.split(".").pop() ?? "";
  const contentTypes: Record<string, string> = {
    html: "text/html; charset=utf-8",
    js: "application/javascript",
    css: "text/css",
  };
  const contentType = contentTypes[ext] ?? "application/octet-stream";
  try {
    const content = readFileSync(filePath);
    res.writeHead(200, { "Content-Type": contentType });
    res.end(content);
    return true;
  } catch {
    return false;
  }
}

// Le sessoes ativas de ~/.claude/sessions/*.json
// Cada arquivo: { pid, sessionId, cwd, startedAt, procStart, version, kind, entrypoint }
function readActiveSessions(): unknown[] {
  try {
    return readdirSync(SESSIONS_DIR)
      .filter((f) => f.endsWith(".json"))
      .map((f) => {
        try {
          return JSON.parse(readFileSync(join(SESSIONS_DIR, f), "utf8"));
        } catch {
          return null;
        }
      })
      .filter((s) => s !== null);
  } catch {
    return [];
  }
}

const server = createServer(async (req: IncomingMessage, res: ServerResponse) => {
  const url = new URL(req.url ?? "/", `http://localhost:${PORT}`);
  const pathname = url.pathname;
  const method = req.method ?? "GET";

  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  // GET / → dashboard HTML
  if (method === "GET" && (pathname === "/" || pathname === "/index.html")) {
    if (!serveStatic(res, "index.html")) {
      res.writeHead(404);
      res.end("Dashboard not found. Run from squad-monitor/ directory.");
    }
    return;
  }

  // Arquivos estaticos: /app.js, /styles.css
  if (method === "GET" && (pathname === "/app.js" || pathname === "/styles.css")) {
    const filename = pathname.slice(1);
    if (!serveStatic(res, filename)) {
      res.writeHead(404);
      res.end("Not found");
    }
    return;
  }

  // GET /events → SSE stream
  if (method === "GET" && pathname === "/events") {
    addClient(res);
    // Envia snapshot inicial ao cliente ao conectar
    const snapshot = getSnapshot();
    broadcastSnapshot(snapshot, res);
    req.on("close", () => removeClient(res));
    return;
  }

  // POST /ingest → recebe hooks do Claude Code
  if (method === "POST" && pathname === "/ingest") {
    // Responde 202 imediatamente para nao bloquear o Claude Code (RNF-04)
    res.writeHead(202, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true }));

    // Processa de forma assincrona apos responder
    try {
      const body = await readBody(req);
      const rawPayload = JSON.parse(body);
      const event = normalizeHook(rawPayload);
      if (event) {
        addEvent(event);
        appendEvent(event);
        broadcastEvent(event);
        console.log(
          `[ingest] ${event.kind} session=${event.sessionId.slice(0, 8)}` +
          (event.agentId ? ` agent=${event.agentId.slice(0, 8)}` : "") +
          (event.tool ? ` tool=${event.tool.name}` : "")
        );
      }
    } catch (err) {
      console.warn(`[ingest] Failed to process hook: ${err}`);
    }
    return;
  }

  // GET /api/sessions → lista sessoes ativas de ~/.claude/sessions/*.json
  if (method === "GET" && pathname === "/api/sessions") {
    const sessions = readActiveSessions();
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(sessions));
    return;
  }

  // GET /agent/:id → detalhe do agente via transcript (RF-06)
  const agentMatch = pathname.match(/^\/agent\/([^/]+)$/);
  if (method === "GET" && agentMatch) {
    const agentId = decodeURIComponent(agentMatch[1]);
    const sessionId = url.searchParams.get("sessionId") ?? "";
    const cwd = url.searchParams.get("cwd") ?? undefined;
    const detail = readAgentTranscript(sessionId, agentId, cwd);
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(detail));
    return;
  }

  // GET /snapshot → estado atual completo (debug)
  if (method === "GET" && pathname === "/snapshot") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(getSnapshot()));
    return;
  }

  res.writeHead(404);
  res.end("Not found");
});

server.listen(PORT, () => {
  console.log(`\nSquad Monitor em http://localhost:${PORT}`);
  console.log(`  GET  /          → dashboard`);
  console.log(`  GET  /events    → SSE stream`);
  console.log(`  POST /ingest    → recebe hooks do Claude Code`);
  console.log(`  GET  /api/sessions → sessoes ativas (filesystem)`);
  console.log(`  GET  /agent/:id → detalhe de agente (transcript)`);
  console.log(`\n  Configurar hooks: cole hooks/settings.snippet.json em ~/.claude/settings.json\n`);
});

export { server };
