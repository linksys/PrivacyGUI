import { Page } from '@playwright/test';
import { getAllScenariosJson } from './mock-data/index';

/**
 * Injects a mock `window.UspClient` class and sets `window.__uspClientReady`
 * so the Flutter app boots without real WASM.
 *
 * IMPORTANT: Must also intercept `usp_init.js` via `page.route()` to prevent
 * the real WASM loader from overwriting these globals.
 *
 * Methods mirror the JS interop surface in `usp_client_wasm.dart`:
 *   UspClientJS extension type (14 methods: 12 async + isAuthenticated + getToken + free)
 *
 * The mock get() performs wildcard path matching against fixture data
 * loaded from e2e/fixtures/mock-data/.
 */
export async function injectWasmMock(page: Page): Promise<void> {
  // 1. Intercept usp_init.js to prevent real WASM loading
  await page.route('**/usp_init.js', (route) =>
    route.fulfill({
      contentType: 'application/javascript',
      body: '/* E2E: usp_init.js intercepted — mock UspClient injected via addInitScript */',
    })
  );

  // 2. Serialize fixture data for injection into browser context
  const scenariosJson = getAllScenariosJson();

  // 3. Inject mock UspClient before any page scripts run
  await page.addInitScript((scenariosStr: string) => {
    // Parse fixture scenarios into browser memory
    const scenarios = JSON.parse(scenariosStr) as Record<string, Record<string, string>>;

    let authenticated = false;
    let token: string | null = null;
    const apiCalls: string[] = [];

    /**
     * Resolve fixture data for the active scenario.
     * Tests can switch scenario via: window.__mockScenario = 'empty'
     */
    function getFixtures(): Record<string, string> {
      const scenario = ((window as any).__mockScenario as string) || 'default';
      return scenarios[scenario] ?? scenarios['default'] ?? {};
    }

    /**
     * Match a wildcard request path against fixture keys.
     *
     * Wildcard patterns from codegen:
     *   Device.WiFi.SSID.*.SSID         → matches Device.WiFi.SSID.1.SSID
     *   Device.Hosts.Host.*.IPv6Address.*.IPAddress → matches .Host.1.IPv6Address.2.IPAddress
     *
     * Special case: trailing dot (e.g., "Device.WiFi.AccessPoint.*.AssociatedDevice.")
     * is a fetchAll request — return all keys under that prefix with instances expanded.
     */
    function matchPaths(
      requestedPath: string,
      fixtures: Record<string, string>,
    ): Record<string, string> {
      const result: Record<string, string> = {};

      if (requestedPath.includes('*')) {
        // Convert wildcard pattern to regex
        // Escape dots, replace .*.  with .\d+.
        const escaped = requestedPath
          .replace(/\./g, '\\.')
          .replace(/\\\.\*\\\./g, '\\.\\d+\\.');
        const regex = new RegExp('^' + escaped + '$');

        for (const [key, value] of Object.entries(fixtures)) {
          if (regex.test(key)) {
            result[key] = value;
          }
        }
      } else if (requestedPath.endsWith('.')) {
        // Trailing dot = fetchAll: return everything under this prefix
        for (const [key, value] of Object.entries(fixtures)) {
          if (key.startsWith(requestedPath)) {
            result[key] = value;
          }
        }
      } else {
        // Exact path match
        if (requestedPath in fixtures) {
          result[requestedPath] = fixtures[requestedPath];
        }
      }

      return result;
    }

    class MockUspClient {
      baseUrl: string;

      constructor(baseUrl: string) {
        this.baseUrl = baseUrl;
        apiCalls.push(`constructor:${baseUrl}`);
      }

      async login(password: string) {
        apiCalls.push(`login:${password}`);
        if (password === 'admin' || password === 'test') {
          authenticated = true;
          token = 'mock-jwt-token-e2e';
          return { success: true, token };
        }
        return { success: false, error: 'Invalid password' };
      }

      async logout() {
        apiCalls.push('logout');
        authenticated = false;
        token = null;
        return { success: true };
      }

      async refreshToken() {
        apiCalls.push('refreshToken');
        token = 'mock-jwt-refreshed-e2e';
        return { success: true, token };
      }

      async get(paths: string | string[]) {
        const pathList = Array.isArray(paths) ? paths : [paths];
        apiCalls.push(`get:${pathList.length}paths`);

        const fixtures = getFixtures();
        const data: Record<string, string> = {};

        for (const p of pathList) {
          const matched = matchPaths(p, fixtures);
          Object.assign(data, matched);
        }

        return { success: true, result: { data } };
      }

      async set(parameters: any, options?: any) {
        apiCalls.push(`set:${JSON.stringify(parameters).substring(0, 100)}`);
        return { success: true, result: {} };
      }

      async add(items: any, options?: any) {
        apiCalls.push(`add:${JSON.stringify(items).substring(0, 100)}`);
        return { success: true, result: { path: 'Device.Test.1.' } };
      }

      async delete(paths: any, options?: any) {
        apiCalls.push(`delete:${JSON.stringify(paths).substring(0, 100)}`);
        return { success: true, result: {} };
      }

      async operate(command: string, args: any) {
        apiCalls.push(`operate:${command}`);
        return { success: true, result: {} };
      }

      async subscribe(subscriptionId: string) {
        apiCalls.push(`subscribe:${subscriptionId}`);
        return { success: true };
      }

      async unsubscribe(subscriptionId: string) {
        apiCalls.push(`unsubscribe:${subscriptionId}`);
        return { success: true };
      }

      async listSubscriptions() {
        apiCalls.push('listSubscriptions');
        return [];
      }

      isAuthenticated() {
        return authenticated;
      }

      getToken() {
        return token;
      }

      free() {
        // no-op cleanup
      }
    }

    // Expose on window — writable so Dart JS interop can access it
    (window as any).UspClient = MockUspClient;
    (window as any).__uspClientReady = Promise.resolve(true);
    (window as any).__apiCalls = apiCalls;
    (window as any).__mockScenario = 'default';
  }, scenariosJson);
}

/**
 * Returns all API calls recorded by the mock UspClient.
 */
export async function getApiCalls(page: Page): Promise<string[]> {
  return page.evaluate(() => (window as any).__apiCalls ?? []);
}

/**
 * Clears the recorded API calls.
 */
export async function clearApiCalls(page: Page): Promise<void> {
  await page.evaluate(() => {
    (window as any).__apiCalls = [];
  });
}

/**
 * Switch the mock data scenario at runtime.
 * Available scenarios: 'default', 'empty', 'wifi-only'
 */
export async function setMockScenario(page: Page, scenario: string): Promise<void> {
  await page.evaluate((s) => {
    (window as any).__mockScenario = s;
  }, scenario);
}
