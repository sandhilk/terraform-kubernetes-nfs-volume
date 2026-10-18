terraform {
  required_version = ">= 1.7.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "app_data" {
  source = "../.."

  name       = "app-data"
  namespace  = "default"
  nfs_server = "nfs.example.internal"
  nfs_path   = "/exports/app-data"
  capacity   = "20Gi"

  labels = {
    team = "platform"
  }
}

output "claim_name" {
  value = module.app_data.persistent_volume_claim_name
}
