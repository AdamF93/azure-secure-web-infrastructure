targetScope = 'subscription'

param location string = 'germanywestcentral'
param locationCode string = 'gwc'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-secure-web-dev-${locationCode}'
  location: location
  tags: {
    Environment: 'Development'
    Project: 'AzureSecureWeb'
    ManagedBy: 'Bicep'
  }
}
