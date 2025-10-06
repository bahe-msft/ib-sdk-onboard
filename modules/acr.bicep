// Parameters
@description('Name of the Azure Container Registry')
param acrName string

@description('Location for the ACR')
param location string

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

// Outputs
output acrName string = acr.name
output acrId string = acr.id
output loginServer string = acr.properties.loginServer