resource "databricks_group" "mlops-service-principal-group-staging" {
  display_name = "mlops-poc-service-principals"
  provider     = databricks.staging
}

resource "databricks_group" "mlops-service-principal-group-prod" {
  display_name = "mlops-poc-service-principals"
  provider     = databricks.prod
}

module "azure_create_sp" {
  depends_on = [databricks_group.mlops-service-principal-group-staging, databricks_group.mlops-service-principal-group-prod]
  source     = "databricks/mlops-azure-project-with-sp-creation/databricks"
  providers = {
    databricks.staging = databricks.staging
    databricks.prod    = databricks.prod
    azuread            = azuread
  }
  service_principal_name       = "mlops-poc-cicd"
  project_directory_path       = "/mlops-poc"
  azure_tenant_id              = var.azure_tenant_id
  service_principal_group_name = "mlops-poc-service-principals"
}

data "databricks_current_user" "staging_user" {
  provider = databricks.staging
}

provider "databricks" {
  alias = "staging_sp"
  host  = "https://adb-1778171230779412.12.azuredatabricks.net"
  token = module.azure_create_sp.staging_service_principal_aad_token
}

provider "databricks" {
  alias = "prod_sp"
  host  = "https://adb-8569209645075352.12.azuredatabricks.net"
  token = module.azure_create_sp.prod_service_principal_aad_token
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "staging_kv" {
  name                        = "staging-mlops-poc-kv"
  location                    = "East US"
  resource_group_name         = "mlopspoc"
  enabled_for_disk_encryption = true
  tenant_id                   = var.azure_tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = module.azure_create_sp.staging_service_principal_application_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set"
    ]

    storage_permissions = [
      "Get",
      "List",
      "Delete",
      "Update"
    ]
  }
}

resource "azurerm_key_vault_access_policy" "staging_create_user_policy" {
  key_vault_id = azurerm_key_vault.staging_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set"
  ]
}

resource "azurerm_key_vault" "prod_kv" {
  name                        = "prod-mlops-poc-kv"
  location                    = "East US"
  resource_group_name         = "mlopspoc"
  enabled_for_disk_encryption = true
  tenant_id                   = var.azure_tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = module.azure_create_sp.prod_service_principal_application_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set"
    ]

    storage_permissions = [
      "Get",
      "List",
      "Delete",
      "Update"
    ]
  }
}

resource "azurerm_key_vault_access_policy" "prod_create_user_policy" {
  key_vault_id = azurerm_key_vault.prod_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set"
  ]
}

# resource "databricks_secret_scope" "staging_cd_credentials" {
#   name = "staging-mlops-poc-cd-credentials"
# }

# resource "databricks_secret_scope" "prod_cd_credentials" {
#   name = "prod-mlops-poc-cd-credentials"
# }

# module "staging_workspace_cicd" {
#   source = "./common"
#   providers = {
#     databricks = databricks.staging_sp
#   }
#   git_provider      = var.git_provider
#   git_token         = var.git_token
#   env               = "staging"
#   github_repo_url   = var.github_repo_url
#   github_server_url = var.github_server_url
# }

# module "prod_workspace_cicd" {
#   source = "./common"
#   providers = {
#     databricks = databricks.prod_sp
#   }
#   git_provider    = var.git_provider
#   git_token       = var.git_token
#   env             = "prod"
#   github_repo_url = var.github_repo_url
# }



// We produce the service princpal's application ID, client secret, and tenant ID as output, to enable
// extracting their values and storing them as secrets in your CI system
//
// If using GitHub Actions, you can create new repo secrets through Terraform as well
// e.g. using https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret

output "stagingAzureSpApplicationId" {
  value     = module.azure_create_sp.staging_service_principal_application_id
  sensitive = true
}

output "stagingAzureSpClientSecret" {
  value     = module.azure_create_sp.staging_service_principal_client_secret
  sensitive = true
}

output "stagingAzureSpTenantId" {
  value     = var.azure_tenant_id
  sensitive = true
}

output "prodAzureSpApplicationId" {
  value     = module.azure_create_sp.prod_service_principal_application_id
  sensitive = true
}

output "prodAzureSpClientSecret" {
  value     = module.azure_create_sp.prod_service_principal_client_secret
  sensitive = true
}

output "prodAzureSpTenantId" {
  value     = var.azure_tenant_id
  sensitive = true
}

output "staging_kv_url" {
  value = azurerm_key_vault.staging_kv.vault_uri
}

output "prod_kv_url" {
  value = azurerm_key_vault.prod_kv.vault_uri
}
