# Azure Infrastructure Deployment Makefile
# Requires Azure CLI and Bicep CLI to be installed

# Variables - extracted from bicepparam file as source of truth
TEMPLATE_FILE = main.bicep
PARAMS_FILE = main.bicepparam
DEPLOYMENT_NAME = azure-infra-demo-$(shell date +%Y%m%d-%H%M%S)

# Extract parameters from main.bicepparam file
LOCATION = $(shell grep "param location" $(PARAMS_FILE) | sed "s/param location = '\(.*\)'/\1/")
RG_NAME = $(shell grep "param resourceGroupName" $(PARAMS_FILE) | sed "s/param resourceGroupName = '\(.*\)'/\1/")

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  deploy     - Deploy the Azure infrastructure"
	@echo "  validate   - Validate the Bicep templates"
	@echo "  cleanup    - Delete the resource group and all resources"
	@echo "  status     - Show deployment status and outputs"
	@echo "  what-if    - Preview what changes will be made"
	@echo "  show-vars  - Show variables extracted from bicepparam file"
	@echo "  get-aks-creds - Configure kubectl with AKS credentials"
	@echo "  help       - Show this help message"

# Show extracted variables from bicepparam file
.PHONY: show-vars
show-vars:
	@echo "Variables extracted from $(PARAMS_FILE):"
	@echo "  LOCATION: $(LOCATION)"
	@echo "  RG_NAME: $(RG_NAME)"
	@echo "  TEMPLATE_FILE: $(TEMPLATE_FILE)"
	@echo "  PARAMS_FILE: $(PARAMS_FILE)"

# Validate Bicep templates
.PHONY: validate
validate:
	@echo "Validating Bicep templates..."
	az deployment sub validate \
		--location "$(LOCATION)" \
		--template-file $(TEMPLATE_FILE) \
		--parameters $(PARAMS_FILE)

# Preview deployment changes
.PHONY: what-if
what-if:
	@echo "Running what-if analysis..."
	az deployment sub what-if \
		--location "$(LOCATION)" \
		--template-file $(TEMPLATE_FILE) \
		--parameters $(PARAMS_FILE)

# Deploy infrastructure
.PHONY: deploy
deploy: validate
	@echo "Deploying Azure infrastructure..."
	@echo "Deployment name: $(DEPLOYMENT_NAME)"
	az deployment sub create \
		--name $(DEPLOYMENT_NAME) \
		--location "$(LOCATION)" \
		--template-file $(TEMPLATE_FILE) \
		--parameters $(PARAMS_FILE) \
		--verbose
	@echo "Deployment completed!"
	@$(MAKE) status

# Check deployment status and show outputs
.PHONY: status
status:
	@echo "Checking deployment status..."
	@if az group exists --name $(RG_NAME) --output tsv | grep -q "true"; then \
		echo "Resource Group: $(RG_NAME) exists"; \
		echo ""; \
		echo "=== Deployment Outputs ==="; \
		az deployment sub show \
			--name $(shell az deployment sub list --query "[?contains(name, 'azure-infra-demo')].name | [0]" -o tsv) \
			--query "properties.outputs" \
			--output table 2>/dev/null || echo "No recent deployment found"; \
		echo ""; \
		echo "=== Resource Group Resources ==="; \
		az resource list --resource-group $(RG_NAME) --output table; \
	else \
		echo "Resource Group $(RG_NAME) does not exist"; \
	fi

# Get AKS credentials after deployment
.PHONY: get-aks-creds
get-aks-creds:
	@echo "Getting AKS credentials..."
	@AKS_NAME=$$(az aks list --resource-group $(RG_NAME) --query "[0].name" -o tsv); \
	if [ -n "$$AKS_NAME" ]; then \
		az aks get-credentials --resource-group $(RG_NAME) --name $$AKS_NAME --overwrite-existing; \
		echo "AKS credentials configured. Test with: kubectl get nodes"; \
	else \
		echo "No AKS cluster found in resource group $(RG_NAME)"; \
	fi


# Clean up all resources
.PHONY: cleanup
cleanup:
	@echo "Cleaning up Azure resources..."
	@read -p "Are you sure you want to delete resource group '$(RG_NAME)' and ALL its resources? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "Deleting resource group $(RG_NAME)..."; \
		az group delete --name $(RG_NAME) --yes --no-wait; \
		echo "Cleanup initiated. Resources are being deleted in the background."; \
		echo "Check status with: az group show --name $(RG_NAME)"; \
	else \
		echo "Cleanup cancelled."; \
	fi

# Force cleanup without confirmation (use with caution)
.PHONY: force-cleanup
force-cleanup:
	@echo "Force deleting resource group $(RG_NAME)..."
	az group delete --name $(RG_NAME) --yes --no-wait
	@echo "Force cleanup initiated."