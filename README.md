# terraform-kubernetes-nfs-volume

A small Terraform module that creates an NFS-backed PersistentVolume and a
matching PersistentVolumeClaim in Kubernetes, bound to each other.

Static NFS volumes are simple, but setting them up by hand for every service
is slow and easy to get wrong: a capacity typo, a claim that binds to the wrong
volume, or a reclaim policy that deletes data. This module makes the setup one
reviewed block of code with the mistakes caught at plan time.

## Usage

```hcl
module "app_data" {
  source = "github.com/<your-username>/terraform-kubernetes-nfs-volume"

  name       = "app-data"
  namespace  = "team-a"
  nfs_server = "nfs.example.internal"
  nfs_path   = "/exports/app-data"
  capacity   = "20Gi"
}
```

Then mount the claim from a pod:

```hcl
volume {
  name = "data"
  persistent_volume_claim {
    claim_name = module.app_data.persistent_volume_claim_name
  }
}
```

A runnable example is in [`examples/basic`](examples/basic).

## Design choices

- **The volume is reserved for its claim.** The PersistentVolume sets
  `claim_ref`, and the claim sets `volume_name`. Without both, another claim
  with the same storage class could bind to the volume first.
- **`Retain` is the default reclaim policy.** Deleting a claim should not
  delete data on a shared NFS export. `Delete` has to be chosen on purpose.
- **Volume names include the namespace.** PersistentVolumes are cluster-wide,
  so two teams using the name `app-data` would collide. The volume is named
  `<namespace>-<name>`.
- **Bad input fails at plan time.** Variables are validated (absolute NFS path,
  a real Kubernetes quantity, known access modes, a valid DNS label), so errors
  appear in review and not half-way through an apply.
- **`hard` NFS mounts by default.** A soft mount can return errors to the
  application during a short NFS outage and corrupt writes. Override
  `mount_options` if your workload prefers to fail fast.

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `name` | Name of the claim. The volume is named `<namespace>-<name>`. | `string` | required |
| `nfs_server` | Hostname or IP address of the NFS server. | `string` | required |
| `nfs_path` | Absolute path of the export. | `string` | required |
| `namespace` | Namespace for the claim. Must already exist. | `string` | `"default"` |
| `capacity` | Size as a Kubernetes quantity. | `string` | `"10Gi"` |
| `access_modes` | Access modes for the volume and claim. | `list(string)` | `["ReadWriteMany"]` |
| `reclaim_policy` | `Retain` or `Delete`. | `string` | `"Retain"` |
| `storage_class_name` | Storage class set on both objects. | `string` | `"nfs-static"` |
| `mount_options` | NFS mount options. | `list(string)` | `["nfsvers=4.1", "hard"]` |
| `read_only` | Mount the export read-only. | `bool` | `false` |
| `labels` | Extra labels for both objects. | `map(string)` | `{}` |
| `wait_until_bound` | Wait for the claim to bind before apply finishes. | `bool` | `true` |

## Outputs

| Name | Description |
|---|---|
| `persistent_volume_name` | Name of the PersistentVolume. |
| `persistent_volume_claim_name` | Name of the claim, for use in a pod's `volumes` block. |
| `namespace` | Namespace of the claim. |
| `capacity` | Requested capacity. |

## Testing

Tests use Terraform's built-in test framework with a mocked Kubernetes
provider, so they need no cluster:

```sh
terraform init -backend=false
terraform test
```

- `tests/defaults.tftest.hcl` checks naming, the claim reservation, the default
  reclaim policy, capacity and labels.
- `tests/validation.tftest.hcl` checks that bad input is rejected.

The GitHub Actions workflow runs format, validate and test on every push and
pull request, with providers cached between runs.

## Requirements

- Terraform 1.7 or later (the tests use provider mocking)
- `hashicorp/kubernetes` provider 2.25 or later
- An NFS server reachable from the cluster nodes, with NFS client packages
  installed on the nodes

## Limitations

- NFS does not enforce `capacity`; it is used for binding only. Quotas must be
  set on the NFS server.
- Kubernetes does not delete data on NFS volumes automatically. With `Retain`,
  clean up the export yourself when a volume is retired.
