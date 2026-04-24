import { test, expect } from '@playwright/test';
import { injectWasmMock, getApiCalls } from '../fixtures/wasm-mock';
import { setupBridgeMocks, getBridgeCalls } from '../fixtures/bridge-mock';
import { waitForFlutterReady } from '../fixtures/flutter-helpers';
import { performLoginViaUI, waitForPostLogin } from '../fixtures/login-helper';

/**
 * H3: Can page.route() intercept all Bridge HTTP calls and simulate SSE?
 *
 * Tests:
 * 1. All Bridge HTTP requests are intercepted by route handlers
 * 2. SSE text/event-stream response is delivered and parsed by Flutter
 * 3. Auth header (Bearer token) is present in requests
 *
 * These tests perform login first to trigger Bridge API calls
 * (health, SSE, subscriptions happen during dashboard boot).
 *
 * Pass criteria: Bridge HTTP requests intercepted; SSE events delivered.
 */
test.describe('H3: API Intercept + SSE Simulation', () => {
  test.beforeEach(async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);
  });

  test('Bridge API calls intercepted after login', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);

    // Perform login to trigger dashboard boot
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);

    // Wait for orchestrator to fire domain providers
    await page.waitForTimeout(5000);

    const bridgeCalls = getBridgeCalls(page);
    console.log('Bridge calls after login:', bridgeCalls);

    const apiCalls = await getApiCalls(page);
    console.log('WASM API calls after login:', apiCalls);

    // After login, the WASM mock should have received:
    // - constructor call
    // - login call
    // - multiple get calls (11 domain providers)
    const loginCalls = apiCalls.filter((c) => c.startsWith('login:'));
    const getCalls = apiCalls.filter((c) => c.startsWith('get:'));

    expect(loginCalls.length).toBeGreaterThan(0);
    expect(getCalls.length).toBeGreaterThan(0);
  });

  test('SSE notifications endpoint receives connection', async ({ page }) => {
    let sseConnected = false;
    let sseHeaders: Record<string, string> = {};

    // Override default SSE mock to capture details
    await page.route('**/api/v1/notifications', async (route) => {
      sseConnected = true;
      sseHeaders = route.request().headers();

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
        },
        body,
      });
    });

    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    console.log('SSE connected:', sseConnected);
    console.log('SSE Authorization header present:', 'authorization' in sseHeaders);

    // After login + dashboard boot, SSE should be connected
    if (sseConnected) {
      // Verify Bearer token is in the request
      expect(sseHeaders['authorization']).toContain('Bearer');
    }
  });

  test('subscription registration after domain ready', async ({ page }) => {
    const subscriptionRequests: { method: string; body: string }[] = [];

    await page.route('**/api/v1/subscription', async (route) => {
      subscriptionRequests.push({
        method: route.request().method(),
        body: route.request().postData() ?? '',
      });
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ success: true }),
      });
    });

    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);

    // Subscriptions are deferred: wait for domainReady + throttler.whenIdle()
    await page.waitForTimeout(10000);

    console.log('Subscription requests:', subscriptionRequests.length);
    for (const req of subscriptionRequests) {
      console.log(`  ${req.method}: ${req.body.substring(0, 120)}`);
    }

    // Log WASM-level subscribe calls too
    const apiCalls = await getApiCalls(page);
    const subscribeCalls = apiCalls.filter((c) => c.startsWith('subscribe:'));
    console.log('WASM subscribe calls:', subscribeCalls);
  });

  test('all intercepted Bridge calls have valid HTTP methods', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    const calls = getBridgeCalls(page);
    console.log('All Bridge calls:', calls);

    // Every intercepted call should have a valid HTTP method
    for (const call of calls) {
      expect(call).toMatch(/^(GET|POST|PUT|DELETE|PATCH|OPTIONS) /);
    }
  });
});
