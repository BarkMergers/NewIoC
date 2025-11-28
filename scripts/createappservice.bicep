param webAppName string = 'MicroGateway3'
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




// --- 2. Web App (Equivalent to 'az webapp create') ---
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  // Link the Web App to the App Service Plan using the ID reference
  properties: {
    serverFarmId: appServicePlan.id
    // Set the runtime stack for the web app (e.g., DOTNET|9.0 on Linux)
    siteConfig: {
      linuxFxVersion: dotnetVersion
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
  dependsOn: [ // Explicit dependency ensures the plan exists before the app is created
    appServicePlan
  ]
}




output webAppUrl string = webApp.properties.defaultHostName