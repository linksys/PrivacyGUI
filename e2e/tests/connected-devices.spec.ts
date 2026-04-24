import { test, expect } from '@playwright/test';
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
 * Connected Devices page tests.
 *
 * Mock data: 3 devices
 *   1. desktop-pc   — wired, active,  192.168.1.100
 *   2. smartphone   — wifi 5GHz, active, 192.168.1.101
 *   3. tablet       — wifi 2.4GHz, inactive, 192.168.1.102
 */

async function navigateToDevices(page: import('@playwright/test').Page) {
  await navigateToPage(page, 'uspDeviceList', /menu-devices/);
}

test.describe('Connected Devices', () => {
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

  test('device list renders all 3 fixture devices', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);

    // All 3 device hostnames should appear
    expect(snapshot).toContain('desktop-pc');
    expect(snapshot).toContain('smartphone');
    expect(snapshot).toContain('tablet');

    console.log('PASS: All 3 fixture devices rendered');
  });

  test('device list shows IP addresses', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);

    expect(snapshot).toContain('192.168.1.100');
    expect(snapshot).toContain('192.168.1.101');
    expect(snapshot).toContain('192.168.1.102');

    console.log('PASS: All 3 device IPs rendered');
  });

  test('device list shows device count', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);

    // Count display: "filtered / total" — all 3 devices visible
    expect(snapshot).toContain('3 / 3');

    console.log('PASS: Device count 3 / 3 displayed');
  });

  test('device list has search bar', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    // Search input with hint text
    const searchInput = page.getByRole('textbox', { name: /search/i });
    const count = await searchInput.count();

    // If semantic label not available, try placeholder text
    if (count === 0) {
      const snapshot = await getSemanticSnapshot(page);
      const hasSearch = snapshot.toLowerCase().includes('search');
      expect(hasSearch).toBe(true);
      console.log('PASS: Search functionality present (detected via snapshot)');
    } else {
      expect(count).toBe(1);
      console.log('PASS: Search input accessible via getByRole');
    }
  });

  test('clicking a device navigates to detail view', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    // Click on the desktop-pc device tile
    const deviceTile = page.getByText('desktop-pc');
    expect(await deviceTile.count()).toBeGreaterThanOrEqual(1);
    await deviceTile.first().click({ force: true });
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);

    // Device detail should show MAC, IP, and connection info
    expect(snapshot).toContain('Device Detail');
    expect(snapshot).toContain('AA:BB:CC:11:22:33');
    expect(snapshot).toContain('192.168.1.100');

    console.log('PASS: Device detail view loaded for desktop-pc');
  });

  test('device detail shows connection type Ethernet for wired device', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    // Navigate to desktop-pc (wired device)
    const deviceTile = page.getByText('desktop-pc');
    await deviceTile.first().click({ force: true });
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);

    expect(snapshot).toContain('Ethernet');
    expect(snapshot).toContain('Connection');

    console.log('PASS: Wired device shows Ethernet connection type');
  });

  test('device detail shows WiFi info for wireless device', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    // Navigate to smartphone (WiFi device)
    const deviceTile = page.getByText('smartphone');
    await deviceTile.first().click({ force: true });
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);

    expect(snapshot).toContain('Device Detail');
    expect(snapshot).toContain('11:22:33:44:55:66');
    expect(snapshot).toContain('WiFi');

    console.log('PASS: WiFi device shows wireless connection info');
  });

  test('device detail shows DHCP reservation section', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    const deviceTile = page.getByText('desktop-pc');
    await deviceTile.first().click({ force: true });
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);

    expect(snapshot).toContain('DHCP Reservation');

    // Should show either "Reserved" + "Release" or "Not Reserved" + "Reserve"
    const hasReserved = snapshot.includes('Reserved');
    expect(hasReserved).toBe(true);

    console.log('PASS: DHCP Reservation section present');
  });

  test('device detail Back button returns to device list', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    // Go to detail
    const deviceTile = page.getByText('desktop-pc');
    await deviceTile.first().click({ force: true });
    await page.waitForTimeout(3000);

    let snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Device Detail');

    // Click back
    await clickBack(page);
    await page.waitForTimeout(3000);

    snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Devices');
    // Should see device list again
    expect(snapshot).toContain('desktop-pc');

    console.log('PASS: Back from detail returns to device list');
  });

  test('page title shows Devices and screenshot baseline', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Devices');

    await expect(page).toHaveScreenshot('devices-list-default.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Devices page title and screenshot baseline');
  });

  test('device detail screenshot baseline (wired)', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    const deviceTile = page.getByText('desktop-pc');
    await deviceTile.first().click({ force: true });
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Device Detail');

    await expect(page).toHaveScreenshot('device-detail-wired.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Device detail (wired) screenshot baseline');
  });

  test('device detail screenshot baseline (wireless)', async ({ page }) => {
    await navigateToDevices(page);
    await page.waitForTimeout(3000);

    const deviceTile = page.getByText('smartphone');
    await deviceTile.first().click({ force: true });
    await page.waitForTimeout(3000);

    const snapshot = await getSemanticSnapshot(page);
    expect(snapshot).toContain('Device Detail');
    expect(snapshot).toContain('WiFi');

    await expect(page).toHaveScreenshot('device-detail-wireless.png', {
      maxDiffPixelRatio: 0.01,
    });

    console.log('PASS: Device detail (wireless) screenshot baseline');
  });
});
