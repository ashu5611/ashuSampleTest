param dbUsername string
@secure()
param dbPassword string
param location string = resourceGroup().location
param serverName string
param dbName string
param serverEdition string = 'Burstable'
param skuSizeGB int = 32
param dbInstanceType string = 'Standard_B1ms'
param haMode string = 'ZoneRedundant'
param availabilityZone string = '1'
param version string = '12'
param virtualNetworkExternalId string =
param subnetName string = ''
param privateDnsZoneArmResourceId string = ''

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
      delegatedSubnetResourceId: (empty(virtualNetworkExternalId) ? json('null') : json('\'${virtualNetworkExternalId}/subnets/${subnetName}\''))
      privateDnsZoneArmResourceId: (empty(virtualNetworkExternalId) ? json('null') : privateDnsZoneArmResourceId)
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
    availabilityZone: availabilityZone
  }
}

resource postgresDb 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  name: dbName
  parent: postgresServer
}

resource postgresFirewallRule 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  name: '${postgresServer.name}/AllowAll'
  properties: {
    startIpAddress: startIpAddress
    endIpAddress: endIpAddress
  }
}