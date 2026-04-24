import { test, expect } from '@playwright/test';
import { injectWasmMock, getApiCalls, setMockScenario } from '../fixtures/wasm-mock';
import { setupBridgeMocks } from '../fixtures/bridge-mock';
import { waitForFlutterReady } from '../fixtures/flutter-helpers';
import { performLoginViaUI, waitForPostLogin } from '../fixtures/login-helper';
import { dismissOnboarding, getSemanticSnapshot } from '../fixtures/interaction-helpers';

/**
 * Dashboard rendering tests — verify mock data appears in the dashboard.
 *
 * The dashboard shows multiple cards populated by 11 domain providers:
 *   systemInfo, devices, ethernet, wifi, wan, lan, dhcp,
 *   firewall, portForwarding, portTriggering, time
 *
 * Tests verify that fixture data is consumed and rendered correctly.
 */
test.describe('Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);
  });

  test('dashboard renders Device Information card with fixture data', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await dismissOnboarding(page);
    await page.waitForTimeout(5000);

    const snapshot = await getSemanticSnapshot(page, 8000);

    // Device Information card should contain fixture data
    expect(snapshot).toContain('Device Information');

    // Check for specific fixture values from system-info.ts
    const hasModelOrManufacturer =
      snapshot.includes('MR9600') || snapshot.includes('Linksys');
    expect(hasModelOrManufacturer).toBe(true);

    console.log('PASS: Device Information card renders fixture data');
    await page.screenshot({ path: 'test-results/dashboard-device-info.png' });
  });

  test('dashboard all domain providers trigger get() calls', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(8000);

    await dismissOnboarding(page);
    await page.waitForTimeout(5000);

    const calls = await getApiCalls(page);
    const getCalls = calls.filter((c: string) => c.startsWith('get:'));

    console.log(`Total get() calls: ${getCalls.length}`);
    // 11 domain providers should trigger at least 5 distinct get() rounds
    expect(getCalls.length).toBeGreaterThanOrEqual(5);

    await page.screenshot({ path: 'test-results/dashboard-all-providers.png' });
  });

  test('dashboard shows bottom navigation bar with 3 tabs', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await dismissOnboarding(page);
    await page.waitForTimeout(3000);

    // Bottom nav should have Home, Menu, Support
    const home = page.getByRole('button', { name: /Home Home/ });
    const menu = page.getByRole('button', { name: /Menu Menu/ });
    const support = page.getByRole('button', { name: /Support Support/ });

    expect(await home.count()).toBe(1);
    expect(await menu.count()).toBe(1);
    expect(await support.count()).toBe(1);

    console.log('PASS: Bottom navigation bar has all 3 tabs');
    await page.screenshot({ path: 'test-results/dashboard-bottom-nav.png' });
  });

  // ---------------------------------------------------------------------------
  // Screenshot Baselines
  // ---------------------------------------------------------------------------

  test('screenshot baseline: dashboard with all cards', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await dismissOnboarding(page);
    await page.waitForTimeout(5000);

    await expect(page).toHaveScreenshot('dashboard-all-cards.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Dashboard all cards screenshot baseline');
  });

  test('dashboard general settings button is accessible', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await dismissOnboarding(page);
    await page.waitForTimeout(3000);

    const settingsBtn = page.getByRole('button', { name: /general settings/ });
    expect(await settingsBtn.count()).toBe(1);

    console.log('PASS: General settings button accessible on dashboard');
    await page.screenshot({ path: 'test-results/dashboard-settings.png' });
  });
});
