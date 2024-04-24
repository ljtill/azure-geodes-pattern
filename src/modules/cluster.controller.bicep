// -------
// Imports
// -------

import * as types from '../types/main.bicep'

// ---------
// Providers
// ---------

provider kubernetes with {
  kubeConfig: kubeConfig
  namespace: 'default'
}

// ---------
// Resources
// ---------

// Service Account

resource account 'core/ServiceAccount@v1' = {
  metadata: {
    name: 'flux-reconciler'
    namespace: 'default'
  }
}

// Role

resource role 'rbac.authorization.k8s.io/Role@v1' = {
  metadata: {
    name: 'flux-reconciler'
    namespace: 'default'
  }
  rules: [
    {
      apiGroups: ['*']
      resources: ['*']
      verbs: ['*']
    }
  ]
}

// Role Binding

resource binding 'rbac.authorization.k8s.io/RoleBinding@v1' = {
  metadata: {
    name: 'flux-reconciler'
    namespace: 'default'
  }
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io'
    kind: 'Role'
    name: 'flux-reconciler'
  }
  subjects: [
    {
      kind: 'ServiceAccount'
      name: 'flux-reconciler'
      namespace: 'default'
    }
  ]
}

// Cluster Role

resource clusterRole 'rbac.authorization.k8s.io/ClusterRole@v1' = {
  metadata: {
    name: 'flux-reconciler'
  }
  rules: [
    {
      apiGroups: ['*']
      resources: ['*']
      verbs: ['*']
    }
  ]
}

// Cluster Role Binding

resource clusterBinding 'rbac.authorization.k8s.io/ClusterRoleBinding@v1' = {
  metadata: {
    name: 'flux-reconciler'
  }
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io'
    kind: 'ClusterRole'
    name: 'flux-reconciler'
  }
  subjects: [
    {
      kind: 'ServiceAccount'
      name: 'flux-reconciler'
      namespace: 'default'
    }
  ]
}

// Repository

#disable-next-line BCP081
resource repository 'source.toolkit.fluxcd.io/HelmRepository@v1beta2' = {
  metadata: {
    name: 'application-lb'
    namespace: 'default'
  }
  spec: {
    type: 'oci'
    interval: '5m'
    url: 'oci://mcr.microsoft.com/application-lb/charts'
  }
}

// Release

#disable-next-line BCP081
resource release 'helm.toolkit.fluxcd.io/HelmRelease@v2beta1' = {
  metadata: {
    name: 'alb-controller'
    namespace: 'default'
  }
  spec: {
    serviceAccountName: 'flux-reconciler'
    targetNamespace: 'azure-alb-system'
    interval: '50m'
    chart: {
      spec: {
        chart: 'alb-controller'
        sourceRef: {
          kind: 'HelmRepository'
          name: 'application-lb'
        }
      }
    }
    install: {
      createNamespace: true
    }
    values: {
      albController: {
        podIdentity: {
          clientID: clientId
        }
      }
    }
  }
}

// ----------
// Parameters
// ----------

@secure()
param kubeConfig string

@secure()
param clientId string
