// Parameters
@description('Name of the AKS cluster')
param aksName string

@description('Location for the AKS cluster')
param location string

@description('Name of the ACR to integrate with')
param acrName string

// Variables
var nodeResourceGroup = '${aksName}-nodes-rg'

// Get ACR reference for role assignment
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

// AKS Cluster
resource aks 'Microsoft.ContainerService/managedClusters@2025-08-01' = {
  name: aksName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: aksName
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        minCount: 1
        maxCount: 3
      }
    ]
    nodeResourceGroup: nodeResourceGroup
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'standard'
    }
  }
}

// Role assignment for AKS to pull from ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, aks.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    ) // AcrPull role
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output aksName string = aks.name
output aksId string = aks.id
output aksFqdn string = aks.properties.fqdn
output nodeResourceGroupName string = aks.properties.nodeResourceGroup
