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

resource group 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: functions.getName(metadata.project, 'global', metadata.location, 'resourceGroup', null)
  location: metadata.location
  properties: {}
  tags: tags
}

// -------
// Modules
// -------

module resources './global.resources.bicep' = {
  scope: group
  params: {
    metadata: metadata
    tags: tags
  }
}

// ----------
// Parameters
// ----------

param metadata types.metadata
param tags object
