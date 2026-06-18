// Squad Monitor — SSE Broadcast
// Gerencia conexoes SSE e broadcast de eventos para clientes conectados

import type { ServerResponse } from "http";
import type { MonitorEvent } from "./types.js";

const clients = new Set<ServerResponse>();

// Registra cliente SSE e envia headers + ping inicial
export function addClient(res: ServerResponse): void {
  res.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
    "Access-Control-Allow-Origin": "*",
  });
  res.write(": connected\n\n");
  clients.add(res);
}

// Remove cliente ao desconectar
export function removeClient(res: ServerResponse): void {
  clients.delete(res);
}

// Broadcast de evento individual para todos os clientes
export function broadcastEvent(event: MonitorEvent): void {
  if (clients.size === 0) return;
  const msg = `data: ${JSON.stringify({ type: "event", payload: event })}\n\n`;
  for (const client of clients) {
    try {
      client.write(msg);
    } catch {
      clients.delete(client);
    }
  }
}

// Broadcast de snapshot completo (usado na reconexao inicial)
export function broadcastSnapshot(snapshot: unknown, res?: ServerResponse): void {
  const msg = `data: ${JSON.stringify({ type: "snapshot", payload: snapshot })}\n\n`;
  if (res) {
    // Envia apenas para o cliente especifico (ao conectar)
    try {
      res.write(msg);
    } catch {
      clients.delete(res);
    }
  } else {
    // Broadcast para todos
    for (const client of clients) {
      try {
        client.write(msg);
      } catch {
        clients.delete(client);
      }
    }
  }
}

// Retorna contagem de clientes conectados
export function clientCount(): number {
  return clients.size;
}
