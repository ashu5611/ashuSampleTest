param location string = resourceGroup().location
param appName string = uniqueString(resourceGroup().id)
param logAnalyticsWorkspaceName string = 'law${appName}'
param keyVaultName string = 'kv${appName}'
param lastDeployed string = utcNow('d')
param imageTag string
param dbUsername string
@secure()
param dbPassword string

//container registry
param containerRegistryName string = 'acr${appName}'

//container environment
param containerEnvironmentName string = 'env${appName}'

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

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableSoftDelete: false
    accessPolicies: [
    ]
  }
}

module db 'postgresdb.bicep' =  {
  name: 'postgres-db'
  params: {

    location: location
    dbUsername: dbUsername
    dbPassword: dbPassword
    serverName: 'ashu-db-server'
    dbName: 'ashu-db'
  }
}
//module invocations:

module logAnalytics 'logAnalytics.bicep' = {
  name: 'log-analytics'
  params: {
    tags: tags
    keyVaultName: keyVault.name
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module containerEnv 'containerAppEnvironment.bicep' = {
  name: 'container-app-env'
  params: {
    containerEnvironmentName: containerEnvironmentName
    location: location
    logAnalyticsCustomerId: logAnalytics.outputs.customerId
    logAnalyticsSharedKey: keyVault.getSecret('law-shared-key')
    tags: tags
  }
}

module containerRegistry 'containerRegistry.bicep' =  {
  name: 'acr'
  params: {
    tags: tags
    crName: containerRegistryName
    keyVaultName: keyVault.name
    location: location
  }
}

module containerApp 'containerApp.bicep' = {
  name: 'container-app'
  dependsOn: [
    containerRegistry
    db
  ]
  params: {
    tags: tags
    imageTag: imageTag
    location: location
    containerAppName: containerAppName
    envVariables: containerAppEnvVariables
    containerAppEnvId: containerEnv.outputs.containerAppEnvId
    acrServerName: containerRegistry.outputs.serverName
    acrUsername: keyVault.getSecret('acr-username-shared-key')
    acrPasswordSecret: keyVault.getSecret('acr-password-shared-key')
  }
}
