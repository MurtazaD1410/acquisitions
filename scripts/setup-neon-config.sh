#!/bin/bash

# Script to help configure Neon environment variables
# This script helps you gather and set up all the necessary Neon configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Neon Configuration Setup${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

print_step() {
    echo -e "${GREEN}➤ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to extract values from existing .env
extract_current_config() {
    if [ -f .env ]; then
        echo -e "${CYAN}Current configuration found in .env:${NC}"
        echo
        
        # Extract DATABASE_URL components
        if grep -q "DATABASE_URL=" .env; then
            DATABASE_URL=$(grep "DATABASE_URL=" .env | cut -d'=' -f2-)
            echo "Database URL: $DATABASE_URL"
            
            # Extract project info from URL
            if [[ $DATABASE_URL =~ ep-([^.]+)\.([^.]+)\.([^.]+)\.aws\.neon\.tech ]]; then
                ENDPOINT_ID="ep-${BASH_REMATCH[1]}"
                REGION="${BASH_REMATCH[2]}"
                PROVIDER="${BASH_REMATCH[3]}"
                echo "Endpoint ID: $ENDPOINT_ID"
                echo "Region: $REGION"
                echo "Provider: $PROVIDER"
            fi
        fi
        
        # Extract ARCJET_KEY
        if grep -q "ARCJET_KEY=" .env; then
            ARCJET_KEY=$(grep "ARCJET_KEY=" .env | cut -d'=' -f2-)
            echo "Arcjet Key: ${ARCJET_KEY:0:10}..."
        fi
        
        echo
    fi
}

# Function to show where to find Neon configuration
show_neon_instructions() {
    print_step "Where to find your Neon configuration:"
    echo
    
    echo -e "${YELLOW}1. Neon API Key:${NC}"
    echo "   • Go to https://console.neon.tech/app/settings/api-keys"
    echo "   • Click 'Create new API key'"
    echo "   • Copy the generated key"
    echo
    
    echo -e "${YELLOW}2. Project ID:${NC}"
    echo "   • Go to https://console.neon.tech/app/projects"
    echo "   • Click on your project"
    echo "   • Copy the Project ID from the URL or project settings"
    echo "   • Format: proj_xxxxxxxxxxxxxxxxxxxxxxxxx"
    echo
    
    echo -e "${YELLOW}3. Branch ID:${NC}"
    echo "   • In your project, go to the Branches tab"
    echo "   • Find your main/production branch"
    echo "   • Copy the Branch ID"
    echo "   • Format: br_xxxxxxxxxxxxxxxxxxxxxxxxx"
    echo
    
    echo -e "${YELLOW}4. Database URL:${NC}"
    echo "   • In your project, go to the Dashboard"
    echo "   • Under 'Connection Details', copy the connection string"
    echo "   • Should include ?sslmode=require"
    echo
}

# Function to show Arcjet instructions
show_arcjet_instructions() {
    print_step "Where to find your Arcjet configuration:"
    echo
    
    echo -e "${YELLOW}Arcjet API Key:${NC}"
    echo "   • Go to https://app.arcjet.com/"
    echo "   • Sign in or create an account"
    echo "   • Go to your project settings"
    echo "   • Copy your API key"
    echo "   • Format: ajkey_xxxxxxxxxxxxxxxxxxxxxxxxx"
    echo
}

# Function to create production environment file
create_production_env() {
    print_step "Creating production environment file..."
    
    echo "Please provide your production configuration:"
    echo
    
    # Get DATABASE_URL
    echo -n "Enter your Neon Database URL: "
    read -r PROD_DATABASE_URL
    
    # Get JWT_SECRET
    echo -n "Enter a strong JWT secret (or press Enter to generate one): "
    read -r PROD_JWT_SECRET
    
    if [ -z "$PROD_JWT_SECRET" ]; then
        PROD_JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || echo "PLEASE-CHANGE-THIS-TO-A-SECURE-RANDOM-STRING")
        echo "Generated JWT secret: $PROD_JWT_SECRET"
    fi
    
    # Get NEON_API_KEY
    echo -n "Enter your Neon API Key (optional, press Enter to skip): "
    read -r PROD_NEON_API_KEY
    
    # Get NEON_PROJECT_ID
    echo -n "Enter your Neon Project ID (optional, press Enter to skip): "
    read -r PROD_NEON_PROJECT_ID
    
    # Get NEON_BRANCH_ID
    echo -n "Enter your Neon Branch ID (optional, press Enter to skip): "
    read -r PROD_NEON_BRANCH_ID
    
    # Get ARCJET_KEY
    echo -n "Enter your Arcjet API Key (optional, press Enter to skip): "
    read -r PROD_ARCJET_KEY
    
    # Create the file
    cat > .env.prod.local << EOF
# Production Environment Configuration
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Database Configuration - Neon Cloud
DATABASE_URL=$PROD_DATABASE_URL

# JWT Configuration
JWT_SECRET=$PROD_JWT_SECRET

# Neon API Configuration
NEON_API_KEY=$PROD_NEON_API_KEY
NEON_PROJECT_ID=$PROD_NEON_PROJECT_ID
NEON_BRANCH_ID=$PROD_NEON_BRANCH_ID

# Arcjet Configuration
ARCJET_KEY=$PROD_ARCJET_KEY

# Additional Production Settings
# CORS_ORIGINS=https://yourdomain.com
# TRUSTED_PROXIES=1
EOF

    echo -e "${GREEN}✓ Created .env.prod.local${NC}"
    echo -e "${YELLOW}⚠ Remember: Never commit this file to git!${NC}"
    echo
}

