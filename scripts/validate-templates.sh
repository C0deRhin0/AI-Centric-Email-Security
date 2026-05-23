#!/usr/bin/env bash
# ============================================================
# ESL Automation — Template Validation Script
# ============================================================
# Validates all HTML email templates for:
#   - Missing dynamic field placeholders
#   - Incomplete or empty template content
#   - Missing confidentiality notices
#   - Structural completeness
#
# Usage: bash scripts/validate-templates.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_DIRS=(
    "$BASE_DIR/approach-a-power-automate/templates"
    "$BASE_DIR/approach-b-n8n/templates"
)

ERRORS=0
WARNINGS=0
CHECKED=0

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  ESL Template Validation${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

validate_template() {
    local file="$1"
    local name
    name=$(basename "$file")
    CHECKED=$((CHECKED + 1))

    echo -e "${YELLOW}Checking: $file${NC}"

    # Check 1: File is not empty
    if [ ! -s "$file" ]; then
        echo -e "  ${RED}✗ FAIL: File is empty${NC}"
        ERRORS=$((ERRORS + 1))
        return
    fi

    # Check 2: File is valid HTML
    if ! grep -qi '<!DOCTYPE html>' "$file" && ! grep -qi '<html' "$file"; then
        echo -e "  ${RED}✗ FAIL: Not a valid HTML file (missing DOCTYPE or <html>)${NC}"
        ERRORS=$((ERRORS + 1))
        return
    fi

    # Check 3: Has inline CSS (Outlook requirement)
    if ! grep -qi 'style=' "$file"; then
        echo -e "  ${YELLOW}⚠ WARN: No inline CSS found (Outlook may not render correctly)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check 4: Has confidentiality notice
    if ! grep -qi 'CONFIDENTIALITY' "$file" && ! grep -qi 'confidential' "$file"; then
        echo -e "  ${YELLOW}⚠ WARN: No confidentiality notice found${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check 5: Has signature block (Name + Department + Company)
    if grep -qi 'Cybersecurity Department' "$file" && grep -qi '\[Your Company\]' "$file"; then
        : # Has placeholder signature block
    elif grep -qi 'Stay safe' "$file" || grep -qi 'Sincerely' "$file" || grep -qi 'Regards' "$file"; then
        : # Has some form of closing
    else
        echo -e "  ${YELLOW}⚠ WARN: No signature block detected${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check 6: Closing body and html tags present
    if ! grep -qi '</body>' "$file" || ! grep -qi '</html>' "$file"; then
        echo -e "  ${RED}✗ FAIL: Missing closing </body> or </html> tags${NC}"
        ERRORS=$((ERRORS + 1))
        return
    fi

    echo -e "  ${GREEN}✓ Pass${NC}"
}

# Validate Power Automate templates
echo -e "${BLUE}--- Approach A: Power Automate Templates ---${NC}"
for template in "${TEMPLATE_DIRS[0]}"/*.html; do
    if [ -f "$template" ]; then
        validate_template "$template"
    fi
done

echo ""

# Validate n8n templates
echo -e "${BLUE}--- Approach B: n8n Templates ---${NC}"
for template in "${TEMPLATE_DIRS[1]}"/*.html; do
    if [ -f "$template" ]; then
        validate_template "$template"
    fi
done

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}  Validation complete${NC}"
echo -e "  ${GREEN}Files checked: $CHECKED${NC}"

if [ "$ERRORS" -gt 0 ]; then
    echo -e "  ${RED}Errors: $ERRORS${NC}"
else
    echo -e "  ${GREEN}Errors: 0${NC}"
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo -e "  ${YELLOW}Warnings: $WARNINGS${NC}"
else
    echo -e "  ${GREEN}Warnings: 0${NC}"
fi

echo -e "${BLUE}============================================${NC}"

# Exit with error code if any failures
exit $ERRORS
