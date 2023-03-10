@description('Virtual Machine name')
param name string

param subnetId string
param virtualNetworkName string
param subnetName string
param addressPrefix string
param networkNumber string
param adminUser string
param sshKey string
param privateDnsZoneName string
param customData string

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2s_v5'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

var privateIpAddress = '10.${networkNumber}.0.250'

var imageReference = {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUser}/.ssh/authorized_keys'
        keyData: sshKey
      }
    ]
  }
}

var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: '${replace(name, '-', '')}bootdiag'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource vmPublicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: '${name}-vm-public-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${name}-vm'
    }
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${name}-vm-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${name}-vm-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: privateIpAddress
          publicIPAddress: {
            id: vmPublicIp.id
            properties: {
              deleteOption: 'Delete'
            }
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]

  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: '${name}-dns-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${name}-vm'
      adminUsername: adminUser
      linuxConfiguration: linuxConfiguration
      customData: customData
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : json('null'))
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
          deleteOption: 'Delete'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
  }
}

