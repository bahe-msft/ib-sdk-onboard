#!/bin/bash

# Deploy Kubernetes application with identity binding
# Usage: ./deploy.sh [pod-name] [container-image]

set -euo pipefail

# Default values
DEFAULT_POD_NAME="demo-app-ib"
DEFAULT_CONTAINER_IMAGE="ghcr.io/bahe-msft/identity-binding-example-go:latest@sha256:912c6a64827e1e364aac8095642739605a74e98b6cbd85a5b16666df2bd91cda"

# Override with command line arguments if provided
POD_NAME="${1:-$DEFAULT_POD_NAME}"
CONTAINER_IMAGE="${2:-$DEFAULT_CONTAINER_IMAGE}"

echo "Deploying Kubernetes application with identity binding..."
echo "Pod Name: $POD_NAME"
echo "Container Image: $CONTAINER_IMAGE"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Extract variables from deployment outputs
echo "Extracting deployment variables..."

# Get resource group name from bicepparam
RG_NAME=$(grep "param resourceGroupName" "$PROJECT_ROOT/main.bicepparam" | sed "s/param resourceGroupName = '\(.*\)'/\1/")

# Get resources directly from resource group
echo "Querying resources from resource group: $RG_NAME"

# Get Managed Identity Client ID
MANAGED_IDENTITY_CLIENT_ID=$(az identity list --resource-group "$RG_NAME" --query "[0].clientId" -o tsv)

# Get Key Vault name
KEYVAULT_NAME=$(az keyvault list --resource-group "$RG_NAME" --query "[0].name" -o tsv)

# Get AKS cluster name
AKS_NAME=$(az aks list --resource-group "$RG_NAME" --query "[0].name" -o tsv)

# Construct Key Vault URL
KEYVAULT_URL="https://${KEYVAULT_NAME}.vault.azure.net"

# Validate required variables
if [ -z "$RG_NAME" ]; then
    echo "Error: Failed to extract resource group name from bicepparam file."
    exit 1
fi

if [ -z "$MANAGED_IDENTITY_CLIENT_ID" ] || [ -z "$KEYVAULT_NAME" ] || [ -z "$AKS_NAME" ]; then
    echo "Error: Failed to find required resources in resource group '$RG_NAME'."
    echo "Make sure the resource group contains exactly one instance of each:"
    echo "  - Managed Identity (found: $([ -n "$MANAGED_IDENTITY_CLIENT_ID" ] && echo "✓" || echo "✗"))"
    echo "  - Key Vault (found: $([ -n "$KEYVAULT_NAME" ] && echo "✓" || echo "✗"))"
    echo "  - AKS Cluster (found: $([ -n "$AKS_NAME" ] && echo "✓" || echo "✗"))"
    echo ""
    echo "Please run 'make deploy' first to create the required resources."
    exit 1
fi

echo "Variables extracted:"
echo "  Managed Identity Client ID: $MANAGED_IDENTITY_CLIENT_ID"
echo "  Key Vault URL: $KEYVAULT_URL"
echo "  AKS Cluster: $AKS_NAME"

# Check if kubeconfig exists
KUBECONFIG_FILE="$PROJECT_ROOT/$AKS_NAME.kubeconfig"
if [ ! -f "$KUBECONFIG_FILE" ]; then
    echo "Kubeconfig not found. Getting AKS credentials..."
    cd "$PROJECT_ROOT"
    make get-aks-creds
fi

# Render the manifest template
echo "Rendering Kubernetes manifest..."
TEMP_MANIFEST=$(mktemp)

# Substitute variables in the template
sed -e "s|\${MANAGED_IDENTITY_CLIENT_ID}|$MANAGED_IDENTITY_CLIENT_ID|g" \
    -e "s|\${KEYVAULT_URL}|$KEYVAULT_URL|g" \
    -e "s|\${POD_NAME}|$POD_NAME|g" \
    -e "s|\${CONTAINER_IMAGE}|$CONTAINER_IMAGE|g" \
    "$SCRIPT_DIR/manifests/demo-app.yaml" > "$TEMP_MANIFEST"

echo "Applying manifest to AKS cluster..."
kubectl --kubeconfig="$KUBECONFIG_FILE" apply -f "$TEMP_MANIFEST"

# Clean up
rm "$TEMP_MANIFEST"

echo ""
echo "✅ Application deployed successfully!"
echo ""
echo "Next steps:"
echo "  1. Check deployment status:"
echo "     kubectl --kubeconfig=$AKS_NAME.kubeconfig get pods -n demo-app-ib"
echo ""
echo "  2. View application logs:"
echo "     kubectl --kubeconfig=$AKS_NAME.kubeconfig logs -n demo-app-ib -l app=$POD_NAME -f"
echo ""
echo "  3. Delete deployment:"
echo "     kubectl --kubeconfig=$AKS_NAME.kubeconfig delete -f k8s-app/manifests/demo-app.yaml"