import { ServerResponse } from 'http';

/**
 * Manages SSE connections and event pushing for the mock bridge server.
 *
 * SSE Protocol (matching usp-bridge):
 *   - Event types: connected, heartbeat, notification, turbo_channel
 *   - Frame format: `event: <type>\ndata: <json>\n\n`
 *   - Heartbeat interval: 10s in test mode (30s in production)
 *
 * Test control:
 *   - pushEvent(): inject any SSE event to all connections
 *   - closeAll(): force-close all connections (simulates server disconnect)
 *   - getConnectionCount(): check active connections
 */

interface SseConnection {
  id: number;
  res: ServerResponse;
  createdAt: number;
}

export class SseManager {
  private connections: Map<number, SseConnection> = new Map();
  private nextId = 1;
  private heartbeatInterval: NodeJS.Timeout | null = null;
  private heartbeatMs: number;

  constructor(heartbeatMs: number = 10_000) {
    this.heartbeatMs = heartbeatMs;
  }

  /**
   * Add a new SSE connection. Sends initial `connected` event
   * and starts heartbeat if not already running.
   */
  addConnection(res: ServerResponse): number {
    const id = this.nextId++;
    const conn: SseConnection = { id, res, createdAt: Date.now() };
    this.connections.set(id, conn);

    // SSE headers
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
    });

    // Send initial connected event
    this.sendToConnection(conn, 'connected', '');

    // Start heartbeat if first connection
    if (this.connections.size === 1) {
      this.startHeartbeat();
    }

    // Clean up on client disconnect
    res.on('close', () => {
      this.connections.delete(id);
      if (this.connections.size === 0) {
        this.stopHeartbeat();
      }
    });

    return id;
  }

  /**
   * Push an SSE event to all active connections.
   */
  pushEvent(eventType: string, data: any): void {
    const dataStr = typeof data === 'string' ? data : JSON.stringify(data);
    for (const conn of this.connections.values()) {
      this.sendToConnection(conn, eventType, dataStr);
    }
  }

  /**
   * Push a notification event (the most common test scenario).
   */
  pushNotification(notification: {
    subscription_id: string;
    type: 'ValueChange' | 'ObjectCreation' | 'ObjectDeletion' | 'OperationComplete' | 'Event';
    value_change?: { param_path: string; param_value?: string };
    obj_creation?: { obj_path: string };
    obj_deletion?: { obj_path: string };
    oper_complete?: Record<string, unknown>;
  }): void {
    this.pushEvent('notification', notification);
  }

  /**
   * Force-close all connections (simulates server-side disconnect).
   */
  closeAll(): void {
    for (const conn of this.connections.values()) {
      conn.res.end();
    }
    this.connections.clear();
    this.stopHeartbeat();
  }

  /**
   * Close a specific connection by ID.
   */
  closeConnection(id: number): void {
    const conn = this.connections.get(id);
    if (conn) {
      conn.res.end();
      this.connections.delete(id);
    }
  }

  /**
   * Get the number of active SSE connections.
   */
  getConnectionCount(): number {
    return this.connections.size;
  }

  /**
   * Get connection metadata for debugging.
   */
  getConnections(): Array<{ id: number; createdAt: number }> {
    return Array.from(this.connections.values()).map(c => ({
      id: c.id,
      createdAt: c.createdAt,
    }));
  }

  /**
   * Change heartbeat interval at runtime.
   */
  setHeartbeatInterval(ms: number): void {
    this.heartbeatMs = ms;
    if (this.heartbeatInterval) {
      this.stopHeartbeat();
      this.startHeartbeat();
    }
  }

  /**
   * Pause heartbeats (for testing watchdog timeout).
   */
  pauseHeartbeat(): void {
    this.stopHeartbeat();
  }

  /**
   * Resume heartbeats.
   */
  resumeHeartbeat(): void {
    if (this.connections.size > 0 && !this.heartbeatInterval) {
      this.startHeartbeat();
    }
  }

  // --- Private ---

  private sendToConnection(conn: SseConnection, event: string, data: string): void {
    try {
      conn.res.write(`event: ${event}\ndata: ${data}\n\n`);
    } catch {
      // Connection may have been closed
      this.connections.delete(conn.id);
    }
  }

  private startHeartbeat(): void {
    this.heartbeatInterval = setInterval(() => {
      this.pushEvent('heartbeat', '');
    }, this.heartbeatMs);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
    }
  }
}
