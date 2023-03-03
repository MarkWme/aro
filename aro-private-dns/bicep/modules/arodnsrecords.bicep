param privateDnsZoneName string
param name string

param aroApiServerIp string
param aroIngressIp string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}


resource apiDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: 'api.${name}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: aroApiServerIp
      }
    ]
  }
}

resource ingressDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: '*.apps.${name}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: aroIngressIp
      }
    ]
  }
}

