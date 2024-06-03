param dbUsername string
@secure()
param dbPassword string
param serverEdition string = 'Burstable'
param skuSizeGB int = 32
param dbInstanceType string = 'Standard_B1ms'
param haMode string = 'Disabled'
param version string = '12'
param subnetName string 
param vnetName string
param postgresServerName string
param postgresDbName string


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: vnetName
  resource subnet 'subnets' existing = {
    name: '${subnetName}-db'
  
  }
}

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: postgresServerName
  location: resourceGroup().location
  sku: {
    name: dbInstanceType
    tier: serverEdition
  }
  properties: {
    version: version
    administratorLogin: dbUsername
    administratorLoginPassword: dbPassword
    network: {
      delegatedSubnetResourceId: virtualNetwork::subnet.id
    }
    highAvailability: {
      mode: haMode
    }

    storage: {
      storageSizeGB: skuSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }
}

resource postgresDb 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  name: postgresDbName
  parent: postgresServer
}


@description('Private Endpoint for PostgreSQL')
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'myPostgresPrivateEndpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: virtualNetwork::subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'postgresConnection'
        properties: {
          privateLinkServiceId: postgresServer.id
          groupIds: ['postgresqlServer']
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${postgresServerName}.postgres.database.azure.com'
  location: resourceGroup().location
}

// DNS Zone Group
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: 'myPostgresPrivateDnsZoneGroup'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'zoneConfig'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
