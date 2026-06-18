// Squad Monitor — SSE Broadcast
// Gerencia clientes SSE conectados, broadcast de eventos e snapshot inicial

import type { ServerResponse } from "http";

const clients = new Set<ServerResponse>();

// Configura headers SSE + envia comentario inicial de conexao
// Deve ser chamado antes de addClient
export function initClient(res: ServerResponse): void {
  res.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
    "Access-Control-Allow-Origin": "*",
  });
  res.write(": connected\n\n");
}

// Registra cliente SSE no conjunto de destinatarios
export function addClient(res: ServerResponse): void {
  clients.add(res);
}

// Remove cliente ao desconectar (ou ao detectar erro de escrita)
export function removeClient(res: ServerResponse): void {
  clients.delete(res);
}

// Broadcast de dados arbitrarios para todos os clientes conectados
// Cada cliente recebe try/catch individual — cliente morto e removido silenciosamente
export function broadcast(data: unknown): void {
  if (clients.size === 0) return;
  const msg = `data: ${JSON.stringify(data)}\n\n`;
  for (const client of clients) {
    try {
      client.write(msg);
    } catch {
      clients.delete(client);
    }
  }
}

// Broadcast tipado de MonitorEvent (envelope { type, payload })
export function broadcastEvent(event: unknown): void {
  broadcast({ type: "event", payload: event });
}

// Broadcast de snapshot completo — para cliente especifico ou todos
export function broadcastSnapshot(snapshot: unknown, res?: ServerResponse): void {
  const msg = `data: ${JSON.stringify({ type: "snapshot", payload: snapshot })}\n\n`;
  if (res) {
    // Snapshot inicial para cliente recem-conectado
    try {
      res.write(msg);
    } catch {
      clients.delete(res);
    }
  } else {
    // Broadcast para todos os clientes
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
