#!/bin/bash

# Salesforce Demo Project Deployment Script
# This script deploys the Salesforce demo project to a scratch org

set -e

echo "🚀 Starting Salesforce Demo Project Deployment..."

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo "❌ Salesforce CLI is not installed. Please install it first."
    echo "Visit: https://developer.salesforce.com/tools/sfdxcli"
    exit 1
fi

# Check if we're in a Salesforce project directory
if [ ! -f "sfdx-project.json" ]; then
    echo "❌ Not in a Salesforce project directory. Please run this script from the project root."
    exit 1
fi

# Create scratch org
echo "📦 Creating scratch org..."
sf org create scratch --definition-file config/project-scratch-def.json --alias demo-org --duration-days 7 --set-default

# Deploy source to scratch org
echo "📤 Deploying source to scratch org..."
sf project deploy start --target-org demo-org

# Assign permission sets (if any)
echo "🔐 Assigning permission sets..."
# sf org assign permset --name "Demo_Permission_Set" --target-org demo-org

# Create test data
echo "📊 Creating test data..."
sf apex run --file scripts/createTestData.apex --target-org demo-org

# Open the org
echo "🌐 Opening scratch org..."
sf org open --target-org demo-org

echo "✅ Deployment completed successfully!"
echo "🎉 Your Salesforce demo project is ready to use!"
echo ""
echo "📋 Next steps:"
echo "1. Navigate to the App Launcher and find 'Salesforce Demo'"
echo "2. Explore the Customer Management and Product Catalog components"
echo "3. Create some test orders to see the business logic in action"
echo ""
echo "🔧 Useful commands:"
echo "- View org info: sf org display --target-org demo-org"
echo "- Run tests: sf apex run test --target-org demo-org"
echo "- Delete org: sf org delete scratch --target-org demo-org"
