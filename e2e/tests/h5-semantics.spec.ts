import { test, expect } from '@playwright/test';
import { injectWasmMock, getApiCalls } from '../fixtures/wasm-mock';
import { setupBridgeMocks } from '../fixtures/bridge-mock';
import { waitForFlutterReady } from '../fixtures/flutter-helpers';
import { performLoginViaUI } from '../fixtures/login-helper';

/**
 * H5: Can Playwright find and interact with Flutter widgets via Semantics?
 *
 * Prerequisites (Flutter code change — already done):
 *   - Login page password input wrapped with Semantics(label: 'login-password-input')
 *   - Login button wrapped with Semantics(label: 'login-submit-button')
 *
 * Key findings from investigation:
 *   - flt-semantics-host is a DIRECT child of flutter-view (NOT in shadow DOM)
 *   - flt-glass-pane HAS a shadow root, but flt-semantics-host does NOT live there
 *   - Semantics <input> elements receive pointer events
 *   - Login works via fill() + dispatchEvent on semantics input + force click on button
 *   - SemanticsBinding.instance.ensureSemantics() already called in main.dart (web builds)
 *
 * Pass criteria: semantics elements found, fill + click triggers login.
 */
test.describe('H5: Semantics Interaction', () => {
  test.beforeEach(async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);
  });

  test('flt-semantics-host exists as child of flutter-view', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    // flt-semantics-host is a direct child of flutter-view, not inside shadow DOM
    const semanticsHost = await page.evaluate(() => {
      const host = document.querySelector('flt-semantics-host');
      if (!host) return { found: false, reason: 'no flt-semantics-host in DOM' };

      const semanticsNodes = host.querySelectorAll('flt-semantics');
      return {
        found: true,
        parentTag: host.parentElement?.tagName?.toLowerCase(),
        semanticsNodeCount: semanticsNodes.length,
        sampleLabels: Array.from(semanticsNodes)
          .filter((n) => n.getAttribute('aria-label'))
          .slice(0, 10)
          .map((n) => ({
            role: n.getAttribute('role'),
            label: n.getAttribute('aria-label'),
            id: n.id,
          })),
      };
    });

    console.log('Semantics host:', JSON.stringify(semanticsHost, null, 2));

    expect(semanticsHost.found).toBe(true);
    expect(semanticsHost.parentTag).toBe('flutter-view');
    expect(semanticsHost.semanticsNodeCount).toBeGreaterThan(0);
  });

  test('login page semantic elements are discoverable', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    // These aria-labels are set by Semantics(label: ...) in login_local_view.dart
    const passwordInput = page.locator('[aria-label="login-password-input"]');
    const loginButton = page.locator('[aria-label="login-submit-button"]');

    const passwordCount = await passwordInput.count();
    const loginCount = await loginButton.count();

    console.log(`login-password-input: found=${passwordCount > 0}`);
    console.log(`login-submit-button: found=${loginCount > 0}`);

    expect(passwordCount).toBeGreaterThan(0);
    expect(loginCount).toBeGreaterThan(0);
  });

  test('semantics-based login triggers API calls', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);

    // Use the proven login approach: fill semantics input + click button
    const success = await performLoginViaUI(page, 'admin');
    expect(success).toBe(true);

    const apiCalls = await getApiCalls(page);
    console.log('API calls after login:', apiCalls);

    // Verify login was called with 'admin'
    const loginCalls = apiCalls.filter((c: string) => c.startsWith('login:'));
    expect(loginCalls.length).toBeGreaterThan(0);
    expect(loginCalls[0]).toBe('login:admin');

    // Verify domain providers were triggered (GET calls)
    const getCalls = apiCalls.filter((c: string) => c.startsWith('get:'));
    expect(getCalls.length).toBeGreaterThan(0);
  });

  test('all semantic elements have valid structure', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const allSemantics = await page.evaluate(() => {
      const host = document.querySelector('flt-semantics-host');
      if (!host) return [];

      return Array.from(host.querySelectorAll('flt-semantics')).map((n) => ({
        id: n.id,
        role: n.getAttribute('role'),
        label: n.getAttribute('aria-label'),
        childCount: n.children.length,
        hasInput: n.querySelector('input') !== null,
      }));
    });

    console.log(`Total semantic nodes: ${allSemantics.length}`);
    const labeled = allSemantics.filter((n) => n.label);
    console.log('Labeled nodes:', JSON.stringify(labeled, null, 2));

    expect(allSemantics.length).toBeGreaterThan(0);
    // Every semantics node should have an ID
    for (const node of allSemantics) {
      expect(node.id).toBeTruthy();
    }
  });
});
