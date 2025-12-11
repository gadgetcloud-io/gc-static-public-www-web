import { test, expect } from '@playwright/test';

test.describe('Contact Form', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/contact_us.html');
  });

  test('form fields are present', async ({ page }) => {
    await expect(page.locator('#firstName')).toBeVisible();
    await expect(page.locator('#lastName')).toBeVisible();
    await expect(page.locator('#email')).toBeVisible();
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
    // Intercept the API call and modify to add isTest flag
    await page.route('**/rest.gadgetcloud.io/forms', async (route) => {
      const request = route.request();
      const postData = JSON.parse(request.postData() || '{}');

      // Add isTest flag to prevent email sending
      postData.tags = { ...postData.tags, isTest: true };

      // Continue with modified request
      await route.continue({
        postData: JSON.stringify(postData),
      });
    });

    // Fill in the form
    await page.fill('#firstName', 'Playwright');
    await page.fill('#lastName', 'Test');
    await page.fill('#email', 'playwright-test@example.com');
    await page.fill('#message', 'This is an automated E2E test submission from Playwright. Please ignore.');

    // Submit the form
    await page.click('button[type="submit"]');

    // Verify button shows loading state
    await expect(page.locator('button[type="submit"]')).toHaveText('Sending...');

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
    await expect(page.locator('#message')).toHaveValue('');
  });

  test('form submission handles API errors gracefully', async ({ page }) => {
    // Mock API to return an error
    await page.route('**/rest.gadgetcloud.io/forms', async (route) => {
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
    await page.fill('#message', 'Test message for error handling.');

    // Submit the form
    await page.click('button[type="submit"]');

    // Wait for error message
    const formStatus = page.locator('#formStatus');
    await expect(formStatus).toHaveText('firstName: Must be at least 2 characters', { timeout: 10000 });
    await expect(formStatus).toHaveClass(/error/);

    // Form should not be reset on error
    await expect(page.locator('#firstName')).toHaveValue('Test');
  });

  test('form submission handles network errors', async ({ page }) => {
    // Mock network failure
    await page.route('**/rest.gadgetcloud.io/forms', async (route) => {
      await route.abort('failed');
    });

    // Fill in the form
    await page.fill('#firstName', 'Test');
    await page.fill('#lastName', 'User');
    await page.fill('#email', 'test@example.com');
    await page.fill('#message', 'Test message for network error.');

    // Submit the form
    await page.click('button[type="submit"]');

    // Wait for error message
    const formStatus = page.locator('#formStatus');
    await expect(formStatus).toHaveText('Unable to send message. Please check your connection and try again.', { timeout: 10000 });
    await expect(formStatus).toHaveClass(/error/);
  });

  test('form submission sends correct data to API', async ({ page }) => {
    let capturedRequest: { formType: string; firstName: string; lastName: string; email: string; message: string; tags?: { source?: string } } | null = null;

    // Intercept and capture the request
    await page.route('**/rest.gadgetcloud.io/forms', async (route) => {
      const request = route.request();
      capturedRequest = JSON.parse(request.postData() || '{}');

      // Modify to add isTest flag and continue
      capturedRequest!.tags = { ...capturedRequest!.tags, isTest: true };

      await route.continue({
        postData: JSON.stringify(capturedRequest),
      });
    });

    // Fill in the form
    await page.fill('#firstName', 'DataTest');
    await page.fill('#lastName', 'Verify');
    await page.fill('#email', 'data-test@example.com');
    await page.fill('#message', 'Testing data submission to API endpoint.');

    // Submit the form
    await page.click('button[type="submit"]');

    // Wait for submission to complete
    await expect(page.locator('#formStatus')).toHaveClass(/success/, { timeout: 10000 });

    // Verify request data
    expect(capturedRequest).not.toBeNull();
    expect(capturedRequest!.formType).toBe('contacts');
    expect(capturedRequest!.firstName).toBe('DataTest');
    expect(capturedRequest!.lastName).toBe('Verify');
    expect(capturedRequest!.email).toBe('data-test@example.com');
    expect(capturedRequest!.message).toBe('Testing data submission to API endpoint.');
    expect(capturedRequest!.tags).toBeDefined();
    expect(capturedRequest!.tags!.source).toBeDefined();
  });
});
