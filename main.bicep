targetScope = 'subscription'

// Parameters
@description('The location for all resources')
param location string = 'West US 3'

@description('Environment prefix for resource naming')
param environmentPrefix string = 'demo'

@description('Resource group name')
param resourceGroupName string = '${environmentPrefix}-rg'

// Variables
var acrName = '${environmentPrefix}acr${uniqueString(resourceGroupName)}'
var akvName = '${environmentPrefix}-akv-${uniqueString(resourceGroupName)}'
var aksName = '${environmentPrefix}-aks'
var managedIdentityName = '${environmentPrefix}-mi'

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

// Managed Identity
module managedIdentity 'modules/managed-identity.bicep' = {
  scope: resourceGroup
  name: 'managedIdentityDeployment'
  params: {
    managedIdentityName: managedIdentityName
    location: location
  }
}

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  scope: resourceGroup
  name: 'acrDeployment'
  params: {
    acrName: acrName
    location: location
  }
}

// Azure Key Vault
module keyVault 'modules/keyvault.bicep' = {
  scope: resourceGroup
  name: 'keyVaultDeployment'
  params: {
    keyVaultName: akvName
    location: location
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
  }
}

// AKS Cluster
module aks 'modules/aks.bicep' = {
  scope: resourceGroup
  name: 'aksDeployment'
  params: {
    aksName: aksName
    location: location
    acrName: acrName
  }
  dependsOn: [
    acr
  ]
}

// Outputs
output resourceGroupName string = resourceGroup.name
output acrName string = acr.outputs.acrName
output acrLoginServer string = acr.outputs.loginServer
output keyVaultName string = keyVault.outputs.keyVaultName
output aksName string = aks.outputs.aksName
output managedIdentityName string = managedIdentity.outputs.name
output managedIdentityClientId string = managedIdentity.outputs.clientId
