import { Page, Route } from '@playwright/test';

/**
 * Height (px) of the SSE "Connecting to router..." banner that appears in
 * the mock environment. Use this to clip screenshots so the banner is excluded.
 *
 * Root cause: The compiled Dart async state machine in _startSseStream throws
 * before reaching web.window.fetch(), preventing the JS-level fetch override
 * from providing a streaming SSE response. The banner is CanvasKit-rendered
 * (not in the semantics tree) so it cannot be hidden via DOM manipulation.
 */
export const SSE_BANNER_HEIGHT = 38;

/**
 * Sets up route handlers for all Bridge HTTP endpoints.
 *
 * Endpoints intercepted:
 *   GET  /api/v1/health         — health check
 *   GET  /api/v1/notifications  — SSE stream (one-shot for MVP)
 *   POST /api/v1/subscription   — register/unregister subscriptions
 *   GET  /api/v1/turbo/status   — turbo channel status
 *   POST /api/v1/turbo/start    — start turbo channel
 *   POST /api/v1/turbo/heartbeat — turbo heartbeat
 *   POST /api/v1/turbo/release  — release turbo channel
 *
 * Also intercepts the service worker to prevent caching interference.
 */
export async function setupBridgeMocks(page: Page): Promise<void> {
  const intercepted: string[] = [];

  // SSE MOCK LIMITATION:
  // The app's SSE connection (_startSseStream in usp_bridge_client_web.dart)
  // fails in the mock environment before reaching the fetch() call — likely
  // due to a Dart async/JS-interop issue when accessing the session token
  // within the compiled async state machine. This causes the
  // "Connecting to router..." banner to show. The fetch override below is
  // kept for potential future use but does not currently prevent the banner.
  // Screenshots should use SSE_BANNER_HEIGHT clip offset to exclude it.
  await page.addInitScript(() => {
    const originalFetch = window.fetch;
    window.fetch = function (
      input: RequestInfo | URL,
      init?: RequestInit
    ): Promise<Response> {
      const url = typeof input === 'string' ? input : input instanceof URL ? input.toString() : input.url;
      if (url.includes('/api/v1/notifications')) {
        (window as any).__apiCalls?.push('sse:connect');
        const encoder = new TextEncoder();
        const stream = new ReadableStream({
          start(controller) {
            const frame = 'event: heartbeat\ndata: {"type":"heartbeat"}\n\n';
            controller.enqueue(encoder.encode(frame));
            const interval = setInterval(() => {
              try { controller.enqueue(encoder.encode(frame)); }
              catch { clearInterval(interval); }
            }, 10_000);
            (window as any).__sseCleanup = () => {
              clearInterval(interval);
              try { controller.close(); } catch { /* already closed */ }
            };
          },
        });
        return Promise.resolve(
          new Response(stream, {
            status: 200,
            headers: {
              'Content-Type': 'text/event-stream',
              'Cache-Control': 'no-cache',
              'Connection': 'keep-alive',
            },
          })
        );
      }
      return originalFetch.call(window, input, init);
    };
  });

  // Block service worker to prevent caching interference with route handlers
  await page.route('**/flutter_service_worker.js', (route) =>
    route.fulfill({
      contentType: 'application/javascript',
      body: '/* E2E: service worker disabled */',
    })
  );

  // Health check
  await page.route('**/api/v1/health', (route) => {
    intercepted.push(`${route.request().method()} /api/v1/health`);
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ status: 'ok' }),
    });
  });

  // SSE Notifications — one-shot delivery for MVP
  // Delivers initial heartbeat + empty stream close
  await page.route('**/api/v1/notifications', (route) => {
    intercepted.push(`${route.request().method()} /api/v1/notifications`);
    const body = [
      'event: heartbeat',
      'data: {"type":"heartbeat"}',
      '',
      '',
    ].join('\n');

    return route.fulfill({
      status: 200,
      headers: {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
        'connection': 'keep-alive',
      },
      body,
    });
  });

  // Subscription register/unregister
  await page.route('**/api/v1/subscription', (route) => {
    intercepted.push(`${route.request().method()} /api/v1/subscription`);
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ success: true }),
    });
  });

  // Turbo channel endpoints
  await page.route('**/api/v1/turbo/status', (route) => {
    intercepted.push(`${route.request().method()} /api/v1/turbo/status`);
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ active: false }),
    });
  });

  await page.route('**/api/v1/turbo/start', (route) => {
    intercepted.push(`${route.request().method()} /api/v1/turbo/start`);
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ success: true }),
    });
  });

  await page.route('**/api/v1/turbo/heartbeat', (route) => {
    intercepted.push(`${route.request().method()} /api/v1/turbo/heartbeat`);
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ success: true }),
    });
  });

  await page.route('**/api/v1/turbo/release', (route) => {
    intercepted.push(`${route.request().method()} /api/v1/turbo/release`);
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ success: true }),
    });
  });

  // Also intercept auth endpoint (login goes through lighttpd)
  await page.route('**/api/v1/auth/login', (route) => {
    intercepted.push(`${route.request().method()} /api/v1/auth/login`);
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ success: true, token: 'mock-jwt-token-e2e' }),
    });
  });

  // Store intercepted calls on window for test assertions
  await page.addInitScript(() => {
    (window as any).__bridgeCalls = [];
  });

  // Expose getter
  (page as any).__bridgeIntercepted = intercepted;
}

/**
 * Returns all intercepted Bridge HTTP calls.
 */
export function getBridgeCalls(page: Page): string[] {
  return (page as any).__bridgeIntercepted ?? [];
}
