// CT Dashboard Server — Bun/Node
// Monitora Agent Teams em tempo real via claude agents --json + filesystem
// Porta 3002 (hooks server já usa 3001)

import { execSync, exec } from "child_process";
import { readFileSync, readdirSync, existsSync, statSync } from "fs";
import { join, resolve } from "path";
import { createServer } from "http";
import { fileURLToPath } from "url";
import { dirname } from "path";

const PORT = parseInt(process.env.PORT || "3099");
const CLAUDE_DIR = join(process.env.HOME, ".claude");
const TEAMS_DIR = join(CLAUDE_DIR, "teams");
const TASKS_DIR = join(CLAUDE_DIR, "tasks");
const JOBS_DIR = join(CLAUDE_DIR, "jobs");
const __dirname = dirname(fileURLToPath(import.meta.url));

// SSE clients
const sseClients = new Set();

function readJsonFile(path) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return null;
  }
}

function safeReadDir(dir) {
  try {
    return readdirSync(dir);
  } catch {
    return [];
  }
}

// Roda `claude agents --json` e retorna resultado
async function getSessions() {
  return new Promise((resolve) => {
    exec("claude agents --json 2>/dev/null", { timeout: 5000 }, (err, stdout) => {
      if (err || !stdout.trim()) return resolve([]);
      try {
        resolve(JSON.parse(stdout));
      } catch {
        resolve([]);
      }
    });
  });
}

// Lê teams de ~/.claude/teams/
function getTeams() {
  const teams = [];
  const dirs = safeReadDir(TEAMS_DIR);
  for (const dir of dirs) {
    const configPath = join(TEAMS_DIR, dir, "config.json");
    const config = readJsonFile(configPath);
    if (config) teams.push({ id: dir, ...config });
  }
  return teams;
}

// Lê tasks de ~/.claude/tasks/
function getTasks() {
  const result = {};
  const teamDirs = safeReadDir(TASKS_DIR);
  for (const teamDir of teamDirs) {
    const taskDir = join(TASKS_DIR, teamDir);
    if (!statSync(taskDir).isDirectory()) continue;
    const files = safeReadDir(taskDir).filter((f) => f.endsWith(".json"));
    result[teamDir] = files.map((f) => readJsonFile(join(taskDir, f))).filter(Boolean);
  }
  return result;
}

// Lê stories de um projeto
function getStories(projectPath) {
  if (!projectPath) return null;
  const storiesBase = resolve(projectPath, "docs/smart-memory/stories");
  if (!existsSync(storiesBase)) return null;

  const states = ["backlog", "active", "in-review", "done"];
  const result = {};
  for (const state of states) {
    const dir = join(storiesBase, state);
    result[state] = safeReadDir(dir)
      .filter((f) => f.endsWith(".md"))
      .map((f) => {
        const content = readFileSync(join(dir, f), "utf8");
        const titleMatch = content.match(/^# (.+)$/m);
        const assigneeMatch = content.match(/\*\*Assignee:\*\* (.+)/);
        return {
          file: f,
          title: titleMatch ? titleMatch[1] : f.replace(".md", ""),
          assignee: assigneeMatch ? assigneeMatch[1].trim() : null,
        };
      });
  }
  return result;
}

// Coleta todos os dados para o dashboard
async function collectData(projectPath) {
  const [sessions, teams, tasks] = await Promise.all([
    getSessions(),
    Promise.resolve(getTeams()),
    Promise.resolve(getTasks()),
  ]);
  const stories = getStories(projectPath);
  return { sessions, teams, tasks, stories, timestamp: new Date().toISOString() };
}

// Push SSE para todos os clientes
async function pushUpdate(projectPath) {
  if (sseClients.size === 0) return;
  const data = await collectData(projectPath);
  const msg = `data: ${JSON.stringify(data)}\n\n`;
  for (const client of sseClients) {
    try {
      client.write(msg);
    } catch {
      sseClients.delete(client);
    }
  }
}

// Polling a cada 4 segundos
let projectPath = process.env.CT_PROJECT_PATH || null;
setInterval(() => pushUpdate(projectPath), 4000);

// HTTP Server
const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const path = url.pathname;

  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  // Serve HTML dashboard
  if (path === "/" || path === "/index.html") {
    const html = readFileSync(join(__dirname, "index.html"), "utf8");
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    return res.end(html);
  }

  // SSE endpoint
  if (path === "/events") {
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
    });
    res.write(": connected\n\n");
    sseClients.add(res);

    // Enviar dados iniciais imediatamente
    const projectPathParam = url.searchParams.get("project");
    if (projectPathParam) projectPath = projectPathParam;
    const data = await collectData(projectPath);
    res.write(`data: ${JSON.stringify(data)}\n\n`);

    req.on("close", () => sseClients.delete(res));
    return;
  }

  // API: sessions
  if (path === "/api/sessions") {
    const sessions = await getSessions();
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(sessions));
  }

  // API: teams
  if (path === "/api/teams") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(getTeams()));
  }

  // API: tasks
  if (path === "/api/tasks") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(getTasks()));
  }

  // API: stories
  if (path === "/api/stories") {
    const p = url.searchParams.get("path");
    if (p) projectPath = p;
    const stories = getStories(projectPath);
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(stories));
  }

  // API: set project path
  if (path === "/api/set-project" && req.method === "POST") {
    let body = "";
    req.on("data", (chunk) => (body += chunk));
    req.on("end", () => {
      try {
        const { path: p } = JSON.parse(body);
        projectPath = p;
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true, path: projectPath }));
      } catch {
        res.writeHead(400);
        res.end("Bad request");
      }
    });
    return;
  }

  res.writeHead(404);
  res.end("Not found");
});

server.listen(PORT, () => {
  console.log(`\n🚀 CT Dashboard rodando em http://localhost:${PORT}`);
  console.log(`   Monitorando: ${CLAUDE_DIR}`);
  if (projectPath) console.log(`   Projeto: ${projectPath}`);
  console.log(`\n   Para setar o projeto:\n   CT_PROJECT_PATH="/caminho/do/projeto" bun dashboard/server.js\n`);
});
