# Kubernetes Application with Identity Binding

This directory contains Kubernetes manifests and deployment scripts for testing Azure workload identity and identity binding functionality.

## Overview

The test application demonstrates:
- Azure workload identity integration
- Identity binding for secure Azure service access
- Key Vault secret retrieval using managed identity
- Multiple Azure SDK implementations testing

## Components

### Kubernetes Resources
- **Namespace**: `demo-app-ib` - Isolated environment for testing
- **ServiceAccount**: `identity-binding-sa` - Configured with workload identity
- **RBAC**: ClusterRole and ClusterRoleBinding for identity permissions
- **Deployment**: Configurable pod deployment with identity binding

### Files
- `manifests/demo-app.yaml` - Templated Kubernetes manifest
- `deploy.sh` - Deployment script with variable substitution
- `README.md` - This documentation

## Usage

### Basic Deployment
Deploy with default settings:
```bash
cd k8s-app
./deploy.sh
```

### Custom Pod Name
Deploy with custom pod name for testing different implementations:
```bash
./deploy.sh my-test-app
```

### Custom Container Image
Deploy with different container image and pod name:
```bash
./deploy.sh go-sdk-test ghcr.io/example/go-sdk-test:latest
./deploy.sh python-sdk-test ghcr.io/example/python-sdk-test:latest
./deploy.sh dotnet-sdk-test ghcr.io/example/dotnet-sdk-test:latest
```

## Template Variables

The script automatically extracts and substitutes these variables:

| Variable | Source | Description |
|----------|--------|-------------|
| `MANAGED_IDENTITY_CLIENT_ID` | Deployment output | Client ID of the managed identity |
| `KEYVAULT_URL` | Deployment output | Azure Key Vault URL |
| `POD_NAME` | Command line argument | Name for the deployment and pod |
| `CONTAINER_IMAGE` | Command line argument | Container image to deploy |

## Monitoring and Troubleshooting

### Check Pod Status
```bash
kubectl --kubeconfig=<cluster-name>.kubeconfig get pods -n demo-app-ib
```

### View Application Logs
```bash
kubectl --kubeconfig=<cluster-name>.kubeconfig logs -n demo-app-ib -l app=<pod-name> -f
```

### Describe Pod for Details
```bash
kubectl --kubeconfig=<cluster-name>.kubeconfig describe pod -n demo-app-ib -l app=<pod-name>
```

### Check Service Account Configuration
```bash
kubectl --kubeconfig=<cluster-name>.kubeconfig get serviceaccount identity-binding-sa -n demo-app-ib -o yaml
```

## Testing Different SDKs

The flexible deployment allows testing various Azure SDK implementations:

1. **Go SDK**: Default example container
2. **Python SDK**: Custom Python-based implementation
3. **.NET SDK**: Custom .NET-based implementation
4. **Java SDK**: Custom Java-based implementation

Each can be deployed with a unique pod name for parallel testing.

## Cleanup

Remove all resources:
```bash
kubectl --kubeconfig=<cluster-name>.kubeconfig delete namespace demo-app-ib
```

Or remove specific deployment:
```bash
kubectl --kubeconfig=<cluster-name>.kubeconfig delete deployment <pod-name> -n demo-app-ib
```

## Prerequisites

1. Azure infrastructure deployed (run `make deploy` from project root)
2. AKS credentials downloaded (run `make get-aks-creds` from project root)
3. kubectl installed and configured