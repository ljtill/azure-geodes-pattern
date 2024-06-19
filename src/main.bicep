// -------
// Imports
// -------

import * as functions from './functions/main.bicep'
import * as types from './types/main.bicep'

// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

module regions './modules/regional.scope.bicep' = [
  for (location, index) in locations: {
    name: functions.getDeploymentName('regions-${index}')
    params: {
      metadata: {
        location: location
        project: project
        application: application
      }
      tags: tags
    }
  }
]

module global './modules/global.scope.bicep' = {
  name: functions.getDeploymentName('global')
  params: {
    metadata: {
      location: 'swedencentral'
      project: project
      domains: [for (region, index) in locations: regions[index].outputs.domain]
      application: application
    }
    locations: locations
    tags: tags
  }
}

// ---------
// Variables
// ---------

// Determines if the demo application
// should be installed in the clusters.
var application = false

// ----------
// Parameters
// ----------

@description('The name of the project')
param project string

@description('The locations to deploy resources')
param locations array

@description('The tags to apply to all resources')
param tags object
