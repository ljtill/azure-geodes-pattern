// -------
// Imports
// -------

import * as functions from '../functions/main.bicep'
import * as types from '../types/main.bicep'

// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Virtual Network

resource network 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: functions.getResourceName(metadata.project, 'regional', metadata.location, 'virtualNetwork', null)
  location: metadata.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.224.0.0/12'
      ]
    }
    subnets: [
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: '10.224.0.0/16'
          natGateway: {
            id: gateway.id
          }
          networkSecurityGroup: {
            id: securityGroup.id
          }
        }
      }
      {
        name: 'alb-subnet'
        properties: {
          addressPrefix: '10.225.0.0/16'
          delegations: [
            {
              name: 'Microsoft.ServiceNetworking/trafficControllers'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ]
          networkSecurityGroup: {
            id: securityGroup.id
          }
        }
      }
    ]
  }
  tags: tags
}

// Security Group

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: functions.getResourceName(metadata.project, 'regional', metadata.location, 'securityGroup', null)
  location: metadata.location
  properties: {
    securityRules: []
  }
  tags: tags
}

// Public IP

resource ipAddress 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: functions.getResourceName(metadata.project, 'regional', metadata.location, 'ipAddress', null)
  location: metadata.location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

// NAT Gateway

resource gateway 'Microsoft.Network/natGateways@2023-11-01' = {
  name: functions.getResourceName(metadata.project, 'regional', metadata.location, 'natGateway', null)
  location: metadata.location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: ipAddress.id
      }
    ]
  }
  tags: tags
}

// Traffic Controller

resource controller 'Microsoft.ServiceNetworking/trafficControllers@2023-11-01' = {
  name: functions.getResourceName(metadata.project, 'regional', metadata.location, 'trafficController', null)
  location: metadata.location
  properties: {}
  tags: tags
}

resource frontend 'Microsoft.ServiceNetworking/trafficControllers/frontends@2023-11-01' = {
    name: 'default'
  // name: functions.getResourceName(metadata.project, 'region', metadata.location, 'frontend', null)
  parent: controller
    location: metadata.location
    properties: {}
  }

// TODO: Implement multiple associations

resource association 'Microsoft.ServiceNetworking/trafficControllers/associations@2023-11-01' = {
    name: 'default'
  // name: functions.getResourceName(metadata.project, 'stamp', metadata.location, 'assocation', null)
  parent: controller
    location: metadata.location
    properties: {
      associationType: 'subnets'
      subnet: {
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', network.name, 'alb-subnet')
      }
    }
  }

// Kubernetes Service

resource cluster 'Microsoft.ContainerService/managedClusters@2024-03-02-preview' = {
  name: functions.getResourceName(metadata.project, 'regional', metadata.location, 'managedCluster', null)
  location: metadata.location
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    nodeResourceGroup: functions.getResourceName(metadata.project, 'managed', metadata.location, 'resourceGroup', null)
    dnsPrefix: functions.getResourceName(metadata.project, 'regional', metadata.location, 'managedCluster', null)
    agentPoolProfiles: [
      {
        name: 'system'
        count: 3
        vmSize: 'Standard_D2ds_v5'
        enableAutoScaling: true
        minCount: 1
        maxCount: 5
        osType: 'Linux'
        mode: 'System'
        availabilityZones: pickZones('Microsoft.ContainerService', 'managedClusters', metadata.location, 3)
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', network.name, 'aks-subnet')
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
      {
        name: 'user'
        count: 5
        vmSize: 'Standard_D4ds_v5'
        enableAutoScaling: true
        minCount: 3
        maxCount: 20
        osType: 'Linux'
        mode: 'User'
        availabilityZones: pickZones('Microsoft.ContainerService', 'managedClusters', metadata.location, 3)
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', network.name, 'aks-subnet')
      }
    ]
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
    }
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    networkProfile: {
      networkPlugin: 'azure'
      outboundType: 'userAssignedNATGateway'
    }
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      imageCleaner: {
        enabled: true
        intervalHours: 168
      }
      workloadIdentity: {
        enabled: true
      }
    }
  }
  tags: tags
}

// Extensions

resource extension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  name: 'flux'
  scope: cluster
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    configurationSettings: {
      'source-controller.enabled': 'true'
      'helm-controller.enabled': 'true'
      'kustomize-controller.enabled': 'false'
      'notification-controller.enabled': 'true'
      'image-automation-controller.enabled': 'false'
      'image-reflector-controller.enabled': 'false'
    }
  }
}

// Managed Identity

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: functions.getResourceName(metadata.project, 'regional', metadata.location, 'userIdentity', null)
  location: metadata.location
  tags: tags
}

resource credential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-07-31-preview' = {
  name: 'default'
  parent: identity
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.properties.oidcIssuerProfile.issuerURL
    subject: 'system:serviceaccount:azure-alb-system:alb-controller-sa'
  }
}

// Role Assignments

resource networkAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(network.name, 'NetworkContributor')
  scope: network
  properties: {
    principalId: identity.properties.principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4d97b98b-1d4f-4787-a291-c67834d212e7'
    )
    principalType: 'ServicePrincipal'
  }
}

resource gatewayAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identity.name, 'ApplicationGatewayForContainersConfigurationManager')
  scope: controller
  properties: {
    principalId: identity.properties.principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'fbc52c3f-28ad-4303-a892-8a056630b8f1'
    )
    principalType: 'ServicePrincipal'
  }
}

// -------
// Modules
// -------

module controllerModule './cluster.controller.bicep' = {
  name: functions.getDeploymentName('controller')
  params: {
    kubeConfig: cluster.listClusterAdminCredential().kubeconfigs[0].value
    clientId: identity.properties.clientId
  }
  dependsOn: [extension]
}

  name: functions.getDeploymentName('application')
    params: {
      kubeConfig: cluster.listClusterAdminCredential().kubeconfigs[0].value
      metadata: metadata
      trafficController: {
        id: controller.id
        frontend: {
        name: functions.getResourceName(metadata.project, 'regional', metadata.location, 'frontend', null)
        }
      }
    }
    dependsOn: [controllerModule]
  }

// ----------
// Parameters
// ----------

param metadata types.metadata
param tags object
