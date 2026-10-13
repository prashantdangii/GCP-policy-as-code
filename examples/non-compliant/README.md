# Non-compliant example

Each file is one intentional violation. Comments name the policy that should fail.

| File | Control |
|---|---|
| `public_bucket.tf` | GCS-001 uniform access and public access prevention |
| `open_ssh.tf` | FW-001 SSH from `0.0.0.0/0` |
| `missing_labels.tf` | LBL-001 owner, env, cost-center |
| `public_vm.tf` | VM-001 external IP and VM-002 default Compute service account |
| `editor_binding.tf` | IAM-001 `roles/editor` |
| `bucket_no_cmek.tf` | CMEK-001 advisory missing KMS key |

`plan.json` is the offline plan fixture. `make policy-demo` asserts this exact set. Static scanners skip this directory because the violations are deliberate.
