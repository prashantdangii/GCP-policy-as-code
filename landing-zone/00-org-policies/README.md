# 00-org-policies

Organization Policy constraints for the landing zone. Scope is `organization`, `folder`, or `project`, so a lab without Cloud Identity can still attach the same constraints to one project. See `docs/adr/0004-org-vs-project-scope.md`.

## Constraints

| Constraint | Behavior |
| --- | --- |
| `iam.disableServiceAccountKeyCreation` | No new SA keys |
| `iam.disableServiceAccountKeyUpload` | No imported keys |
| `iam.automaticIamGrantsForDefaultServiceAccounts` | Default SAs do not get Editor |
| `compute.vmExternalIpAccess` | Deny all external IPs |
| `compute.requireOsLogin` | IAM-based SSH |
| `compute.skipDefaultNetworkCreation` | No default VPC |
| `compute.disableSerialPortAccess` | No serial console |
| `compute.requireShieldedVm` | Shielded VM required |
| `storage.uniformBucketLevelAccess` | No object ACLs |
| `storage.publicAccessPrevention` | No public buckets |
| `sql.restrictPublicIp` | No public Cloud SQL |
| `gcp.resourceLocations` | Allow list, default `in:eu-locations` and `in:us-locations` |

## Exceptions

`var.exceptions` maps a constraint to child folders or projects. Every entry needs `reason` and `expires` (`YYYY-MM-DD`). Validation rejects an empty reason. The API does not auto-expire the waiver; the expiry is a review obligation tracked in `docs/rollout-strategy.md`.

List exceptions that omit `allowed_values` set `allow_all = TRUE`, which fully relaxes that list constraint on the child. Prefer a narrow `allowed_values` list.

## Apply

```bash
terraform init -backend=false   # or -backend-config="bucket=PROJECT_PREFIX-tfstate"
terraform plan
```
