param name string
param location string
param controlPlaneSubnetId string
param nodeSubnetId string
param clientId string
param controlPlaneVmSize string
param nodeVmSize string
param nodeVmDiskSize int
param nodeCount int
param apiServerVisibility string
param ingressVisibility string
param domain string
param podCidr string
param serviceCidr string

@secure()
param clientSecret string

@secure()
param pullSecret string

resource aroCluster 'Microsoft.RedHatOpenShift/OpenShiftClusters@2020-04-30' = {
  name: name
  location: location
  properties: {
    clusterProfile: {
      domain: domain
      resourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${name}-${location}'
      pullSecret: pullSecret
    }
    networkProfile: {
      podCidr: podCidr
      serviceCidr: serviceCidr
    }
    servicePrincipalProfile: {
      clientId: clientId
      clientSecret: clientSecret
    }
    masterProfile: {
      vmSize: controlPlaneVmSize
      subnetId: controlPlaneSubnetId
    }
    workerProfiles: [
      {
        name: 'worker'
        vmSize: nodeVmSize
        diskSizeGB: nodeVmDiskSize
        subnetId: nodeSubnetId
        count: nodeCount
      }
    ]
    apiserverProfile: {
      visibility: apiServerVisibility
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: ingressVisibility
      }
    ]
  }
}

output apiServerIp string = aroCluster.properties.apiserverProfile.ip
output ingressIp string = aroCluster.properties.ingressProfiles[0].ip
