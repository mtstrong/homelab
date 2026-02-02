#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Setting up Azure Storage Backend for OpenTofu State ===${NC}\n"

# Configuration
RESOURCE_GROUP="rg-tofu-state"
STORAGE_ACCOUNT="sttofustate$(date +%s | tail -c 6)" # Generate unique name
CONTAINER_NAME="tfstate"
LOCATION="eastus"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Container: $CONTAINER_NAME"
echo "  Location: $LOCATION"
echo ""

# Check if already logged in
echo -e "${BLUE}Checking Azure authentication...${NC}"
if ! az account show &> /dev/null; then
    echo "Not logged in. Please run 'az login' first."
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✓ Logged in to subscription: $SUBSCRIPTION_ID${NC}\n"

# Create resource group
echo -e "${BLUE}Creating resource group...${NC}"
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}Resource group already exists${NC}"
else
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
    echo -e "${GREEN}✓ Resource group created${NC}"
fi

# Create storage account
echo -e "\n${BLUE}Creating storage account...${NC}"
if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}Storage account already exists${NC}"
else
    az storage account create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --sku Standard_LRS \
        --encryption-services blob \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --output none
    echo -e "${GREEN}✓ Storage account created${NC}"
fi

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$STORAGE_ACCOUNT" \
    --query '[0].value' -o tsv)

# Create blob container
echo -e "\n${BLUE}Creating blob container...${NC}"
if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --account-key "$ACCOUNT_KEY" &> /dev/null; then
    echo -e "${YELLOW}Container already exists${NC}"
else
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$ACCOUNT_KEY" \
        --output none
    echo -e "${GREEN}✓ Container created${NC}"
fi

# Create backend configuration file
echo -e "\n${BLUE}Creating backend configuration...${NC}"
cat > backend-config.tfvars <<EOF
resource_group_name  = "$RESOURCE_GROUP"
storage_account_name = "$STORAGE_ACCOUNT"
container_name       = "$CONTAINER_NAME"
key                  = "uptimekuma.tfstate"
EOF

echo -e "${GREEN}✓ Backend config saved to backend-config.tfvars${NC}"

# Update main.tf with backend block
echo -e "\n${BLUE}Updating main.tf with backend configuration...${NC}"
cat > backend.tf <<EOF
terraform {
  backend "azurerm" {
    # Configuration is loaded from backend-config.tfvars
    # Run: tofu init -backend-config=backend-config.tfvars
  }
}
EOF

echo -e "${GREEN}✓ Backend configuration created in backend.tf${NC}"

# Print summary
echo -e "\n${GREEN}=== Setup Complete! ===${NC}\n"
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Initialize OpenTofu with the backend:"
echo -e "     ${BLUE}tofu init -backend-config=backend-config.tfvars${NC}"
echo ""
echo "  2. If you have existing state, migrate it:"
echo -e "     ${BLUE}tofu init -backend-config=backend-config.tfvars -migrate-state${NC}"
echo ""
echo -e "${YELLOW}Backend Details:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Container: $CONTAINER_NAME"
echo "  Subscription: $SUBSCRIPTION_ID"
echo ""
echo -e "${YELLOW}Cost:${NC} ~\$0.02/month for state storage"
