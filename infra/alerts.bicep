targetScope = 'resourceGroup'

param locationCode string = 'gwc'
param alertEnabled bool = false
param cpuThreshold int = 80
@secure()
@description('Email address for alert notifications; supplied during deployment.')
param alertEmail string

resource monitoredVm 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: 'vm-web-secure-web-dev-${locationCode}-01'
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-secure-web-dev-${locationCode}'
  location: 'global'
  tags: {
    Environment: 'Development'
    Project: 'AzureSecureWeb'
    ManagedBy: 'Bicep'
  }
  properties: {
    groupShortName: 'SecureWeb'
    enabled: true
    emailReceivers: [
      {
        name: 'ProjectOwner'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-cpu-secure-web-dev-${locationCode}'
  location: 'global'
  tags: {
    Environment: 'Development'
    Project: 'AzureSecureWeb'
    ManagedBy: 'Bicep'
  }
  properties: {
    description: 'Average VM CPU exceeds the threshold over five minutes.'
    severity: 2
    enabled: alertEnabled
    scopes: [
      monitoredVm.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    autoMitigate: true
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPU'
          criterionType: 'StaticThresholdCriterion'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          metricName: 'Percentage CPU'
          operator: 'GreaterThan'
          threshold: cpuThreshold
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
