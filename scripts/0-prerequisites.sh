#!/bin/bash

# Demo 1: Prerequisites Check
# This script verifies all required tools are installed and configured

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Change to the demo1 root directory (parent of scripts/)
cd "$SCRIPT_DIR/.."

echo "🔍 Checking Demo 1 Prerequisites..."
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if all prerequisites are met
ALL_GOOD=true

# =============================================================================
# 1. Check for required CLI tools
# =============================================================================

echo "📦 Checking required tools..."

# Check for cast (Foundry)
if command -v cast &> /dev/null; then
    CAST_VERSION=$(cast --version | head -n 1)
    printf "${GREEN}✓${NC} cast: $CAST_VERSION\n"
else
    printf "${RED}✗${NC} cast not found\n"
    echo "  Install Foundry: curl -L https://foundry.paradigm.xyz | bash"
    ALL_GOOD=false
fi

# Check for filecoin-pin CLI
if command -v filecoin-pin &> /dev/null; then
    printf "${GREEN}✓${NC} filecoin-pin: installed\n"
else
    printf "${RED}✗${NC} filecoin-pin not found\n"
    echo "  Install: npm install -g filecoin-pin"
    ALL_GOOD=false
fi

# Check for jq (JSON processing)
if command -v jq &> /dev/null; then
    printf "${GREEN}✓${NC} jq: installed\n"
else
    printf "${YELLOW}⚠${NC} jq not found (optional but recommended)\n"
    echo "  Install: brew install jq"
fi

# Check for curl
if command -v curl &> /dev/null; then
    printf "${GREEN}✓${NC} curl: installed\n"
else
    printf "${RED}✗${NC} curl not found\n"
    ALL_GOOD=false
fi

echo ""

# =============================================================================
# 2. Check environment variables
# =============================================================================

echo "🔐 Checking environment variables..."

if [ -f ".env" ]; then
    source .env
    printf "${GREEN}✓${NC} .env file found\n"

    if [ -n "$PRIVATE_KEY" ]; then
        printf "${GREEN}✓${NC} PRIVATE_KEY is set\n"
    else
        printf "${RED}✗${NC} PRIVATE_KEY not set in .env\n"
        ALL_GOOD=false
    fi

    if [ -n "$WALLET_ADDRESS" ]; then
        printf "${GREEN}✓${NC} WALLET_ADDRESS: $WALLET_ADDRESS\n"
    else
        printf "${YELLOW}⚠${NC} WALLET_ADDRESS not set (optional)\n"
    fi

    if [ -n "$BASE_SEPOLIA_RPC" ]; then
        printf "${GREEN}✓${NC} BASE_SEPOLIA_RPC is set\n"
    else
        printf "${RED}✗${NC} BASE_SEPOLIA_RPC not set in .env\n"
        ALL_GOOD=false
    fi
else
    printf "${RED}✗${NC} .env file not found\n"
    echo "  Copy .env.example to .env and fill in your values"
    ALL_GOOD=false
fi

echo ""

# =============================================================================
# 3. Check network connectivity
# =============================================================================

echo "🌐 Checking network connectivity..."

# Check Base Sepolia RPC
if [ -n "$BASE_SEPOLIA_RPC" ]; then
    if cast block-number --rpc-url "$BASE_SEPOLIA_RPC" &> /dev/null; then
        BLOCK_NUMBER=$(cast block-number --rpc-url "$BASE_SEPOLIA_RPC")
        printf "${GREEN}✓${NC} Base Sepolia RPC: Block #$BLOCK_NUMBER\n"
    else
        printf "${RED}✗${NC} Cannot connect to Base Sepolia RPC\n"
        ALL_GOOD=false
    fi
fi

# Check if Identity Registry contract exists
if [ -n "$IDENTITY_REGISTRY" ] && [ -n "$BASE_SEPOLIA_RPC" ]; then
    if cast code "$IDENTITY_REGISTRY" --rpc-url "$BASE_SEPOLIA_RPC" | grep -q "0x"; then
        printf "${GREEN}✓${NC} Identity Registry contract exists at $IDENTITY_REGISTRY\n"
    else
        printf "${RED}✗${NC} Identity Registry contract not found\n"
        ALL_GOOD=false
    fi
fi

echo ""

# =============================================================================
# 4. Check wallet balances
# =============================================================================

echo "💰 Checking wallet balances..."

