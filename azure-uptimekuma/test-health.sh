#!/bin/bash
# Health test script for Azure Uptime Kuma
# Can be run locally or in CI/CD pipeline

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================================"
echo "Azure Uptime Kuma - Health Check"
echo "================================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Test function
test_step() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name ... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

# Get infrastructure outputs
echo "📡 Getting infrastructure details..."
if command -v tofu &> /dev/null; then
    UPTIME_URL=$(tofu output -raw uptimekuma_url 2>/dev/null || echo "")
    UPTIME_FQDN=$(tofu output -raw uptimekuma_fqdn 2>/dev/null || echo "")
    UPTIME_IP=$(tofu output -raw uptimekuma_ip 2>/dev/null || echo "")
    STORAGE_ACCOUNT=$(tofu output -raw storage_account_name 2>/dev/null || echo "")
else
    echo -e "${YELLOW}⚠️  OpenTofu not installed, skipping output retrieval${NC}"
    UPTIME_URL=""
fi

if [ -z "$UPTIME_URL" ]; then
    echo -e "${RED}❌ Could not retrieve infrastructure outputs${NC}"
    echo "Run 'tofu init' and 'tofu apply' first"
    exit 1
fi

echo "URL: $UPTIME_URL"
echo "FQDN: $UPTIME_FQDN"
echo "IP: $UPTIME_IP"
echo ""

# Run tests
echo "🧪 Running health tests..."
echo ""

# Test 1: DNS Resolution
if [ -n "$UPTIME_FQDN" ]; then
    test_step "DNS Resolution" "nslookup $UPTIME_FQDN"
fi

# Test 2: HTTP Connectivity
if [ -n "$UPTIME_URL" ]; then
    test_step "HTTP Connectivity" "curl -s -o /dev/null -w '%{http_code}' '$UPTIME_URL' | grep -E '200|301|302'"
fi

# Test 3: Response Time
if [ -n "$UPTIME_URL" ]; then
    echo -n "Testing: Response Time ... "
    RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' "$UPTIME_URL" 2>/dev/null || echo "999")
    if (( $(echo "$RESPONSE_TIME < 5" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${GREEN}✅ PASS${NC} (${RESPONSE_TIME}s)"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠️  SLOW${NC} (${RESPONSE_TIME}s)"
        ((PASSED++))
    fi
fi

# Test 4: Azure CLI - Resource Group
if command -v az &> /dev/null; then
    test_step "Azure Resource Group" "az group show --name rg-uptimekuma-monitoring"
    
    # Test 5: Container Status
    echo -n "Testing: Container Status ... "
    CONTAINER_STATUS=$(az container show \
        --resource-group rg-uptimekuma-monitoring \
        --name uptimekuma \
        --query "instanceView.state" -o tsv 2>/dev/null || echo "Unknown")
    
    if [ "$CONTAINER_STATUS" = "Running" ]; then
        echo -e "${GREEN}✅ PASS${NC} (Running)"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC} (Status: $CONTAINER_STATUS)"
        ((FAILED++))
    fi
    
    # Test 6: Storage Account
    if [ -n "$STORAGE_ACCOUNT" ]; then
        test_step "Storage Account" "az storage account show --name $STORAGE_ACCOUNT --resource-group rg-uptimekuma-monitoring"
    else
        echo -e "${YELLOW}⚠️  Storage account name not available${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Azure CLI not installed, skipping Azure-specific tests${NC}"
fi

# Summary
echo ""
echo "================================================"
echo "Test Summary"
echo "================================================"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
