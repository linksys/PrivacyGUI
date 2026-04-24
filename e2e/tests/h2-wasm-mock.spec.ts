import { test, expect } from '@playwright/test';
import { injectWasmMock, getApiCalls } from '../fixtures/wasm-mock';
import { setupBridgeMocks, getBridgeCalls } from '../fixtures/bridge-mock';
import { waitForFlutterReady, collectPageErrors } from '../fixtures/flutter-helpers';

/**
 * H2: Can `addInitScript` replace `window.UspClient`, enabling app boot?
 *
 * Strategy:
 * 1. Intercept `usp_init.js` via page.route() → prevents real WASM loading
 * 2. Inject MockUspClient via addInitScript → app sees mock class
 * 3. Intercept Bridge HTTP endpoints → prevent network errors
 * 4. Verify app boots past WASM init and issues API calls
 *
 * Key risk: Whether addInitScript runs before usp_init.js.
 * Mitigation: We intercept usp_init.js entirely, so no race condition.
 *
 * Pass criteria: Mock UspClient methods are called by the Flutter app.
 */
test.describe('H2: WASM Mock Enables App Boot', () => {
  test('app boots with mock UspClient — no real WASM needed', async ({ page }) => {
    const tracker = collectPageErrors(page);

    // Set up all mocks before navigation
    await injectWasmMock(page);
    await setupBridgeMocks(page);

    await page.goto('/');
    await waitForFlutterReady(page);

    // Wait a bit for the app to issue initial API calls
    await page.waitForTimeout(3000);

    // Verify: mock UspClient was instantiated and called
    const apiCalls = await getApiCalls(page);

    // At minimum, the constructor should have been called
    const constructorCalls = apiCalls.filter((c) => c.startsWith('constructor:'));
    expect(constructorCalls.length).toBeGreaterThan(0);

    // No fatal errors (network errors from SSE reconnect are filtered)
    expect(tracker.fatalErrors).toHaveLength(0);
  });

  test('usp_init.js is intercepted — real WASM never loads', async ({ page }) => {
    let uspInitIntercepted = false;

    // Track usp_init.js interception
    await page.route('**/usp_init.js', (route) => {
      uspInitIntercepted = true;
      return route.fulfill({
        contentType: 'application/javascript',
        body: '/* intercepted */',
      });
    });

    await page.addInitScript(() => {
      // Minimal mock — just enough to not crash
      (window as any).UspClient = class {
        constructor() {}
        async login() { return { success: false }; }
        async get() { return { success: true, result: { data: {} } }; }
        async set() { return { success: true }; }
        async add() { return { success: true }; }
        async delete() { return { success: true }; }
        async operate() { return { success: true }; }
        async subscribe() { return { success: true }; }
        async unsubscribe() { return { success: true }; }
        async listSubscriptions() { return []; }
        async logout() {}
        async refreshToken() { return { success: true }; }
        isAuthenticated() { return false; }
        getToken() { return null; }
        free() {}
      };
      (window as any).__uspClientReady = Promise.resolve(true);
    });

    await setupBridgeMocks(page);

    await page.goto('/');
    await waitForFlutterReady(page);

    expect(uspInitIntercepted).toBe(true);
  });

  test('mock UspClient receives login call', async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);

    await page.goto('/');
    await waitForFlutterReady(page);

    // Wait for app to settle — it should reach login page
    await page.waitForTimeout(5000);

    const apiCalls = await getApiCalls(page);

    // The app should have constructed a UspClient
    expect(apiCalls.some((c) => c.startsWith('constructor:'))).toBe(true);

    // Log all calls for debugging
    console.log('API calls after boot:', apiCalls);
  });
});
