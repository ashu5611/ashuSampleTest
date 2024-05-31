param containerEnvironmentName string
param location string
param logAnalyticsCustomerId string
@secure()
param logAnalyticsSharedKey string
param tags object
param vnetName string
param subnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: vnetName
  resource subnet 'subnets' existing = {
    name: '${subnetName}-app'
  
  }
}
resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerEnvironmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: virtualNetwork::subnet.id
    
    }
  }
}

output containerAppEnvId string = env.id
