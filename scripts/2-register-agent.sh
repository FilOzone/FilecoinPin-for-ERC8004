#!/bin/bash

# Demo 1: Register Agent on ERC-8004 Identity Registry
# This script registers the agent on Base Sepolia using the Filecoin-stored CID

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Change to the demo1 root directory (parent of scripts/)
cd "$SCRIPT_DIR/.."

# Load environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ .env file not found"
    exit 1
fi

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🎫 Registering Agent on ERC-8004 Identity Registry..."
echo ""

# =============================================================================
# 1. Verify prerequisites
# =============================================================================

if [ -z "$TOKEN_URI" ]; then
    echo -e "${RED}❌ TOKEN_URI not set in .env${NC}"
    echo "Set TOKEN_URI=ipfs://\$AGENT_CARD_CID first"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}❌ PRIVATE_KEY not set in .env${NC}"
    exit 1
fi

if [ -z "$BASE_SEPOLIA_RPC" ]; then
    echo -e "${RED}❌ BASE_SEPOLIA_RPC not set in .env${NC}"
    exit 1
fi

if [ -z "$IDENTITY_REGISTRY" ]; then
    echo -e "${RED}❌ IDENTITY_REGISTRY not set in .env${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Prerequisites checked"
echo ""

# =============================================================================
# 2. Display registration details
# =============================================================================

echo -e "${BLUE}📋 Registration Details:${NC}"
echo "  Network: Base Sepolia"
echo "  Contract: $IDENTITY_REGISTRY"
echo "  Token URI: $TOKEN_URI"
echo "  Wallet: ${WALLET_ADDRESS:-[from private key]}"
echo ""

# =============================================================================
# 3. Check wallet balance
# =============================================================================

echo -e "${BLUE}💰 Checking wallet balance...${NC}"

if [ -n "$WALLET_ADDRESS" ]; then
    BALANCE=$(cast balance "$WALLET_ADDRESS" --rpc-url "$BASE_SEPOLIA_RPC" --ether)
    echo "  Balance: $BALANCE ETH"

    if (( $(echo "$BALANCE < 0.01" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Low balance - consider getting more ETH${NC}"
    fi
else
    echo "  (Wallet address not set in .env, deriving from private key)"
fi

echo ""

# =============================================================================
# 4. Register agent
# =============================================================================

echo -e "${BLUE}🚀 Registering agent on-chain...${NC}"
echo ""

# The actual command to register
echo "Running:"
echo "  cast send $IDENTITY_REGISTRY \\"
echo "    \"register(string)\" \\"
echo "    \"$TOKEN_URI\" \\"
echo "    --rpc-url $BASE_SEPOLIA_RPC \\"
echo "    --private-key \$PRIVATE_KEY"
echo ""

# Uncomment to actually execute
cast send "$IDENTITY_REGISTRY" \
  "register(string)" \
  "$TOKEN_URI" \
  --rpc-url "$BASE_SEPOLIA_RPC" \
  --private-key "$PRIVATE_KEY"

# Expected output example
echo -e "${GREEN}Expected Output:${NC}"
echo "blockHash               0x1234...5678"
echo "blockNumber             12345678"
echo "contractAddress"
echo "cumulativeGasUsed       123456"
echo "effectiveGasPrice       1234567890"
echo "from                    0xYourAddress..."
echo "gasUsed                 98765"
echo "logs                    [{...}]"
echo "logsBloom               0x..."
echo "root"
echo "status                  1 (success)"
echo "transactionHash         0xabcd...ef01"
echo "transactionIndex        12"
echo "type                    2"
echo ""

# =============================================================================
# 5. Get agent ID from transaction logs
# =============================================================================

echo -e "${YELLOW}⚠️  MANUAL STEP REQUIRED:${NC}"
echo "After transaction succeeds, get your agent ID:"
echo ""
echo "Option 1: Query total agents (your ID will be the latest)"
echo "  cast call $IDENTITY_REGISTRY \\"
echo "    \"totalAgents()\" \\"
echo "    --rpc-url $BASE_SEPOLIA_RPC"
echo ""
echo "Option 2: Parse from transaction receipt logs"
echo "  (Look for 'Registered' event in transaction logs)"
echo ""
echo "Then update .env:"
echo "  AGENT_ID=42  # Your agent ID"
echo ""

# =============================================================================
# 6. Verify registration (if AGENT_ID is set)
# =============================================================================

if [ -n "$AGENT_ID" ]; then
    echo -e "${BLUE}🔍 Verifying registration...${NC}"
    echo ""

    echo "Getting token URI for agent #$AGENT_ID:"
    echo "  cast call $IDENTITY_REGISTRY \\"
    echo "    \"tokenURI(uint256)\" \\"
    echo "    $AGENT_ID \\"
    echo "    --rpc-url $BASE_SEPOLIA_RPC"
    echo ""

    # Uncomment to actually verify
    RETRIEVED_URI_RAW=$(cast call "$IDENTITY_REGISTRY" \
      "tokenURI(uint256)" \
      "$AGENT_ID" \
      --rpc-url "$BASE_SEPOLIA_RPC")
    RETRIEVED_URI=$(cast --abi-decode "f()(string)" "$RETRIEVED_URI_RAW")
    echo "Retrieved URI: $RETRIEVED_URI"

    echo "Getting owner of agent #$AGENT_ID:"
    echo "  cast call $IDENTITY_REGISTRY \\"
    echo "    \"ownerOf(uint256)\" \\"
    echo "    $AGENT_ID \\"
    echo "    --rpc-url $BASE_SEPOLIA_RPC"
    echo ""
fi

# =============================================================================
# Summary
# =============================================================================

echo -e "${GREEN}✅ Registration step complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Copy agent ID from transaction and update .env"
echo "  2. View on Base Sepolia explorer:"
echo "     https://sepolia.basescan.org/address/$IDENTITY_REGISTRY"
echo "  3. Run ./scripts/3-verify-storage.sh to check PDP proofs"
