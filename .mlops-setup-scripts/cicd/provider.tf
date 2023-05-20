terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.16.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.15.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.1"
    }
  }
  // The `backend` block below configures the azurerm backend
  // (docs:
  // https://www.terraform.io/language/settings/backends/azurerm and
  // https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage)
  // for storing Terraform state in Azure Blob Storage. The targeted Azure Blob Storage bucket is
  // provisioned by the Terraform config under .mlops-setup-scripts/terraform:
  //
  backend "azurerm" {
    resource_group_name  = "mlopspoc"
    storage_account_name = "mlopspoc5sm4v" ## Change this based on the terraform/main-azure.tf result
    container_name       = "cicd-setup-tfstate"
    key                  = "cicd-setup.terraform.tfstate"
  }

}

provider "databricks" {
  alias   = "staging"
  profile = var.staging_profile
}

provider "databricks" {
  alias   = "prod"
  profile = var.prod_profile
}

provider "azurerm" {
  features {}
}

provider "azuread" {}
