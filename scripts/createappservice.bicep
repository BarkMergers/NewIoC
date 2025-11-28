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



param KeystoneDBConnection string = '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneDBConnection)'
param MaintenanceDBConnection string = '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/MaintenanceDBConnection)'
param KeystoneHasherKey string = '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/KeystoneHasherKey/aa2d250dc55c461fa65f062ef859d90a)'
param OpenAIKey string = '@Microsoft.KeyVault(SecretUri=https://microkeyvault2.vault.azure.net/secrets/OpenAIKey)'



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








// Use a different API version for the Key Vault that supports defining accessPolicies as an array
// The newer API version forces the use of 'add', 'remove', or 'replace' actions.
resource existingKeyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

// ----------------------------------------------------------------------------------------
// --- FIX: Create an array variable containing all access policies from the 'for' loop ---
// ----------------------------------------------------------------------------------------
var newAccessPolicies = [for (service, i) in microservices: {
  tenantId: subscription().tenantId
  objectId: webApps[i].identity.principalId // Use the principal ID of the Web App
  permissions: {
    secrets: [
      'get' // Only need 'get' to read secrets referenced in app settings
    ]
  }
}]

// ----------------------------------------------------------------------------------------
// --- FIX: Reference the Key Vault and use a symbolic name for the access policy resource ---
// ----------------------------------------------------------------------------------------
// You are now modifying the Key Vault resource itself, not creating a separate one.
resource keyVaultPolicyUpdate 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: existingKeyVault.location
  properties: {
    // Retain existing properties, if any (this is crucial for Key Vault updates!)
    sku: {
      family: existingKeyVault.properties.sku.family
      name: existingKeyVault.properties.sku.name
    }
    tenantId: existingKeyVault.properties.tenantId
    
    // Add the new policies to the existing policies
    accessPolicies: concat(existingKeyVault.properties.accessPolicies, newAccessPolicies)
  }
}





// output webAppUrl string = webApp1.properties.defaultHostName