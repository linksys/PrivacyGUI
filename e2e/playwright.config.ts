import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for PrivacyGUI E2E tests.
 *
 * The Flutter web app is built with CanvasKit renderer — the entire UI
 * is drawn on a <canvas> element. DOM selectors cannot find Flutter widgets.
 * Tests rely on:
 *   - Layer 1: API/WASM mocking + request verification
 *   - Layer 2: Screenshot comparison
 *   - Layer 3: Flutter Semantics tree (flt-semantics DOM elements)
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: false, // tests within a file run sequentially; files run in parallel
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 2 : 3,
  reporter: process.env.CI ? 'github' : 'html',

  use: {
    // Flutter web app served locally
    baseURL: process.env.BASE_URL || 'http://localhost:4200',

    // CanvasKit needs a real browser viewport
    viewport: { width: 1280, height: 800 },

    // Collect traces on failure for debugging
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',

    // Longer timeouts for Flutter CanvasKit initialization
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
  },

  // Timeout per test — Flutter web boot can be slow
  timeout: 60_000,

  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.01, // 1% tolerance for CanvasKit non-determinism
      animations: 'disabled',
    },
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  // Web server: serve pre-built Flutter web app
  webServer: {
    command: 'bash scripts/serve.sh',
    port: 4200,
    reuseExistingServer: !process.env.CI,
    timeout: 10_000,
  },
});
