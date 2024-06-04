param location string = resourceGroup().location
param appName string
param logAnalyticsWorkspaceName string = 'law${appName}'
param keyVaultName string = 'kv${appName}'
param vnetName string = 'vnet${appName}'
param subnetName string = 'subnet${appName}'
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

param postgresServerName string = 'ashu-vnet-postgres-db-server'

param postgresDbName string = 'ashu-vnet-postgres-db'


var tags = {
  ApplicationName: 'epicApp'
  Environment: 'Development'
  LastDeployed: lastDeployed
}

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'sampleapp-dev-github-action'
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
    principalId: userIdentity.properties.principalId 
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7') // Key Vault Secrets Officer
  }
}

resource userName 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'db-username'
  parent: keyVault
  properties: {
    value: dbUsername
  }
}

resource password 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'db-password'
  parent: keyVault
  properties: {
    value: dbPassword
  }
}

module vnet 'virtualNetwork.bicep' = {
  name: 'vnet'
  params: {
    vnetName: vnetName
    tags: tags
    subnetName: subnetName
    postgresServerName: postgresServerName
  }
}

module db 'postgresdb.bicep' =  {
  name: 'postgres-db'
  dependsOn: [vnet]
  params: {
    dbUsername: dbUsername
    dbPassword: dbPassword
    postgresServerName: postgresServerName
    postgresDbName: postgresDbName
    dnsZoneId: vnet.outputs.privateDnsZoneId
    subnetId: vnet.outputs.subnetId
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
  dependsOn: [vnet, db]
  params: {
    containerEnvironmentName: containerEnvironmentName
    location: location
    logAnalyticsCustomerId: logAnalytics.outputs.customerId
    logAnalyticsSharedKey: keyVault.getSecret('law-shared-key')
    tags: tags
    vnetName: vnetName
    subnetName: subnetName
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
