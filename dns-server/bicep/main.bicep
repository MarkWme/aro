@description('Region for the first cluster')
param location string = resourceGroup().location

@description('Network number')
param networkNumber string

@description('Name of the private DNS zone to create')
param privateDnsZoneName string

param adminUser string

param customData string

@description('Pull secret from cloud.redhat.com. The json should be input as a string')
@secure()
param sshKey string

param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param name string = 'aks-${uniqueString(uniqueSeed)}'

module dnsNetwork 'modules/network.bicep' = {
  name: '${deployment().name}--dnsNetwork'
  params: {
    name: name
    location: location
    networkNumber: networkNumber
  }
}

module jumpboxVM 'modules/dnsserver.bicep' = {
  name: '${deployment().name}--jumpboxVM'
  params: {
    name: name
    location: location
    adminUser: adminUser
    sshKey: sshKey
    privateDnsZoneName: privateDnsZoneName
    subnetId: dnsNetwork.outputs.dnsServerSubnetId
    addressPrefix: dnsNetwork.outputs.dnsServerSubnetCidr
    networkNumber: networkNumber
    virtualNetworkName: dnsNetwork.outputs.virtualNetworkName
    subnetName: dnsNetwork.outputs.dnsServerSubnetName
    customData: customData
  }
}
