// Parameters
@description('Name of the Key Vault')
param keyVaultName string

@description('Location for the Key Vault')
param location string

@description('Principal ID of the managed identity to grant access')
param managedIdentityPrincipalId string

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: managedIdentityPrincipalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// Sample secret
resource sampleSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'sample-secret-key'
  parent: keyVault
  properties: {
    value: 'hello from akv'
  }
}

// Outputs
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output sampleSecretName string = sampleSecret.name
