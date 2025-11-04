# ERC-8004 Agent Registration with Filecoin Pin

This repository contains everything you need to register an existing service as an [ERC-8004](https://eips.ethereum.org/EIPS/eip-8004) compliant agent with verifiable persistent storage on Filecoin.

## What This Does

ERC-8004 is a standard for registering trustless autonomous agents on-chain. The challenge has always been: where do you store the agent metadata (the JSON file describing what an agent does and how to connect to it)?

This demo shows you how to:
1. Store agent metadata on Filecoin with cryptographic proof (PDP - Proof of Data Possession)
2. Register the agent on the ERC-8004 Identity Registry (Base Sepolia testnet)
3. Verify that your agent is discoverable and its storage is provably persistent

> **⚠️ Important**: This is currently a testnet-only demo. Both Filecoin Pin and this implementation run on Filecoin Calibration testnet, which has no persistence guarantees and limited data retention. Filecoin Pin is not yet available on mainnet. For production use, you'll need to wait for mainnet support.

## Learn More

- **Blog Post**: [Making Services Discoverable with ERC-8004](https://dev.to/hammertoe/making-services-discoverable-with-erc-8004-trustless-agent-registration-with-filecoin-pin-1al3)
- **Tutorial**: [ERC-8004 Agent Registration with Filecoin Pin](https://docs.filecoin.io/builder-cookbook/filecoin-pin/erc-8004-agent-registration)

## What You'll Build

By the end of this, you'll have:
- An agent card (JSON metadata) stored on Filecoin with daily PDP proofs
- An ERC-721 NFT representing your agent on Base Sepolia
- A discoverable, verifiable agent identity that other agents can find and use

The example in this repo registers GitHub's official MCP server as an ERC-8004 agent, but you can adapt it for any service you want to make discoverable.

## Prerequisites

### Required Tools

You'll need these installed:

1. **[Filecoin Pin CLI](https://docs.filecoin.io/builder-cookbook/filecoin-pin/filecoin-pin-cli)** - For uploading to Filecoin with PDP proofs
   ```bash
   npm install -g filecoin-pin
   ```

2. **[Foundry](https://book.getfoundry.sh/getting-started/installation)** - Ethereum development toolkit (we use `cast` for contract interactions)
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

3. **jq** (optional but recommended) - JSON processor for viewing outputs
   ```bash
   # macOS
   brew install jq

   # Ubuntu/Debian
   sudo apt-get install jq
   ```

### Required Testnet Tokens

You'll need tokens on **two testnets**:

#### Filecoin Calibration Testnet
- **tFIL** (testnet Filecoin) - For gas fees
  - Faucet: https://faucet.calibnet.chainsafe-fil.io/funds.html
  - Amount needed: ~5 tFIL
- **USDFC** (Filecoin stablecoin) - For storage payments
  - Mint at: https://stg.usdfc.net (requires tFIL as collateral)
  - Amount needed: ~5 USDFC

#### Base Sepolia Testnet
- **Sepolia ETH** - For NFT minting and registration
  - Faucet: https://www.alchemy.com/faucets/base-sepolia
  - Amount needed: ~0.001 ETH

> **Note**: The same Ethereum wallet works on both Filecoin Calibration and Base Sepolia. You only need one private key.

## Getting Started

### 1. Clone and Configure

```bash
git clone https://github.com/[your-username]/FilecoinPin-for-ERC8004.git
cd FilecoinPin-for-ERC8004
```

### 2. Set Up Environment

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
```

Edit `.env` and add:
- Your private key (with 0x prefix)
- Your wallet address

The other values are pre-configured for the testnets.

### 3. Get Testnet Tokens

Visit the faucets listed in the Prerequisites section to get:
1. tFIL from the Filecoin Calibration faucet
2. USDFC by minting at stg.usdfc.net
3. Sepolia ETH from the Base Sepolia faucet

### 4. Customise Your Agent Card (Optional)

The repo includes `github-agent-card.json` which registers GitHub's MCP server. If you want to register your own service:

1. Edit `github-agent-card.json`
2. Update the `name`, `description`, and `endpoints` to match your service
3. Follow the [ERC-8004 specification](https://eips.ethereum.org/EIPS/eip-8004) for the schema

## Usage

Run the scripts in order:

### Step 0: Check Prerequisites

```bash
./scripts/0-prerequisites.sh
```

This verifies you have all the required tools and testnet tokens.

### Step 1: Upload to Filecoin Pin

```bash
./scripts/1-upload-to-filecoin.sh
```

This uploads your agent card to Filecoin with PDP proofs and returns a CID (Content Identifier).

**Important**: Copy the `AGENT_CARD_CID` and `DATASET_ID` from the output and add them to your `.env` file.

### Step 2: Register on Base Sepolia

```bash
./scripts/2-register-agent.sh
```

This mints an ERC-721 NFT representing your agent on the ERC-8004 Identity Registry.

**Important**: Copy the `AGENT_ID` from the output and add it to your `.env` file.

### Step 3: Verify Storage and Registration

```bash
./scripts/3-verify-storage.sh
```

This verifies:
- Your agent card is retrievable via IPFS
- PDP proofs are active
- Your agent is registered on-chain
- The tokenURI matches your uploaded content

### Step 4: Query Your Agent

```bash
./scripts/4-query-agent.sh
```

This demonstrates how other agents/applications would discover and use your agent:
1. Query the registry for your agent ID
2. Retrieve the tokenURI
3. Fetch the agent card from IPFS
4. Parse capabilities

## Repository Structure

```
FilecoinPin-for-ERC8004/
├── README.md                      # This file
├── .env.example                   # Environment template
├── github-agent-card.json         # Example agent card (GitHub MCP server)
└── scripts/
    ├── 0-prerequisites.sh         # Check tools and tokens
    ├── 1-upload-to-filecoin.sh    # Upload to Filecoin Pin
    ├── 2-register-agent.sh        # Register on ERC-8004 registry
    ├── 3-verify-storage.sh        # Verify storage and registration
    └── 4-query-agent.sh           # Demonstrate agent discovery
```

## What You Get

After running these scripts successfully, you'll have:

- ✅ **Persistent storage** - Your agent card stored on Filecoin with cryptographic PDP proofs
- ✅ **On-chain registration** - An ERC-721 NFT representing your agent on Base Sepolia
- ✅ **Discoverability** - Other agents can find your agent via the ERC-8004 registry
- ✅ **Verifiability** - Anyone can verify your storage proofs and on-chain data
- ✅ **IPFS compatibility** - Your agent card is accessible via any IPFS gateway

## Troubleshooting

### `filecoin-pin: command not found`
Install the Filecoin Pin CLI:
```bash
npm install -g filecoin-pin
```

### `Insufficient USDFC`
Mint more USDFC at https://stg.usdfc.net using tFIL as collateral.

### `Transaction reverted` on Base Sepolia
Check your Base Sepolia ETH balance and get more from the faucet if needed.

### IPFS retrieval is slow
IPFS propagation can take a few minutes. Try different gateways:
- https://ipfs.io/ipfs/<CID>/github-agent-card.json
- https://gateway.pinata.cloud/ipfs/<CID>/github-agent-card.json
- https://cloudflare-ipfs.com/ipfs/<CID>/github-agent-card.json

### PDP proofs not showing
PDP proofs can take up to 24 hours to begin after upload. This is normal - your data is still stored, proofs just take time to generate.

## Resources

- **ERC-8004 Specification**: https://eips.ethereum.org/EIPS/eip-8004
- **Filecoin Pin Documentation**: https://docs.filecoin.io/builder-cookbook/filecoin-pin
- **Base Sepolia Explorer**: https://sepolia.basescan.org
- **ERC-8004 Reference Implementation**: https://github.com/ChaosChain/trustless-agents-erc-ri

## Contributing

This is an experimental demo running on testnets. We'd love feedback on what works and what doesn't!

If you encounter issues or have suggestions, please open an issue on GitHub.

## Licence

MIT
