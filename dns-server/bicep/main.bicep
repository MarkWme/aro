param location string = resourceGroup().location

@description('Network number. This is used to create a virtual network CIDR of 10.x.0.0/16, where x is the network number.')
param networkNumber string

@description('Name of the Key Vault that contains the SSH public key and admin user name.')
param keyVaultName string

@description('Resource group of the Key Vault that contains the SSH public key and admin user name.')
param keyVaultResourceGroup string

@description('Custom data (cloud-init file) to be passed to the VM.')
param customData string

@description('Name to use for resources.')
param name string

//
// Get a reference to the Key Vault that contains the SSH public key and admin user name.
//
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroup)
}

//
// Deploy the virtual network and subnet
//
module dnsNetwork 'modules/network.bicep' = {
  name: '${deployment().name}--dnsNetwork'
  params: {
    name: name
    location: location
    networkNumber: networkNumber
  }
}

//
// Deploy the DNS server VM
//
module dnsServerVM 'modules/dnsserver.bicep' = {
  name: '${deployment().name}--jumpboxVM'
  params: {
    name: name
    location: location
    adminUser: keyVault.getSecret('adminUser')
    sshKey: keyVault.getSecret('sshKey')
    subnetId: dnsNetwork.outputs.dnsServerSubnetId
    networkNumber: networkNumber
    customData: customData
  }
}

//
// Configure the virtual network and subnets
//
// When the virtual network is first created, the virtual network DNS is set 
// to the Azure-provided DNS servers. If this is not done, the DNS server cannot 
// install Bind as the Ubuntu package repository is not accessible. Chicken and egg.
//
// After the DNS server is deployed, the virtual network DNS is set to custom DNS and
// and the DNS server IP is added. The VM deployment's cloud-init setup script finishes
// with a delayed reboot to ensure the virtual network has been updated so that on next boot
// the VM picks up the custom DNS server configuration.
//
// This module also adds the NSG that's required to allow SSH and DNS traffic. It's added
// at this point to avoid it being removed when the virtual network configuration is updated.
//
module networkSetup 'modules/networkSetup.bicep' = {
  name: '${deployment().name}--dnsNetworkUpdate'
  params: {
    name: name
    location: location
    networkNumber: networkNumber
  }
  //
  // Have to wait for the server VM to be fully deployed before running this module
  // otherwise Bind may end up not being installed because it can't resolve the Ubuntu
  // package repository.
  //
  dependsOn: [
    dnsServerVM
  ]
}
