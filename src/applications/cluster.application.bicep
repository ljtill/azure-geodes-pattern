// -------
// Imports
// -------

import * as functions from '../functions/main.bicep'
import * as types from '../types/main.bicep'

// ----------
// Extensions
// ----------

extension kubernetes with {
  kubeConfig: kubeConfig
  namespace: 'default'
}

// ---------
// Resources
// ---------

// Namespace

resource namespace 'core/Namespace@v1' = {
  metadata: {
    name: 'test-infra'
  }
}

// Service

resource service 'core/Service@v1' = {
  metadata: {
    name: 'backend'
    namespace: 'test-infra'
  }
  spec: {
    selector: {
      app: 'backend'
    }
    ports: [
      {
        name: 'http'
        protocol: 'TCP'
        port: 3000
        targetPort: '3000'
      }
    ]
  }
  dependsOn: [namespace]
}

// Deployment

resource deployment 'apps/Deployment@v1' = {
  metadata: {
    name: 'backend'
    namespace: 'test-infra'
    labels: {
      app: 'backend'
    }
  }
  spec: {
    replicas: 3
    selector: {
      matchLabels: {
        app: 'backend'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'backend'
        }
      }
      spec: {
        containers: [
          {
            name: 'backend'
            image: 'gcr.io/k8s-staging-ingressconformance/echoserver:v20221109-7ee2f3e'
            env: [
              {
                name: 'POD_NAME'
                value: 'backend'
              }
              {
                name: 'NAMESPACE'
                value: 'test-infra'
              }
            ]
          }
        ]
      }
    }
  }
  dependsOn: [namespace]
}

// Gateway

#disable-next-line BCP081
resource gateway 'gateway.networking.k8s.io/Gateway@v1' = {
  metadata: {
    name: 'gateway'
    namespace: 'test-infra'
    annotations: {
      'alb.networking.azure.io/alb-id': trafficController.id
    }
  }
  spec: {
    gatewayClassName: 'azure-alb-external'
    listeners: [
      {
        name: 'http'
        port: 80
        protocol: 'HTTP'
        allowedRoutes: {
          namespaces: {
            from: 'Same'
          }
        }
      }
    ]
    addresses: [
      {
        type: 'alb.networking.azure.io/alb-frontend'
        value: trafficController.frontend.name
      }
    ]
  }
  dependsOn: [namespace]
}

// HTTP Route

#disable-next-line BCP081
resource route 'gateway.networking.k8s.io/HTTPRoute@v1' = {
  metadata: {
    name: 'traffic-route'
    namespace: 'test-infra'
  }
  spec: {
    parentRefs: [
      {
        name: 'gateway'
      }
    ]
    rules: [
      {
        backendRefs: [
          {
            name: 'backend'
            port: 3000
            weight: 100
          }
        ]
      }
    ]
  }
  dependsOn: [namespace]
}

// ----------
// Parameters
// ----------

@secure()
param kubeConfig string

param metadata types.metadata

param trafficController object
