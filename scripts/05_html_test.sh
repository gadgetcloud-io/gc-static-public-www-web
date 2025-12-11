#!/bin/bash
# HTML Validation and Testing Script
# Tests HTML files for structure, links, and required elements
# Usage: ./scripts/05_html_test.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}▶ $1${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$ROOT_DIR/src"

TESTS_PASSED=0
TESTS_FAILED=0

test_pass() { success "$1"; TESTS_PASSED=$((TESTS_PASSED+1)); }
test_fail() { error "$1"; TESTS_FAILED=$((TESTS_FAILED+1)); }
test_warn() { warn "$1"; TESTS_FAILED=$((TESTS_FAILED+1)); }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  HTML Validation and Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
section "Checking Prerequisites"

[ -d "$SRC_DIR" ] || error "src directory not found"
test_pass "src directory exists"

# Test HTML file existence
section "Testing HTML Files"

HTML_FILES=("index.html" "about_us.html" "products.html" "services.html" "contact_us.html" "error.html")

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ]; then
        test_pass "$file exists"
    else
        test_fail "$file not found"
    fi
done

# Test HTML structure
section "Testing HTML Structure"

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ]; then
        # Check DOCTYPE
        if head -1 "$SRC_DIR/$file" | grep -qi "<!DOCTYPE html>"; then
            test_pass "$file: DOCTYPE declared"
        else
            test_warn "$file: DOCTYPE missing or incorrect"
        fi

        # Check html tag
        if grep -q "<html" "$SRC_DIR/$file"; then
            test_pass "$file: <html> tag present"
        else
            test_fail "$file: <html> tag missing"
        fi

        # Check head tag
        if grep -q "<head>" "$SRC_DIR/$file"; then
            test_pass "$file: <head> tag present"
        else
            test_fail "$file: <head> tag missing"
        fi

        # Check body tag
        if grep -q "<body>" "$SRC_DIR/$file"; then
            test_pass "$file: <body> tag present"
        else
            test_fail "$file: <body> tag missing"
        fi

        # Check title tag
        if grep -q "<title>" "$SRC_DIR/$file"; then
            test_pass "$file: <title> tag present"
        else
            test_warn "$file: <title> tag missing"
        fi

        # Check meta charset
        if grep -q 'meta charset="UTF-8"' "$SRC_DIR/$file"; then
            test_pass "$file: UTF-8 charset declared"
        else
            test_warn "$file: UTF-8 charset not declared"
        fi

        # Check viewport meta
        if grep -q 'meta name="viewport"' "$SRC_DIR/$file"; then
            test_pass "$file: Viewport meta tag present"
        else
            test_warn "$file: Viewport meta tag missing"
        fi

        # Check meta description
        if grep -q 'meta name="description"' "$SRC_DIR/$file"; then
            test_pass "$file: Meta description present"
        else
            test_warn "$file: Meta description missing"
        fi
    fi
done

# Test CSS references
section "Testing CSS References"

CSS_FILES=("css/styles.css")

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ]; then
        for css in "${CSS_FILES[@]}"; do
            if grep -q "href=\"$css\"" "$SRC_DIR/$file"; then
                test_pass "$file: $css referenced"

                # Check if CSS file exists
                if [ -f "$SRC_DIR/$css" ]; then
                    test_pass "$file: $css file exists"
                else
                    test_fail "$file: $css file not found"
                fi
            else
                test_warn "$file: $css not referenced"
            fi
        done
    fi
done

# Test JavaScript references
section "Testing JavaScript References"

JS_FILES=("js/main.js")

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ]; then
        for js in "${JS_FILES[@]}"; do
            if grep -q "src=\"$js\"" "$SRC_DIR/$file"; then
                test_pass "$file: $js referenced"

                # Check if JS file exists
                if [ -f "$SRC_DIR/$js" ]; then
                    test_pass "$file: $js file exists"
                else
                    test_fail "$file: $js file not found"
                fi
            else
                test_warn "$file: $js not referenced"
            fi
        done
    fi
done

