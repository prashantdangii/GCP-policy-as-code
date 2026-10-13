# Runbook

The agent that built this repo did not create a GCP organization, did not run `terraform apply`, and did not configure GitHub. Those steps are yours.

## Human-only setup

1. Create a Cloud Identity organization if you want folder and org-policy inheritance. A single project is enough to `validate` and to apply the bootstrap stack.
2. Create a billing account and a bootstrap project.
3. `gcloud auth application-default login` with a principal who can create buckets, service accounts, and workload identity pools in that project.
4. Copy each `terraform.tfvars.example` to `terraform.tfvars` (gitignored) and replace `ORG_ID`, `BILLING_ACCOUNT_ID`, `PROJECT_PREFIX`, and `GITHUB_ORG/REPO`.
5. Apply stacks in the order below.
6. After bootstrap, set GitHub variables: `WIF_PROVIDER`, `WIF_SERVICE_ACCOUNT`, `TF_STATE_BUCKET`, `TF_STACK`, `GCP_PROJECT_ID`, `DRIFT_SCOPE`.
7. Create the GitHub Environment `production` with required reviewers.
8. Turn on branch protection for `main`: pull request required, the `ci` workflow required, no force push. `CODEOWNERS` names `@GITHUB_ORG/security`. Create that team or edit the file before you require code owner review.
9. Optional: an HCP Terraform organization, if you want Sentinel to enforce inside a remote run. Conftest already gates GitHub.
10. Optional: record the screenshots listed in `docs/HANDOFF.md`.

## First bootstrap apply

State cannot live in the bucket the same apply creates. From `landing-zone/bootstrap`:

```bash
terraform init -backend=false -input=false
terraform plan -input=false -var-file=terraform.tfvars
terraform apply -input=false -var-file=terraform.tfvars
```

Then migrate:

```bash
terraform init -migrate-state -backend-config="bucket=PROJECT_PREFIX-tfstate"
```

Later stacks use the same bucket and the prefix already set in each `backend.tf`:

```bash
terraform init -backend-config="bucket=PROJECT_PREFIX-tfstate"
```

## Apply order

1. `landing-zone/bootstrap`
2. `landing-zone/00-org-policies`
3. `landing-zone/10-folders-projects`
4. `landing-zone/20-network`
5. `landing-zone/30-logging`
6. `landing-zone/40-iam`
7. `landing-zone/50-monitoring`
8. `landing-zone/60-finops`
9. `landing-zone/70-vpc-sc` only if `enable_vpc_sc` is true and an organization exists
10. `landing-zone/80-ai-workload` only if `enable_ai_workload` is true

`make` does not apply. The GitHub workflow `.github/workflows/apply.yml` applies one stack when the variables above are set and a reviewer approves the `production` environment. It re-plans, runs Conftest and `plan_checker`, then `terraform apply` on that saved plan.

## Teardown

Destroy in reverse order. VPC-SC and the AI stack first if you enabled them. Buckets with retention locks and KMS keys with `prevent_destroy` will stop the destroy. Unlock retention only if you accept the compliance consequence, and remove `prevent_destroy` in a reviewed change before destroying keys.

Org policies and the state bucket are last. Empty the state bucket by hand after the other stacks are gone, then destroy bootstrap with `-backend=false` or a local state copy. `force_destroy` is false on the state and archive buckets on purpose.

Project deletion is `PREVENT`. Change `deletion_policy` in a reviewed commit, apply, then delete. Folder `deletion_protection` is true for the same reason.

## Billing export

`landing-zone/60-finops` creates the budget and the Pub/Sub topic. The BigQuery billing export itself is created in the Cloud Billing console. Point `queries/bigquery/billing_by_label.sql` at that table.

## What was validated here

`terraform fmt`, `init -backend=false`, and `validate` for every stack and module example. `terraform test` on the six modules. Sentinel, OPA, Conftest, pytest, Checkov, Trivy, actionlint, and sqlfluff. No live GCP API was called.
