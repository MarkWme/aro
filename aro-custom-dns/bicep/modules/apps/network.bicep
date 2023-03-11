param name string
param location string
param networkNumber string
param hubNetworkName string
param hubResourceGroupName string
param routeTableId string
param dnsServerPrivateIp string

param virtualNetworkCidr string = '10.${networkNumber}.0.0/16'
param appsSubnetCidr string = '10.${networkNumber}.0.0/24'

resource hubNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: hubNetworkName
  scope: resourceGroup(subscription().subscriptionId, hubResourceGroupName)
}

resource appsVirtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: '${name}-network'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkCidr
      ]
    }
    dhcpOptions: {
      dnsServers: [dnsServerPrivateIp]
    }
    subnets: [
      {
        name: '${name}-apps-subnet'
        properties: {
          addressPrefix: appsSubnetCidr
          routeTable: {
            id: routeTableId
          }
        }
      }
    ]
  }
}

resource peerToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${name}-hub-peer'
  parent: appsVirtualNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: hubNetwork.id
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: hubNetwork.properties.addressSpace.addressPrefixes
    }
    useRemoteGateways: false
  }
}

output virtualNetworkName string = appsVirtualNetwork.name
