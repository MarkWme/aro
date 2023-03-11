#!/bin/bash
#
# ARO cluster deployment with private networking and custom (simulating on-premises) DNS
#
# Get the pull secret from https://cloud.redhat.com/openshift/install/azure/aro-provisioned
#
# Set environment variables
#
# Name of Azure Key Vault instance to use
# Script will retrieve the jumpbox VM admin credentials from the Key Vault
keyVaultName=msazuredev
keyVaultResourceGroup=shared
#
# Name of the private / custom DNS zone to use. The Bind DNS server will be configured to serve this zone.
#
privateDnsZoneName=private.chipfat.com
#
# ARO API server and Ingress visibility options
#
apiServerVisibility=Private
ingressVisibility=Private
#
# Azure region to deploy resources to
#
location=westeurope
#
# Choose random name for resources
#
name=$(cat /dev/urandom | base64 2>/dev/null | tr -dc '[:lower:]' | fold -w ${1:-5} | head -n 1)
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
az group create -n hub-${name} -l $location -o table
#
# Deploy resources
#
hubDeploymentName=hub-${name}-$RANDOM
az deployment group create \
    -n $hubDeploymentName \
    -g hub-${name} \
    -f ./bicep/hub.bicep \
    --parameters \
        name=hub-${name} \
        networkNumber=$networkNumber \
        keyVaultName=$keyVaultName \
        keyVaultResourceGroup=$keyVaultResourceGroup \
        customData=$cloudInitCustomData \
    -o table
routeTableId=$(az deployment group show -n $hubDeploymentName -g hub-${name} --query properties.outputs.routeTableId.value -o tsv)
dnsServerPrivateIp=10.${networkNumber}.0.250
name=ifnde
networkNumber=$(expr $number + 2)
#
# Create service principal for ARO
#
clientSecret=$(az ad sp create-for-rbac --name aro-${name}-spn --skip-assignment --query password -o tsv 2>/dev/null)
clientId=$(az ad sp list --display-name aro-${name}-spn --query '[].appId' -o tsv 2>/dev/null)
objectId=$(az ad sp list --display-name aro-${name}-spn --query '[].id' -o tsv 2>/dev/null)
#
# Get the ID of the Azure Red Hat OpenShift RP service principal
#
rpObjectId=$(az ad sp list --filter "displayname eq 'Azure Red Hat OpenShift RP'" --query '[0].id' -o tsv 2>/dev/null)
#
# Create resource group
#
az group create -n aro-${name} -l $location -o table
aroDeploymentName=aro-${name}-$RANDOM
az deployment group create \
    -n $aroDeploymentName \
    -g aro-${name} \
    -f ./bicep/aro.bicep \
    --parameters \
        name=aro-${name} \
        networkNumber=$networkNumber \
        hubNetworkName=hub-${name}-network \
        hubResourceGroupName=hub-${name} \
        routeTableId=$routeTableId \
        dnsServerPrivateIp=$dnsServerPrivateIp \
        objectId=$objectId \
        clientId=$clientId \
        clientSecret=$clientSecret \
        rpObjectId=$rpObjectId \
        apiServerVisibility=$apiServerVisibility \
        ingressVisibility=$ingressVisibility \
        privateDnsZoneName=$privateDnsZoneName \
        dnsServerPrivateIp=$dnsServerPrivateIp \
        keyVaultName=$keyVaultName \
        keyVaultResourceGroup=$keyVaultResourceGroup \
    -o table
#
# Create resource group
#
az group create -n apps-${name} -l $location -o table
networkNumber=$(expr $number + 3)
aroDeploymentName=apps-${name}-$RANDOM
az deployment group create \
    -n $aroDeploymentName \
    -g apps-${name} \
    -f ./bicep/apps.bicep \
    --parameters \
        name=apps-${name} \
        networkNumber=$networkNumber \
        hubNetworkName=hub-${name}-network \
        hubResourceGroupName=hub-${name} \
        routeTableId=$routeTableId \
        dnsServerPrivateIp=$dnsServerPrivateIp \
        privateDnsZoneName=$privateDnsZoneName \
        dnsServerPrivateIp=$dnsServerPrivateIp \
        keyVaultName=$keyVaultName \
        keyVaultResourceGroup=$keyVaultResourceGroup \
    -o table

#
# Get the cluster credentials
#
userName=$(az aro list-credentials --name aro-${name} --resource-group aro-${name} | jq -r ".kubeadminUsername")
password=$(az aro list-credentials --name aro-${name} --resource-group aro-${name} | jq -r ".kubeadminPassword")

#
# Get the cluster admin URL
#
clusterAdminUrl=$(az aro show --name aro-${name} --resource-group aro-${name} --query "consoleProfile.url" -o tsv)
apiUrl=$(az aro show --name aro-${name} --resource-group aro-${name} --query "apiserverProfile.url" -o tsv)
apiIp=$(az aro show --name aro-${name} --resource-group aro-${name} --query "apiserverProfile.ip" -o tsv)
ingressIp=$(az aro show --name aro-${name} --resource-group aro-${name} --query "ingressProfiles[0].ip" -o tsv)
echo "Cluster username: ${userName}"
echo "Cluster password: ${password}"
echo "Cluster admin URL: ${clusterAdminUrl}"
echo "Cluster API URL: ${apiUrl}"
echo "Cluster API IP: ${apiIp}"
echo "Cluster Ingress IP: ${ingressIp}"

echo -e "\nUpdate the DNS zone ${privateDnsZoneName} with the following records:\n"
echo -e "api.aro-${name}\tIN\tA\t${apiIp}"
echo -e "*.apps.api.aro-${name}\tIN\tA\t${ingressIp}"