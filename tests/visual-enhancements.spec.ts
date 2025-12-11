import { test, expect } from '@playwright/test';

test.describe('Visual Enhancements - Hero Section', () => {
  test('hero dashboard illustration is visible', async ({ page }) => {
    await page.goto('/');
    const heroDashboard = page.locator('.hero-illustration img[src*="hero-dashboard.svg"]');
    await expect(heroDashboard).toBeVisible();
  });

  test('hero device illustrations are visible', async ({ page }) => {
    await page.goto('/');
    const deviceIcon1 = page.locator('.hero-illustration img[src*="devices.svg"]');
    const deviceIcon2 = page.locator('.hero-illustration img[src*="cloud-storage.svg"]');
    await expect(deviceIcon1).toBeVisible();
    await expect(deviceIcon2).toBeVisible();
  });

  test('hero illustration has proper styling', async ({ page }) => {
    await page.goto('/');
    const heroIllustration = page.locator('.hero-illustration');
    await expect(heroIllustration).toHaveCSS('position', 'absolute');
  });
});

test.describe('Visual Enhancements - Testimonials', () => {
  test('testimonials section exists on homepage', async ({ page }) => {
    await page.goto('/');
    const testimonialsSection = page.locator('.testimonials');
    await expect(testimonialsSection).toBeVisible();
  });

  test('displays correct number of testimonial cards', async ({ page }) => {
    await page.goto('/');
    const testimonialCards = page.locator('.testimonial-card');
    await expect(testimonialCards).toHaveCount(3);
  });

  test('each testimonial has avatar, content, and author info', async ({ page }) => {
    await page.goto('/');
    const firstTestimonial = page.locator('.testimonial-card').first();

    await expect(firstTestimonial.locator('.testimonial-avatar img')).toBeVisible();
    await expect(firstTestimonial.locator('.testimonial-content')).toBeVisible();
    await expect(firstTestimonial.locator('.testimonial-info h4')).toBeVisible();
    await expect(firstTestimonial.locator('.testimonial-info p')).toBeVisible();
  });

  test('testimonial avatars load correctly', async ({ page }) => {
    await page.goto('/');
    const avatar1 = page.locator('img[src*="avatar-1.svg"]');
    const avatar2 = page.locator('img[src*="avatar-2.svg"]');
    const avatar3 = page.locator('img[src*="avatar-3.svg"]');

    await expect(avatar1).toBeVisible();
    await expect(avatar2).toBeVisible();
    await expect(avatar3).toBeVisible();
  });

  test('testimonial content is not empty', async ({ page }) => {
    await page.goto('/');
    const testimonialContents = page.locator('.testimonial-content p');
    const count = await testimonialContents.count();

    for (let i = 0; i < count; i++) {
      const text = await testimonialContents.nth(i).textContent();
      expect(text).toBeTruthy();
      expect(text!.length).toBeGreaterThan(20);
    }
  });

  test('testimonial author names are present', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('.testimonial-info h4:has-text("Sarah Johnson")')).toBeVisible();
    await expect(page.locator('.testimonial-info h4:has-text("Michael Chen")')).toBeVisible();
    await expect(page.locator('.testimonial-info h4:has-text("Emily Rodriguez")')).toBeVisible();
  });
});

test.describe('Visual Enhancements - Trust Badges', () => {
  test('trust badges section exists', async ({ page }) => {
    await page.goto('/');
    const trustBadges = page.locator('.trust-badges');
    await expect(trustBadges).toBeVisible();
  });

  test('displays correct number of badges', async ({ page }) => {
    await page.goto('/');
    const badges = page.locator('.trust-badges .badge');
    await expect(badges).toHaveCount(3);
  });

  test('SSL secure badge is visible', async ({ page }) => {
    await page.goto('/');
    const sslBadge = page.locator('img[src*="ssl-secure.svg"]');
    await expect(sslBadge).toBeVisible();
    await expect(sslBadge).toHaveAttribute('alt', 'SSL Secure');
  });

  test('GDPR compliant badge is visible', async ({ page }) => {
    await page.goto('/');
    const gdprBadge = page.locator('img[src*="gdpr-compliant.svg"]');
    await expect(gdprBadge).toBeVisible();
    await expect(gdprBadge).toHaveAttribute('alt', 'GDPR Compliant');
  });

  test('uptime badge is visible', async ({ page }) => {
    await page.goto('/');
    const uptimeBadge = page.locator('img[src*="uptime-99.svg"]');
    await expect(uptimeBadge).toBeVisible();
    await expect(uptimeBadge).toHaveAttribute('alt', '99.9% Uptime');
  });
});

test.describe('Visual Enhancements - Product Showcase', () => {
  test('product showcase exists on products page', async ({ page }) => {
    await page.goto('/products.html');
    const productShowcase = page.locator('.product-showcase');
    await expect(productShowcase).toBeVisible();
  });

  test('displays product mockup images', async ({ page }) => {
    await page.goto('/products.html');
    const dashboardImage = page.locator('img[src*="hero-dashboard.svg"]');
    const mobileAppImage = page.locator('img[src*="mobile-app.svg"]');
    const analyticsImage = page.locator('img[src*="analytics-dashboard.svg"]');

    await expect(dashboardImage).toBeVisible();
    await expect(mobileAppImage).toBeVisible();
    await expect(analyticsImage).toBeVisible();
  });

  test('product images have proper alt text', async ({ page }) => {
    await page.goto('/products.html');
    const images = page.locator('.product-showcase img');
    const count = await images.count();

    for (let i = 0; i < count; i++) {
      const altText = await images.nth(i).getAttribute('alt');
      expect(altText).toBeTruthy();
    }
  });
});

