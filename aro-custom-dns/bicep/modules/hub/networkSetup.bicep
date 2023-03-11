param name string
param location string
param networkNumber string

param virtualNetworkCidr string = '10.${networkNumber}.0.0/16'
param dnsSubnetCidr string = '10.${networkNumber}.0.0/24'
param firewallSubnetCidr string = '10.${networkNumber}.10.0/24'
param jumpboxSubnetCidr string = '10.${networkNumber}.20.0/24'

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: '${name}-network'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkCidr
      ]
    }
    dhcpOptions: {
      dnsServers: ['10.${networkNumber}.0.250']
    }
    subnets: [
      {
        name: '${name}-jumpbox-subnet'
        properties: {
          addressPrefix: jumpboxSubnetCidr
          networkSecurityGroup: {
            id: jumpboxNetworkSecurityGroup.id
          }
        }
      }
      {
        name: '${name}-dns-subnet'
        properties: {
          addressPrefix: dnsSubnetCidr
          networkSecurityGroup: {
            id: dnsNetworkSecurityGroup.id
          }
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetCidr
        }
      }
    ]
  }
}

resource dnsNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: '${name}-dns-vm-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'dns'
        properties: {
          priority: 1100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '53'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource jumpboxNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: '${name}-win-vm-nsg'
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

