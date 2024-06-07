param vnetName string
param subnetName string
param tags object
param postgresServerName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01'= {
  name: vnetName
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }

  resource databaseSubnet 'subnets' = {
    name: '${subnetName}-db'
    properties: {
      addressPrefix: '10.0.0.0/24'
      privateEndpointNetworkPolicies: 'Disabled' // Required for private link
      delegations: [
        {
          name: '${subnetName}-delegation-db'
          properties: {
            serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
          }
        }
      ]
    }
  }

  resource containerAppSubnet 'subnets' = {
    name: '${subnetName}-app'
    properties: {
      addressPrefix: '10.0.2.0/23'
      delegations: [
        {
          name: '${subnetName}-delegation-app'
          properties: {
            serviceName: 'Microsoft.App/environments'
          }
        }
      ]
    }
    
  }
}
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${postgresServerName}.privatelink.postgres.database.azure.com'
  location: 'global'
  dependsOn: [virtualNetwork]

  resource vnetLink 'virtualNetworkLinks' = {
    name: '${postgresServerName}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetwork.id
      }
    }
  }
}

output vnetId string = virtualNetwork.id
output privateDnsZoneId string = privateDnsZone.id
output subnetId string = virtualNetwork::databaseSubnet.id
