# Plan-only tests. The Kubernetes provider is mocked, so no cluster is needed.
mock_provider "kubernetes" {}

variables {
  name       = "app-data"
  namespace  = "team-a"
  nfs_server = "nfs.example.internal"
  nfs_path   = "/exports/app-data"
}

run "defaults" {
  command = plan

  assert {
    condition     = kubernetes_persistent_volume_v1.this.metadata[0].name == "team-a-app-data"
    error_message = "The volume name should be <namespace>-<name>."
  }

  assert {
    condition     = kubernetes_persistent_volume_v1.this.spec[0].persistent_volume_reclaim_policy == "Retain"
    error_message = "The default reclaim policy should be Retain so data survives claim deletion."
  }

  assert {
    condition     = kubernetes_persistent_volume_v1.this.spec[0].claim_ref[0].name == "app-data"
    error_message = "The volume should be reserved for the claim created by this module."
  }

  assert {
    condition     = kubernetes_persistent_volume_claim_v1.this.spec[0].resources[0].requests["storage"] == "10Gi"
    error_message = "The claim should request the default capacity."
  }

  assert {
    condition     = kubernetes_persistent_volume_claim_v1.this.metadata[0].labels["app.kubernetes.io/managed-by"] == "terraform"
    error_message = "Standard labels should be applied."
  }
}

run "custom_capacity_and_labels" {
  command = plan

  variables {
    capacity = "250Gi"
    labels   = { team = "payments" }
  }

  assert {
    condition     = kubernetes_persistent_volume_v1.this.spec[0].capacity["storage"] == "250Gi"
    error_message = "The volume should use the requested capacity."
  }

  assert {
    condition     = kubernetes_persistent_volume_v1.this.metadata[0].labels["team"] == "payments"
    error_message = "Extra labels should be merged in."
  }
}
