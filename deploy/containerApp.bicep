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
param imageTag string

resource postgresDb 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  name: dbName
  parent: postgresServer
}
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
        image: '${acrServerName}/epicapp:${imageTag}'
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