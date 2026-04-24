import { test, expect } from '@playwright/test';
import { injectWasmMock } from '../fixtures/wasm-mock';
import { setupBridgeMocks } from '../fixtures/bridge-mock';
import { waitForFlutterReady } from '../fixtures/flutter-helpers';
import { performLoginViaUI, waitForPostLogin } from '../fixtures/login-helper';
import {
  dismissOnboarding,
  navigateToWifi,
  getSemanticSnapshot,
} from '../fixtures/interaction-helpers';

/**
 * Navigation tests — bottom nav switching and menu → sub-page.
 */
test.describe('Navigation', () => {
  test.setTimeout(90_000);

  test.beforeEach(async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);
  });

  test('bottom nav: Home → Menu → Support switching', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await dismissOnboarding(page);
    await page.waitForTimeout(3000);

    // Start on Home (Dashboard)
    let snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Device Information');

    // Navigate to Menu
    const menuBtn = page.getByRole('button', { name: /^Menu Menu$/ });
    expect(await menuBtn.count()).toBe(1);
    await menuBtn.click({ force: true });
    await page.waitForTimeout(3000);

    snapshot = await getSemanticSnapshot(page);
    // Menu page should have WiFi settings card
    const hasMenuCards =
      snapshot.includes('menu-wifi-settings') || snapshot.includes('WiFi Settings');
    expect(hasMenuCards).toBe(true);
    console.log('PASS: Navigated to Menu page');

    // Navigate to Support
    const supportBtn = page.getByRole('button', { name: /Support Support/ });
    expect(await supportBtn.count()).toBe(1);
    await supportBtn.click({ force: true });
    await page.waitForTimeout(3000);

    snapshot = await getSemanticSnapshot(page);
    console.log('Support page snapshot (first 1000):', snapshot.substring(0, 1000));

    // Navigate back to Home
    const homeBtn = page.getByRole('button', { name: /Home Home/ });
    expect(await homeBtn.count()).toBe(1);
    await homeBtn.click({ force: true });
    await page.waitForTimeout(3000);

    snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Device Information');
    console.log('PASS: Full bottom nav cycle: Home → Menu → Support → Home');

    await page.screenshot({ path: 'test-results/navigation-bottom-nav.png' });
  });

  test('Menu → WiFi Settings page loads correctly', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await dismissOnboarding(page);
    await page.waitForTimeout(3000);

    await navigateToWifi(page);
    await page.waitForTimeout(3000);

    // Verify WiFi page loaded with tabs
    const wifiTab = page.getByRole('tab', { name: 'WiFi' });
    const advancedTab = page.getByRole('tab', { name: 'Advanced' });
    expect(await wifiTab.count()).toBe(1);
    expect(await advancedTab.count()).toBe(1);

    // Verify WiFi tab is selected by default
    const selected = await wifiTab.getAttribute('aria-selected');
    expect(selected).toBe('true');

    // Verify fixture SSID data appears
    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('E2E-TestNet-2.4G');
    expect(snapshot).toContain('E2E-TestNet-5G');

    console.log('PASS: Menu → WiFi Settings navigation works');
    await page.screenshot({ path: 'test-results/navigation-wifi.png' });
  });

  test('WiFi Settings Back button returns to previous page', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await dismissOnboarding(page);
    await page.waitForTimeout(3000);

    // Navigate to WiFi
    await navigateToWifi(page);
    await page.waitForTimeout(3000);

    // Verify we're on WiFi
    expect(await page.getByRole('tab', { name: 'WiFi' }).count()).toBe(1);

    // Click Back
    const backBtn = page.getByRole('button', { name: 'Back' });
    expect(await backBtn.count()).toBe(1);
    await backBtn.click({ force: true });
    await page.waitForTimeout(3000);

    // Should return to menu or dashboard
    const snapshot = await getSemanticSnapshot(page);
    const returnedToMenu =
      snapshot.includes('menu-wifi-settings') || snapshot.includes('WiFi Settings');
    const returnedToDash =
      snapshot.includes('Device Information') || snapshot.includes('Home Home');
    expect(returnedToMenu || returnedToDash).toBe(true);

    console.log('PASS: Back button returns to previous page');
    await page.screenshot({ path: 'test-results/navigation-back.png' });
  });
});
