import { test, expect } from '@playwright/test';

test.describe('Page Loading', () => {
  test('homepage loads correctly', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/GadgetCloud/);
    await expect(page.locator('.hero h1')).toContainText('Your Gadgets, Your Cloud');
    await expect(page.locator('.header .logo img')).toBeVisible();
  });

  test('about page loads correctly', async ({ page }) => {
    await page.goto('/about_us.html');
    await expect(page).toHaveTitle(/About Us/);
    await expect(page.locator('.page-header h1')).toContainText('About Us');
  });

  test('products page loads correctly', async ({ page }) => {
    await page.goto('/products.html');
    await expect(page).toHaveTitle(/Products/);
    await expect(page.locator('.page-header h1')).toContainText('Our Products');
  });

  test('services page loads correctly', async ({ page }) => {
    await page.goto('/services.html');
    await expect(page).toHaveTitle(/Services/);
    await expect(page.locator('.page-header h1')).toContainText('Our Services');
  });

  test('contact page loads correctly', async ({ page }) => {
    await page.goto('/contact_us.html');
    await expect(page).toHaveTitle(/Contact Us/);
    await expect(page.locator('.page-header h1')).toContainText('Contact Us');
    await expect(page.locator('#contactForm')).toBeVisible();
  });
});

test.describe('Navigation', () => {
  test('header navigation links work', async ({ page, isMobile }) => {
    await page.goto('/');

    // Helper to open mobile menu if needed
    const openMenuIfMobile = async () => {
      if (isMobile) {
        const navToggle = page.locator('.nav-toggle');
        if (await navToggle.isVisible()) {
          await navToggle.click();
          await page.waitForTimeout(300); // Wait for menu animation
        }
      }
    };

    await openMenuIfMobile();
    await page.click('.nav-menu a[href="about_us.html"]');
    await expect(page).toHaveURL(/about_us\.html/);

    await openMenuIfMobile();
    await page.click('.nav-menu a[href="products.html"]');
    await expect(page).toHaveURL(/products\.html/);

    await openMenuIfMobile();
    await page.click('.nav-menu a[href="services.html"]');
    await expect(page).toHaveURL(/services\.html/);

    await openMenuIfMobile();
    await page.click('.nav-menu a[href="contact_us.html"]');
    await expect(page).toHaveURL(/contact_us\.html/);

    await openMenuIfMobile();
    await page.click('.nav-menu a[href="index.html"]');
    await expect(page).toHaveURL(/index\.html|\/$/);
  });

  test('logo links to homepage', async ({ page }) => {
    await page.goto('/about_us.html');
    await page.click('.header .logo');
    await expect(page).toHaveURL(/index\.html|\/$/);
  });
});

test.describe('Logo Display', () => {
  test('logo is visible and properly sized', async ({ page }) => {
    await page.goto('/');
    const logo = page.locator('.header .logo img');
    await expect(logo).toBeVisible();

    const box = await logo.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.height).toBeGreaterThanOrEqual(40);
  });
});

test.describe('Visual Elements', () => {
  test('hero section displays correctly', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('.hero')).toBeVisible();
    await expect(page.locator('.hero .btn-primary')).toBeVisible();
    await expect(page.locator('.hero .btn-secondary')).toBeVisible();
  });

  test('feature cards are visible', async ({ page }) => {
    await page.goto('/');
    const featureCards = page.locator('.feature-card');
    await expect(featureCards).toHaveCount(4);
  });

  test('footer is visible', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('.footer')).toBeVisible();
  });
});
