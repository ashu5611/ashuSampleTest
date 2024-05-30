param appName string = '235611'
param location string
param containerAppEnvId string
param acrServerName string
param imageTag string
param lastDeployed string = utcNow('d')
@secure()
param dbUsername string
@secure()
param dbPassword string

//container app
param containerAppName string = 'aca${appName}'

var tags = {
  ApplicationName: 'epicApp'
  Environment: 'Development'
  LastDeployed: lastDeployed
}

resource acrUserIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'acr-pull-identity'
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
      targetPort: 1989
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
        name: 'spring-datasource-username'
        value: dbUsername
      }
      {
        name: 'spring-datasource-password'
        value: dbPassword
      }
    ]
    registries: [
      {
        server: acrServerName
        identity: acrUserIdentity.id
      }
    ]
   }
   template: {
    containers: [
      {
        name: containerAppName
        image: '${acrServerName}/epicapp:${imageTag}'
        env: [
          {
            name: 'SPRING_PROFILES_ACTIVE'
            value: 'test'
          }
          { 
            name: 'SPRING_DATASOURCE_USERNAME'
            secretRef: 'spring-datasource-username'
          }
          {
            name: 'SPRING_DATASOURCE_PASSWORD'
            secretRef: 'spring-datasource-password'
          }
          {
            name: 'SPRING_DATASOURCE_URL'
            value: 'jdbc:postgresql://ashu-vnet-postgres-db-server.postgres.database.azure.com:5432/ashu-vnet-postgres-db'
          }
        ]
        resources: {
          cpu: 1
          memory: '2.0Gi'
        }
      }
    
    ]
    scale: {
      minReplicas: 1
      maxReplicas: 2
    }
   }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${acrUserIdentity.id}': {}
    }
  }
}
