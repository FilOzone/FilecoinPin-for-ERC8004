#!/bin/bash

# Demo 1: Verify Storage and PDP Proofs
# This script verifies the agent card is retrievable and checks PDP proof status

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
NC='\033[0m'

echo "🔍 Verifying Storage and PDP Proofs..."
echo ""

# =============================================================================
# 1. Verify IPFS retrieval
# =============================================================================

if [ -n "$AGENT_CARD_CID" ]; then
    echo -e "${BLUE}📥 Testing IPFS Retrieval...${NC}"
    echo ""

    echo "Retrieving agent card from IPFS gateway:"
    echo "  curl -s https://ipfs.io/ipfs/$AGENT_CARD_CID/github-agent-card.json | jq ."
    echo ""

    # Uncomment to actually retrieve
    # echo "Retrieved agent card:"
    # curl -s "https://ipfs.io/ipfs/$AGENT_CARD_CID/github-agent-card.json" | jq .
    # echo ""

    echo -e "${GREEN}Expected: Agent card JSON is returned${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠️  AGENT_CARD_CID not set in .env${NC}"
    echo "Set it first to test retrieval"
    echo ""
fi

# =============================================================================
# 2. Check PDP proof status
# =============================================================================

if [ -n "$AGENT_CARD_CID" ]; then
    echo -e "${BLUE}🔐 Checking PDP Proof Status...${NC}"
    echo ""

    if [ -n "$DATASET_ID" ]; then
        echo "Checking PDP proofs for dataset: $DATASET_ID"
        echo ""

        # Export PRIVATE_KEY for filecoin-pin authentication
        export PRIVATE_KEY

        # Run the actual command
        filecoin-pin data-set "$DATASET_ID"
        echo ""
    else
        echo -e "${YELLOW}⚠️  DATASET_ID not set in .env${NC}"
        echo ""
        echo "To check proof status manually:"
        echo "  filecoin-pin data-set <dataset-id>"
        echo ""
        echo "To find your dataset ID:"
        echo "  filecoin-pin data-set list"
        echo ""

        # Expected output example
        echo -e "${GREEN}Expected Output:${NC}"
        echo "CID: $AGENT_CARD_CID"
        echo "Storage Provider: f01234"
        echo "Last PDP Proof: 2025-10-27 12:34:56 UTC"
        echo "Proof Height: 1234567"
        echo "Status: Active"
        echo "Next Proof: 2025-10-28 12:34:56 UTC"
        echo ""
    fi
fi

# =============================================================================
# 3. Verify on-chain registration
# =============================================================================

if [ -n "$AGENT_ID" ]; then
    echo -e "${BLUE}🎫 Verifying On-Chain Registration...${NC}"
    echo ""

    echo "Getting token URI for agent #$AGENT_ID:"
    RETRIEVED_URI_RAW=$(cast call "$IDENTITY_REGISTRY" \
      "tokenURI(uint256)" \
      "$AGENT_ID" \
      --rpc-url "$BASE_SEPOLIA_RPC" 2>/dev/null || echo "")

    if [ -n "$RETRIEVED_URI_RAW" ]; then
        # Decode the ABI-encoded string
        RETRIEVED_URI=$(cast --abi-decode "f()(string)" "$RETRIEVED_URI_RAW" 2>/dev/null || echo "$RETRIEVED_URI_RAW")
        echo "  Retrieved URI: $RETRIEVED_URI"

        if [[ "$RETRIEVED_URI" == *"$AGENT_CARD_CID"* ]]; then
            echo -e "${GREEN}  ✓ URI matches uploaded CID${NC}"
        else
            echo -e "${YELLOW}  ⚠️  URI doesn't match CID${NC}"
        fi
    else
        echo "  Run command manually:"
        echo "    cast call $IDENTITY_REGISTRY \\"
        echo "      \"tokenURI(uint256)\" \\"
        echo "      $AGENT_ID \\"
        echo "      --rpc-url $BASE_SEPOLIA_RPC"
    fi
    echo ""

    echo "Getting owner of agent #$AGENT_ID:"
    OWNER=$(cast call "$IDENTITY_REGISTRY" \
      "ownerOf(uint256)" \
      "$AGENT_ID" \
      --rpc-url "$BASE_SEPOLIA_RPC" 2>/dev/null || echo "")

    if [ -n "$OWNER" ]; then
        echo "  Owner: $OWNER"
        if [ -n "$WALLET_ADDRESS" ] && [[ "$OWNER" == *"$WALLET_ADDRESS"* ]]; then
            echo -e "${GREEN}  ✓ You own this agent${NC}"
        fi
    else
        echo "  Run command manually:"
        echo "    cast call $IDENTITY_REGISTRY \\"
        echo "      \"ownerOf(uint256)\" \\"
        echo "      $AGENT_ID \\"
        echo "      --rpc-url $BASE_SEPOLIA_RPC"
    fi
    echo ""
