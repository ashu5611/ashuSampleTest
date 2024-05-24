param crName string
param location string
param tags object
param keyVaultName string
var registryLoginServer = 'registry-login-server'

@secure()
param primaryPasswordSecret string
@secure()
param usernameSecret string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'ashuSampleTest-githubAction'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: crName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}': {}
    }
  }
}


//adding container registry username to keyvault
resource acrUsername 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: usernameSecret
  parent: keyVault
  properties: {
    value: containerRegistry.listCredentials().username
  }
}

//adding container registry password to key vault
resource acrPasswordSecret1 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: primaryPasswordSecret
  parent: keyVault
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value
  }
}

//adding login server  to key vault
resource acrLoginServer 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: registryLoginServer
  parent: keyVault
  properties: {
    value: containerRegistry.properties.loginServer
  }
}
