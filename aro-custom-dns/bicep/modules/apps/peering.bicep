param name string
param hubNetworkName string
param appsNetworkName string
param appsResourceGroupName string

resource hubNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: hubNetworkName
}

resource aroNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: appsNetworkName
  scope: resourceGroup(subscription().subscriptionId, appsResourceGroupName)
}

resource peerFromHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${name}-apps-peer'
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

