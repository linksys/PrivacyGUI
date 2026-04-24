import { Page } from '@playwright/test';

/**
 * Perform login via Flutter's semantics accessibility layer.
 *
 * Flutter CanvasKit renders everything on a canvas — there are no real DOM
 * form elements. When semantics is enabled (`ensureSemantics()`), Flutter
 * creates a semantics overlay (`flt-semantics-host`) with accessible elements
 * including `<input>` for text fields and clickable nodes for buttons.
 *
 * The working approach:
 *   1. Find the semantics `<input type="password">` (non-disabled)
 *   2. Set its value via DOM + dispatch `input`/`change` events
 *   3. Click the login button's semantics element (triggers SemanticsAction.tap)
 */
export async function performLoginViaUI(
  page: Page,
  password: string = 'admin'
): Promise<boolean> {
  await page.waitForTimeout(2000);

  // Find the non-disabled password input in the semantics tree
  const pwInput = page.locator('input[type="password"]:not([disabled])');
  const pwCount = await pwInput.count();

  if (pwCount === 0) {
    console.log('[login-helper] No active password input found in semantics tree');
    return false;
  }

  console.log(`[login-helper] Found ${pwCount} active password input(s)`);

  // Set the password value via DOM manipulation + event dispatch
  // Flutter's semantics bridge listens for `input` events on these elements
  await pwInput.first().fill(password, { force: true });
  await pwInput.first().evaluate((el: HTMLInputElement, pw: string) => {
    el.value = pw;
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }, password);
  await page.waitForTimeout(500);

  // Click the login button via its semantics label
  const loginBtn = page.locator('[aria-label="login-submit-button"]');
  const btnCount = await loginBtn.count();

  if (btnCount === 0) {
    console.log('[login-helper] No login button found in semantics tree');
    return false;
  }

  console.log('[login-helper] Clicking login button');
  await loginBtn.click({ force: true });
  await page.waitForTimeout(3000);
  return true;
}

/**
 * Wait for the app to navigate past the login page.
 */
export async function waitForPostLogin(
  page: Page,
  timeout: number = 15_000
): Promise<void> {
  try {
    await page.waitForURL('**/usp/**', { timeout });
  } catch {
    await page.waitForTimeout(5000);
  }
}
