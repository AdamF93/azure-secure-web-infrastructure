targetScope = 'resourceGroup'

param location string = resourceGroup().location
param locationCode string = 'gwc'

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-secure-web-dev-${locationCode}'
  location: location
  tags: {
    Environment: 'Development'
    Project: 'AzureSecureWeb'
    ManagedBy: 'Bicep'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource collectionRule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'dcr-web-secure-web-dev-${locationCode}'
  location: location
  kind: 'Linux'
  tags: {
    Environment: 'Development'
    Project: 'AzureSecureWeb'
    ManagedBy: 'Bicep'
  }
  properties: {
    dataSources: {
      performanceCounters: [
        {
          name: 'cpuPerformance'
          streams: [
            'Microsoft-Perf'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            'Processor(*)\\% Processor Time'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'workspaceDestination'
          workspaceResourceId: workspace.id
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Perf'
        ]
        destinations: [
          'workspaceDestination'
        ]
      }
    ]
  }
}

resource monitoredVm 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: 'vm-web-secure-web-dev-${locationCode}-01'
}

resource ruleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  name: 'dcra-web-cpu'
  scope: monitoredVm
  properties: {
    description: 'Collect web VM CPU measurements in Log Analytics.'
    dataCollectionRuleId: collectionRule.id
  }
}

output collectionRuleId string = collectionRule.id
output workspaceId string = workspace.id
output workspaceName string = workspace.name
