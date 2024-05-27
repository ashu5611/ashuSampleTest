param location string = resourceGroup().location
param appName string
param logAnalyticsWorkspaceName string = 'law${appName}'
param keyVaultName string = 'kv${appName}'
param lastDeployed string = utcNow('d')
param dbUsername string
@secure()
param dbPassword string
@secure()
param secretNameRegistryUser string 
@secure() 
param secretNameRegistryPassword string

//container registry
param containerRegistryName string = 'acr${appName}'

//container environment
param containerEnvironmentName string = 'env${appName}'


var tags = {
  ApplicationName: 'epicApp'
  Environment: 'Development'
  LastDeployed: lastDeployed
}

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'ashuSampleTest-githubAction'
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
    enableRbacAuthorization: true
    accessPolicies: [

    ]
  }
}

resource keyVaultSecretUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, 'keyVaultSecretUserRoleAssignment')
  scope: keyVault
  properties: {
    principalId: userIdentity.properties.clientId  
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets Officer
  }
}


module db 'postgresdb.bicep' =  {
  name: 'postgres-db'
  params: {
    dbUsername: dbUsername
    dbPassword: dbPassword
    serverName: 'ashu-postgres-new-db-server'
    dbName: 'ashu-postgres-new-db'
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
    usernameSecret:  secretNameRegistryUser
    primaryPasswordSecret:  secretNameRegistryPassword
  }
}
