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

resource group 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: functions.getResourceName(metadata.project, 'regional', metadata.location, 'resourceGroup', null)
  location: metadata.location
  properties: {}
  tags: tags
}

// -------
// Modules
// -------

module resources './regional.resources.bicep' = {
  name: functions.getDeploymentName('resources')
  scope: group
  params: {
    metadata: metadata
    tags: tags
  }
}

// ----------
// Parameters
// ----------

@description('The metadata for the deployment.')
param metadata types.metadata

@description('The tags to apply to all resources')
param tags object

// -------
// Outputs
// -------

output domain string = resources.outputs.domain