if [ -n "$WALLET_ADDRESS" ] && [ -n "$BASE_SEPOLIA_RPC" ]; then
    ETH_BALANCE=$(cast balance "$WALLET_ADDRESS" --rpc-url "$BASE_SEPOLIA_RPC" --ether)
    echo "  Base Sepolia ETH: $ETH_BALANCE ETH"

    # Check if balance is sufficient (at least 0.01 ETH recommended)
    if (( $(echo "$ETH_BALANCE > 0.01" | bc -l) )); then
        printf "${GREEN}✓${NC} Sufficient ETH for transactions\n"
    else
        printf "${YELLOW}⚠${NC} Low ETH balance - get more from faucet\n"
        echo "  Faucet: https://www.alchemy.com/faucets/base-sepolia"
    fi
fi

# Check Filecoin Calibration balances
echo ""
echo "🪙 Checking Filecoin Calibration balances..."

if [ -n "$WALLET_ADDRESS" ]; then
    # Check tFIL balance
    FIL_BALANCE=$(cast balance "$WALLET_ADDRESS" \
      --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
      --ether 2>/dev/null || echo "0")
    echo "  tFIL: $FIL_BALANCE FIL"

    if (( $(echo "$FIL_BALANCE > 10" | bc -l) )); then
        printf "${GREEN}  ✓ Sufficient tFIL for USDFC minting${NC}\n"
    else
        printf "${YELLOW}  ⚠️  Low tFIL - get more from faucet${NC}\n"
        echo "    Faucet: https://faucet.calibnet.chainsafe-fil.io/funds.html"
    fi

    # Check USDFC balance (ERC-20)
    # Note: Using Ethereum-style address (0x...), not Filecoin t4 format
    USDFC_TOKEN="0xb3042734b608a1B16e9e86B374A3f3e389B4cDf0"
    USDFC_RAW=$(cast call "$USDFC_TOKEN" \
      "balanceOf(address)" "$WALLET_ADDRESS" \
      --rpc-url https://api.calibration.node.glif.io/rpc/v1 2>/dev/null || echo "0")

    # Convert from hex to decimal, then from wei to USDFC (18 decimals)
    USDFC_DECIMAL=$(printf "%d" "$USDFC_RAW" 2>/dev/null || echo "0")
    USDFC_BALANCE=$(echo "scale=2; $USDFC_DECIMAL / 1000000000000000000" | bc -l 2>/dev/null || echo "0")
    echo "  USDFC: $USDFC_BALANCE USDFC"

    if (( $(echo "$USDFC_BALANCE > 1" | bc -l) )); then
        printf "${GREEN}  ✓ Sufficient USDFC for Filecoin Pin uploads${NC}\n"
    else
        printf "${YELLOW}  ⚠️  Low USDFC - mint more at https://stg.usdfc.net${NC}\n"
    fi
else
    echo "  Wallet address not set - skipping balance checks"
fi

echo ""

# =============================================================================
# 5. Verify agent card JSON
# =============================================================================

echo "📄 Checking agent card..."

if [ -f "github-agent-card.json" ]; then
    printf "${GREEN}✓${NC} github-agent-card.json found\n"

    # Validate JSON syntax
    if jq empty github-agent-card.json 2>/dev/null; then
        printf "${GREEN}✓${NC} Valid JSON syntax\n"

        # Check for required ERC-8004 fields
        if jq -e '.type' github-agent-card.json > /dev/null; then
            printf "${GREEN}✓${NC} Has 'type' field\n"
        fi
        if jq -e '.name' github-agent-card.json > /dev/null; then
            printf "${GREEN}✓${NC} Has 'name' field\n"
        fi
        if jq -e '.endpoints' github-agent-card.json > /dev/null; then
            printf "${GREEN}✓${NC} Has 'endpoints' array\n"
        fi
    else
        printf "${RED}✗${NC} Invalid JSON syntax\n"
        ALL_GOOD=false
    fi
else
    printf "${RED}✗${NC} github-agent-card.json not found\n"
    ALL_GOOD=false
fi

echo ""

# =============================================================================
# Summary
# =============================================================================

if [ "$ALL_GOOD" = true ]; then
    printf "${GREEN}✅ All prerequisites met! Ready to start demo.${NC}\n"
    echo ""
    echo "Next steps:"
    echo "  1. Run ./scripts/1-upload-to-filecoin.sh"
    echo "  2. Run ./scripts/2-register-agent.sh"
    echo "  3. Run ./scripts/3-verify-storage.sh"
    exit 0
else
    printf "${RED}❌ Some prerequisites are missing. Please fix the issues above.${NC}\n"
    exit 1
fi
