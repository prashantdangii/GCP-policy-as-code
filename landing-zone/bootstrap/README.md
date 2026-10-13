# bootstrap

Creates the Terraform state bucket, the keyless CI service account, and a GitHub Workload Identity Federation pool.

## What you get

- State bucket: versioning, uniform access, public access prevention, access logs, lifecycle cap on old versions, `force_destroy = false`. CMEK is optional.
- `sa-terraform-ci` with no JSON keys.
- WIF provider for `https://token.actions.githubusercontent.com`, attribute mapping for `repository`, `ref`, and `actor`, and an attribute condition locked to `github_repository`.
- `roles/iam.workloadIdentityUser` bound with a `principalSet` for that repository only.

## First apply (human)

The state bucket cannot store its own state on the first apply.

1. `gcloud auth application-default login` against the bootstrap project.
2. `cp terraform.tfvars.example terraform.tfvars` and replace every placeholder.
3. `terraform init -backend=false`
4. `terraform apply`
5. Reconfigure the backend and migrate:

```bash
terraform init -migrate-state -backend-config="bucket=PROJECT_PREFIX-tfstate"
```

See `docs/runbook.md` and `docs/adr/0003-wif-over-sa-keys.md`.

## Steady state

```bash
terraform init -backend-config="bucket=PROJECT_PREFIX-tfstate"
terraform plan
```

Copy `workload_identity_provider` and `ci_service_account` into GitHub Actions variables `WIF_PROVIDER` and `WIF_SERVICE_ACCOUNT`. Do not create a service-account key.
