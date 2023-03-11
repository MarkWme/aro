param name string
param hubNetworkName string
param aroNetworkName string
param aroResourceGroupName string

resource hubNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: hubNetworkName
}

resource aroNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: aroNetworkName
  scope: resourceGroup(subscription().subscriptionId, aroResourceGroupName)
}

resource peerFromHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${name}-aro-peer'
  parent: hubNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: aroNetwork.id
    }
    useRemoteGateways: false
  }
}

