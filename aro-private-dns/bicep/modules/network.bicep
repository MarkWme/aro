param name string
param location string
param networkNumber string
param contribRole string
param objectId string
param rpObjectId string

param virtualNetworkCidr string = '10.${networkNumber}.0.0/16'
param controlPlaneSubnetCidr string = '10.${networkNumber}.0.0/24'
param nodeSubnetCidr string = '10.${networkNumber}.1.0/24'
param jumpboxSubnetCidr string = '10.${networkNumber}.2.0/24'
param aciSubnetCidr string = '10.${networkNumber}.3.0/24'
param firewallSubnetCidr string = '10.${networkNumber}.4.0/24'

resource aroVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
      {
        name: '${name}-jumpbox-subnet'
        properties: {
          addressPrefix: jumpboxSubnetCidr
        }
      }
      {
        name: '${name}-aci-subnet'
        properties: {
          addressPrefix: aciSubnetCidr
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
  resource controlPlaneSubnet 'subnets' existing = {
    name: '${name}-control-subnet'
  }

  resource nodeSubnet 'subnets' existing = {
    name: '${name}-node-subnet'
  }

  resource jumpboxSubnet 'subnets' existing = {
    name: '${name}-jumpbox-subnet'
  }

  resource aciSubnet 'subnets' existing = {
    name: '${name}-aci-subnet'
  }

  resource firewallSubnet 'subnets' existing = {
    name: 'AzureFirewallSubnet'
  }

}

output virtualNetworkId string = aroVirtualNetwork.id
output controlPlaneSubnetId string = aroVirtualNetwork::controlPlaneSubnet.id
output nodeSubnetId string = aroVirtualNetwork::nodeSubnet.id
output jumpboxSubnetId string = aroVirtualNetwork::jumpboxSubnet.id
output aciSubnetId string = aroVirtualNetwork::aciSubnet.id
output firewallSubnetId string = aroVirtualNetwork::firewallSubnet.id
output jumpboxSubnetCidr string = jumpboxSubnetCidr
output virtualNetworkName string = aroVirtualNetwork.name
output jumpboxSubnetName string = aroVirtualNetwork::jumpboxSubnet.name

resource aroVirtualNetworkSPNContributorRole 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(aroVirtualNetwork.id, objectId, contribRole)
  properties: {
    roleDefinitionId: contribRole
    principalId: objectId
    principalType: 'ServicePrincipal'
  }
  scope: aroVirtualNetwork
}

resource aroVirtualNetworkRPContributorRole 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(aroVirtualNetwork.id, rpObjectId, contribRole)
  properties: {
    roleDefinitionId: contribRole
    principalId: rpObjectId
    principalType: 'ServicePrincipal'
  }
  scope: aroVirtualNetwork
}
