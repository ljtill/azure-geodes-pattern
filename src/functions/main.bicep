// ---------
// Functions
// ---------

// Defaults

func loadDefaults() object => loadJsonContent('../defaults.json')

// Deployment Scopes

// TODO: Allowed deployment scope list

func deploymentScopeAlias(scope string) string => '-${loadDefaults().deploymentScopes[scope]}'

// Locations

// TODO: Allowed location list

func locationAlias(location string) string => '-${loadDefaults().locations[location]}'

// Resource Types

// TODO: Allowed resource type list

func resourceTypeAlias(resourceType string) string => '-${loadDefaults().resourceTypes[resourceType]}'

// Deployments

@export()
func getDeploymentName(name string) string => format('${name}-${uniqueString('${name}', deployment().name)}')

// Names
// See defaults.json for allowed values

@export()
func getResourceName(project string, deploymentScope string, location string, resourceType string, count string?) string =>
  '${toLower(project)}${deploymentScopeAlias(deploymentScope)}${locationAlias(location!)}${resourceTypeAlias(resourceType)}${count == null ? '' : '-${count!}'}'
