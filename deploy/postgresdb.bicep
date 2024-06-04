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


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
  resource subnet 'subnets' existing = {
    name: '${subnetName}-db'
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${postgresServerName}.private.postgres.database.azure.com'
  location: 'global'
}


resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${postgresServerName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
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
      privateDnsZoneArmResourceId: privateDnsZone.id
      publicNetworkAccess: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled' 
      passwordAuth: 'Disabled'
      tenantId: tenant().tenantId
    }
    highAvailability: {
      mode: 'Disabled'
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

resource postgresqlDbServerPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${postgresServerName}-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: virtualNetwork::subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${postgresServerName}-connection'
        properties: {
          privateLinkServiceId: postgresServer.id
          groupIds: [
            'postgresqlServer'
          ]
          requestMessage: 'Please approve connection'
        }
      }
    ]
  }
}
resource postgresqlDbServerPrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: 'default'
  parent: postgresqlDbServerPrivateEndpoint
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
