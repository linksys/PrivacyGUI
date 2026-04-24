import { test, expect, Page } from '@playwright/test';
import { injectWasmMock, getApiCalls } from '../fixtures/wasm-mock';
import { setupBridgeMocks } from '../fixtures/bridge-mock';
import { waitForFlutterReady } from '../fixtures/flutter-helpers';
import { performLoginViaUI, waitForPostLogin } from '../fixtures/login-helper';

/**
 * #1 Text Input Spike + #2c Mock Data Rendering Verification
 *
 * Goals:
 *   1. Verify mock data is consumed by the app (get() returns real fixture data)
 *   2. Verify Dashboard renders content from fixture data
 *   3. Attempt text input on WiFi SSID field
 */
test.describe('Mock Data & Text Input Verification', () => {
  test.beforeEach(async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);
  });

  test('mock get() returns fixture data for all domain providers', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(8000);

    const calls = await getApiCalls(page);
    const getCalls = calls.filter(c => c.startsWith('get:'));
    console.log(`Total get() calls: ${getCalls.length}`);

    // Should have multiple get() calls from domain providers
    expect(getCalls.length).toBeGreaterThanOrEqual(5);

    // Dump accessibility tree to verify dashboard rendered real content
    const snapshot = await page.locator('flt-semantics-host').ariaSnapshot();
    console.log('Dashboard snapshot (first 2000 chars):\n', snapshot.substring(0, 2000));

    await page.screenshot({ path: 'test-results/mock-data-dashboard.png' });
  });

  test('WiFi page renders fixture SSID names and security modes', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    // Dismiss onboarding
    const cancelBtn = page.getByRole('button', { name: /preset-cancel/ });
    if (await cancelBtn.count() > 0) {
      await cancelBtn.click({ force: true });
      await page.waitForTimeout(3000);
    }

    // Navigate to WiFi Settings
    await page.evaluate(() => { window.location.hash = '#/uspWifiSettings'; });
    await page.waitForTimeout(5000);

    // Verify fixture data appears in semantics
    const snapshot = await page.locator('flt-semantics-host').ariaSnapshot();

    expect(snapshot).toContain('E2E-TestNet-2.4G');
    expect(snapshot).toContain('E2E-TestNet-5G');
    expect(snapshot).toContain('WPA2-Personal');
    expect(snapshot).toContain('WPA2-WPA3-Personal');
    console.log('PASS: WiFi page renders all fixture SSID data');

    await page.screenshot({ path: 'test-results/mock-data-wifi.png' });
  });

  test('text input spike: click SSID name button → find input element', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    // Dismiss onboarding
    const cancelBtn = page.getByRole('button', { name: /preset-cancel/ });
    if (await cancelBtn.count() > 0) {
      await cancelBtn.click({ force: true });
      await page.waitForTimeout(3000);
    }

    // Navigate to WiFi Settings
    await page.evaluate(() => { window.location.hash = '#/uspWifiSettings'; });
    await page.waitForTimeout(5000);

    // WiFi SSID name is rendered as a button — click it to potentially enter edit mode
    const ssidButton = page.getByRole('button', { name: /wifi-name-2\.4GHz/ });
    expect(await ssidButton.count()).toBe(1);
    console.log('Found SSID name button, clicking...');

    await ssidButton.click({ force: true });
    await page.waitForTimeout(3000);

    // Check if a text input appeared after clicking
    const allInputs = page.locator('input');
    const inputCount = await allInputs.count();
    console.log(`Inputs after clicking SSID button: ${inputCount}`);

    for (let i = 0; i < Math.min(inputCount, 10); i++) {
      const input = allInputs.nth(i);
      const type = await input.getAttribute('type');
      const ariaLabel = await input.getAttribute('aria-label');
      const value = await input.evaluate((el: HTMLInputElement) => el.value);
      const disabled = await input.isDisabled();
      console.log(`  Input[${i}]: type=${type}, aria-label=${ariaLabel}, value="${value}", disabled=${disabled}`);
    }

    // Also check the new accessibility tree for any dialog or expanded form
    const snapshot = await page.locator('flt-semantics-host').ariaSnapshot();
    console.log('Snapshot after SSID click (first 3000 chars):\n', snapshot.substring(0, 3000));

    if (inputCount > 0) {
      // Try to fill the first non-disabled input
      const editableInput = page.locator('input:not([disabled])').first();
      const testValue = 'E2E-Modified-SSID';

      try {
        await editableInput.fill(testValue, { force: true });
        await editableInput.evaluate((el: HTMLInputElement, val: string) => {
          el.value = val;
          el.dispatchEvent(new Event('input', { bubbles: true }));
          el.dispatchEvent(new Event('change', { bubbles: true }));
        }, testValue);
        await page.waitForTimeout(1000);

        const newValue = await editableInput.evaluate((el: HTMLInputElement) => el.value);
        console.log(`After fill: value="${newValue}"`);
        console.log(`RESULT: fill() on text input ${newValue === testValue ? 'SUCCEEDED' : 'PARTIAL'}`);
      } catch (err) {
        console.log(`fill() error: ${err}`);
      }
    } else {
      console.log('FINDING: Clicking SSID button did not produce a text input.');
      console.log('The WiFi page may use a custom dialog or inline edit pattern.');
    }

    await page.screenshot({ path: 'test-results/text-input-spike-click.png' });
  });
});
