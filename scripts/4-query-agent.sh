#!/bin/bash

# Demo 1: Query Agent from Registry
# This script demonstrates how other agents/apps would discover and use your agent

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

echo "🔎 Querying Agent from ERC-8004 Registry..."
echo ""

# =============================================================================
# 1. Query registry for all agents
# =============================================================================

echo -e "${BLUE}📊 Registry Statistics:${NC}"
echo ""

echo "Getting total number of registered agents:"
echo "  cast call $IDENTITY_REGISTRY \\"
echo "    \"totalAgents()\" \\"
echo "    --rpc-url $BASE_SEPOLIA_RPC"
echo ""

# Uncomment to actually query
# TOTAL_AGENTS=$(cast call "$IDENTITY_REGISTRY" \
#   "totalAgents()" \
#   --rpc-url "$BASE_SEPOLIA_RPC")
# echo "Total agents: $((TOTAL_AGENTS))"
# echo ""

# =============================================================================
# 2. Query specific agent
# =============================================================================

if [ -n "$AGENT_ID" ]; then
    echo -e "${BLUE}🤖 Agent #$AGENT_ID Details:${NC}"
    echo ""

    # Get owner
    echo "1. Getting agent owner:"
    echo "   cast call $IDENTITY_REGISTRY \\"
    echo "     \"ownerOf(uint256)\" $AGENT_ID \\"
    echo "     --rpc-url $BASE_SEPOLIA_RPC"
    echo ""

    # Get tokenURI
    echo "2. Getting agent tokenURI:"
    echo "   cast call $IDENTITY_REGISTRY \\"
    echo "     \"tokenURI(uint256)\" $AGENT_ID \\"
    echo "     --rpc-url $BASE_SEPOLIA_RPC"
    echo ""

    # Uncomment to actually query
    # OWNER=$(cast call "$IDENTITY_REGISTRY" "ownerOf(uint256)" "$AGENT_ID" --rpc-url "$BASE_SEPOLIA_RPC")
    # TOKEN_URI=$(cast call "$IDENTITY_REGISTRY" "tokenURI(uint256)" "$AGENT_ID" --rpc-url "$BASE_SEPOLIA_RPC")
    # echo "Owner: $OWNER"
    # echo "Token URI: $TOKEN_URI"
    # echo ""
fi

# =============================================================================
# 3. Retrieve and parse agent card
# =============================================================================

if [ -n "$AGENT_CARD_CID" ]; then
    echo -e "${BLUE}📄 Agent Card Content:${NC}"
    echo ""

    echo "Fetching agent card from IPFS:"
    echo "  curl -s https://ipfs.io/ipfs/$AGENT_CARD_CID | jq ."
    echo ""

    # Uncomment to actually fetch
    # AGENT_CARD=$(curl -s "https://ipfs.io/ipfs/$AGENT_CARD_CID")
    # echo "$AGENT_CARD" | jq .
    # echo ""

    echo "Extracting MCP endpoint:"
    echo "  curl -s https://ipfs.io/ipfs/$AGENT_CARD_CID | jq '.endpoints[] | select(.name==\"MCP\")'"
    echo ""

    echo -e "${GREEN}Expected Output:${NC}"
    echo "{"
    echo "  \"name\": \"MCP\","
    echo "  \"endpoint\": \"https://api.githubcopilot.com/mcp/\","
    echo "  \"version\": \"1.0.0\","
    echo "  \"capabilities\": {...}"
    echo "}"
    echo ""
fi

# =============================================================================
# 4. Simulate agent discovery workflow
# =============================================================================

echo -e "${BLUE}🔄 Agent Discovery Workflow:${NC}"
echo ""
echo "This is how another agent/application would discover and use your agent:"
echo ""

cat << 'EOF'
#!/bin/bash
# Agent Discovery Example

REGISTRY="0x7177a6867296406881E20d6647232314736Dd09A"
RPC="https://sepolia.base.org"

# 1. Search registry for agents (in real implementation, might filter by capabilities)
TOTAL=$(cast call "$REGISTRY" "totalAgents()" --rpc-url "$RPC")
echo "Found $TOTAL agents in registry"

# 2. For each agent, get tokenURI
for AGENT_ID in $(seq 1 $TOTAL); do
    TOKEN_URI=$(cast call "$REGISTRY" "tokenURI(uint256)" "$AGENT_ID" --rpc-url "$RPC")

    # 3. Extract CID from tokenURI
    CID=${TOKEN_URI#ipfs://}

    # 4. Fetch agent card
    AGENT_CARD=$(curl -s "https://ipfs.io/ipfs/$CID")

    # 5. Check if agent has desired capability (e.g., GitHub MCP)
    HAS_GITHUB=$(echo "$AGENT_CARD" | jq -r '.endpoints[] | select(.name=="MCP" and .endpoint | contains("github")) | .endpoint')

    if [ -n "$HAS_GITHUB" ]; then
        echo "Found GitHub MCP agent: Agent #$AGENT_ID"
        echo "MCP Endpoint: $HAS_GITHUB"

        # 6. Use the agent's MCP endpoint
        # (In real implementation, connect to MCP server and use tools)
    fi
done
EOF

echo ""

# =============================================================================
# 5. Demonstrate agent usage
# =============================================================================

echo -e "${BLUE}🚀 Using the Agent:${NC}"
echo ""
echo "Once discovered, an application would:"
echo ""
echo "1. Connect to MCP endpoint: https://api.githubcopilot.com/mcp/"
echo "2. Authenticate (OAuth or PAT)"
echo "3. Call available tools:"
echo "   - repository_management"
echo "   - issue_management"
echo "   - pull_request_management"
echo ""
echo "Example MCP tool call (pseudo-code):"
cat << 'EOF'

// Connect to GitHub MCP agent
const agent = await connectToMCPServer({
  endpoint: "https://api.githubcopilot.com/mcp/",
  auth: { type: "oauth" }
});

// Use repository management tool
const result = await agent.tools.repository_management({
  action: "search_files",
  repo: "user/repo",
  query: "function main"
});

console.log(result);
EOF

echo ""

# =============================================================================
# Summary
# =============================================================================

echo -e "${GREEN}✅ Query demonstration complete!${NC}"
echo ""
echo "Key Takeaways:"
echo "  🔍 Agents are discoverable via ERC-8004 registry"
echo "  📄 Agent cards are retrievable from IPFS"
echo "  🔒 Storage is verifiable via PDP proofs"
echo "  🌐 Endpoints are machine-readable and standardized"
echo "  🤝 Agents can find and interact with each other"
echo ""
echo "This enables:"
echo "  • Agent-to-agent (A2A) communication"
echo "  • Decentralized agent discovery"
echo "  • Trustless agent verification"
echo "  • Composable agent ecosystems"
