import { test, expect } from '@playwright/test';

test.describe('Contact Form', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/contact_us.html');
  });

  test('form fields are present', async ({ page }) => {
    await expect(page.locator('#firstName')).toBeVisible();
    await expect(page.locator('#lastName')).toBeVisible();
    await expect(page.locator('#email')).toBeVisible();
    await expect(page.locator('#subject')).toBeVisible();
    await expect(page.locator('#message')).toBeVisible();
    await expect(page.locator('button[type="submit"]')).toBeVisible();
  });

  test('form has required field validation', async ({ page }) => {
    await page.click('button[type="submit"]');
    const firstName = page.locator('#firstName');
    const isInvalid = await firstName.evaluate((el: HTMLInputElement) => !el.validity.valid);
    expect(isInvalid).toBe(true);
  });

  test('email field validates email format', async ({ page }) => {
    await page.fill('#firstName', 'John');
    await page.fill('#lastName', 'Doe');
    await page.fill('#email', 'invalid-email');
    await page.fill('#subject', 'Test Subject');
    await page.fill('#message', 'Test message content');
    await page.click('button[type="submit"]');

    const email = page.locator('#email');
    const isInvalid = await email.evaluate((el: HTMLInputElement) => !el.validity.valid);
    expect(isInvalid).toBe(true);
  });

  test('form fields have proper placeholders', async ({ page }) => {
    await expect(page.locator('#firstName')).toHaveAttribute('placeholder', 'John');
    await expect(page.locator('#lastName')).toHaveAttribute('placeholder', 'Doe');
    await expect(page.locator('#email')).toHaveAttribute('placeholder', 'john@example.com');
    await expect(page.locator('#subject')).toHaveAttribute('placeholder', 'How can we help?');
  });

  test('honeypot field is hidden', async ({ page }) => {
    const honeypot = page.locator('input[name="_gotcha"]');
    // Honeypot uses CSS positioning off-screen (better for catching bots than display:none)
    // Verify it's not visible in viewport and has the honeypot class
    await expect(honeypot).toHaveClass(/honeypot/);
    await expect(honeypot).not.toBeInViewport();
  });
});

