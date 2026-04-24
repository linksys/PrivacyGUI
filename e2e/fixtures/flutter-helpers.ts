import { Page, expect } from '@playwright/test';

/**
 * Wait for the Flutter CanvasKit app to finish initial rendering.
 *
 * Flutter 3.38+ renders the canvas inside `flt-glass-pane`'s **shadow DOM**:
 *   flutter-view > flt-glass-pane > shadow-root > flt-scene-host > flt-scene
 *     > flt-canvas-container > <canvas>
 *
 * Standard `page.locator('canvas')` cannot pierce shadow roots, so we
 * use `page.waitForFunction()` to query inside the shadow DOM directly.
 */
export async function waitForFlutterReady(page: Page, timeout = 30_000): Promise<void> {
  // Wait for flt-glass-pane to appear
  await page.waitForFunction(
    () => document.querySelector('flt-glass-pane') !== null,
    { timeout }
  );
  // Wait for canvas inside shadow DOM
  await page.waitForFunction(
    () => {
      const gp = document.querySelector('flt-glass-pane');
      return gp?.shadowRoot?.querySelector('canvas') !== null &&
             gp?.shadowRoot?.querySelector('canvas') !== undefined;
    },
    { timeout: 15_000 }
  );
}

/**
 * Collect JS console errors during page lifecycle.
 * Returns an object with helpers to inspect errors.
 */
export function collectPageErrors(page: Page) {
  const errors: string[] = [];
  const consoleErrors: string[] = [];

  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (msg) => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
    }
  });

  return {
    /** Fatal JS errors (uncaught exceptions) */
    get errors() {
      return errors;
    },
    /** Console.error calls */
    get consoleErrors() {
      return consoleErrors;
    },
    /** Filter out expected errors from mock environment */
    get fatalErrors() {
      return errors.filter(
        (e) =>
          !e.includes('fetch') &&
          !e.includes('network') &&
          !e.includes('Failed to fetch') &&
          !e.includes('NetworkError') &&
          !e.includes('AbortError') &&
          !e.includes('ERR_CONNECTION_REFUSED') &&
          // Generic "Error" from Dart/Flutter async zones — expected in mock env
          e !== 'Error'
      );
    },
  };
}
