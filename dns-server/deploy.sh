#!/bin/bash
#
# Deploy BIND DNS server
#
# Set environment variables
#
# Name of Azure Key Vault instance to use
# Script will retrieve the jumpbox SSH key from the Key Vault
keyVaultName=msazuredev
sshKeyName=sshKey
sshKey=$(az keyvault secret show --vault-name $keyVaultName --name $sshKeyName --query value -o tsv)
adminUser=$(az keyvault secret show --vault-name $keyVaultName --name adminUser --query value -o tsv)

privateDnsZoneName=private.chipfat.com

location=westeurope
#
# Choose random name for resources
#
name=dns-$(cat /dev/urandom | base64 | tr -dc '[:lower:]' | fold -w ${1:-5} | head -n 1) 2>/dev/null
#
# Calculate next available network address space
#
number=$(az network vnet list --query "[].addressSpace.addressPrefixes" -o tsv | cut -d . -f 2 | sort | tail -n 1)
if [[ -z $number ]]
then
    number=0
fi
networkNumber=$(expr $number + 1)

cp cloud-init/cloud-init-template.yaml cloud-init/cloud-init.yaml
sed -i '' -e "s/{privateIpV4Address}/10.${networkNumber}.0.250/g" cloud-init/cloud-init.yaml
sed -i '' -e "s/{networkNumber}/${networkNumber}/g" cloud-init/cloud-init.yaml
sed -i '' -e "s/{dnsZoneName}/${privateDnsZoneName}/g" cloud-init/cloud-init.yaml

cloudInitCustomData=$(cat cloud-init/cloud-init.yaml | base64)


az group create -n $name -l $location -o table

az deployment group create \
    -n $name-$RANDOM \
    -g $name \
    -f ./bicep/main.bicep \
    --parameters \
        name=$name \
        networkNumber=$networkNumber \
        privateDnsZoneName=$privateDnsZoneName \
        adminUser=$adminUser \
        sshKey=$sshKey \
        customData=$cloudInitCustomData \
    -o table