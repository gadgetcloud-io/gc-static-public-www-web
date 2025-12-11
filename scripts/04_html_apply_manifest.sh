#!/bin/bash
# HTML Manifest Synchronization Script
# Applies manifest.yaml configuration and version/build info to HTML files
# Usage: ./scripts/04_html_apply_manifest.sh [--apply]

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
MANIFEST_FILE="$ROOT_DIR/manifest.yaml"
VERSION_FILE="$ROOT_DIR/VERSION"
SRC_DIR="$ROOT_DIR/src"

CHECKS_PASSED=0
CHECKS_FAILED=0
APPLY_CHANGES=false

check_pass() { success "$1"; CHECKS_PASSED=$((CHECKS_PASSED+1)); }
check_fail() { warn "$1"; CHECKS_FAILED=$((CHECKS_FAILED+1)); }

# Parse arguments
if [[ "$1" == "--apply" ]]; then
    APPLY_CHANGES=true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  HTML Manifest Synchronization"
if [ "$APPLY_CHANGES" = true ]; then
    echo "  Mode: Apply Changes"
else
    echo "  Mode: Validation Only"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
section "Checking Prerequisites"

command -v yq &>/dev/null || error "yq not installed"
check_pass "yq installed"

[ -f "$MANIFEST_FILE" ] || error "manifest.yaml not found"
check_pass "manifest.yaml exists"

[ -d "$SRC_DIR" ] || error "src directory not found"
check_pass "src directory exists"

# Check or create VERSION file
if [ ! -f "$VERSION_FILE" ]; then
    warn "VERSION file not found - creating default"
    echo "1.0.0" > "$VERSION_FILE"
fi
check_pass "VERSION file exists"

# Read version and generate build info
section "Reading Version Information"

VERSION=$(cat "$VERSION_FILE" | tr -d '\n')
BUILD_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
BUILD_TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "")

info "Version: $VERSION"
info "Build Date: $BUILD_DATE"
info "Build ID: $BUILD_TIMESTAMP"
info "Git Commit: $GIT_COMMIT"

# Create version string for footer
if [ -n "$GIT_COMMIT" ]; then
    VERSION_STRING="v${VERSION} | Build ${BUILD_TIMESTAMP} | ${GIT_COMMIT}"
else
    VERSION_STRING="v${VERSION} | Build ${BUILD_TIMESTAMP}"
fi

# Read manifest data
section "Reading Manifest Configuration"

SITE_TITLE=$(yq eval '.site_title' "$MANIFEST_FILE")
SITE_HEADER=$(yq eval '.header' "$MANIFEST_FILE")
SITE_FOOTER=$(yq eval '.footer' "$MANIFEST_FILE")
SITE_DESCRIPTION=$(yq eval '.site_description' "$MANIFEST_FILE")

info "Site Title: $SITE_TITLE"
info "Header: $SITE_HEADER"

# Count menu items and social links
MENU_COUNT=$(yq eval '.menu_items | length' "$MANIFEST_FILE")
SOCIAL_COUNT=$(yq eval '.social_links | length' "$MANIFEST_FILE")

info "Menu Items: $MENU_COUNT"
info "Social Links: $SOCIAL_COUNT"

# Validate HTML files
section "Validating HTML Files"

HTML_FILES=("index.html" "about_us.html" "products.html" "services.html" "contact_us.html" "error.html")

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ]; then
        check_pass "$file exists"
    else
        check_fail "$file missing"
    fi
done

# Check meta descriptions in HTML match manifest
section "Checking Meta Descriptions"

for i in $(seq 0 $((MENU_COUNT - 1))); do
    PAGE_LINK=$(yq eval ".menu_items[$i].link" "$MANIFEST_FILE")
    PAGE_DESC=$(yq eval ".menu_items[$i].description" "$MANIFEST_FILE")
    PAGE_TITLE=$(yq eval ".menu_items[$i].title" "$MANIFEST_FILE")

    if [ -f "$SRC_DIR/$PAGE_LINK" ]; then
        # Check if description exists in HTML
        if grep -q "meta name=\"description\"" "$SRC_DIR/$PAGE_LINK"; then
            CURRENT_DESC=$(grep "meta name=\"description\"" "$SRC_DIR/$PAGE_LINK" | sed 's/.*content="\([^"]*\)".*/\1/')

            if [ "$CURRENT_DESC" = "$PAGE_DESC" ]; then
                check_pass "$PAGE_LINK: Meta description matches"
            else
                check_fail "$PAGE_LINK: Meta description differs"
                info "  Expected: $PAGE_DESC"
                info "  Found: $CURRENT_DESC"
            fi
        else
            check_fail "$PAGE_LINK: Meta description missing"
        fi

        # Check title
        if grep -q "<title>" "$SRC_DIR/$PAGE_LINK"; then
            CURRENT_TITLE=$(grep "<title>" "$SRC_DIR/$PAGE_LINK" | sed 's/.*<title>\([^<]*\)<\/title>.*/\1/')

            if [ "$CURRENT_TITLE" = "$PAGE_TITLE" ]; then
                check_pass "$PAGE_LINK: Title matches"
            else
                check_fail "$PAGE_LINK: Title differs"
                info "  Expected: $PAGE_TITLE"
                info "  Found: $CURRENT_TITLE"
            fi
        fi
    fi
