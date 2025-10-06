# Azure Infrastructure Demo - Bicep Deployment

This project deploys Azure infrastructure using Bicep templates for a demo setup with ACR, Key Vault, AKS, and Managed Identity.

## Infrastructure Components

- **Resource Group** - Container for all resources
- **Azure Container Registry (ACR)** - Container image storage
- **Azure Key Vault (AKV)** - Secret storage
- **AKS Cluster** - Kubernetes cluster with ACR integration
- **Managed Identity** - For Key Vault access

## Deployment Structure

```
├── README.md
├── main.bicep
├── main.bicepparam
├── Makefile
└── modules/
    ├── acr.bicep
    ├── keyvault.bicep
    ├── managed-identity.bicep
    └── aks.bicep
```

## Key Integrations

- AKS cluster configured to pull images from ACR
- Managed Identity granted Key Vault secret access
- Pre-configured sample secret (`sample-secret-key` = `hello from akv`) for testing
- All resources deployed in single Resource Group

## Deployment Steps

### Prerequisites
- Azure CLI installed and logged in
- Bicep CLI installed
- Make utility (usually pre-installed on macOS/Linux)

### Quick Start

1. **Update parameters (optional)**
   ```bash
   # Edit main.bicepparam if needed
   ```

2. **Deploy infrastructure**
   ```bash
   make deploy
   ```

3. **Get AKS credentials (optional)**
   ```bash
   make get-aks-creds
   # This creates <cluster-name>.kubeconfig file
   # Use with: kubectl --kubeconfig=<cluster-name>.kubeconfig get nodes
   # Or export: export KUBECONFIG=<cluster-name>.kubeconfig
   ```

### Available Make Targets

- `make deploy` - Deploy the Azure infrastructure
- `make validate` - Validate Bicep templates
- `make what-if` - Preview deployment changes
- `make status` - Show deployment status and outputs
- `make get-aks-creds` - Download AKS credentials to `<cluster-name>.kubeconfig`
- `make show-vars` - Show variables extracted from bicepparam file
- `make cleanup` - Delete all resources (with confirmation)
- `make force-cleanup` - Delete all resources (no confirmation)
- `make help` - Show all available targets

### Manual Deployment (Alternative)

```bash
# The location is automatically extracted from main.bicepparam
az deployment sub create \
  --location "$(grep 'param location' main.bicepparam | sed "s/param location = '\(.*\)'/\1/")" \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## Cleanup

```bash
make cleanup
```