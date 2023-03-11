@description('Virtual Machine name')
param name string

@description('Username for the Virtual Machine.')
@secure()
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

param subnetId string

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
  name: '${replace(name, '-', '')}winbootdiag'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource vmPublicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: '${name}-win-vm-public-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${name}-win-vm'
    }
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${name}-win-vm-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${name}-win-vm-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
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
  name: '${name}-win-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'jumpbox'
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
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

resource vmWslInstall 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: '${name}-vm-wsl-rc'
  location: location
  parent: vm
  properties: {
    runAsPassword: adminPassword
    runAsUser: adminUsername
    source: {
      script: 'wsl --install --web-download'
    }
    timeoutInSeconds: 600
  }
}

resource vmRunOnce 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: '${name}-vm-runOnce-rc'
  location: location
  parent: vm
  properties: {
    runAsPassword: adminPassword
    runAsUser: adminUsername
    source: {
      script: 'New-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunOnce -Name InstallWSL -PropertyType String -Value "wsl --install"'
    }
    timeoutInSeconds: 600
  }
  dependsOn: [
    vmWslInstall
  ]
}

resource vmReboot 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: '${name}-vm-reboot-rc'
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
    vmRunOnce
  ]
}

