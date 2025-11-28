param webAppName1 string = 'MicroGateway3'
param webAppName2 string = 'MicroAgent3'
param appServicePlanName string = 'MicroPlan3'
param location string = resourceGroup().location
param skuName string = 'B1' // B1 = Basic tier, size 1
param dotnetVersion string = 'DOTNET|9.0' // Specification for .NET 9 on Linux




// --- 1. App Service Plan (Equivalent to 'az appservice plan create') ---
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName // e.g., 'B1'
  }
  kind: 'linux' // Assuming dotnet:9 means a Linux container for modern .NET
  properties: {
    reserved: true // Required for Linux plans
  }
}







// Repeating data to configure the micro services
var microservices = [
  {
    name: 'MicroGateway'
    port: 8080
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroAccount'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroAgent'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroAsset'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroCustomer'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroFines'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroTenant'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
]






// --- 2. Web App Iteration (Equivalent to 'az webapp create') ---
resource webApps 'Microsoft.Web/sites@2022-09-01' = [for service in microservices: { // <--- The 'for' Loop
  name: service.name // Unique name from the array object
  location: location
  
  properties: {
    serverFarmId: appServicePlan.id // Reference the shared plan ID
    
    siteConfig: {
      linuxFxVersion: dotnetVersion
      minTlsVersion: '1.2'
      // Example of custom app settings from the array object
      appSettings: [
        {
          name: 'CUSTOM_PORT'
          value: string(service.port)
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: service.settings.ASPNETCORE_ENVIRONMENT
        }
      ]
    }
    httpsOnly: true
  }
  
  // NOTE: Bicep automatically handles the dependency on appServicePlan 
  // because you reference its property (appServicePlan.id).
  // The 'dependsOn' is usually unnecessary here and can be removed (as per the linter warning you saw earlier).
}]









// output webAppUrl string = webApp1.properties.defaultHostName