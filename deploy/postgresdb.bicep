param dbUsername string
@secure()
param dbPassword string
param location string = 'East US'
param serverName string
param dbName string
param serverEdition string = 'Burstable'
param skuSizeGB int = 32
param dbInstanceType string = 'Standard_B1ms'
param haMode string = 'Disabled'
param version string = '12'
param subnetName string 
param vnetName string
param startIpAddress string = '0.0.0.0'
param endIpAddress string = '0.0.0.0'


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'ashu-postgres-new-db-server.private.postgres.database.azure.com'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: vnetName
  resource subnet 'subnets' existing = {
    name: '${subnetName}-db'
  
  }
}

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: serverName
  location: location
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
      privateDnsZoneArmResourceId: privateDnsZone.id
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
  name: dbName
  parent: postgresServer
}

