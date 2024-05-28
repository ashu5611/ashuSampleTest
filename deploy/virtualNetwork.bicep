param vnetName string
param subnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }

  resource databaseSubnet 'subnets' = {
    name: 'database-subnet'
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

  resource webappSubnet 'subnets' = {
    name: 'app-subnet'
    properties: {
      addressPrefix: '10.0.1.0/24'
      delegations: [
        {
          name: '${subnetName}-subnet-delegation-app'
          properties: {
            serviceName: 'Microsoft.App/containerApps'
          }
        }
      ]
    }
  }
}


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'ashu-postgres-new-db-server.private.postgres.database.azure.com'
  location: 'global'

  resource vnetLink 'virtualNetworkLinks' = {
    name: 'ashu-postgres-new-db-server-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetwork.id
      }
    }
  }
}
