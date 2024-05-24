param appName string = '235611'
param location string
param containerAppEnvId string
param acrServerName string
param imageTag string
param lastDeployed string = utcNow('d')

@secure()
param acrUsername string 
@secure()
param acrPasswordSecret string

//container app
param containerAppName string = 'aca${appName}'

var containerAppEnvVariables = [
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: 'Development'
  }
]

var tags = {
  ApplicationName: 'epicApp'
  Environment: 'Development'
  LastDeployed: lastDeployed
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
        env: containerAppEnvVariables
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
    type: 'UserAssigned'
  }
}
