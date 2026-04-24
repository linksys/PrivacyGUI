import { Page, expect } from '@playwright/test';

/**
 * Shared interaction helpers for Layer 3 E2E tests.
 *
 * All helpers operate via Flutter's semantics tree (flt-semantics-host).
 * Flutter CanvasKit renders on <canvas> — DOM form elements only exist
 * as semantic overlays when SemanticsBinding.ensureSemantics() is active.
 */

/**
 * Dismiss the onboarding dialog by clicking Cancel.
 * No-op if onboarding is not shown.
 */
export async function dismissOnboarding(page: Page): Promise<boolean> {
  const cancelBtn = page.getByRole('button', { name: /preset-cancel/ });
  if (await cancelBtn.count() > 0) {
    await cancelBtn.click({ force: true });
    await page.waitForTimeout(3000);
    return true;
  }
  console.log('[dismissOnboarding] No onboarding dialog found');
  return false;
}

/**
 * Select an onboarding preset card and optionally click Apply.
 * @param preset - One of: 'essential', 'standard', 'professional', 'monitoring'
 * @param apply - If true, also click Apply (default: false)
 */
export async function selectOnboardingPreset(
  page: Page,
  preset: string,
  apply: boolean = false,
): Promise<void> {
  const card = page.getByRole('button', { name: new RegExp(`preset-${preset}`) });
  expect(await card.count()).toBe(1);
  await card.click({ force: true });
  await page.waitForTimeout(1000);

  if (apply) {
    const applyBtn = page.getByRole('button', { name: /preset-apply/ });
    await applyBtn.click({ force: true });
    await page.waitForTimeout(3000);
  }
}

/**
 * Navigate to a page via bottom nav Menu → card click.
 * Falls back to direct URL hash if semantic navigation fails.
 */
export async function navigateToPage(
  page: Page,
  route: string,
  menuCardPattern?: RegExp,
): Promise<void> {
  // Step 1: Click Menu in bottom nav
  const menuNav = page.getByRole('button', { name: /^Menu Menu$/ });
  if (await menuNav.count() > 0) {
    await menuNav.click({ force: true });
    await page.waitForTimeout(3000);
  } else {
    await page.evaluate(() => { window.location.hash = '#/uspMenu'; });
    await page.waitForTimeout(3000);
  }

  // Step 2: Click the target card on Menu page (or use URL)
  if (menuCardPattern) {
    const card = page.getByRole('button', { name: menuCardPattern });
    if (await card.count() > 0) {
      await card.click({ force: true });
      await page.waitForTimeout(5000);
      return;
    }
  }

  // Fallback: direct hash navigation
  await page.evaluate((r) => { window.location.hash = `#/${r}`; }, route);
  await page.waitForTimeout(5000);
}

/**
 * Navigate to WiFi Settings via Menu → WiFi card.
 */
export async function navigateToWifi(page: Page): Promise<void> {
  await navigateToPage(page, 'uspWifiSettings', /menu-wifi-settings/);
}

/**
 * Fill a text field via the Flutter dialog pattern:
 * button click → dialog opens → find input → fill() → OK.
 *
 * @param buttonPattern - regex to find the button that opens the edit dialog
 * @param value - the value to fill in
 * @param confirm - if true, click OK (default: true)
 * @returns the input value after fill
 */
export async function fillDialogTextField(
  page: Page,
  buttonPattern: RegExp,
  value: string,
  confirm: boolean = true,
): Promise<string> {
  // Click the button to open edit dialog
  const button = page.getByRole('button', { name: buttonPattern });
  expect(await button.count()).toBe(1);
  await button.click({ force: true });
  await page.waitForTimeout(2000);

  // Find the first non-disabled text input in the dialog
  const input = page.locator('input[type="text"]:not([disabled])').first();
  expect(await input.count()).toBe(1);

  // Fill the value
  await input.fill(value, { force: true });
  await input.evaluate((el: HTMLInputElement, val: string) => {
    el.value = val;
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }, value);
  await page.waitForTimeout(500);

  const newValue = await input.evaluate((el: HTMLInputElement) => el.value);

  if (confirm) {
    const okBtn = page.getByRole('button', { name: 'OK' });
    if (await okBtn.count() > 0) {
      await okBtn.click({ force: true });
      await page.waitForTimeout(2000);
    }
  }

  return newValue;
}

/**
 * Toggle a switch widget and verify the state changed.
 *
 * For merged semantics nodes (e.g., WiFi tile row = label + switch),
 * Playwright's default click() targets the node center, which may land
 * on the label area instead of the switch widget. Use `clickTrailing`
 * to click the right edge of the bounding box where the switch lives.
 *
 * @param switchLocator - Playwright locator for the switch
 * @param clickTrailing - click right edge instead of center (for merged tiles)
 * @returns { before, after } aria-checked states
 */
