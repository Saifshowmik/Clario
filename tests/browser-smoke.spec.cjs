const { test, expect } = require('@playwright/test');

test.beforeEach(async ({ page }) => {
  await page.route('https://cdn.jsdelivr.net/**', route => route.abort());
  await page.route('https://fonts.googleapis.com/**', route => route.abort());
  await page.route('https://fonts.gstatic.com/**', route => route.abort());
  await page.goto('http://127.0.0.1:4173/', { waitUntil: 'domcontentloaded' });
});

test('homepage renders and primary navigation switches views', async ({ page }) => {
  await expect(page.locator('#p-home')).toBeVisible();
  await page.locator('[data-go="decide"]:visible').first().click();
  await expect(page.locator('#p-decide')).toBeVisible();
  await expect(page.locator('#p-home')).toBeHidden();
  await page.locator('[data-go="plans"]:visible').first().click();
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

test('feature studios mount and open from homepage shortcuts', async ({ page }) => {
  const routeIds = ['social', 'travel', 'rewards', 'streaks', 'mind'];
  for (const id of routeIds) {
    await page.locator('#p-home [data-go="' + id + '"]').click();
    await expect(page.locator('#p-' + id), id + ' studio should become visible').toBeVisible();
    await page.locator('[data-go="home"]:visible').first().click();
    await expect(page.locator('#p-home')).toBeVisible();
  }
  await page.locator('#p-home [data-go="acct"]').count().then(async count => {
    if (count) await page.locator('#p-home [data-go="acct"]').click();
    else await page.locator('[data-go="acct"]:visible').first().click();
  });
  await page.locator('#profile-open').click();
  await expect(page.locator('#p-profile')).toBeVisible();
});

test('plans page exposes the approved prices', async ({ page }) => {
  await page.locator('[data-go="plans"]:visible').first().click();
  const plans = page.locator('#p-plans');
  await expect(plans).toContainText('29');
  await expect(plans).toContainText('99');
  await expect(plans).toContainText('1,099');
  await expect(plans).toContainText('199');
  await expect(plans).toContainText('1,999');
  await expect(plans).toContainText('999');
  await expect(plans).toContainText('9,999');
});

test('decision studio validates input and produces a safe ranked result', async ({ page }) => {
  await page.locator('[data-go="decide"]:visible').first().click();
  await page.locator('#go').click();
  await expect(page.locator('#err')).toContainText('at least two options');

  await page.locator('#budget').fill('2000');
  await page.locator('#n0').fill('<script>alert(1)</script>');
  await page.locator('#p0').fill('1000');
  await page.locator('#r0').fill('4.5');
  await page.locator('#n1').fill('Budget option');
  await page.locator('#p1').fill('700');
  await page.locator('#r1').fill('4');
  await page.locator('#n2').fill('Premium option');
  await page.locator('#p2').fill('1900');
  await page.locator('#r2').fill('5');
  await page.locator('#go').click();

  await expect(page.locator('#out')).toContainText('Your best pick');
  await expect(page.locator('#out')).toContainText('Premium option');
  await expect(page.locator('#out script')).toHaveCount(0);
  await expect(page.locator('#out')).toContainText('<script>alert(1)</script>');
});

test('decision studio rejects invalid ratings and negative prices', async ({ page }) => {
  await page.locator('[data-go="decide"]:visible').first().click();
  await page.locator('#n0').fill('Option A');
  await page.locator('#p0').fill('-5');
  await page.locator('#r0').fill('4');
  await page.locator('#n1').fill('Option B');
  await page.locator('#p1').fill('500');
  await page.locator('#r1').fill('6');
  await page.locator('#go').click();
  await expect(page.locator('#err')).toContainText('at least two options');
  await expect(page.locator('#out')).toBeEmpty();
});
