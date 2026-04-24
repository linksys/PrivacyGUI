import http from 'http';
import { SseManager } from './sse-manager';

/**
 * Mock Bridge Server for E2E tests.
 *
 * Provides persistent SSE connections with heartbeat + event injection,
 * replacing the one-shot route.fulfill() approach in bridge-mock.ts.
 *
 * Endpoints:
 *   GET  /api/v1/health              → { status: 'ok' }
 *   GET  /api/v1/notifications       → SSE stream (persistent)
 *   POST /api/v1/subscription        → { success: true }
 *   POST /api/v1/auth/login          → { success: true, token: '...' }
 *   GET  /api/v1/turbo/status        → { active: false }
 *   POST /api/v1/turbo/start         → { success: true }
 *   POST /api/v1/turbo/heartbeat     → { success: true }
 *   POST /api/v1/turbo/release       → { success: true }
 *
 * Test control (not part of bridge API):
 *   POST /inject-event               → push SSE event to all connections
 *   POST /inject-notification        → push notification event
 *   POST /close-connections          → force-close all SSE connections
 *   POST /pause-heartbeat            → stop heartbeats (test watchdog)
 *   POST /resume-heartbeat           → restart heartbeats
 *   GET  /status                     → { connections, heartbeat, uptime }
 *
 * Usage:
 *   const server = createMockServer();
 *   await server.start(4201);
 *   // ... run tests ...
 *   await server.stop();
 */

export interface MockServerOptions {
  port?: number;
  heartbeatMs?: number;
}

export interface MockServer {
  start(port?: number): Promise<void>;
  stop(): Promise<void>;
  sse: SseManager;
  port: number;
}

export function createMockServer(options: MockServerOptions = {}): MockServer {
  const sse = new SseManager(options.heartbeatMs ?? 10_000);
  let port = options.port ?? 4201;
  let httpServer: http.Server | null = null;
  const startTime = Date.now();
  const requestLog: string[] = [];

  function json(res: http.ServerResponse, data: any, status = 200) {
    res.writeHead(status, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    res.end(JSON.stringify(data));
  }

  function readBody(req: http.IncomingMessage): Promise<string> {
    return new Promise((resolve) => {
      let body = '';
      req.on('data', (chunk: Buffer) => (body += chunk.toString()));
      req.on('end', () => resolve(body));
    });
  }

  const server: MockServer = {
    sse,
    port,

    async start(p?: number): Promise<void> {
      if (p) port = p;
      server.port = port;

      return new Promise((resolve, reject) => {
        httpServer = http.createServer(async (req, res) => {
          const url = req.url ?? '/';
          const method = req.method ?? 'GET';

          // CORS preflight
          if (method === 'OPTIONS') {
            res.writeHead(204, {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            });
            res.end();
            return;
          }

          requestLog.push(`${method} ${url}`);

          // --- Bridge API endpoints ---

          if (url === '/api/v1/health' && method === 'GET') {
            json(res, { status: 'ok' });
            return;
          }

          if (url === '/api/v1/notifications' && method === 'GET') {
            sse.addConnection(res);
            return;
          }

          if (url === '/api/v1/subscription' && method === 'POST') {
            json(res, { success: true });
            return;
          }

          if (url === '/api/v1/auth/login' && method === 'POST') {
            json(res, { success: true, token: 'mock-jwt-token-e2e' });
            return;
          }

          if (url === '/api/v1/turbo/status' && method === 'GET') {
            json(res, { active: false });
            return;
          }

          if (url.startsWith('/api/v1/turbo/') && method === 'POST') {
            json(res, { success: true });
            return;
          }

          // --- Test control endpoints ---

          if (url === '/inject-event' && method === 'POST') {
            try {
              const body = JSON.parse(await readBody(req));
              sse.pushEvent(body.event ?? 'notification', body.data ?? {});
              json(res, { success: true, connections: sse.getConnectionCount() });
            } catch (err) {
              json(res, { error: String(err) }, 400);
            }
            return;
          }

          if (url === '/inject-notification' && method === 'POST') {
            try {
              const body = JSON.parse(await readBody(req));
              sse.pushNotification(body);
              json(res, { success: true, connections: sse.getConnectionCount() });
            } catch (err) {
              json(res, { error: String(err) }, 400);
            }
            return;
          }

          if (url === '/close-connections' && method === 'POST') {
            sse.closeAll();
            json(res, { success: true });
            return;
          }

          if (url === '/pause-heartbeat' && method === 'POST') {
            sse.pauseHeartbeat();
            json(res, { success: true });
            return;
          }

          if (url === '/resume-heartbeat' && method === 'POST') {
            sse.resumeHeartbeat();
            json(res, { success: true });
            return;
          }

          if (url === '/status' && method === 'GET') {
            json(res, {
              connections: sse.getConnectionCount(),
              connectionDetails: sse.getConnections(),
              uptime: Date.now() - startTime,
              requestCount: requestLog.length,
              recentRequests: requestLog.slice(-20),
            });
            return;
          }

          // 404 for unknown routes
          json(res, { error: `Not found: ${method} ${url}` }, 404);
        });

        httpServer.listen(port, () => {
          console.log(`[mock-server] Bridge mock running on http://localhost:${port}`);
          resolve();
        });

        httpServer.on('error', reject);
      });
    },

    async stop(): Promise<void> {
      sse.closeAll();
      return new Promise((resolve) => {
        if (httpServer) {
          httpServer.close(() => resolve());
        } else {
          resolve();
        }
      });
    },
  };

  return server;
}

// Allow running standalone: `npx tsx mock-server/server.ts`
if (typeof require !== 'undefined' && require.main === module) {
  const server = createMockServer();
  server.start(4201).then(() => {
    console.log('[mock-server] Press Ctrl+C to stop');
  });
}
