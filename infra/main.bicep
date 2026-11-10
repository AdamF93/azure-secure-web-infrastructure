targetScope = 'subscription'

param location string = 'germanywestcentral'
param locationCode string = 'gwc'
@description('SSH public key contents for the Linux VM.')
param sshPublicKey string
@secure()
@description('Email address for alert notifications.')
param alertEmail string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-secure-web-dev-${locationCode}'
  location: location
  tags: {
    Environment: 'Development'
    Project: 'AzureSecureWeb'
    ManagedBy: 'Bicep'
  }
}

module network 'network.bicep' = {
  name: 'deploy-secure-web-network-${locationCode}'
  scope: resourceGroup
  params: {
    location: location
    locationCode: locationCode
  }
}

module webVm 'vm.bicep' = {
  name: 'deploy-secure-web-vm-${locationCode}'
  scope: resourceGroup
  params: {
    location: location
    locationCode: locationCode
    sshPublicKey: sshPublicKey
  }
  dependsOn: [
    network
  ]
}

module monitoring 'monitoring.bicep' = {
  name: 'deploy-secure-web-monitoring-${locationCode}'
  scope: resourceGroup
  params: {
    location: location
    locationCode: locationCode
  }
  dependsOn: [
    webVm
  ]
}

module alerts 'alerts.bicep' = {
  name: 'deploy-secure-web-alerts-${locationCode}'
  scope: resourceGroup
  params: {
    locationCode: locationCode
    alertEmail: alertEmail
    alertEnabled: false
    cpuThreshold: 80
  }
  dependsOn: [
    webVm
  ]
}
