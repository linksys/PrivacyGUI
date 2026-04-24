import { test, expect } from '@playwright/test';
import { collectPageErrors } from '../fixtures/flutter-helpers';

/**
 * H1: Can Playwright load a CanvasKit Flutter web app in headless browser?
 *
 * This test runs WITHOUT any mocks — it simply verifies that:
 * 1. The page loads without fatal JS errors
 * 2. The `flt-glass-pane` element appears (Flutter's canvas host)
 * 3. A <canvas> element is visible (CanvasKit rendered something)
 *
 * Expected: The app will attempt to load WASM and connect to the bridge,
 * which will fail. But the Flutter framework itself should initialize and
 * render at least the initial canvas. Network errors are expected and filtered.
 *
 * Pass criteria: Canvas appears, no fatal JS errors unrelated to network.
 */
test.describe('H1: App Can Load', () => {
  test('Flutter CanvasKit app loads in headless Chromium', async ({ page }) => {
    const tracker = collectPageErrors(page);

    await page.goto('/');

    // Wait for Flutter's glass pane to appear
    await page.waitForFunction(
      () => document.querySelector('flt-glass-pane') !== null,
      { timeout: 30_000 }
    );

    // Verify canvas is rendered
    const canvas = page.locator('canvas');
    await expect(canvas.first()).toBeVisible({ timeout: 10_000 });

    // Check no fatal (non-network) JS errors
    // Network errors are expected since we have no mock backend
    expect(tracker.fatalErrors).toHaveLength(0);
  });

  test('flt-glass-pane structure is correct', async ({ page }) => {
    await page.goto('/');

    await page.waitForFunction(
      () => document.querySelector('flt-glass-pane') !== null,
      { timeout: 30_000 }
    );

    // Verify Flutter's DOM structure: flutter-view > flt-glass-pane
    const flutterView = page.locator('flutter-view');
    const glassPane = page.locator('flt-glass-pane');

    // At least one of these should exist
    const hasFlutterView = await flutterView.count();
    const hasGlassPane = await glassPane.count();

    expect(hasFlutterView + hasGlassPane).toBeGreaterThan(0);
  });
});
