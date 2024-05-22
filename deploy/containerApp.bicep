param containerAppName string
param location string
param containerAppEnvId string
param acrServerName string
@secure()
param acrUsername string
@secure()
param acrPasswordSecret string
param envVariables array = []
param tags object


resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  tags: tags
  properties: {
   managedEnvironmentId: containerAppEnvId
   configuration: {
    activeRevisionsMode: 'Single'
    ingress: {
      external: true
      transport: 'http'
      targetPort: 3500
      allowInsecure: false
      traffic: [
        {
          latestRevision: true
          weight: 100
        }
      ]
    }
    secrets: [
      {
        name: 'container-registry-password'
        value: acrPasswordSecret
      }
    ]
    registries: [
      {
        server: acrServerName
        username: acrUsername
        passwordSecretRef: 'container-registry-password'
      }
    ]
   }
   template: {
    containers: [
      {
        name: containerAppName
        image: '${acrServerName}/epicapp:ddc1b23c4407491218de1cdfcf1966f98ccc0631'
        env: envVariables
        resources: {
          cpu: 1
          memory: '2.0Gi'
        }
      }
    ]
    scale: {
      minReplicas: 1
      maxReplicas: 10
    }
   }
  }
  identity: {
    type: 'SystemAssigned'
  }
}