// Mobile Navigation Toggle
document.addEventListener('DOMContentLoaded', function() {
    const navToggle = document.querySelector('.nav-toggle');
    const navMenu = document.querySelector('.nav-menu');

    if (navToggle && navMenu) {
        navToggle.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            navToggle.classList.toggle('active');
        });

        // Close menu when clicking outside
        document.addEventListener('click', function(e) {
            if (!navToggle.contains(e.target) && !navMenu.contains(e.target)) {
                navMenu.classList.remove('active');
                navToggle.classList.remove('active');
            }
        });

        // Close menu when clicking a link
        navMenu.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', function() {
                navMenu.classList.remove('active');
                navToggle.classList.remove('active');
            });
        });
    }

    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add header background on scroll
    const header = document.querySelector('.header');
    if (header) {
        window.addEventListener('scroll', function() {
            if (window.scrollY > 50) {
                header.classList.add('scrolled');
            } else {
                header.classList.remove('scrolled');
            }
        });
    }

    // Client-side rate limiting
    const RATE_LIMIT_KEY = 'gc_form_submissions';
    const RATE_LIMIT_MAX = 10;
    const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour

    function checkRateLimit() {
        try {
            const now = Date.now();
            const stored = localStorage.getItem(RATE_LIMIT_KEY);
            let submissions = stored ? JSON.parse(stored) : [];

            // Remove expired entries
            submissions = submissions.filter(ts => now - ts < RATE_LIMIT_WINDOW_MS);

            if (submissions.length >= RATE_LIMIT_MAX) {
                const oldestSubmission = Math.min(...submissions);
                const resetTime = new Date(oldestSubmission + RATE_LIMIT_WINDOW_MS);
                const minutes = Math.ceil((resetTime - now) / 60000);
                return {
                    allowed: false,
                    message: `Too many submissions. Please try again in ${minutes} minute${minutes !== 1 ? 's' : ''}.`
                };
            }

            return { allowed: true, submissions };
        } catch (e) {
            // If localStorage fails, allow the request (server will still rate limit)
            return { allowed: true, submissions: [] };
        }
    }

    function recordSubmission() {
        try {
            const stored = localStorage.getItem(RATE_LIMIT_KEY);
            let submissions = stored ? JSON.parse(stored) : [];
            const now = Date.now();

            // Remove expired and add new
            submissions = submissions.filter(ts => now - ts < RATE_LIMIT_WINDOW_MS);
            submissions.push(now);

            localStorage.setItem(RATE_LIMIT_KEY, JSON.stringify(submissions));
        } catch (e) {
            // Ignore localStorage errors
        }
    }

    // Get source from URL parameters or referrer
    function getSource() {
        const params = new URLSearchParams(window.location.search);

        // Check for UTM source first
        if (params.get('utm_source')) {
            return params.get('utm_source');
        }

        // Check for common referral parameters
        if (params.get('ref')) {
            return params.get('ref');
        }

        if (params.get('source')) {
            return params.get('source');
        }

        // Parse referrer domain
        if (document.referrer) {
            try {
                const referrerUrl = new URL(document.referrer);
                const referrerHost = referrerUrl.hostname;

                // Check if it's from the same domain
                if (referrerHost === window.location.hostname) {
                    return 'internal';
                }

                // Known sources
                if (referrerHost.includes('google')) return 'google';
                if (referrerHost.includes('facebook') || referrerHost.includes('fb.com')) return 'facebook';
                if (referrerHost.includes('twitter') || referrerHost.includes('t.co')) return 'twitter';
                if (referrerHost.includes('linkedin')) return 'linkedin';
                if (referrerHost.includes('instagram')) return 'instagram';

                return referrerHost;
            } catch (e) {
                return 'unknown';
            }
        }

        return 'direct';
    }

    // Form submission handling
    const contactForm = document.getElementById('contactForm');
    if (contactForm) {
        contactForm.addEventListener('submit', async function(e) {
            e.preventDefault();

            const submitBtn = contactForm.querySelector('button[type="submit"]');
            const formStatus = document.getElementById('formStatus');
            const honeypot = contactForm.querySelector('input[name="_gotcha"]');

            // Honeypot check
            if (honeypot && honeypot.value) {
                return;
            }

            // Client-side rate limit check
            const rateCheck = checkRateLimit();
            if (!rateCheck.allowed) {
                formStatus.textContent = rateCheck.message;
                formStatus.className = 'form-status error';
                formStatus.style.display = 'block';
                return;
            }

            // Disable button and show loading state
            submitBtn.disabled = true;
            submitBtn.textContent = 'Sending...';
            formStatus.textContent = '';
            formStatus.className = 'form-status';

            const formData = {
                formType: 'contacts',
                firstName: contactForm.firstName.value.trim(),
                lastName: contactForm.lastName.value.trim(),
                email: contactForm.email.value.trim(),
                message: contactForm.message.value.trim(),
                tags: {
                    source: getSource(),
                    referrer: document.referrer || 'direct',
                    pageUrl: window.location.href,
                    userAgent: navigator.userAgent,
                    isTest: false,
                    submittedAt: new Date().toISOString()
                }
            };

            try {
                const response = await fetch('https://rest.gadgetcloud.io/forms', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(formData)
                });

                if (response.ok) {
                    recordSubmission(); // Track successful submission for rate limiting
                    formStatus.textContent = 'Thank you for your message! We will get back to you soon.';
                    formStatus.className = 'form-status success';
                    formStatus.style.display = 'block';
                    contactForm.reset();
                } else {
                    const error = await response.json().catch(() => ({}));
                    formStatus.textContent = error.error || error.message || 'Something went wrong. Please try again.';
                    formStatus.className = 'form-status error';
                    formStatus.style.display = 'block';
                }
            } catch (err) {
                formStatus.textContent = 'Unable to send message. Please check your connection and try again.';
                formStatus.className = 'form-status error';
                formStatus.style.display = 'block';
            } finally {
                submitBtn.disabled = false;
                submitBtn.textContent = 'Send Message';
            }
        });
    }
});
