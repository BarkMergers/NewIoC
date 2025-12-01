param appServicePlanName string = 'MicroPlan4'
param location string = resourceGroup().location
param skuName string = 'B1' // B1 = Basic tier, size 1
param dotnetVersion string = 'DOTNET|9.0' // Specification for .NET 9 on Linux

// Application Settings (Hardcoded for now, but KeyVault is recommended)
param KeystoneDBConnection string = 'Server=tcp:eriksondb.database.windows.net,1433;Initial Catalog=erikson-system-datbase;Persist Security Info=False;User ID=erikson;Password=MyStr0ngP@ssword!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
param MaintenanceDBConnection string = 'Server=tcp:eriksondb.database.windows.net,1433;Initial Catalog=erikson-system-datbase;Persist Security Info=False;User ID=erikson;Password=MyStr0ngP@ssword!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
param KeystoneHasherKey string = 'O5jmvvEQ7QET9RH6jjsW5/d7oL3Jbg3qFx4A6LvDsgg='
param OpenAIKey string = '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'

// Repeating data to configure the micro services
var microservices = [
  {
    name: 'MicroGateway4'
    port: 8080
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroAccount4'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroAgent4'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroAsset4'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroCustomer4'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroFines4'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroTenant4'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
]

// --- 1. App Service Plan (Fixed: Switched to Linux kind) ---
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName // e.g., 'B1'
  }
  kind: 'Linux' // <-- CORRECTED: For modern .NET/containers, this should be Linux
  properties: {
    reserved: true // <-- CORRECTED: Required for Linux plans
  }
}

// --- 2. Microservice App Services ---
resource webApps 'Microsoft.Web/sites@2022-09-01' = [for service in microservices: {
  name: service.name
  location: location
  identity: {
    type: 'SystemAssigned' // This creates and enables the Managed Identity
  }
  properties: {
    serverFarmId: appServicePlan.id
    
    siteConfig: {
      // General Configuration
      minTlsVersion: '1.2'
      linuxFxVersion: dotnetVersion // e.g., 'DOTNET|9.0'
      // Application Settings
      appSettings: [
        {
          name: 'KeystoneDBConnection'
          value: string(KeystoneDBConnection)
        }
        {
          name: 'MaintenanceDBConnection'
          value: string(MaintenanceDBConnection)
        }
        {
          name: 'KeystoneHasherKey'
          value: string(KeystoneHasherKey)
        }
        {
          name: 'OpenAIKey'
          value: string(OpenAIKey)
        }
        {
          name: 'WEBSITES_PORT'
          value: string(service.port) // Ensure the port is exposed
        }
      ]
    }
    httpsOnly: true
  }
}]

//////////////////////////////////////////////////////////////////////////////////////////////

// --- FRONT DOOR CONFIGURATION ---

param frontDoorProfileName string = 'FrontDoorKeystone4'
param endpointName string = 'keystone-endpoint-4'

// Dynamic variable to get the actual hostname of the deployed MicroGateway4 App Service
// MicroGateway4 is the first item in the 'webApps' array (index 0).
var apiGatewayHostName = webApps[0].properties.defaultHostName

// --- Front Door Profile (using stable API version 2023-05-01) ---
resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: frontDoorProfileName
  location: 'global' // Front Door is a global service
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  kind: 'frontdoor'
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

// --- 1. Endpoint ---
resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: endpointName
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

// --- 2. Origin Group ---
resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoorProfile
  name: 'apiGatewayOriginGroup'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    // Health Probe for your API Gateway
    healthProbeSettings: {
      probePath: '/health'
      probeIntervalInSeconds: 100
      probeProtocol: 'Https'
      probeRequestType: 'HEAD'
    }
    // Defines the MicroGateway4 App Service as the Origin
    origins: [
      {
        name: 'ukWestGatewayOrigin'
        properties: {
          hostName: apiGatewayHostName // Dynamically linked to MicroGateway4's hostname
          httpPort: 80
          httpsPort: 443
          originHostHeader: apiGatewayHostName
          priority: 1
          weight: 1000
          originType: 'AppService'
          enforceCertificateVerification: true
          enabledState: 'Enabled'
          // Resource ID link to the gateway app service
          resourceId: webApps[0].id
        }
      }
    ]
  }
}

// --- 3. Route: Maps Endpoint traffic to the Origin Group ---
resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: endpoint
  name: 'defaultRoute'
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*' // Route all paths to the gateway
    ]
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: true
    cdnSettings: {
      queryStringCachingBehavior: 'IgnoreQueryString'
      isCompressionEnabled: false
    }
    enabledState: 'Enabled'
  }
}

// Output the generated Front Door hostname
output frontDoorHostname string = '${endpoint.name}-${frontDoorProfile.name}.azurefd.net'