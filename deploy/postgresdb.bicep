param dbUsername string
@secure()
param dbPassword string
param serverEdition string = 'Burstable'
param skuSizeGB int = 32
param dbInstanceType string = 'Standard_B1ms'
param haMode string = 'Disabled'
param version string = '12'
param postgresServerName string
param postgresDbName string
param dnsZoneId string
param subnetId string




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
      privateDnsZoneArmResourceId: dnsZoneId
      publicNetworkAccess: 'Disabled'
      delegatedSubnetResourceId: subnetId
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled' 
      passwordAuth: 'Disabled'
      tenantId: tenant().tenantId
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

resource postgresqlDbServerPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${postgresServerName}-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: subnetId
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
          privateDnsZoneId: dnsZoneId
        }
      }
    ]
  }
}
