param name string
param location string
param networkNumber string
param contribRole string
param objectId string
param rpObjectId string

param virtualNetworkCidr string = '10.${networkNumber}.0.0/16'
param controlPlaneSubnetCidr string = '10.${networkNumber}.0.0/24'
param nodeSubnetCidr string = '10.${networkNumber}.1.0/24'

resource aroVirtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
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
        name: '${name}-control-subnet'
        properties: {
          addressPrefix: controlPlaneSubnetCidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
            }
          ]
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
