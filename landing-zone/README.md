# Landing zone

Independent Terraform roots. Apply from top to bottom. Each root has its own GCS backend prefix. Pass the bucket at init time:

```bash
terraform init -backend-config="bucket=PROJECT_PREFIX-tfstate"
```

| Order | Stack | Needs |
| --- | --- | --- |
| 1 | `bootstrap` | A project the human already created. First apply uses `-backend=false`. |
| 2 | `00-org-policies` | Organization, folder, or a single project. |
| 3 | `10-folders-projects` | Billing account, unless `scope_type = project`. |
| 4 | `20-network`, `30-logging`, `40-iam` | Project ids from step 3. |
| 5 | `50-monitoring`, `60-finops` | Logging project and billing account. |
| 6 | `70-vpc-sc` | Optional. Dry-run, off by default. |
| 7 | `80-ai-workload` | Optional. Off by default. |

Do not run `terraform apply` from CI until Workload Identity Federation variables exist and a reviewer has approved the `production` environment. The agent that built this repo did not apply it.

Project-only mode is documented in `docs/adr/0004-org-vs-project-scope.md`.