# Test navigation links
section "Testing Navigation Links"

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ]; then
        # Check for nav element
        if grep -q "<nav" "$SRC_DIR/$file"; then
            test_pass "$file: <nav> element present"
        else
            test_warn "$file: <nav> element missing"
        fi

        # Check for navigation links
        NAV_LINKS=0
        for target in "${HTML_FILES[@]}"; do
            if [ "$target" != "error.html" ]; then
                if grep -q "href=\"$target\"" "$SRC_DIR/$file"; then
                    NAV_LINKS=$((NAV_LINKS+1))
                fi
            fi
        done

        if [ $NAV_LINKS -ge 4 ]; then
            test_pass "$file: Navigation links present ($NAV_LINKS found)"
        else
            test_warn "$file: Incomplete navigation ($NAV_LINKS links)"
        fi
    fi
done

# Test contact form (contact_us.html only)
section "Testing Contact Form"

CONTACT_FILE="$SRC_DIR/contact_us.html"

if [ -f "$CONTACT_FILE" ]; then
    # Check form element
    if grep -q "<form" "$CONTACT_FILE"; then
        test_pass "Contact form element present"
    else
        test_fail "Contact form element missing"
    fi

    # Check required form fields
    REQUIRED_FIELDS=("firstName" "lastName" "email" "message")

    for field in "${REQUIRED_FIELDS[@]}"; do
        if grep -q "name=\"$field\"" "$CONTACT_FILE"; then
            test_pass "Form field present: $field"
        else
            test_fail "Form field missing: $field"
        fi
    done

    # Check submit button
    if grep -q 'type="submit"' "$CONTACT_FILE"; then
        test_pass "Submit button present"
    else
        test_fail "Submit button missing"
    fi

    # Check honeypot field
    if grep -q "_gotcha" "$CONTACT_FILE"; then
        test_pass "Honeypot field present"
    else
        test_warn "Honeypot field missing (spam protection)"
    fi
fi

# Test security headers in HTML
section "Testing Security Configuration"

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ]; then
        # Check for CSP meta tag
        if grep -q 'Content-Security-Policy' "$SRC_DIR/$file"; then
            test_pass "$file: CSP header configured"
        else
            test_warn "$file: CSP header not found"
        fi
    fi
done

# Test image references
section "Testing Image References"

IMAGE_DIR="$SRC_DIR/images"

if [ -d "$IMAGE_DIR" ]; then
    test_pass "Images directory exists"

    # Count image files
    IMAGE_COUNT=$(find "$IMAGE_DIR" -type f \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | wc -l | tr -d ' ')
    info "Found $IMAGE_COUNT image files"

    if [ "$IMAGE_COUNT" -gt 0 ]; then
        test_pass "Image assets present"
    else
        test_warn "No image files found"
    fi
else
    test_warn "Images directory not found"
fi

# Test for inline scripts (should be none due to CSP)
section "Testing CSP Compliance"

INLINE_SCRIPT_COUNT=0

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ]; then
        # Check for inline scripts
        if grep -q "<script>" "$SRC_DIR/$file" && ! grep -q 'src=' "$SRC_DIR/$file" | grep -q "<script"; then
            test_warn "$file: Inline script detected (CSP violation)"
            INLINE_SCRIPT_COUNT=$((INLINE_SCRIPT_COUNT+1))
        fi
    fi
done

if [ $INLINE_SCRIPT_COUNT -eq 0 ]; then
    test_pass "No inline scripts found (CSP compliant)"
else
    test_warn "Found $INLINE_SCRIPT_COUNT files with inline scripts"
fi

# Test favicon
section "Testing Favicon"

if [ -f "$SRC_DIR/images/favicon.svg" ] || [ -f "$SRC_DIR/favicon.ico" ]; then
    test_pass "Favicon file exists"
else
    test_warn "Favicon not found"
fi

# Check for favicon reference in HTML
if grep -q "favicon" "$SRC_DIR/index.html"; then
    test_pass "Favicon referenced in HTML"
else
    test_warn "Favicon not referenced in HTML"
fi

# Summary
section "Test Summary"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))

echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    success "All HTML validation tests passed!"
    echo ""
    info "HTML files are ready for deployment"
    echo ""
    exit 0
else
    warn "Some HTML validation tests failed"
    echo ""
    info "Review the issues above before deploying"
    info "Critical issues should be fixed"
    info "Warnings are recommendations but not blockers"
    echo ""
    exit 1
fi
