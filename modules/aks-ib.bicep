@description('Name of the AKS cluster')
param aksName string

@description('Name of the managed identity to assign to the AKS cluster')
param miName string

resource aks 'Microsoft.ContainerService/managedClusters@2025-06-02-preview' existing = {
  name: aksName
}

resource mi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: miName
}

resource identityBinding 'Microsoft.ContainerService/managedClusters/identityBindings@2025-06-02-preview' = {
  parent: aks

  name: '${miName}-ib'
  properties: {
    managedIdentity: {
      resourceId: mi.id
    }
  }
}

output id string = identityBinding.id
output oidcIssuer string = identityBinding.properties.oidcIssuer.oidcIssuerUrl
