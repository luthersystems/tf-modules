# k8s-version-compare

Pure helper (no providers, no resources): reports whether `desired` is a
lower Kubernetes `MAJOR.MINOR` than `current`. Patch/suffix parts are
ignored, and minors compare numerically (`1.9 < 1.10`).

Used by `eks-vpc` to refuse accidental EKS version rollbacks (EKS supports
`VersionRollback`, so lowering `version` in Terraform really rolls a live
cluster back). `current = ""` means "no cluster yet" and never counts as a
downgrade.

| Input | Description |
|---|---|
| `current` | Live version, or `""` |
| `desired` | Requested version |

| Output | Description |
|---|---|
| `is_downgrade` | `true` when desired < current |

Tests: `terraform init -backend=false && terraform test` (Terraform >= 1.6).
