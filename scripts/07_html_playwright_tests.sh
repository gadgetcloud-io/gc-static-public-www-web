#!/bin/bash
# Playwright E2E Testing Script
# Runs Playwright tests against deployed environments
# Usage: ./scripts/07_html_playwright_tests.sh [stg|prd] [options]

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

# Parse arguments
ENV="${1:-stg}"
TEST_MODE="all"
EXTRA_ARGS=""

# Normalize environment
case "$ENV" in
    staging|stg) ENV="stg"; ENV_NAME="Staging" ;;
    production|prd|prod) ENV="prd"; ENV_NAME="Production" ;;
    *) ENV="stg"; ENV_NAME="Staging" ;;
esac

# Parse additional options
shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --headed)
            TEST_MODE="headed"
            EXTRA_ARGS="$EXTRA_ARGS --headed"
            shift
            ;;
        --debug)
            TEST_MODE="debug"
            EXTRA_ARGS="$EXTRA_ARGS --debug"
            shift
            ;;
        --ui)
            TEST_MODE="ui"
            EXTRA_ARGS="$EXTRA_ARGS --ui"
            shift
            ;;
        --reporter=*)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
        --project=*)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
        --grep=*)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
        pages|navigation|contact-form)
            TEST_FILE="$1"
            EXTRA_ARGS="$EXTRA_ARGS $TEST_FILE"
            shift
            ;;
        *)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
    esac
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Playwright E2E Tests"
echo "  Environment: $ENV_NAME"
echo "  Mode: $TEST_MODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
section "Checking Prerequisites"

command -v node &>/dev/null || error "Node.js not installed"
NODE_VERSION=$(node --version)
success "Node.js installed ($NODE_VERSION)"

command -v npm &>/dev/null || error "npm not installed"
NPM_VERSION=$(npm --version)
success "npm installed ($NPM_VERSION)"

command -v yq &>/dev/null || error "yq not installed"
success "yq installed"

# Check if package.json exists
if [ ! -f "$ROOT_DIR/package.json" ]; then
    error "package.json not found"
fi
success "package.json exists"

# Read environment configuration
CONFIG_FILE="$ROOT_DIR/environments/$ENV/config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    error "Config file not found: $CONFIG_FILE"
fi
success "Environment config found"

HOSTNAME=$(yq eval '.hostName' "$CONFIG_FILE")
info "Target: https://$HOSTNAME"

# Check if node_modules exists
section "Checking Dependencies"

if [ ! -d "$ROOT_DIR/node_modules" ]; then
    warn "node_modules not found - installing dependencies..."
    cd "$ROOT_DIR"
    npm install
    success "Dependencies installed"
else
    success "Dependencies already installed"

    # Check if playwright is installed
    if [ ! -d "$ROOT_DIR/node_modules/@playwright/test" ]; then
        warn "Playwright not found - installing..."
        cd "$ROOT_DIR"
        npm install
        success "Playwright installed"
    else
        success "Playwright installed"
    fi
fi

# Check if Playwright browsers are installed
section "Checking Playwright Browsers"

if [ ! -d "$HOME/.cache/ms-playwright" ] && [ ! -d "$HOME/Library/Caches/ms-playwright" ]; then
    warn "Playwright browsers not installed - installing..."
    cd "$ROOT_DIR"
    npx playwright install
    success "Playwright browsers installed"
else
    success "Playwright browsers installed"
fi

# Check test files exist
section "Checking Test Files"

TEST_DIR="$ROOT_DIR/tests"
if [ ! -d "$TEST_DIR" ]; then
    error "Tests directory not found: $TEST_DIR"
fi

TEST_FILES=("pages.spec.ts" "navigation.spec.ts" "contact-form.spec.ts")
TEST_COUNT=0

for file in "${TEST_FILES[@]}"; do
    if [ -f "$TEST_DIR/$file" ]; then
        success "Test file exists: $file"
        TEST_COUNT=$((TEST_COUNT+1))
    else
        warn "Test file missing: $file"
    fi
done

if [ $TEST_COUNT -eq 0 ]; then
    error "No test files found"
fi

info "Found $TEST_COUNT test files"

# Check if site is accessible
section "Testing Site Accessibility"

info "Checking: https://$HOSTNAME"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$HOSTNAME" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    success "Site is accessible (HTTP $HTTP_STATUS)"
elif [ "$HTTP_STATUS" = "403" ]; then
    warn "Site returned HTTP 403 - content may not be deployed yet"
    read -p "Continue with tests anyway? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy](es)?$ ]]; then
        info "Tests cancelled"
        exit 0
    fi
else
    warn "Site returned HTTP $HTTP_STATUS"
    read -p "Continue with tests anyway? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy](es)?$ ]]; then
        info "Tests cancelled"
        exit 0
    fi
fi

# Run Playwright tests
section "Running Playwright Tests"

cd "$ROOT_DIR"

# Set base URL for tests
export BASE_URL="https://$HOSTNAME"

info "Base URL: $BASE_URL"
info "Test mode: $TEST_MODE"

if [ -n "$EXTRA_ARGS" ]; then
    info "Additional args: $EXTRA_ARGS"
fi

echo ""

# Run tests based on mode
case "$TEST_MODE" in
    headed)
        info "Running tests with browser visible..."
        npx playwright test $EXTRA_ARGS
        ;;
    debug)
        info "Running tests in debug mode..."
        npx playwright test $EXTRA_ARGS
        ;;
    ui)
        info "Running tests in UI mode..."
        npx playwright test $EXTRA_ARGS
        ;;
    *)
        info "Running all tests..."
        npx playwright test $EXTRA_ARGS
        ;;
esac

TEST_EXIT_CODE=$?

echo ""

# Check test results
section "Test Results"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    success "All tests passed!"

    # Check for test report
    if [ -d "$ROOT_DIR/playwright-report" ]; then
        info "Test report generated: playwright-report/"
        info "View report: npx playwright show-report"
    fi

    # Check for test results
    if [ -d "$ROOT_DIR/test-results" ]; then
        info "Test artifacts saved: test-results/"
    fi

    echo ""
    info "Test Summary:"
    echo "  Environment: $ENV_NAME"
    echo "  Base URL: $BASE_URL"
    echo "  Status: ✓ PASSED"
    echo ""

    exit 0
else
    error "Tests failed with exit code: $TEST_EXIT_CODE"

    # Check for test report
    if [ -d "$ROOT_DIR/playwright-report" ]; then
        warn "Test report generated: playwright-report/"
        info "View report: npx playwright show-report"
    fi

    # Check for test results
    if [ -d "$ROOT_DIR/test-results" ]; then
        warn "Test artifacts saved: test-results/"
        info "Screenshots and videos may be available for failed tests"
    fi

    echo ""
    warn "Test Summary:"
    echo "  Environment: $ENV_NAME"
    echo "  Base URL: $BASE_URL"
    echo "  Status: ✗ FAILED"
    echo ""
    info "Review the test output above for details"
    info "Or view the HTML report: npx playwright show-report"
    echo ""

    exit 1
fi
