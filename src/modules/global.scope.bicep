// -------
// Imports
// -------

import * as functions from '../functions/main.bicep'
import * as types from '../types/main.bicep'

// ------
// Scopes
// ------

targetScope = 'subscription'

// ---------
// Resources
// ---------

resource group 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: functions.getResourceName(metadata.project, 'global', metadata.location, 'resourceGroup', null)
  location: metadata.location
  properties: {}
  tags: tags
}

// -------
// Modules
// -------

module resources './global.resources.bicep' = {
  name: functions.getDeploymentName('resources')
  scope: group
  params: {
    metadata: metadata
    locations: locations
    tags: tags
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
