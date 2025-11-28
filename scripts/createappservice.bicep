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
	  KeystoneDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneDBConnection)'
	  MaintenanceDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/MaintenanceDBConnection)'
	  KeystoneHasherKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneHasherKey/aa2d250dc55c461fa65f062ef859d90a)'
	  OpenAIKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/OpenAIKey)'
    }
  }
  {
    name: 'MicroAccount'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
	  KeystoneDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneDBConnection)'
	  MaintenanceDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/MaintenanceDBConnection)'
	  KeystoneHasherKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneHasherKey/aa2d250dc55c461fa65f062ef859d90a)'
	  OpenAIKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/OpenAIKey)'
    }
  }
  {
    name: 'MicroAgent'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
	  KeystoneDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneDBConnection)'
	  MaintenanceDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/MaintenanceDBConnection)'
	  KeystoneHasherKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneHasherKey/aa2d250dc55c461fa65f062ef859d90a)'
	  OpenAIKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/OpenAIKey)'
    }
  }
  {
    name: 'MicroAsset'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
	  KeystoneDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneDBConnection)'
	  MaintenanceDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/MaintenanceDBConnection)'
	  KeystoneHasherKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneHasherKey/aa2d250dc55c461fa65f062ef859d90a)'
	  OpenAIKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/OpenAIKey)'
    }
  }
  {
    name: 'MicroCustomer'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
	  KeystoneDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneDBConnection)'
	  MaintenanceDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/MaintenanceDBConnection)'
	  KeystoneHasherKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneHasherKey/aa2d250dc55c461fa65f062ef859d90a)'
	  OpenAIKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/OpenAIKey)'
    }
  }
  {
    name: 'MicroFines'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
	  KeystoneDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneDBConnection)'
	  MaintenanceDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/MaintenanceDBConnection)'
	  KeystoneHasherKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneHasherKey/aa2d250dc55c461fa65f062ef859d90a)'
	  OpenAIKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/OpenAIKey)'
    }
  }
  {
    name: 'MicroTenant'
    port: 8081
    settings: {
      ASPNETCORE_ENVIRONMENT: 'Staging'
	  KeystoneDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneDBConnection)'
	  MaintenanceDBConnection: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/MaintenanceDBConnection)'
	  KeystoneHasherKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneHasherKey/aa2d250dc55c461fa65f062ef859d90a)'
	  OpenAIKey: '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/OpenAIKey)'
    }
  }
]








// --- 2. Web App Iteration (Equivalent to 'az webapp create') ---
resource webApps 'Microsoft.Web/sites@2022-09-01' = [for service in microservices: {
  name: service.name 
  location: location
  
  properties: {
    serverFarmId: appServicePlan.id
    
    siteConfig: {
      linuxFxVersion: dotnetVersion
      minTlsVersion: '1.2'


      appSettings: [
        {
          name: 'KeystoneDBConnection'
          value: string(service.settings.KeystoneDBConnection)
        }
        {
          name: 'MaintenanceDBConnection'
          value: string(service.settings.MaintenanceDBConnection)
        }		
        {
          name: 'KeystoneHasherKey'
          value: string(service.settings.KeystoneHasherKey)
        }
        {
          name: 'OpenAIKey'
          value: string(service.settings.OpenAIKey)
        }		
      ]
    }
    httpsOnly: true
  }
  
}]









// output webAppUrl string = webApp1.properties.defaultHostName