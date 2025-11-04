#!/bin/bash

# Demo 1: Upload Agent Card to Filecoin Pin
# This script uploads the GitHub agent card JSON to Filecoin via IPFS

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Change to the demo1 root directory (parent of scripts/)
cd "$SCRIPT_DIR/.."

# Load environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "❌ .env file not found. Copy .env.example to .env and configure it."
    exit 1
fi

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📤 Uploading Agent Card to Filecoin Pin..."
echo ""

# =============================================================================
# 1. Verify agent card exists
# =============================================================================

AGENT_CARD="github-agent-card.json"

if [ ! -f "$AGENT_CARD" ]; then
    echo "❌ Agent card not found at $AGENT_CARD"
    exit 1
fi

echo -e "${BLUE}📄 Agent Card:${NC}"
cat "$AGENT_CARD" | jq .
echo ""

# =============================================================================
# 2. Setup payments (first time only)
# =============================================================================

echo -e "${BLUE}💳 Setting up payment system...${NC}"
echo ""

# Export PRIVATE_KEY so filecoin-pin can use it
export PRIVATE_KEY

echo "Running: filecoin-pin payments setup --auto"
echo "(This only needs to be done once)"
echo ""

filecoin-pin payments setup --auto

echo ""
echo -e "${GREEN}✓${NC} Payment setup complete"
echo ""

# =============================================================================
# 3. Upload to Filecoin Pin
# =============================================================================

echo -e "${BLUE}🚀 Uploading to Filecoin Pin...${NC}"
echo ""

echo "Running: filecoin-pin add --auto-fund $AGENT_CARD"
echo ""

filecoin-pin add --auto-fund "$AGENT_CARD"

# Expected output (example):
echo -e "${GREEN}Expected Output:${NC}"
echo "✓ File uploaded successfully"
echo "CID: QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG"
echo "Size: 892 bytes"
echo "Storage deal created: bafyreib..."
echo "PDP proofs will begin within 24 hours"
echo ""

# =============================================================================
# 3. Save CID for next steps
# =============================================================================

echo -e "${YELLOW}⚠️  MANUAL STEP REQUIRED:${NC}"
echo "After upload completes, update your .env file with these values:"
echo ""
echo "  AGENT_CARD_CID=Qm...  # The CID from upload output"
echo "  TOKEN_URI=ipfs://Qm.../github-agent-card.json  # ipfs:// + CID + filename"
echo "  DATASET_ID=...  # Dataset ID from upload (for PDP proof checking)"
echo ""
echo "NOTE: The TOKEN_URI must include the filename (github-agent-card.json) at the end!"
echo ""
echo "To get the dataset ID if you missed it:"
echo "  filecoin-pin data-set list"
echo ""

# =============================================================================
# 4. Verify upload (after CID is set)
# =============================================================================

if [ -n "$AGENT_CARD_CID" ]; then
    echo -e "${BLUE}🔍 Verifying upload...${NC}"
    echo ""

    # Retrieve via IPFS gateway
    echo "Retrieving via IPFS gateway:"
    echo "  curl https://ipfs.io/ipfs/$AGENT_CARD_CID"
    echo ""

    # Check with filecoin-pin
    echo "Checking status:"
    echo "  filecoin-pin data-set <dataset-id>"
    echo ""
else
    echo -e "${YELLOW}💡 After setting AGENT_CARD_CID in .env, you can verify with:${NC}"
    echo "  curl https://ipfs.io/ipfs/\$AGENT_CARD_CID | jq ."
    echo ""
fi

# =============================================================================
# Summary
# =============================================================================

echo -e "${GREEN}✅ Upload step complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Update .env with AGENT_CARD_CID and TOKEN_URI"
echo "  2. Run ./scripts/2-register-agent.sh to register on Base Sepolia"