test.describe('Contact Form Submission', () => {
  test.beforeEach(async ({ page }) => {
    // Clear rate limit from localStorage before each test
    await page.goto('/contact_us.html');
    await page.evaluate(() => localStorage.removeItem('gc_form_submissions'));
  });

  test('successful form submission shows success message', async ({ page }) => {
    // Mock successful API response (match backend pattern with query param)
    await page.route((url) => url.hostname.includes('rest.gadgetcloud.io') || url.hostname.includes('rest-stg.gadgetcloud.io'), async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ success: true, submission_id: 'FSM-TEST123', message: 'Form submitted successfully' }),
      });
    });

    // Fill in the form
    await page.fill('#firstName', 'Playwright');
    await page.fill('#lastName', 'Test');
    await page.fill('#email', 'playwright-test@example.com');
    await page.fill('#subject', 'Automated Test');
    await page.fill('#message', 'This is an automated E2E test submission from Playwright. Please ignore.');

    // Submit the form
    await page.click('button[type="submit"]');

    // Wait for success message
    const formStatus = page.locator('#formStatus');
    await expect(formStatus).toHaveText('Thank you for your message! We will get back to you soon.', { timeout: 10000 });
    await expect(formStatus).toHaveClass(/success/);

    // Verify button returns to normal state
    await expect(page.locator('button[type="submit"]')).toHaveText('Send Message');

    // Verify form is reset
    await expect(page.locator('#firstName')).toHaveValue('');
    await expect(page.locator('#lastName')).toHaveValue('');
    await expect(page.locator('#email')).toHaveValue('');
    await expect(page.locator('#subject')).toHaveValue('');
    await expect(page.locator('#message')).toHaveValue('');
  });

  test('form submission handles API errors gracefully', async ({ page }) => {
    // Mock API to return an error
    await page.route((url) => url.hostname.includes('rest.gadgetcloud.io') || url.hostname.includes('rest-stg.gadgetcloud.io'), async (route) => {
      await route.fulfill({
        status: 400,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'firstName: Must be at least 2 characters' }),
      });
    });

    // Fill in the form
    await page.fill('#firstName', 'Test');
    await page.fill('#lastName', 'User');
    await page.fill('#email', 'test@example.com');
    await page.fill('#subject', 'Error Test');
    await page.fill('#message', 'Test message for error handling.');

    // Submit the form
    await page.click('button[type="submit"]');

    // Wait for error message
    const formStatus = page.locator('#formStatus');
    await expect(formStatus).toContainText('firstName: Must be at least 2 characters', { timeout: 10000 });
    await expect(formStatus).toHaveClass(/error/);

    // Form should not be reset on error
    await expect(page.locator('#firstName')).toHaveValue('Test');
  });

  test('form submission handles network errors', async ({ page }) => {
    // Mock network failure
    await page.route((url) => url.hostname.includes('rest.gadgetcloud.io') || url.hostname.includes('rest-stg.gadgetcloud.io'), async (route) => {
      await route.abort('failed');
    });

    // Fill in the form
    await page.fill('#firstName', 'Test');
    await page.fill('#lastName', 'User');
    await page.fill('#email', 'test@example.com');
    await page.fill('#subject', 'Network Test');
    await page.fill('#message', 'Test message for network error.');

    // Submit the form
    await page.click('button[type="submit"]');

    // Wait for error message
    const formStatus = page.locator('#formStatus');
    await expect(formStatus).toHaveText('Unable to send message. Please check your connection and try again.', { timeout: 10000 });
    await expect(formStatus).toHaveClass(/error/);
  });

  test('form submission sends correct data to API', async ({ page }) => {
    let capturedRequest: {
      firstName: string;
      lastName: string;
      email: string;
      subject: string;
      message: string;
      source?: string;
      referrer?: string;
      pageUrl?: string;
      referredBy?: string;
    } | null = null;

    // Intercept and capture the request, then mock response
    await page.route((url) => url.hostname.includes('rest.gadgetcloud.io') || url.hostname.includes('rest-stg.gadgetcloud.io'), async (route) => {
      const request = route.request();
      capturedRequest = JSON.parse(request.postData() || '{}');

      // Mock successful response
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ success: true, submission_id: 'FSM-TEST456', message: 'Form submitted successfully' }),
      });
    });

    // Fill in the form
    await page.fill('#firstName', 'DataTest');
    await page.fill('#lastName', 'Verify');
    await page.fill('#email', 'data-test@example.com');
    await page.fill('#subject', 'Data Validation Test');
    await page.fill('#message', 'Testing data submission to API endpoint.');

    // Submit the form
    await page.click('button[type="submit"]');

    // Wait for submission to complete
    await expect(page.locator('#formStatus')).toHaveClass(/success/, { timeout: 10000 });

    // Verify request data matches backend expectations (flat structure)
    expect(capturedRequest).not.toBeNull();
    expect(capturedRequest!.firstName).toBe('DataTest');
    expect(capturedRequest!.lastName).toBe('Verify');
    expect(capturedRequest!.email).toBe('data-test@example.com');
    expect(capturedRequest!.subject).toBe('Data Validation Test');
    expect(capturedRequest!.message).toBe('Testing data submission to API endpoint.');
    // Verify metadata fields (flat structure, not nested in tags)
    expect(capturedRequest!.source).toBeDefined();
    expect(capturedRequest!.referrer).toBeDefined();
    expect(capturedRequest!.pageUrl).toBeDefined();
  });

  test('form submission includes referredBy from URL parameter', async ({ page }) => {
    let capturedRequest: {
      firstName: string;
      lastName: string;
      email: string;
      subject: string;
      message: string;
      referredBy?: string;
    } | null = null;

    // Intercept and capture the request
    await page.route((url) => url.hostname.includes('rest.gadgetcloud.io') || url.hostname.includes('rest-stg.gadgetcloud.io'), async (route) => {
      const request = route.request();
      capturedRequest = JSON.parse(request.postData() || '{}');

      // Mock successful response
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ success: true, submission_id: 'FSM-TEST789', message: 'Form submitted successfully' }),
      });
    });

    // Navigate to contact page with referredBy parameter
    await page.goto('/contact_us.html?referredBy=affiliate-partner-123');

    // Clear rate limit
    await page.evaluate(() => localStorage.removeItem('gc_form_submissions'));

    // Fill in the form
    await page.fill('#firstName', 'Referral');
    await page.fill('#lastName', 'Test');
    await page.fill('#email', 'referral@example.com');
    await page.fill('#subject', 'Referral Test');
    await page.fill('#message', 'Testing referredBy parameter capture from URL.');

    // Submit the form
    await page.click('button[type="submit"]');

    // Wait for submission to complete
    await expect(page.locator('#formStatus')).toHaveClass(/success/, { timeout: 10000 });

    // Verify referredBy was captured
    expect(capturedRequest).not.toBeNull();
    expect(capturedRequest!.referredBy).toBe('affiliate-partner-123');
  });
});
