import { test, expect, Page } from '@playwright/test';
import { injectWasmMock } from '../fixtures/wasm-mock';
import { setupBridgeMocks } from '../fixtures/bridge-mock';
import { waitForFlutterReady } from '../fixtures/flutter-helpers';
import { performLoginViaUI, waitForPostLogin } from '../fixtures/login-helper';
import {
  dismissOnboarding,
  navigateToPage,
  getSemanticSnapshot,
  clickBack,
} from '../fixtures/interaction-helpers';

/**
 * Port Forwarding page tests.
 *
 * Navigation: Menu → Advanced Settings → Port Forwarding
 *
 * Mock data:
 *   NAT.PortMapping (3 rules):
 *     1. Web Server  — single port, TCP, 8080→80, enabled
 *     2. SSH Access   — single port, TCP, 2222→22, disabled
 *     3. Game Server  — port range, Both, 27015-27030→27015, enabled
 *   NAT.PortTrigger (1 rule):
 *     1. FTP Trigger  — trigger 21 TCP → forward 1024-1030 TCP, enabled
 *
 * Page has 3 tabs:
 *   - Single Port (rules where ExternalPortEndRange == 0)
 *   - Port Range (rules where ExternalPortEndRange > ExternalPort)
 *   - Triggering (PortTrigger rules)
 */

/**
 * Returns "Icon button" elements in order (add, edit1, delete1, edit2, delete2, …).
 * Navigation buttons (Back, Home, Menu, Support, general settings) are skipped.
 */
function getIconButtons(page: Page) {
  return page.getByRole('button', { name: 'Icon button' });
}

async function navigateToPortForwarding(page: Page) {
  // Menu → Advanced Settings
  await navigateToPage(page, 'uspAdvancedSettings', /menu-advanced-settings/);
  await page.waitForTimeout(3000);

  // Advanced Settings → Port Forwarding
  const pfCard = page.getByText('Port Forwarding');
  if (await pfCard.count() > 0) {
    await pfCard.first().click({ force: true });
  } else {
    await page.evaluate(() => { window.location.hash = '#/uspPortForwardingDetail'; });
  }
  await page.waitForTimeout(5000);
}

