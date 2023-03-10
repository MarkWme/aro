#!/bin/bash
#
# Deploy BIND DNS server
#
# Set environment variables
#
# Name and resource group of Azure Key Vault instance to use
keyVaultName=msazuredev
keyVaultResourceGroup=shared
#
# Name of the private / custom DNS zone to use. The Bind DNS server will be configured to serve this zone.
#
privateDnsZoneName=private.chipfat.com
#
# Azure region to deploy resources to
#
location=westeurope
#
# Choose random name for resources
#
name=dns-$(cat /dev/urandom | base64 2>/dev/null | tr -dc '[:lower:]' | fold -w ${1:-5} | head -n 1)
#
# Calculate next available network address space
#
number=$(az network vnet list --query "[].addressSpace.addressPrefixes" -o tsv | cut -d . -f 2 | sort | tail -n 1)
if [[ -z $number ]]
then
    number=0
fi
networkNumber=$(expr $number + 1)
#
# Copy cloud-init template and replace placeholder variables with actual values
#
cp cloud-init/cloud-init-template.yaml cloud-init/cloud-init.yaml
sed -i '' -e "s/{privateIpV4Address}/10.${networkNumber}.0.250/g" cloud-init/cloud-init.yaml
sed -i '' -e "s/{networkNumber}/${networkNumber}/g" cloud-init/cloud-init.yaml
sed -i '' -e "s/{dnsZoneName}/${privateDnsZoneName}/g" cloud-init/cloud-init.yaml
cloudInitCustomData=$(cat cloud-init/cloud-init.yaml | base64)
rm cloud-init/cloud-init.yaml
#
# Create resource group
#
az group create -n $name -l $location -o table
#
# Deploy resources
#
deploymentName=$name-$RANDOM
az deployment group create \
    -n $deploymentName \
    -g $name \
    -f ./bicep/main.bicep \
    --parameters \
        name=$name \
        keyVaultName=$keyVaultName \
        keyVaultResourceGroup=$keyVaultResourceGroup \
        networkNumber=$networkNumber \
        customData=$cloudInitCustomData \
    -o table

deploymentStatus=$(az deployment group show -n $deploymentName -g $name --query properties.provisioningState -o tsv)

if [[ $deploymentStatus == "Succeeded" ]]
then
    dnsServerPublicIp=$(az deployment group show -n $deploymentName -g $name --query properties.outputs.dnsServerPublicIp.value -o tsv)

    echo -e "\nDeployment complete.\n\nTo test for correct DNS server operation, you can SSH to the DNS server at IP address $dnsServerPublicIp and then query the DNS server using dig ns1.$privateDnsZoneName. and confirm that the response contains the IP address of the DNS server (10.$networkNumber.0.250)."
fi
