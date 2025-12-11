import { test, expect, Page } from '@playwright/test';

// Helper to open mobile nav menu if on mobile viewport
async function openMobileMenuIfNeeded(page: Page) {
  const navToggle = page.locator('.nav-toggle');
  const isVisible = await navToggle.isVisible();
  if (isVisible) {
    await navToggle.click();
    await expect(page.locator('.nav-menu')).toHaveClass(/active/);
  }
}

test.describe('Navigation', () => {
  test('main navigation links work', async ({ page }) => {
    await page.goto('/');

    // Open mobile menu if on mobile
    await openMobileMenuIfNeeded(page);

    // Click About link
    await page.click('.nav-menu a[href="about_us.html"]');
    await expect(page).toHaveURL(/about_us\.html/);
    await expect(page.locator('h1')).toContainText('About Us');

    // Open mobile menu if on mobile
    await openMobileMenuIfNeeded(page);

    // Click Products link
    await page.click('.nav-menu a[href="products.html"]');
    await expect(page).toHaveURL(/products\.html/);
    await expect(page.locator('h1')).toContainText('Our Products');

    // Open mobile menu if on mobile
    await openMobileMenuIfNeeded(page);

    // Click Services link
    await page.click('.nav-menu a[href="services.html"]');
    await expect(page).toHaveURL(/services\.html/);
    await expect(page.locator('h1')).toContainText('Our Services');

    // Open mobile menu if on mobile
    await openMobileMenuIfNeeded(page);

    // Click Contact link
    await page.click('.nav-menu a[href="contact_us.html"]');
    await expect(page).toHaveURL(/contact_us\.html/);
    await expect(page.locator('h1')).toContainText('Contact Us');

    // Click Home link (logo) - always visible
    await page.click('.header a.logo');
    await expect(page).toHaveURL(/\/(index\.html)?$/);
  });

  test('footer quick links work', async ({ page }) => {
    await page.goto('/');

    // Scroll to footer
    await page.locator('.footer').scrollIntoViewIfNeeded();

    // Test footer links
    const footerLinks = page.locator('.footer-links a');
    const count = await footerLinks.count();

    expect(count).toBeGreaterThan(0);

    // Click About Us in footer
    await page.locator('.footer-links a[href="about_us.html"]').click();
    await expect(page).toHaveURL(/about_us\.html/);
  });

  test('sign in button links to my.gadgetcloud.io', async ({ page }) => {
    await page.goto('/');

    // Open mobile menu if on mobile (sign in may be in nav)
    await openMobileMenuIfNeeded(page);

    const signInLink = page.locator('a[href="https://my.gadgetcloud.io"]').first();
    await expect(signInLink).toBeVisible();
    await expect(signInLink).toHaveAttribute('href', 'https://my.gadgetcloud.io');
  });

  test('active navigation state is correct', async ({ page }) => {
    // Check About page
    await page.goto('/about_us.html');
    await expect(page.locator('.nav-menu a[href="about_us.html"]')).toHaveClass(/active/);

    // Check Products page
    await page.goto('/products.html');
    await expect(page.locator('.nav-menu a[href="products.html"]')).toHaveClass(/active/);

    // Check Services page
    await page.goto('/services.html');
    await expect(page.locator('.nav-menu a[href="services.html"]')).toHaveClass(/active/);

    // Check Contact page
    await page.goto('/contact_us.html');
    await expect(page.locator('.nav-menu a[href="contact_us.html"]')).toHaveClass(/active/);
  });
});

test.describe('CTA Links', () => {
  test('homepage CTA buttons work', async ({ page }) => {
    await page.goto('/');

    // Check Get Started button exists and links correctly
    const ctaButton = page.locator('.hero a.btn-primary, .cta-section a.btn-primary').first();
    await expect(ctaButton).toBeVisible();
  });

  test('error page return home button works', async ({ page }) => {
    await page.goto('/error.html');

    await page.click('a[href="index.html"]');
    await expect(page).toHaveURL(/\/(index\.html)?$/);
  });
});