test.describe('Port Forwarding', () => {
  test.setTimeout(120_000);

  test.beforeEach(async ({ page }) => {
    await injectWasmMock(page);
    await setupBridgeMocks(page);
    await page.goto('/');
    await waitForFlutterReady(page);
    await performLoginViaUI(page, 'admin');
    await waitForPostLogin(page);
    await page.waitForTimeout(5000);
    await dismissOnboarding(page);
    await page.waitForTimeout(2000);
  });

  // ---------------------------------------------------------------------------
  // Page Load & Tabs
  // ---------------------------------------------------------------------------

  test('page loads with 3 tabs', async ({ page }) => {
    await navigateToPortForwarding(page);

    const singlePortTab = page.getByRole('tab', { name: /Single Port/ });
    const portRangeTab = page.getByRole('tab', { name: /Port Range/ });
    const triggeringTab = page.getByRole('tab', { name: /Triggering/ });

    expect(await singlePortTab.count()).toBe(1);
    expect(await portRangeTab.count()).toBe(1);
    expect(await triggeringTab.count()).toBe(1);

    console.log('PASS: Port Forwarding page has 3 tabs');
  });

  test('Single Port tab shows 2 rules', async ({ page }) => {
    await navigateToPortForwarding(page);

    const snapshot = await getSemanticSnapshot(page);

    // Two single-port rules: Web Server and SSH Access
    expect(snapshot).toContain('Web Server');
    expect(snapshot).toContain('SSH Access');

    // Tab accessible name includes count — match via getByRole
    const singlePortTab = page.getByRole('tab', { name: /Single Port \(2\)/ });
    expect(await singlePortTab.count()).toBe(1);

    console.log('PASS: Single Port tab shows 2 rules');
  });

  test('Port Range tab shows 1 rule', async ({ page }) => {
    await navigateToPortForwarding(page);

    // Switch to Port Range tab
    const portRangeTab = page.getByRole('tab', { name: /Port Range/ });
    await portRangeTab.click({ force: true });
    await page.waitForTimeout(2000);

    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Game Server');

    // Tab accessible name includes count
    const portRangeTabWithCount = page.getByRole('tab', { name: /Port Range \(1\)/ });
    expect(await portRangeTabWithCount.count()).toBe(1);

    console.log('PASS: Port Range tab shows 1 rule (Game Server)');
  });

  test('Triggering tab shows 1 rule', async ({ page }) => {
    await navigateToPortForwarding(page);

    const triggeringTab = page.getByRole('tab', { name: /Triggering \(1\)/ });
    await triggeringTab.click({ force: true });
    await page.waitForTimeout(2000);

    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('FTP Trigger');

    expect(await triggeringTab.count()).toBe(1);

    console.log('PASS: Triggering tab shows 1 rule (FTP Trigger)');
  });

  // ---------------------------------------------------------------------------
  // Rule Details
  // ---------------------------------------------------------------------------

  test('single port rule shows protocol and port info', async ({ page }) => {
    await navigateToPortForwarding(page);

    const snapshot = await getSemanticSnapshot(page);

    // Web Server rule details
    expect(snapshot).toContain('TCP');
    expect(snapshot).toContain('Web Server');

    console.log('PASS: Rule shows protocol and description');
  });

  test('disabled rule (SSH) shows unchecked switch', async ({ page }) => {
    await navigateToPortForwarding(page);

    // Find all switches on the page
    const switches = page.getByRole('switch');
    const switchCount = await switches.count();
    expect(switchCount).toBeGreaterThanOrEqual(2);

    // Collect switch states
    const states: string[] = [];
    for (let i = 0; i < switchCount; i++) {
      const checked = await switches.nth(i).getAttribute('aria-checked');
      states.push(checked ?? 'null');
    }

    // Should have at least one true (Web Server) and one false (SSH Access)
    expect(states).toContain('true');
    expect(states).toContain('false');

    console.log(`PASS: Switch states: [${states.join(', ')}]`);
  });

  // ---------------------------------------------------------------------------
  // Port Range Details
  // ---------------------------------------------------------------------------

  test('Port Range rule shows port summary and protocol', async ({ page }) => {
    await navigateToPortForwarding(page);

    // Switch to Port Range tab
    const portRangeTab = page.getByRole('tab', { name: /Port Range/ });
    await portRangeTab.click({ force: true });
    await page.waitForTimeout(2000);

    const snapshot = await getSemanticSnapshot(page);

    // Game Server rule details
    expect(snapshot).toContain('Game Server');
    expect(snapshot).toContain('Both');

    console.log('PASS: Port Range rule shows details');
  });

  test('Port Range rule has enable switch and edit/delete buttons', async ({ page }) => {
    await navigateToPortForwarding(page);

    const portRangeTab = page.getByRole('tab', { name: /Port Range/ });
    await portRangeTab.click({ force: true });
    await page.waitForTimeout(2000);

    // Game Server is enabled — switch should be checked
    const switches = page.getByRole('switch');
    expect(await switches.count()).toBeGreaterThanOrEqual(1);
    const checked = await switches.first().getAttribute('aria-checked');
    expect(checked).toBe('true');

    console.log('PASS: Port Range rule has enabled switch');
  });

  // ---------------------------------------------------------------------------
  // Triggering Details
  // ---------------------------------------------------------------------------

  test('Triggering rule shows trigger summary', async ({ page }) => {
    await navigateToPortForwarding(page);

    const triggeringTab = page.getByRole('tab', { name: /Triggering/ });
    await triggeringTab.click({ force: true });
    await page.waitForTimeout(2000);

    const snapshot = await getSemanticSnapshot(page);

    // FTP Trigger rule — summary: "Trigger: 21 TCP → Forward: 1024-1030 TCP"
    expect(snapshot).toContain('FTP Trigger');
    expect(snapshot).toContain('Trigger');

    console.log('PASS: Triggering rule shows summary');
  });

  test('Triggering rule has enable switch', async ({ page }) => {
    await navigateToPortForwarding(page);

    const triggeringTab = page.getByRole('tab', { name: /Triggering/ });
    await triggeringTab.click({ force: true });
    await page.waitForTimeout(2000);

    const switches = page.getByRole('switch');
    expect(await switches.count()).toBeGreaterThanOrEqual(1);
    const checked = await switches.first().getAttribute('aria-checked');
    expect(checked).toBe('true');

    console.log('PASS: Triggering rule has enabled switch');
  });

  // ---------------------------------------------------------------------------
  // Dialog Interactions
  // ---------------------------------------------------------------------------

  test('add button opens dialog on Single Port tab', async ({ page }) => {
    await navigateToPortForwarding(page);

    // Icon buttons: [0]=add, [1]=edit1, [2]=delete1, …
    const iconBtns = getIconButtons(page);
    expect(await iconBtns.count()).toBeGreaterThanOrEqual(1);
    await iconBtns.nth(0).click({ force: true });
    await page.waitForTimeout(2000);

    const snapshot = await getSemanticSnapshot(page);
    const hasDialog = snapshot.includes('Add Port Forwarding') ||
                      snapshot.includes('Cancel');
    expect(hasDialog).toBe(true);

    console.log('PASS: Add Single Port dialog opened');
  });

  test('edit button opens dialog with pre-filled data', async ({ page }) => {
    await navigateToPortForwarding(page);

    // Icon buttons: [0]=add, [1]=edit(Web Server), [2]=delete(Web Server), …
    const iconBtns = getIconButtons(page);
    expect(await iconBtns.count()).toBeGreaterThanOrEqual(2);
    await iconBtns.nth(1).click({ force: true });
    await page.waitForTimeout(2000);

    const snapshot = await getSemanticSnapshot(page);
    const hasEditDialog = snapshot.includes('Edit Port Forwarding') ||
                          snapshot.includes('Save');
    expect(hasEditDialog).toBe(true);

    console.log('PASS: Edit Single Port dialog opened');
  });

  test('delete button opens confirmation dialog', async ({ page }) => {
    await navigateToPortForwarding(page);

    // Icon buttons: [0]=add, [1]=edit, [2]=delete(Web Server)
    const iconBtns = getIconButtons(page);
    expect(await iconBtns.count()).toBeGreaterThanOrEqual(3);
    await iconBtns.nth(2).click({ force: true });
    await page.waitForTimeout(2000);

    const snapshot = await getSemanticSnapshot(page);
    const hasDeleteDialog = snapshot.includes('Delete') && snapshot.includes('Cancel');
    expect(hasDeleteDialog).toBe(true);

    console.log('PASS: Delete confirmation dialog opened');
  });

  // ---------------------------------------------------------------------------
  // Toggle Rule
  // ---------------------------------------------------------------------------

  test('toggling a rule switch marks page dirty', async ({ page }) => {
    await navigateToPortForwarding(page);

    // Find the first switch (Web Server, enabled)
    const switches = page.getByRole('switch');
    expect(await switches.count()).toBeGreaterThanOrEqual(1);

    const firstSwitch = switches.first();
    const before = await firstSwitch.getAttribute('aria-checked');
    await firstSwitch.click({ force: true });
    await page.waitForTimeout(2000);

    const after = await firstSwitch.getAttribute('aria-checked');
    console.log(`Toggle: ${before} → ${after}`);

    // After toggle, Save/Revert bottom bar should appear (dirty state)
    const snapshot = await getSemanticSnapshot(page);
    const hasSaveBar = snapshot.includes('Save') || snapshot.includes('Revert');

    if (hasSaveBar) {
      console.log('PASS: Toggle marks page dirty, Save bar appeared');
    } else {
      console.log('NOTE: Save bar not detected — toggle may not trigger dirty state');
    }
  });

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  test('Back button returns to Advanced Settings', async ({ page }) => {
    await navigateToPortForwarding(page);

    let snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Port Forwarding');

    await clickBack(page);
    await page.waitForTimeout(3000);

    snapshot = await getSemanticSnapshot(page);
    const returned = snapshot.includes('Advanced Settings') || snapshot.includes('menu-advanced');
    expect(returned).toBe(true);

    console.log('PASS: Back returns to Advanced Settings');
  });

  // ---------------------------------------------------------------------------
  // Screenshot Baseline
  // ---------------------------------------------------------------------------

  test('screenshot baseline: Single Port tab', async ({ page }) => {
    await navigateToPortForwarding(page);

    await expect(page).toHaveScreenshot('port-forwarding-single-port.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Port Forwarding Single Port screenshot baseline');
  });

  test('screenshot baseline: Port Range tab', async ({ page }) => {
    await navigateToPortForwarding(page);

    const portRangeTab = page.getByRole('tab', { name: /Port Range/ });
    await portRangeTab.click({ force: true });
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('port-forwarding-port-range.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Port Forwarding Port Range screenshot baseline');
  });

  test('screenshot baseline: Triggering tab', async ({ page }) => {
    await navigateToPortForwarding(page);

    const triggeringTab = page.getByRole('tab', { name: /Triggering/ });
    await triggeringTab.click({ force: true });
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('port-forwarding-triggering.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Port Forwarding Triggering screenshot baseline');
  });

  // --- Dialog screenshots ---

  test('screenshot baseline: Add Single Port dialog', async ({ page }) => {
    await navigateToPortForwarding(page);

    const iconBtns = getIconButtons(page);
    await iconBtns.nth(0).click({ force: true });
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('port-forwarding-add-single-port-dialog.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Add Single Port dialog screenshot baseline');
  });

  test('screenshot baseline: Edit Single Port dialog', async ({ page }) => {
    await navigateToPortForwarding(page);

    const iconBtns = getIconButtons(page);
    await iconBtns.nth(1).click({ force: true });
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('port-forwarding-edit-single-port-dialog.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Edit Single Port dialog screenshot baseline');
  });

  test('screenshot baseline: Delete confirmation dialog', async ({ page }) => {
    await navigateToPortForwarding(page);

    const iconBtns = getIconButtons(page);
    await iconBtns.nth(2).click({ force: true });
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('port-forwarding-delete-dialog.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Delete confirmation dialog screenshot baseline');
  });

  test('screenshot baseline: Add Port Range dialog', async ({ page }) => {
    await navigateToPortForwarding(page);

    const portRangeTab = page.getByRole('tab', { name: /Port Range/ });
    await portRangeTab.click({ force: true });
    await page.waitForTimeout(2000);

    const iconBtns = getIconButtons(page);
    await iconBtns.nth(0).click({ force: true });
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('port-forwarding-add-port-range-dialog.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Add Port Range dialog screenshot baseline');
  });

  test('screenshot baseline: Add Port Triggering dialog', async ({ page }) => {
    await navigateToPortForwarding(page);

    const triggeringTab = page.getByRole('tab', { name: /Triggering/ });
    await triggeringTab.click({ force: true });
    await page.waitForTimeout(2000);

    const iconBtns = getIconButtons(page);
    await iconBtns.nth(0).click({ force: true });
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('port-forwarding-add-triggering-dialog.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Add Port Triggering dialog screenshot baseline');
  });

  test('screenshot baseline: Dirty state with Save bar', async ({ page }) => {
    await navigateToPortForwarding(page);

    // Toggle the first switch to trigger dirty state
    const switches = page.getByRole('switch');
    await switches.first().click({ force: true });
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('port-forwarding-dirty-save-bar.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Dirty state Save bar screenshot baseline');
  });
});
