param name string
param azureFirewallSubnetId string
param location string
/*
param virtualNetworkName string
param controlPlaneSubnetName string
param nodeSubnetName string
param controlPlaneAddressPrefix string
param nodeAddressPrefix string
*/

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: '${name}-fw-public-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-01-01'= {
  name: '${name}-fw-policy'
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

resource applicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: firewallPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'aro'
        priority: 1000
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'RedHatServices'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
              {
                protocolType: 'Http'
                port: 80
              }
            ]
            targetFqdns: [
              'registry.redhat.io'
              'registry.access.redhat.com'
              'quay.io'
              'sso.redhat.com'
              'cloud.redhat.com'
              'api.openshift.com'
              'mirror.openshift.com'
            ]
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'GitHub'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
              {
                protocolType: 'Http'
                port: 80
              }
            ]
            targetFqdns: [
              'github.com'
            ]
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'Docker'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
              {
                protocolType: 'Http'
                port: 80
              }
            ]
            targetFqdns: [
              '*.docker.io'
            ]
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-03-01' = {
  name: '${name}-fw'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${name}-fw-ipconfig'
        properties: {
          subnet: {
            id: azureFirewallSubnetId
          }
          publicIPAddress: {
            id: publicIpAddress.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

resource routeTable 'Microsoft.Network/routeTables@2022-07-01' = {
  name: '${name}-rt'
  location: location
  properties: {
    routes: [
      {
        name: 'AzureFirewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

output routeTableId string = routeTable.id

/*
resource controlPlaneSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${virtualNetworkName}/${controlPlaneSubnetName}'
  properties: {
    addressPrefix: controlPlaneAddressPrefix
    routeTable: {
      id: routeTable.id
    }
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
}

resource nodeSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${virtualNetworkName}/${nodeSubnetName}'
  properties: {
    addressPrefix: nodeAddressPrefix
    routeTable: {
      id: routeTable.id
    }
  }
  dependsOn: [
    controlPlaneSubnet
  ]
}

*/
