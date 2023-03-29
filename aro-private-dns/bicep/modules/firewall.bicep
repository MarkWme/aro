param name string
param azureFirewallSubnetId string
param location string

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
    sku: {
      name: 'AZFW_VNet'
      tier: 'Basic'
    }
  }
}
