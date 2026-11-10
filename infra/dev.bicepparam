using './main.bicep'

param location = 'germanywestcentral'
param locationCode = 'gwc'
param vmSize = 'Standard_D2ls_v7'
param adminUsername = 'azureadmin'
param alertEnabled = false
param cpuThreshold = 80

param sshPublicKey = readEnvironmentVariable('AZURE_SSH_PUBLIC_KEY')
param alertEmail = readEnvironmentVariable('AZURE_ALERT_EMAIL')
