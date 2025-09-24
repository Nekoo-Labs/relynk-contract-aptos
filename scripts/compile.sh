#!/bin/bash

# Relynk Smart Contract Compilation and Deployment Script

set -e

echo "🔥 Relynk Smart Contract Setup"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if aptos CLI is installed
if ! command -v aptos &> /dev/null; then
    echo -e "${RED}❌ Aptos CLI is not installed${NC}"
    echo -e "${YELLOW}💡 Install it from: https://aptos.dev/tools/aptos-cli/install-cli${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Aptos CLI found${NC}"

# Navigate to contract directory
cd "$(dirname "$0")/../"

echo -e "${BLUE}📁 Current directory: $(pwd)${NC}"

# Initialize Aptos account if not exists
if [ ! -f ".aptos/config.yaml" ]; then
    echo -e "${YELLOW}🔑 Initializing Aptos account...${NC}"
    aptos init --network devnet
else
    echo -e "${GREEN}✅ Aptos account already configured${NC}"
fi

# Compile the Move contracts
echo -e "${BLUE}🔨 Compiling Move contracts...${NC}"
if aptos move compile; then
    echo -e "${GREEN}✅ Compilation successful${NC}"
else
    echo -e "${RED}❌ Compilation failed${NC}"
    exit 1
fi

# Run tests if they exist
if [ -d "tests" ] && [ "$(ls -A tests)" ]; then
    echo -e "${BLUE}🧪 Running tests...${NC}"
    if aptos move test; then
        echo -e "${GREEN}✅ All tests passed${NC}"
    else
        echo -e "${RED}❌ Tests failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  No tests found, skipping...${NC}"
fi

echo -e "${GREEN}🎉 Smart contracts ready for deployment!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Fund your account: aptos account fund-with-faucet --account default"
echo "2. Deploy contracts: ./scripts/deploy.sh"
echo "3. Initialize protocol: ./scripts/initialize.sh"