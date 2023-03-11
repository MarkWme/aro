@description('Region for the first cluster')
param location string = resourceGroup().location

@description('Network number')
param networkNumber string

param hubNetworkName string
param hubResourceGroupName string
param routeTableId string

param privateDnsZoneName string
param dnsServerPrivateIp string

@description('Name of the Key Vault that contains the SSH public key and admin user name.')
param keyVaultName string

@description('Resource group of the Key Vault that contains the SSH public key and admin user name.')
param keyVaultResourceGroup string

param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param name string = 'aks-${uniqueString(uniqueSeed)}'

//
// Get a reference to the Key Vault that contains the SSH public key and admin user name.
//
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroup)
}

module network 'modules/apps/network.bicep' = {
  name: '${deployment().name}--network'
  params: {
    name: name
    location: location
    networkNumber: networkNumber
    hubNetworkName: hubNetworkName
    hubResourceGroupName: hubResourceGroupName
    routeTableId: routeTableId
    dnsServerPrivateIp: dnsServerPrivateIp
  }
}

module peering 'modules/apps/peering.bicep' = {
  name: '${deployment().name}--peering'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    name: name
    appsNetworkName: network.outputs.virtualNetworkName
    appsResourceGroupName: resourceGroup().name
    hubNetworkName: hubNetworkName
  }
}
