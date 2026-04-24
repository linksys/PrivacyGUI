import { test, expect } from '@playwright/test';
import { injectWasmMock } from '../fixtures/wasm-mock';
import { setupBridgeMocks } from '../fixtures/bridge-mock';
import { waitForFlutterReady } from '../fixtures/flutter-helpers';
import { performLoginViaUI, waitForPostLogin } from '../fixtures/login-helper';

/**
 * H4: Are CanvasKit screenshots deterministic in headless Chromium?
 *
 * Tests screenshot stability on the dashboard (post-login) — a page with
 * dynamic content from multiple domain providers. Login page is static
 * and trivially stable, so it's not a meaningful test target.
 *
 * Key finding: CanvasKit is NOT byte-identical between frames (cursor blink,
 * animation timing). Use maxDiffPixelRatio: 0.01 as the practical threshold.
 *
 * Pass criteria: dashboard screenshots within 1% pixel diff across runs.
 */
test.describe('H4: Screenshot Stability', () => {
  test.beforeEach(async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);
  });

  test('dashboard screenshot is stable across runs', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);

    // Login → navigate to dashboard
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);

    // Wait for all domain providers to load and rendering to settle
    await page.waitForTimeout(8000);

    // toHaveScreenshot: first run creates baseline, subsequent runs compare.
    // Dashboard has mock data from 11 domain providers — tests rendering
    // determinism with dynamic content.
    await expect(page).toHaveScreenshot('dashboard.png', {
      maxDiffPixelRatio: 0.01,
    });
  });

  test('login page screenshot is stable across runs', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    await expect(page).toHaveScreenshot('login-page.png', {
      maxDiffPixelRatio: 0.01,
    });
  });

  test('canvas has non-zero dimensions', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await page.waitForTimeout(2000);

    // Canvas is inside flt-glass-pane's shadow DOM:
    // flt-glass-pane > shadowRoot > flt-scene-host > flt-scene > flt-canvas-container > canvas
    const canvasSize = await page.evaluate(() => {
      const glassPane = document.querySelector('flt-glass-pane');
      let canvas: HTMLCanvasElement | null = null;
      if (glassPane?.shadowRoot) {
        canvas = glassPane.shadowRoot.querySelector('canvas');
      }
      if (!canvas) {
        canvas = document.querySelector('canvas');
      }
      if (!canvas) return null;
      return {
        width: canvas.width,
        height: canvas.height,
        clientWidth: canvas.clientWidth,
        clientHeight: canvas.clientHeight,
      };
    });

    expect(canvasSize).not.toBeNull();
    expect(canvasSize!.width).toBeGreaterThan(0);
    expect(canvasSize!.height).toBeGreaterThan(0);
  });
});
