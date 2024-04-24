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

// module global './modules/global.scope.bicep' = {
//   params: {
//     metadata: {
//       location: 'swedencentral'
//       project: project
//       domains: ['bing.com']
//     }
//     tags: tags
//   }
// }

// ---------
// Variables
// ---------

var tags = {
  Owner: 'Lyon Till'
}

// ----------
// Parameters
// ----------

@description('The name of the project')
param project string

@description('The locations to deploy resources')
param locations array

@description('Installation of test-infra application')
param application bool
