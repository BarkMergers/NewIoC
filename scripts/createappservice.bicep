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



// param KeystoneDBConnection string = '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneDBConnection)'
// param MaintenanceDBConnection string = '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/MaintenanceDBConnection)'
// param KeystoneHasherKey string = '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneHasherKey/aa2d250dc55c461fa65f062ef859d90a)'
// param OpenAIKey string = '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/OpenAIKey)'



param KeystoneDBConnection string = 'Server=tcp:eriksondb.database.windows.net,1433;Initial Catalog=erikson-system-datbase;Persist Security Info=False;User ID=erikson;Password=MyStr0ngP@ssword!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
param MaintenanceDBConnection string = 'Server=tcp:eriksondb.database.windows.net,1433;Initial Catalog=erikson-system-datbase;Persist Security Info=False;User ID=erikson;Password=MyStr0ngP@ssword!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
param KeystoneHasherKey string = 'O5jmvvEQ7QET9RH6jjsW5/d7oL3Jbg3qFx4A6LvDsgg='
param OpenAIKey string = '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'





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
    name: 'MicroAccount3'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroAgent3'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroAsset3'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroCustomer3'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroFines3'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
  {
    name: 'MicroTenant3'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
    }
  }
]



///// Latest version of file




resource webApps 'Microsoft.Web/sites@2022-09-01' = [for service in microservices: {
  name: service.name 
  location: location
  identity: {
    type: 'SystemAssigned' // This creates and enables the Managed Identity
  }  
  properties: {
    serverFarmId: appServicePlan.id
    
    siteConfig: {
      linuxFxVersion: dotnetVersion
      minTlsVersion: '1.2'


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
      ]
    }
    httpsOnly: true
  }
}]







// output webAppUrl string = webApp1.properties.defaultHostName