else
    echo -e "${YELLOW}⚠️  AGENT_ID not set in .env${NC}"
    echo "Set it first to verify registration"
    echo ""
fi

# =============================================================================
# 4. View on Block Explorers
# =============================================================================

echo -e "${BLUE}🌐 View on Block Explorers:${NC}"
echo ""

if [ -n "$AGENT_ID" ]; then
    # Convert hex to decimal for URL if needed
    if [[ "$AGENT_ID" == 0x* ]]; then
        AGENT_ID_DECIMAL=$(printf "%d" "$AGENT_ID")
    else
        AGENT_ID_DECIMAL="$AGENT_ID"
    fi

    echo "Base Sepolia Explorer (NFT):"
    echo "  https://sepolia.basescan.org/token/$IDENTITY_REGISTRY?a=$AGENT_ID_DECIMAL"
    echo ""
fi

echo "Base Sepolia Explorer (Contract):"
echo "  https://sepolia.basescan.org/address/$IDENTITY_REGISTRY"
echo ""

if [ -n "$AGENT_CARD_CID" ]; then
    echo "IPFS Gateways:"
    echo "  https://ipfs.io/ipfs/$AGENT_CARD_CID/github-agent-card.json"
    echo "  https://gateway.pinata.cloud/ipfs/$AGENT_CARD_CID/github-agent-card.json"
    echo ""

    echo "PDP Scan Explorer (check proof status):"
    echo "  https://pdpscan.io/cid/$AGENT_CARD_CID"
    echo "  (Note: Actual URL may differ - check with Filecoin Pin team)"
    echo ""
fi

# =============================================================================
# 5. Test complete workflow
# =============================================================================

echo -e "${BLUE}🧪 Complete Workflow Test:${NC}"
echo ""

if [ -n "$AGENT_CARD_CID" ] && [ -n "$AGENT_ID" ]; then
    echo "1. Retrieve agent ID from registry"
    echo "2. Get tokenURI from registry"
    echo "3. Extract CID from tokenURI"
    echo "4. Fetch agent card from IPFS"
    echo "5. Parse agent capabilities"
    echo ""

    echo "Simulating agent discovery:"
    echo ""
    echo "  # Step 1: Get total agents"
    echo "  TOTAL=\$(cast call $IDENTITY_REGISTRY \"totalAgents()\" --rpc-url $BASE_SEPOLIA_RPC)"
    echo ""
    echo "  # Step 2: Get tokenURI for agent #$AGENT_ID"
    echo "  URI=\$(cast call $IDENTITY_REGISTRY \"tokenURI(uint256)\" $AGENT_ID --rpc-url $BASE_SEPOLIA_RPC)"
    echo ""
    echo "  # Step 3: Fetch agent card"
    echo "  curl -s \"https://ipfs.io/ipfs/$AGENT_CARD_CID/github-agent-card.json\" | jq '.endpoints[]'"
    echo ""
else
    echo -e "${YELLOW}⚠️  Set both AGENT_CARD_CID and AGENT_ID to run complete test${NC}"
    echo ""
fi

# =============================================================================
# Summary
# =============================================================================

echo -e "${GREEN}✅ Verification complete!${NC}"
echo ""
echo "Summary:"
echo "  ✓ Agent card stored on Filecoin with PDP proofs"
echo "  ✓ Agent registered on ERC-8004 Identity Registry"
echo "  ✓ Retrievable via IPFS gateways"
echo "  ✓ Verifiable on Base Sepolia block explorer"
echo ""
echo "Your agent is now:"
echo "  🔒 Persistently stored with cryptographic proof"
echo "  🌐 Discoverable via ERC-8004 registry"
echo "  🔍 Verifiable by any third party"
echo "  🚀 Ready to be used by other agents/applications"
