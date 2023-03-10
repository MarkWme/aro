param name string
param location string
param networkNumber string

param virtualNetworkCidr string = '10.${networkNumber}.0.0/16'
param dnsServerSubnetCidr string = '10.${networkNumber}.0.0/24'

resource dnsVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
        name: '${name}-dns-subnet'
        properties: {
          addressPrefix: dnsServerSubnetCidr
        }
      }
    ]
  }
  resource dnsServerSubnet 'subnets' existing = {
    name: '${name}-dns-subnet'
  }

}

output virtualNetworkId string = dnsVirtualNetwork.id
output virtualNetworkName string = dnsVirtualNetwork.name
output dnsServerSubnetId string = dnsVirtualNetwork::dnsServerSubnet.id
output dnsServerSubnetName string = dnsVirtualNetwork::dnsServerSubnet.name
output dnsServerSubnetCidr string = dnsServerSubnetCidr
