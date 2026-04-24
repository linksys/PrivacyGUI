import { test, expect } from '@playwright/test';
import { injectWasmMock, setMockScenario } from '../fixtures/wasm-mock';
import { setupBridgeMocks } from '../fixtures/bridge-mock';
import { waitForFlutterReady } from '../fixtures/flutter-helpers';
import { performLoginViaUI, waitForPostLogin } from '../fixtures/login-helper';
import {
  dismissOnboarding,
  selectOnboardingPreset,
  navigateToPage,
  navigateToWifi,
  getSemanticSnapshot,
} from '../fixtures/interaction-helpers';

/**
 * Layer 2: Screenshot baselines for key pages.
 *
 * Creates golden file baselines on first run; subsequent runs compare
 * against them. CanvasKit is not byte-identical between renders due to
 * animation timing and cursor blink, so 1% pixel diff tolerance is used.
 *
 * Pages covered:
 *   1. Login — default state
 *   2. Login — password error state
 *   3. Dashboard — full data (after onboarding dismiss)
 *   4. WiFi Settings — WiFi tab with 2 SSIDs
 *   5. WiFi Settings — Advanced tab
 *   6. Menu page — all cards visible
 *   7. Support page
 *
 * Stability measures:
 *   - Fixed viewport 1280x800 (from playwright.config.ts)
 *   - Wait for rendering to settle after each navigation
 *   - maxDiffPixelRatio: 0.01 tolerance for CanvasKit non-determinism
 */
test.describe('Screenshot Baselines', () => {
  // Screenshots need extra time: login + navigate + settle
  test.setTimeout(120_000);

  test.beforeEach(async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);
  });

  test('login page — default state', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    await expect(page).toHaveScreenshot('login-default.png', {
      maxDiffPixelRatio: 0.01,
    });
  });

  test('login page — after wrong password', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);

    await performLoginViaUI(page, 'wrong-password');
    await page.waitForTimeout(3000);

    await expect(page).toHaveScreenshot('login-error.png', {
      maxDiffPixelRatio: 0.01,
    });
  });

  test('dashboard — full data', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await dismissOnboarding(page);
    await page.waitForTimeout(5000);

    // Verify dashboard has rendered data before taking screenshot
    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Device Information');

    await expect(page).toHaveScreenshot('dashboard-default.png', {
      maxDiffPixelRatio: 0.01,
    });
  });

  test('WiFi Settings — WiFi tab', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(3000);

    await dismissOnboarding(page);
    await navigateToWifi(page);
    await page.waitForTimeout(3000);

    // Verify WiFi data rendered
    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('E2E-TestNet-2.4G');

    await expect(page).toHaveScreenshot('wifi-tab-default.png', {
      maxDiffPixelRatio: 0.01,
    });
  });

  test('WiFi Settings — Advanced tab', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(3000);

    await dismissOnboarding(page);
    await navigateToWifi(page);
    await page.waitForTimeout(3000);

    // Switch to Advanced tab
    const advancedTab = page.getByRole('tab', { name: 'Advanced' });
    await advancedTab.click({ force: true });
    await page.waitForTimeout(3000);

    await expect(page).toHaveScreenshot('wifi-advanced-default.png', {
      maxDiffPixelRatio: 0.01,
    });
  });

  test('Menu page — all cards', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(3000);

    await dismissOnboarding(page);
    await page.waitForTimeout(2000);

    // Navigate to Menu
    const menuBtn = page.getByRole('button', { name: /^Menu Menu$/ });
    await menuBtn.click({ force: true });
    await page.waitForTimeout(3000);

    // Verify menu cards rendered
    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('menu-wifi-settings');

    await expect(page).toHaveScreenshot('menu-default.png', {
      maxDiffPixelRatio: 0.01,
    });
  });

  test('Support page', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(3000);

    await dismissOnboarding(page);
    await page.waitForTimeout(2000);

    // Navigate to Support
    const supportBtn = page.getByRole('button', { name: /Support Support/ });
    await supportBtn.click({ force: true });
    await page.waitForTimeout(3000);

    await expect(page).toHaveScreenshot('support-default.png', {
      maxDiffPixelRatio: 0.01,
    });
  });
});
