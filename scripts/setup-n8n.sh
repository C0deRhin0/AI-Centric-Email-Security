#!/usr/bin/env bash
# ============================================================
# ESL Automation — n8n Setup Script (Linux / macOS)
# ============================================================
# This script installs n8n and configures it for the ESL
# email security automation workflow.
#
# Usage: bash setup-n8n.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  ESL Automation — n8n Setup Script${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ----------------------------------------------------------
# Step 1: Check for Node.js
# ----------------------------------------------------------
echo -e "${YELLOW}[1/5] Checking Node.js installation...${NC}"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "  ${GREEN}✓ Node.js found: ${NODE_VERSION}${NC}"
else
    echo -e "  ${RED}✗ Node.js is not installed.${NC}"
    echo -e "  Please install Node.js LTS from: https://nodejs.org"
    echo -e "  Or use your package manager:"
    echo -e "    macOS: brew install node"
    echo -e "    Ubuntu/Debian: sudo apt install nodejs npm"
    exit 1
fi

# Extract major version
NODE_MAJOR=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_MAJOR" -lt 18 ]; then
    echo -e "  ${RED}✗ Node.js 18+ is required. Found version ${NODE_VERSION}${NC}"
    exit 1
fi

# ----------------------------------------------------------
# Step 2: Install n8n globally
# ----------------------------------------------------------
echo -e "${YELLOW}[2/5] Installing n8n globally...${NC}"

npm install -g n8n
echo -e "  ${GREEN}✓ n8n installed successfully${NC}"

# ----------------------------------------------------------
# Step 3: Verify installation
# ----------------------------------------------------------
echo -e "${YELLOW}[3/5] Verifying n8n installation...${NC}"

if command -v n8n &> /dev/null; then
    N8N_VERSION=$(n8n --version 2>/dev/null || echo "version detected")
    echo -e "  ${GREEN}✓ n8n is installed: ${N8N_VERSION}${NC}"
else
    echo -e "  ${RED}✗ n8n command not found after install${NC}"
    echo -e "  Check your npm global bin path: npm root -g"
    exit 1
fi

# ----------------------------------------------------------
# Step 4: Check for pm2 (optional, for VPS/always-on)
# ----------------------------------------------------------
echo -e "${YELLOW}[4/5] Checking for pm2 (optional, for always-on)...${NC}"

if command -v pm2 &> /dev/null; then
    echo -e "  ${GREEN}✓ pm2 is available${NC}"
    echo -e "  To start n8n with pm2: pm2 start n8n -- --start"
    echo -e "  To save pm2 config: pm2 save"
    echo -e "  To enable startup: pm2 startup"
else
    echo -e "  ${YELLOW}  pm2 not found — optional for VPS always-on.${NC}"
    echo -e "  Install with: npm install -g pm2"
fi

# ----------------------------------------------------------
# Step 5: Setup instructions
# ----------------------------------------------------------
echo -e "${YELLOW}[5/5] Setup complete! Quick start instructions:${NC}"
echo ""
echo -e "  ${GREEN}1. Start n8n:${NC}"
echo -e "     n8n"
echo ""
echo -e "  ${GREEN}2. Open n8n editor:${NC}"
echo -e "     http://localhost:5678"
echo ""
echo -e "  ${GREEN}3. Create your local account:${NC}"
echo -e "     Enter any email and password (local only — not transmitted)"
echo ""
echo -e "  ${GREEN}4. Import the ESL workflow:${NC}"
echo -e "     Download from: https://github.com/[your-repo]/codebase/approach-b-n8n/workflow.json"
echo -e "     In n8n: Workflows → Import from File"
echo ""
echo -e "  ${GREEN}5. Configure OAuth:${NC}"
echo -e "     See docs/oauth-setup.md for Azure App Registration guide"
echo ""
echo -e "  ${GREEN}6. Set up always-on (optional):${NC}"
echo -e "     - Windows: Use Task Scheduler"
echo -e "     - Linux: Use systemd or pm2"
echo -e "     - macOS: Use launchd or pm2"
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}  n8n setup complete! Happy automating! 🚀${NC}"
echo -e "${BLUE}============================================${NC}"