export async function toggleSwitch(
  page: Page,
  switchLocator: ReturnType<Page['locator']>,
  clickTrailing: boolean = false,
): Promise<{ before: string | null; after: string | null }> {
  const before = await switchLocator.first().getAttribute('aria-checked');

  if (clickTrailing) {
    const box = await switchLocator.boundingBox();
    if (box) {
      // Click near the right edge where the trailing switch widget lives
      await page.mouse.click(box.x + box.width - 20, box.y + box.height / 2);
    } else {
      await switchLocator.click({ force: true });
    }
  } else {
    await switchLocator.click({ force: true });
  }

  await page.waitForTimeout(1500);
  // After toggle, Flutter may briefly render both old and new semantics nodes.
  // Use .first() to avoid strict mode violation from duplicate elements.
  const after = await switchLocator.first().getAttribute('aria-checked');
  return { before, after };
}

/**
 * Click the Back button in the page header.
 *
 * Flutter renders the Back button inside a banner element.
 * Uses bounding box coordinates for reliable click targeting.
 * Fallback: browser back navigation (may cause GoRouter issues).
 */
export async function clickBack(page: Page): Promise<void> {
  const backBtn = page.getByRole('button', { name: 'Back' });
  if ((await backBtn.count()) > 0) {
    const box = await backBtn.first().boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    } else {
      await backBtn.first().click({ force: true });
    }
  } else {
    console.log('[clickBack] Back button not found, using browser history.back()');
    await page.evaluate(() => window.history.back());
  }
  await page.waitForTimeout(2000);
}

/**
 * Expect the dirty guard dialog to appear with Discard/Go Back options.
 *
 * Flutter renders nested semantics for dialog buttons:
 *   outer: button "unsaved-discard" → inner: button "Discard changes"
 *   outer: button "unsaved-go-back" → inner: button "Go back"
 * Use outer labels for detection, inner labels for clicking.
 *
 * @returns true if dirty guard appeared
 */
export async function expectDirtyGuard(page: Page): Promise<boolean> {
  const discardBtn = page.getByRole('button', { name: /unsaved-discard/ });
  const goBackBtn = page.getByRole('button', { name: /unsaved-go-back/ });

  const appeared = (await discardBtn.count()) > 0;
  if (appeared) {
    expect(await goBackBtn.count()).toBe(1);
  }
  return appeared;
}

/**
 * Click the Discard button in the dirty guard dialog.
 *
 * Flutter renders nested semantics for dialog buttons:
 *   outer: button "unsaved-discard"  (Semantics wrapper, no onTap)
 *   inner: button "Discard changes"  (TextButton, has onTap)
 *
 * Playwright .click({ force: true }) dispatches a DOM click on the
 * flt-semantics element, which triggers SemanticsAction.tap — but on
 * the outer wrapper that has no handler. To reach the real TextButton,
 * use page.mouse.click() at the inner button's bounding box center.
 * This sends a pointer event through Flutter's PointerBinding → canvas
 * → GestureDetector.onTap, bypassing the semantics layer entirely.
 */
export async function clickDirtyGuardDiscard(page: Page): Promise<void> {
  const btn = page.getByRole('button', { name: 'Discard changes' });
  if ((await btn.count()) > 0) {
    const box = await btn.first().boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      await page.waitForTimeout(3000);
      return;
    }
  }
  // Fallback: force click (may not trigger TextButton onTap in headless CanvasKit)
  await btn.first().click({ force: true });
  await page.waitForTimeout(3000);
}

/**
 * Click the Go Back button in the dirty guard dialog.
 * Uses bounding box coordinate click to bypass semantics layer.
 * See clickDirtyGuardDiscard for detailed explanation.
 */
export async function clickDirtyGuardGoBack(page: Page): Promise<void> {
  const btn = page.getByRole('button', { name: 'Go back' });
  if ((await btn.count()) > 0) {
    const box = await btn.first().boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      await page.waitForTimeout(2000);
      return;
    }
  }
  // Fallback: force click
  await btn.first().click({ force: true });
  await page.waitForTimeout(2000);
}

/**
 * Get the full accessibility snapshot of the semantics tree.
 * Useful for debugging and content verification.
 */
export async function getSemanticSnapshot(
  page: Page,
  maxLength: number = 5000,
): Promise<string> {
  const snapshot = await page.locator('flt-semantics-host').ariaSnapshot();
  return snapshot.substring(0, maxLength);
}