# Function to validate configuration
validate_neon_config() {
    print_step "Validating Neon configuration..."
    
    # Check if neonctl is installed
    if command -v neonctl &> /dev/null; then
        echo "✓ neonctl CLI found"
        
        # Try to list projects if API key is available
        if [ ! -z "$NEON_API_KEY" ]; then
            echo "Testing Neon API connection..."
            if neonctl projects list --api-key "$NEON_API_KEY" &> /dev/null; then
                echo "✓ Neon API connection successful"
            else
                echo "✗ Neon API connection failed"
            fi
        fi
    else
        print_info "neonctl CLI not found. To install:"
        echo "npm install -g neonctl"
        echo "or"
        echo "curl -sf https://neon.tech/install.sh | sh"
    fi
    echo
}

# Function to show usage examples
show_usage_examples() {
    print_step "Usage examples:"
    echo
    
    echo -e "${CYAN}Start development (with local PostgreSQL):${NC}"
    echo "npm run docker:dev"
    echo
    
    echo -e "${CYAN}Start production (with Neon Cloud):${NC}"
    echo "export \$(cat .env.prod.local | xargs) && npm run docker:prod"
    echo
    
    echo -e "${CYAN}Test database connection:${NC}"
    echo "neonctl connection-string --project-id \$NEON_PROJECT_ID --branch-id \$NEON_BRANCH_ID"
    echo
    
    echo -e "${CYAN}Create a new branch (for feature development):${NC}"
    echo "neonctl branches create --project-id \$NEON_PROJECT_ID --name feature-branch"
    echo
}

# Main function
main() {
    print_header
    
    echo -e "${CYAN}This script helps you configure Neon and Arcjet for your application.${NC}"
    echo
    
    extract_current_config
    show_neon_instructions
    show_arcjet_instructions
    
    echo -e "${YELLOW}Would you like to create a production environment file? (y/N):${NC}"
    read -r CREATE_PROD_ENV
    
    if [[ $CREATE_PROD_ENV =~ ^[Yy]$ ]]; then
        create_production_env
    fi
    
    validate_neon_config
    show_usage_examples
    
    echo -e "${GREEN}Configuration setup complete!${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Complete your .env.prod.local file with real values"
    echo "2. Test your development environment: npm run docker:dev"
    echo "3. Test your production environment with proper credentials"
    echo
}

# Run main function
main "$@"