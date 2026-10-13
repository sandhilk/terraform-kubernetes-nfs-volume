variable "name" {
  description = "Name of the PersistentVolumeClaim. The PersistentVolume is named <namespace>-<name> so it stays unique across the cluster."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name)) && length(var.name) <= 63
    error_message = "name must be a valid DNS-1123 label: lowercase letters, digits and hyphens, at most 63 characters."
  }
}

variable "namespace" {
  description = "Namespace the PersistentVolumeClaim is created in. The namespace must already exist."
  type        = string
  default     = "default"
}

variable "nfs_server" {
  description = "Hostname or IP address of the NFS server."
  type        = string

  validation {
    condition     = length(trimspace(var.nfs_server)) > 0
    error_message = "nfs_server must not be empty."
  }
}

variable "nfs_path" {
  description = "Absolute path of the export on the NFS server."
  type        = string

  validation {
    condition     = startswith(var.nfs_path, "/")
    error_message = "nfs_path must be an absolute path starting with '/'."
  }
}

variable "capacity" {
  description = "Size of the volume, as a Kubernetes quantity such as 10Gi."
  type        = string
  default     = "10Gi"

  validation {
    condition     = can(regex("^[1-9][0-9]*(Mi|Gi|Ti)$", var.capacity))
    error_message = "capacity must be a whole number followed by Mi, Gi or Ti, for example 10Gi."
  }
}

variable "access_modes" {
  description = "Access modes for the volume and the claim."
  type        = list(string)
  default     = ["ReadWriteMany"]

  validation {
    condition = length(var.access_modes) > 0 && alltrue([
      for mode in var.access_modes : contains(["ReadWriteOnce", "ReadOnlyMany", "ReadWriteMany"], mode)
    ])
    error_message = "access_modes must contain one or more of ReadWriteOnce, ReadOnlyMany, ReadWriteMany."
  }
}

variable "reclaim_policy" {
  description = "What happens to the PersistentVolume when the claim is deleted. Retain keeps the data."
  type        = string
  default     = "Retain"

  validation {
    condition     = contains(["Retain", "Delete"], var.reclaim_policy)
    error_message = "reclaim_policy must be Retain or Delete."
  }
}

variable "storage_class_name" {
  description = "Storage class name set on both the volume and the claim so they only bind to each other."
  type        = string
  default     = "nfs-static"
}

variable "mount_options" {
  description = "NFS mount options applied when the volume is mounted on a node."
  type        = list(string)
  default     = ["nfsvers=4.1", "hard"]
}

variable "read_only" {
  description = "Mount the NFS export read-only."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Extra labels added to the volume and the claim."
  type        = map(string)
  default     = {}
}

variable "wait_until_bound" {
  description = "Wait for the claim to reach the Bound phase before the apply finishes."
  type        = bool
  default     = true
}
