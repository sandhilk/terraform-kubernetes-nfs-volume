output "persistent_volume_name" {
  description = "Name of the PersistentVolume."
  value       = kubernetes_persistent_volume_v1.this.metadata[0].name
}

output "persistent_volume_claim_name" {
  description = "Name of the PersistentVolumeClaim. Reference this from a pod's volumes block."
  value       = kubernetes_persistent_volume_claim_v1.this.metadata[0].name
}

output "namespace" {
  description = "Namespace of the PersistentVolumeClaim."
  value       = kubernetes_persistent_volume_claim_v1.this.metadata[0].namespace
}

output "capacity" {
  description = "Requested capacity of the volume."
  value       = var.capacity
}
