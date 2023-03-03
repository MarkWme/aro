@description('Virtual Machine name')
param name string

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

param subnetId string
param virtualNetworkName string
param subnetName string
param addressPrefix string

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2s_v5'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'Standard'

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

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: '${name}-vm-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource jumpboxSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${virtualNetworkName}/${subnetName}'
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: {
      id: networkSecurityGroup.id
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
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vmPublicIp.id
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
  name: '${name}-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${name}-vm'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: 'windows-11'
        sku: 'win11-22h2-pro'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : json('null'))
  }
}

resource vmExtensions 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  name: '${name}-vm-extensions'
  location: location
  parent: vm
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/MarkWme/aro/main/aro-private-dns/ps/wsl.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File wsl.ps1'
    }
  }
}

/*
resource vmWslInstall 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: '${name}-vm-wsl-runCommand'
  location: location
  parent: vm
  properties: {
    runAsPassword: adminPassword
    runAsUser: adminUsername
    source: {
      script: 'wsl --install'
    }
    timeoutInSeconds: 600
  }
}

resource vmReboot 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: '${name}-vm-wsl-reboot'
  location: location
  parent: vm
  properties: {
    runAsPassword: adminPassword
    runAsUser: adminUsername
    source: {
      script: 'Restart-Computer'
    }
    timeoutInSeconds: 600
  }
  dependsOn: [
    vmWslInstall
  ]
}
*/
