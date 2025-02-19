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

// Cosmos DB

resource database 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: functions.getResourceName(metadata.project, 'global', metadata.location, 'cosmosDb', null)
  location: metadata.location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableMultipleWriteLocations: true
    locations: [
      for (location, index) in locations!: {
        locationName: location
        isZoneRedundant: false
        failoverPriority: index
      }
    ]
  }
}

// Managed Prometheus

// TODO: Implement

// Managed Grafana

// TODO: Implement

// Container Registry

// TODO: Enable registry geo-replication
// TODO: Add registry access for clusters

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: replace(
    functions.getResourceName(metadata.project, 'global', metadata.location, 'containerRegistry', null),
    '-',
    ''
  )
  location: metadata.location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
  }
  tags: tags
}

// Front Door

resource front 'Microsoft.Cdn/profiles@2024-09-01' = {
  name: functions.getResourceName(metadata.project, 'global', metadata.location, 'frontDoor', null)
  location: 'global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  tags: tags
}

// Origin Group

resource group 'Microsoft.Cdn/profiles/originGroups@2024-09-01' = {
  name: 'default'
  parent: front
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 2
    }
    healthProbeSettings: {
      probePath: '/'
      probeProtocol: 'Http'
      probeRequestType: 'HEAD'
      probeIntervalInSeconds: 100
    }
  }
}
resource origins 'Microsoft.Cdn/profiles/originGroups/origins@2024-09-01' = [
  for domain in metadata.?domains!: {
    name: split(domain, '.')[0]
    parent: group
    properties: {
      hostName: domain
      httpPort: 80
      httpsPort: 443
      priority: 1
      weight: 1000
    }
  }
]

// Endpoints

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-09-01' = {
  name: 'default'
  parent: front
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}
resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-09-01' = {
  name: 'default'
  parent: endpoint
  properties: {
    enabledState: 'Enabled'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Disabled'
    forwardingProtocol: 'MatchRequest'
    supportedProtocols: [
      'Http'
    ]
    originGroup: {
      id: group.id
    }
    originPath: '/'
    patternsToMatch: [
      '/*'
    ]
  }
}

// ----------
// Parameters
// ----------

@description('The metadata for the deployment.')
param metadata types.metadata

@description('The list of locations to deploy resources to.')
param locations array

@description('The tags to apply to all resources')
param tags object
