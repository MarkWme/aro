@description('Region for the first cluster')
param location string = resourceGroup().location

@description('Network number')
param networkNumber string

@description('Name of the private DNS zone to create')
param customDnsZoneName string

param customDnsServers array

param dnsServerVirtualNetworkId string

@description('Pull secret from cloud.redhat.com. The json should be input as a string')
@secure()
param pullSecret string

@description('Admin username to be used for the jumpbox VM')
@secure()
param jumpboxAdminUser string

@description('Admin password to be used for the jumpbox VM')
@secure()
param jumpboxAdminPassword string

param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param name string = 'aks-${uniqueString(uniqueSeed)}'

param aroDomain string = '${name}.${customDnsZoneName}'

@description('Master Node VM Type')
param controlPlaneVmSize string = 'Standard_D8s_v3'

@description('Worker Node VM Type')
param nodeVmSize string = 'Standard_D4s_v3'

@description('Worker Node Disk Size in GB')
@minValue(128)
param nodeVmDiskSize int = 128

@description('Number of Worker Nodes')
@minValue(3)
param nodeCount int = 3

@description('Cidr for Pods')
param podCidr string = '10.128.0.0/14'

@metadata({
  description: 'Cidr of service'
})
param serviceCidr string = '172.30.0.0/16'

@description('Api Server Visibility')
@allowed([
  'Private'
  'Public'
])
param apiServerVisibility string = 'Public'

@description('Ingress Visibility')
@allowed([
  'Private'
  'Public'
])
param ingressVisibility string = 'Public'

@description('The Application ID of an Azure Active Directory client application')
param clientId string

@description('The Object ID of an Azure Active Directory client application')
param objectId string

@description('The secret of an Azure Active Directory client application')
@secure()
param clientSecret string

@description('The ObjectID of the Resource Provider Service Principal')
param rpObjectId string

var contribRole = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'


module aroNetwork 'modules/network.bicep' = {
  name: '${deployment().name}--aroNetwork'
  params: {
    name: name
    location: location
    networkNumber: networkNumber
    contribRole: contribRole
    objectId: objectId
    rpObjectId: rpObjectId
    customDnsServers: customDnsServers
    dnsServerVirtualNetworkId: dnsServerVirtualNetworkId
  }
}

/*
module jumpboxVM 'modules/jumpboxvm.bicep' = {
  name: '${deployment().name}--jumpboxVM'
  params: {
    name: name
    location: location
    adminUsername: jumpboxAdminUser
    adminPassword: jumpboxAdminPassword
    subnetId: aroNetwork.outputs.jumpboxSubnetId
    addressPrefix: aroNetwork.outputs.jumpboxSubnetCidr
    virtualNetworkName: aroNetwork.outputs.virtualNetworkName
    subnetName: aroNetwork.outputs.jumpboxSubnetName
  }
  dependsOn: [
    aroNetwork
    firewall
  ]
}

module firewall 'modules/firewall.bicep' = {
  name: '${deployment().name}--firewall'
  params: {
    name: name
    azureFirewallSubnetId: aroNetwork.outputs.firewallSubnetId
    location: location
    virtualNetworkName: aroNetwork.outputs.virtualNetworkName
    controlPlaneSubnetName: aroNetwork.outputs.controlPlaneSubnetName
    controlPlaneAddressPrefix: aroNetwork.outputs.controlPlaneSubnetCidr
    nodeSubnetName: aroNetwork.outputs.nodeSubnetName
    nodeAddressPrefix: aroNetwork.outputs.nodeSubnetCidr
  }
  dependsOn: [
    aroNetwork
  ]
}

/*
module aroCluster 'modules/aro.bicep' = {
  name: '${deployment().name}--aroCluster'
  params: {
    name: name
    location: location
    controlPlaneSubnetId: aroNetwork.outputs.controlPlaneSubnetId
    nodeSubnetId: aroNetwork.outputs.nodeSubnetId
    clientId: clientId
    clientSecret: clientSecret
    apiServerVisibility: apiServerVisibility
    ingressVisibility: ingressVisibility
    pullSecret: pullSecret
    controlPlaneVmSize: controlPlaneVmSize
    nodeVmSize: nodeVmSize
    nodeVmDiskSize: nodeVmDiskSize
    nodeCount: nodeCount
    domain: aroDomain
    podCidr: podCidr
    serviceCidr: serviceCidr
  }
}

/*
module aroPrivateDNSRecords 'modules/arodnsrecords.bicep' = {
  name: '${deployment().name}--aroPrivateDNSRecords'
  params: {
    name: name
    privateDnsZoneName: privateDnsZoneName
    aroApiServerIp: aroCluster.outputs.apiServerIp
    aroIngressIp: aroCluster.outputs.ingressIp
  }
}

*/