done

# Check social links in HTML
section "Checking Social Links"

SOCIAL_PLATFORMS=$(yq eval '.social_links[].platform' "$MANIFEST_FILE")

for platform in $SOCIAL_PLATFORMS; do
    PLATFORM_URL=$(yq eval ".social_links[] | select(.platform == \"$platform\") | .url" "$MANIFEST_FILE")

    # Check if social link exists in index.html
    if grep -q "$PLATFORM_URL" "$SRC_DIR/index.html"; then
        check_pass "Social link found: $platform"
    else
        check_fail "Social link missing: $platform"
        info "  URL: $PLATFORM_URL"
    fi
done

# Check navigation consistency
section "Checking Navigation Consistency"

NAV_ISSUES=0

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ] && [ "$file" != "error.html" ]; then
        # Check if all menu items are present
        for i in $(seq 0 $((MENU_COUNT - 1))); do
            MENU_LINK=$(yq eval ".menu_items[$i].link" "$MANIFEST_FILE")
            MENU_TEXT=$(yq eval ".menu_items[$i].text" "$MANIFEST_FILE")

            if ! grep -q "href=\"$MENU_LINK\"" "$SRC_DIR/$file"; then
                warn "$file: Navigation link missing: $MENU_TEXT ($MENU_LINK)"
                NAV_ISSUES=$((NAV_ISSUES+1))
            fi
        done
    fi
done

if [ $NAV_ISSUES -eq 0 ]; then
    check_pass "All navigation links present"
else
    check_fail "Found $NAV_ISSUES navigation inconsistencies"
fi

# Update version and build info in HTML footers
section "Updating Version and Build Information"

if [ "$APPLY_CHANGES" = true ]; then
    info "Applying version and build info to HTML files..."
    echo ""

    for file in "${HTML_FILES[@]}"; do
        if [ -f "$SRC_DIR/$file" ]; then
            # Check if footer has version info
            if grep -q "class=\"version-info\"" "$SRC_DIR/$file"; then
                # Update existing version info using awk
                awk -v version="$VERSION_STRING" '
                    /<div class="version-info">/ {
                        print "        <div class=\"version-info\">" version "</div>"
                        next
                    }
                    { print }
                ' "$SRC_DIR/$file" > "$SRC_DIR/$file.tmp"
                mv "$SRC_DIR/$file.tmp" "$SRC_DIR/$file"
                success "$file: Version info updated"
            else
                # Add version info before closing footer tag using awk
                if grep -q "</footer>" "$SRC_DIR/$file"; then
                    awk -v version="$VERSION_STRING" '
                        /<\/footer>/ {
                            print "        <div class=\"version-info\">" version "</div>"
                        }
                        { print }
                    ' "$SRC_DIR/$file" > "$SRC_DIR/$file.tmp"
                    mv "$SRC_DIR/$file.tmp" "$SRC_DIR/$file"
                    success "$file: Version info added"
                else
                    warn "$file: No footer tag found, skipping version info"
                fi
            fi
        fi
    done

    echo ""
    success "Version and build info applied to all HTML files"
    info "Version String: $VERSION_STRING"
else
    info "Skipping version updates (use --apply to apply changes)"

    # Check if version info exists
    for file in "${HTML_FILES[@]}"; do
        if [ -f "$SRC_DIR/$file" ]; then
            if grep -q "class=\"version-info\"" "$SRC_DIR/$file"; then
                CURRENT_VERSION=$(grep -A 1 "class=\"version-info\"" "$SRC_DIR/$file" | tail -1 | sed 's/.*>\(.*\)<.*/\1/' | xargs)
                check_pass "$file: Version info exists ($CURRENT_VERSION)"
            else
                check_fail "$file: Version info missing"
            fi
        fi
    done
fi

# Check footer consistency (basic footer text, not version)
section "Checking Footer Content"

for file in "${HTML_FILES[@]}"; do
    if [ -f "$SRC_DIR/$file" ]; then
        # Check for basic footer structure
        if grep -q "<footer" "$SRC_DIR/$file"; then
            check_pass "$file: Footer element exists"
        else
            check_fail "$file: Footer element missing"
        fi
    fi
done

# Summary
section "Validation Summary"

TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED))

echo "Total Checks: $TOTAL_CHECKS"
echo "Passed: $CHECKS_PASSED"
echo "Failed: $CHECKS_FAILED"
echo ""

if [ "$APPLY_CHANGES" = true ]; then
    echo "Version Information Applied:"
    echo "  Version: $VERSION"
    echo "  Build: $BUILD_TIMESTAMP"
    echo "  Commit: $GIT_COMMIT"
    echo ""
fi

if [ $CHECKS_FAILED -eq 0 ]; then
    success "All manifest validation checks passed!"
    echo ""
    info "HTML files are consistent with manifest.yaml"
    if [ "$APPLY_CHANGES" = true ]; then
        info "Version and build information has been applied"
    else
        info "Run with --apply to update version and build information"
    fi
    echo ""
    exit 0
else
    warn "Some validation checks failed"
    echo ""
    info "Review the issues above and update HTML files to match manifest.yaml"
    if [ "$APPLY_CHANGES" = false ]; then
        info "Run with --apply to update version and build information"
    fi
    echo ""
    exit 1
fi
