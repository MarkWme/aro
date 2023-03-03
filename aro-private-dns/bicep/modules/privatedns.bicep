@description('Resource name')
param name string

@description('Private DNS zone name')
param privateDnsZoneName string

@description('ID of virtual network to link the zone to')
param virtualNetworkId string

@description('Enable automatic VM DNS registration in the zone')
param vmRegistration bool = true

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${name}-link'
  location: 'global'
  properties: {
    registrationEnabled: vmRegistration
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}
