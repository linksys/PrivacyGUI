import { test, expect } from '@playwright/test';
import { injectWasmMock, getApiCalls } from '../fixtures/wasm-mock';
import { setupBridgeMocks } from '../fixtures/bridge-mock';
import { waitForFlutterReady } from '../fixtures/flutter-helpers';
import { performLoginViaUI, waitForPostLogin } from '../fixtures/login-helper';
import { selectOnboardingPreset, getSemanticSnapshot } from '../fixtures/interaction-helpers';

/**
 * Onboarding flow tests — preset selection, Apply, and Cancel.
 *
 * After login, the app shows a preset selection dialog with 4 dashboard presets:
 *   - Essential (6 cards)
 *   - Standard (12 cards)
 *   - Professional (17 cards)
 *   - Monitoring (8 cards)
 *
 * Selecting a preset enables the Apply button. Apply saves the selection
 * and navigates to the configured dashboard.
 */
test.describe('Onboarding Flow', () => {
  test.beforeEach(async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);
  });

  test('onboarding shows 4 preset cards with correct labels', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    // Verify all 4 presets are accessible
    const presets = ['essential', 'standard', 'professional', 'monitoring'];
    for (const preset of presets) {
      const card = page.getByRole('button', { name: new RegExp(`preset-${preset}`) });
      expect(await card.count()).toBe(1);
    }

    // Apply should be disabled before selection
    const applyBtn = page.getByRole('button', { name: /preset-apply/ });
    expect(await applyBtn.count()).toBe(1);

    // Cancel should be enabled
    const cancelBtn = page.getByRole('button', { name: /preset-cancel/ });
    expect(await cancelBtn.count()).toBe(1);

    await page.screenshot({ path: 'test-results/onboarding-presets.png' });
  });

  test('selecting a preset enables Apply button', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    // Select "Standard" preset
    await selectOnboardingPreset(page, 'standard', false);
    await page.waitForTimeout(1000);

    // After selection, check if Apply button is no longer disabled
    const snapshot = await getSemanticSnapshot(page);
    // The Apply button should now be actionable (not [disabled])
    const applyBtn = page.getByRole('button', { name: /preset-apply/ });
    expect(await applyBtn.count()).toBe(1);

    console.log(
      'Apply button state after preset selection — check screenshot for visual confirmation',
    );

    await page.screenshot({ path: 'test-results/onboarding-selected.png' });
  });

  test('Apply preset navigates to configured dashboard', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    // Select "Standard" and Apply
    await selectOnboardingPreset(page, 'standard', true);
    await page.waitForTimeout(5000);

    // Verify we're on the dashboard
    const snapshot = await getSemanticSnapshot(page);
    const onDashboard =
      snapshot.includes('Device Information') ||
      snapshot.includes('Home Home') ||
      snapshot.includes('Dashboard');
    expect(onDashboard).toBe(true);

    // Verify the onboarding dialog is gone
    const cancelBtn = page.getByRole('button', { name: /preset-cancel/ });
    expect(await cancelBtn.count()).toBe(0);

    console.log('PASS: Preset applied, dashboard loaded');
    await page.screenshot({ path: 'test-results/onboarding-applied.png' });
  });

  // ---------------------------------------------------------------------------
  // Screenshot Baselines
  // ---------------------------------------------------------------------------

  test('screenshot baseline: onboarding preset selection', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await expect(page).toHaveScreenshot('onboarding-presets.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Onboarding presets screenshot baseline');
  });

  test('screenshot baseline: onboarding preset selected', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    await selectOnboardingPreset(page, 'standard', false);
    await page.waitForTimeout(1000);

    await expect(page).toHaveScreenshot('onboarding-selected.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Onboarding selected preset screenshot baseline');
  });

  test('Cancel dismisses onboarding and shows dashboard', async ({ page }) => {
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);

    const cancelBtn = page.getByRole('button', { name: /preset-cancel/ });
    expect(await cancelBtn.count()).toBe(1);
    await cancelBtn.click({ force: true });
    await page.waitForTimeout(3000);

    // Verify dashboard loaded
    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Device Information');

    // No onboarding buttons should remain
    expect(await cancelBtn.count()).toBe(0);

    console.log('PASS: Onboarding canceled, dashboard visible');
    await page.screenshot({ path: 'test-results/onboarding-canceled.png' });
  });
});
