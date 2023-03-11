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
    subnets: [
      {
        name: '${name}-jumpbox-subnet'
        properties: {
          addressPrefix: jumpboxSubnetCidr
        }
      }
      {
        name: '${name}-dns-subnet'
        properties: {
          addressPrefix: dnsSubnetCidr
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

  resource jumpboxSubnet 'subnets' existing = {
    name: '${name}-jumpbox-subnet'
  }

  resource dnsSubnet 'subnets' existing = {
    name: '${name}-dns-subnet'
  }

  resource firewallSubnet 'subnets' existing = {
    name: 'AzureFirewallSubnet'
  }

}

output virtualNetworkId string = hubVirtualNetwork.id
output jumpboxSubnetId string = hubVirtualNetwork::jumpboxSubnet.id
output dnsSubnetId string = hubVirtualNetwork::dnsSubnet.id
output firewallSubnetId string = hubVirtualNetwork::firewallSubnet.id
output jumpboxSubnetCidr string = jumpboxSubnetCidr
output virtualNetworkName string = hubVirtualNetwork.name
output jumpboxSubnetName string = hubVirtualNetwork::jumpboxSubnet.name
