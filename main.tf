locals {
  pv_name = "${var.namespace}-${var.name}"

  labels = merge(
    {
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/managed-by" = "terraform"
    },
    var.labels,
  )
}

resource "kubernetes_persistent_volume_v1" "this" {
  metadata {
    name   = local.pv_name
    labels = local.labels
  }

  spec {
    capacity = {
      storage = var.capacity
    }

    access_modes                     = var.access_modes
    persistent_volume_reclaim_policy = var.reclaim_policy
    storage_class_name               = var.storage_class_name
    mount_options                    = var.mount_options

    # Reserve this volume for the claim created below, so no other claim
    # with the same storage class can bind to it first.
    claim_ref {
      name      = var.name
      namespace = var.namespace
    }

    persistent_volume_source {
      nfs {
        server    = var.nfs_server
        path      = var.nfs_path
        read_only = var.read_only
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    access_modes       = var.access_modes
    storage_class_name = var.storage_class_name
    volume_name        = kubernetes_persistent_volume_v1.this.metadata[0].name

    resources {
      requests = {
        storage = var.capacity
      }
    }
  }

  wait_until_bound = var.wait_until_bound
}
