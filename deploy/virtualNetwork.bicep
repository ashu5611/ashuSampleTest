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
      delegations: [
        {
          name: '${subnetName}-subnet-delegation-db'
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
    }
  }
}


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${postgresServerName}.private.postgres.database.azure.com'
  dependsOn: [virtualNetwork]
  location: 'global'

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
