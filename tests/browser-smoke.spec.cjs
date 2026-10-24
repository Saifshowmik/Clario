const { test, expect } = require('@playwright/test');

test.beforeEach(async ({ page }) => {
  await page.route('https://cdn.jsdelivr.net/**', route => route.abort());
  await page.route('https://fonts.googleapis.com/**', route => route.abort());
  await page.route('https://fonts.gstatic.com/**', route => route.abort());
  await page.goto('http://127.0.0.1:4173/', { waitUntil: 'domcontentloaded' });
});

test('homepage renders and primary navigation switches views', async ({ page }) => {
  await expect(page.locator('#p-home')).toBeVisible();
  await page.locator('[data-go="decide"]').first().click();
  await expect(page.locator('#p-decide')).toBeVisible();
  await expect(page.locator('#p-home')).toBeHidden();
  await page.locator('[data-go="plans"]').first().click();
  await expect(page.locator('#p-plans')).toBeVisible();
});

test('language toggle switches between English and Bangla labels', async ({ page }) => {
  const lang = page.locator('#lang');
  await expect(lang).toHaveText('বাংলা');
  await lang.click();
  await expect(lang).toHaveText('English');
  await lang.click();
  await expect(lang).toHaveText('বাংলা');
});

test('mobile viewport keeps navigation controls visible and usable', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const decide = page.locator('nav [data-go="decide"]');
  await expect(decide).toBeVisible();
  await decide.click();
  await expect(page.locator('#p-decide')).toBeVisible();
  await expect(page.locator('#budget')).toBeVisible();
});

test('feature studios mount and open from their navigation controls', async ({ page }) => {
  const routeIds = ['social', 'travel', 'rewards', 'streaks', 'mind'];
  for (const id of routeIds) {
    const pageSection = page.locator('#p-' + id);
    await expect(pageSection, id + ' studio should mount').toHaveCount(1);
    await page.locator('[data-go="' + id + '"]').first().click();
    await expect(pageSection, id + ' studio should become visible').toBeVisible();
  }
  await page.locator('[data-go="acct"]').first().click();
  await page.locator('#profile-open').click();
  await expect(page.locator('#p-profile')).toBeVisible();
});

test('plans page exposes the approved prices', async ({ page }) => {
  await page.locator('[data-go="plans"]').first().click();
  const plans = page.locator('#p-plans');
  await expect(plans).toContainText('29');
  await expect(plans).toContainText('99');
  await expect(plans).toContainText('1,099');
  await expect(plans).toContainText('199');
  await expect(plans).toContainText('1,999');
  await expect(plans).toContainText('999');
  await expect(plans).toContainText('9,999');
});
