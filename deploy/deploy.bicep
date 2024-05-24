param appName string = '235611'
param imageTag string
param keyVaultName string = 'kv${appName}'
param containerRegistryName string = 'acr${appName}'
param containerAppEnvName string = 'env${appName}'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}
resource containerAppEnv 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppEnvName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}


module containerApp 'containerApp.bicep' = {
  name: 'container-app'
  params: {
    containerAppEnvId: containerAppEnv.id
    acrServerName: containerRegistry.properties.loginServer
    acrUsername: keyVault.getSecret('acr-username-shared-key')
    acrPasswordSecret: keyVault.getSecret('acr-password-shared-key')
    imageTag: imageTag
    location: resourceGroup().location
  }
}
