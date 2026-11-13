targetScope = 'resourceGroup'

param location string = resourceGroup().location
param locationCode string = 'gwc'
param vmSize string = 'Standard_D2ls_v7'
param adminUsername string = 'azureadmin'

@description('SSH public key contents. Never supply the private key.')
param sshPublicKey string

var vmName = 'vm-web-secure-web-dev-${locationCode}-01'

var tags = {
  Environment: 'Development'
  Project: 'AzureSecureWeb'
  ManagedBy: 'Bicep'
}

resource webSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: 'vnet-secure-web-dev-${locationCode}/snet-web'
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-web-secure-web-dev-${locationCode}-01'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: 'secure-web-${uniqueString(resourceGroup().id)}'
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-web-secure-web-dev-${locationCode}-01'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-web'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: webSubnet.id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk-${vmName}'
        createOption: 'FromImage'
        diskSizeGB: 32
        caching: 'ReadWrite'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    osProfile: {
      computerName: 'web01'
      adminUsername: adminUsername
      customData: base64(replace(replace(loadTextContent('cloud-init.yaml'), '\r\n', '\n'), '\n', '\r\n'))
      linuxConfiguration: {
        disablePasswordAuthentication: true
        provisionVMAgent: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
}

resource monitorAgent 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: virtualMachine
  name: 'AzureMonitorLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

output vmName string = virtualMachine.name
output publicIpAddress string = publicIp.properties.ipAddress
output publicHostname string = publicIp.properties.dnsSettings.fqdn
