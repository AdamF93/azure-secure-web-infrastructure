targetScope = 'subscription'

param location string = 'uksouth'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-secure-web-dev-uks'
  location: location
  tags: {
    Environment: 'Development'
    Project: 'AzureSecureWeb'
    ManagedBy: 'Bicep'
  }
}