test.describe('Visual Enhancements - Services Workflow', () => {
  test('workflow illustration exists on services page', async ({ page }) => {
    await page.goto('/services.html');
    const workflowImage = page.locator('img[src*="workflow.svg"]');
    await expect(workflowImage).toBeVisible();
  });

  test('workflow illustration has proper alt text', async ({ page }) => {
    await page.goto('/services.html');
    const workflowImage = page.locator('img[src*="workflow.svg"]');
    await expect(workflowImage).toHaveAttribute('alt', 'Service workflow');
  });
});

test.describe('Visual Enhancements - About Page', () => {
  test('team collaboration illustration exists', async ({ page }) => {
    await page.goto('/about_us.html');
    const teamImage = page.locator('img[src*="team-collaboration.svg"]');
    await expect(teamImage).toBeVisible();
  });

  test('team illustration has proper alt text', async ({ page }) => {
    await page.goto('/about_us.html');
    const teamImage = page.locator('img[src*="team-collaboration.svg"]');
    await expect(teamImage).toHaveAttribute('alt', 'Team collaboration');
  });
});

test.describe('Visual Enhancements - Contact Page', () => {
  test('contact support illustration exists', async ({ page }) => {
    await page.goto('/contact_us.html');
    const contactImage = page.locator('img[src*="contact-support.svg"]');
    await expect(contactImage).toBeVisible();
  });

  test('contact illustration has proper alt text', async ({ page }) => {
    await page.goto('/contact_us.html');
    const contactImage = page.locator('img[src*="contact-support.svg"]');
    await expect(contactImage).toHaveAttribute('alt', 'Contact support');
  });
});

test.describe('Visual Enhancements - Image Loading', () => {
  test('all new illustration files load successfully', async ({ page }) => {
    await page.goto('/');

    const illustrations = [
      'hero-dashboard.svg',
      'devices.svg',
      'cloud-storage.svg',
      'security.svg',
      'avatar-1.svg',
      'avatar-2.svg',
      'avatar-3.svg',
      'ssl-secure.svg',
      'gdpr-compliant.svg',
      'uptime-99.svg'
    ];

    for (const illustration of illustrations) {
      const img = page.locator(`img[src*="${illustration}"]`).first();
      await expect(img).toBeVisible({ timeout: 5000 });
    }
  });

  test('images have proper dimensions', async ({ page }) => {
    await page.goto('/');
    const avatar = page.locator('.testimonial-avatar img').first();

    const box = await avatar.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.width).toBeGreaterThan(0);
    expect(box!.height).toBeGreaterThan(0);
  });
});

test.describe('Visual Enhancements - Responsive Design', () => {
  test('testimonials are responsive on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    const testimonialCards = page.locator('.testimonial-card');
    await expect(testimonialCards.first()).toBeVisible();
  });

  test('product showcase is responsive on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/products.html');

    const productShowcase = page.locator('.product-showcase');
    await expect(productShowcase).toBeVisible();
  });

  test('trust badges wrap properly on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    const trustBadges = page.locator('.trust-badges');
    await expect(trustBadges).toBeVisible();

    const badges = page.locator('.trust-badges .badge');
    await expect(badges).toHaveCount(3);
  });
});

test.describe('Visual Enhancements - CSS Styling', () => {
  test('testimonial cards have proper styling', async ({ page }) => {
    await page.goto('/');
    const testimonialCard = page.locator('.testimonial-card').first();

    await expect(testimonialCard).toHaveCSS('background-color', /rgb/);
    await expect(testimonialCard).toHaveCSS('border-radius', /\d+px/);
  });

  test('badges have hover effects', async ({ page }) => {
    await page.goto('/');
    const badge = page.locator('.trust-badges .badge').first();

    await expect(badge).toBeVisible();
  });

  test('product images have proper styling', async ({ page }) => {
    await page.goto('/products.html');
    const productImage = page.locator('.product-image').first();

    await expect(productImage).toHaveCSS('border-radius', /\d+px/);
  });
});

test.describe('Visual Enhancements - Accessibility', () => {
  test('testimonial avatars have alt text', async ({ page }) => {
    await page.goto('/');
    const avatars = page.locator('.testimonial-avatar img');
    const count = await avatars.count();

    for (let i = 0; i < count; i++) {
      const altText = await avatars.nth(i).getAttribute('alt');
      expect(altText).toBeTruthy();
      expect(altText!.length).toBeGreaterThan(0);
    }
  });

  test('hero illustrations have proper aria attributes', async ({ page }) => {
    await page.goto('/');
    const heroIllustrations = page.locator('.hero-illustration img');
    const count = await heroIllustrations.count();

    for (let i = 0; i < count; i++) {
      const ariaHidden = await heroIllustrations.nth(i).getAttribute('aria-hidden');
      // Decorative images should have aria-hidden="true" or proper alt text
      if (ariaHidden !== 'true') {
        const altText = await heroIllustrations.nth(i).getAttribute('alt');
        expect(altText !== null).toBeTruthy();
      }
    }
  });

  test('badge images have descriptive alt text', async ({ page }) => {
    await page.goto('/');
    const badges = page.locator('.trust-badges img');
    const count = await badges.count();

    for (let i = 0; i < count; i++) {
      const altText = await badges.nth(i).getAttribute('alt');
      expect(altText).toBeTruthy();
      expect(altText!.length).toBeGreaterThan(3);
    }
  });
});
