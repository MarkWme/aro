param name string
param location string
param networkNumber string
param hubNetworkName string
param hubResourceGroupName string
param routeTableId string
param contribRole string
param objectId string
param rpObjectId string
param dnsServerPrivateIp string

param virtualNetworkCidr string = '10.${networkNumber}.0.0/16'
param controlPlaneSubnetCidr string = '10.${networkNumber}.0.0/24'
param nodeSubnetCidr string = '10.${networkNumber}.1.0/24'

resource hubNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: hubNetworkName
  scope: resourceGroup(subscription().subscriptionId, hubResourceGroupName)
}

resource aroVirtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
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
        name: '${name}-control-subnet'
        properties: {
          addressPrefix: controlPlaneSubnetCidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
            }
          ]
          routeTable: {
            id: routeTableId
          }
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: '${name}-node-subnet'
        properties: {
          addressPrefix: nodeSubnetCidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
            }
          ]
          routeTable: {
            id: routeTableId
          }
        }
      }
    ]
  }
  resource controlPlaneSubnet 'subnets' existing = {
    name: '${name}-control-subnet'
  }

  resource nodeSubnet 'subnets' existing = {
    name: '${name}-node-subnet'
  }
}

output virtualNetworkId string = aroVirtualNetwork.id
output controlPlaneSubnetId string = aroVirtualNetwork::controlPlaneSubnet.id
output nodeSubnetId string = aroVirtualNetwork::nodeSubnet.id
output virtualNetworkName string = aroVirtualNetwork.name
output controlPlaneSubnetName string = aroVirtualNetwork::controlPlaneSubnet.name
output nodeSubnetName string = aroVirtualNetwork::nodeSubnet.name
output controlPlaneSubnetCidr string = controlPlaneSubnetCidr
output nodeSubnetCidr string = nodeSubnetCidr

resource peerToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${name}-hub-peer'
  parent: aroVirtualNetwork
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

resource aroVirtualNetworkSPNContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aroVirtualNetwork.id, objectId, contribRole)
  properties: {
    roleDefinitionId: contribRole
    principalId: objectId
    principalType: 'ServicePrincipal'
  }
  scope: aroVirtualNetwork
}

resource aroVirtualNetworkRPContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aroVirtualNetwork.id, rpObjectId, contribRole)
  properties: {
    roleDefinitionId: contribRole
    principalId: rpObjectId
    principalType: 'ServicePrincipal'
  }
  scope: aroVirtualNetwork
}
