#!/bin/bash
#
# ARO cluster deployment with private networking and DNS
#
# Get the pull secret from https://cloud.redhat.com/openshift/install/azure/aro-provisioned
#
# Set environment variables
#
# Name of Azure Key Vault instance to use
# Script will retrieve the jumpbox VM admin credentials from the Key Vault
keyVaultName=msazuredev
adminUser=$(az keyvault secret show --vault-name $keyVaultName --name adminUser --query value -o tsv)
adminPassword=$(az keyvault secret show --vault-name $keyVaultName --name adminPassword --query value -o tsv)

apiServerVisibility=Private
ingressVisibility=Private

privateDnsZoneName=private.msazure.dev.test

location=westeurope
#
# Choose random name for resources
#
name=aro-$(cat /dev/urandom | base64 | tr -dc '[:lower:]' | fold -w ${1:-5} | head -n 1) 2>/dev/null
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
# Create service principal
#
clientSecret=$(az ad sp create-for-rbac --name ${name}-spn --skip-assignment --query password -o tsv 2>/dev/null)
clientId=$(az ad sp list --display-name ${name}-spn --query '[].appId' -o tsv 2>/dev/null)
objectId=$(az ad sp list --display-name ${name}-spn --query '[].id' -o tsv 2>/dev/null)
#
# Get the pull secret from https://cloud.redhat.com/openshift/install/azure/aro-provisioned
#
pullSecret=$(cat /Users/mark/Downloads/pull-secret.txt)

rpObjectId=$(az ad sp list --filter "displayname eq 'Azure Red Hat OpenShift RP'" --query '[0].id' -o tsv 2>/dev/null)

az group create -n $name -l $location -o table

az deployment group create \
    -n $name-$RANDOM \
    -g $name \
    -f ./bicep/main.bicep \
    --parameters \
        name=$name \
        networkNumber=$networkNumber \
        privateDnsZoneName=$privateDnsZoneName \
        objectId=$objectId \
        clientId=$clientId \
        clientSecret=$clientSecret \
        pullSecret=$pullSecret \
        rpObjectId=$rpObjectId \
        apiServerVisibility=$apiServerVisibility \
        ingressVisibility=$ingressVisibility \
        jumpboxAdminUser=$adminUser \
        jumpboxAdminPassword=$adminPassword \
    -o table

#
# Get the cluster credentials
#
userName=$(az aro list-credentials --name $name --resource-group $name | jq -r ".kubeadminUsername")
password=$(az aro list-credentials --name $name --resource-group $name | jq -r ".kubeadminPassword")

#
# Get the cluster admin URL
#
clusterAdminUrl=$(az aro show --name $name --resource-group $name --query "consoleProfile.url" -o tsv)

echo "Cluster username: ${userName}"
echo "Cluster password: ${password}"
echo "Cluster admin URL: ${clusterAdminUrl}"