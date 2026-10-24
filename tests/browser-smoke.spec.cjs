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
