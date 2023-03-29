@description('Region for the first cluster')
param location string = resourceGroup().location

@description('Network number')
param networkNumber string

@description('Name of the Key Vault that contains the SSH public key and admin user name.')
param keyVaultName string

@description('Resource group of the Key Vault that contains the SSH public key and admin user name.')
param keyVaultResourceGroup string

param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param name string = 'aks-${uniqueString(uniqueSeed)}'

param aroDomain string = name

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

//
// Get a reference to the Key Vault that contains the pull secret.
//
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroup)
}

module network 'modules/network.bicep' = {
  name: '${deployment().name}--network'
  params: {
    name: name
    location: location
    networkNumber: networkNumber
    contribRole: contribRole
    objectId: objectId
    rpObjectId: rpObjectId
  }
}

module aroCluster 'modules/aro.bicep' = {
  name: '${deployment().name}--aroCluster'
  params: {
    name: name
    location: location
    controlPlaneSubnetId: network.outputs.controlPlaneSubnetId
    nodeSubnetId: network.outputs.nodeSubnetId
    clientId: clientId
    clientSecret: clientSecret
    apiServerVisibility: apiServerVisibility
    ingressVisibility: ingressVisibility
    pullSecret: keyVault.getSecret('redHatPullSecret')
    controlPlaneVmSize: controlPlaneVmSize
    nodeVmSize: nodeVmSize
    nodeVmDiskSize: nodeVmDiskSize
    nodeCount: nodeCount
    domain: aroDomain
    podCidr: podCidr
    serviceCidr: serviceCidr
  }
}
