# Sentinel and OPA

Both tools answer "should this Terraform plan be applied?" They sit in different products, so a team usually standardizes on one and keeps the other only when there is a reason. This repo keeps both on purpose. ADR 0001.

| | Sentinel | OPA / Rego + Conftest |
|---|---|---|
| Style | Policy language with rules, `for` filters, and `print` | Rego. This repo uses `import rego.v1` and `deny contains msg if` |
| Plan input | `tfplan/v2` import inside a Terraform run or a mock | `terraform show -json` as `input` |
| Enforcement levels | `advisory`, `soft-mandatory`, `hard-mandatory` in `sentinel.hcl` | Conftest fails on `deny`. `warn` fails only with `--fail-on-warn` |
| Tests | `sentinel test` with mock modules | `opa test` and `conftest verify` |
| Where it runs here | Locally and in CI as tests. Native enforcement needs HCP Terraform | CI gate on every pull request, including forks |
| Ecosystem | HashiCorp Terraform runs | Kubernetes, Envoy, any JSON. Multi-cloud shops already have Rego |
| Learning curve | Small language, Terraform-specific imports | Rego unification takes longer and then covers more than Terraform |

## What I would pick

For a Terraform Enterprise or HCP Terraform shop, I would make Sentinel the gate. Enforcement levels, policy sets per workspace, and the run UI are the product those teams already pay for. I would still keep a few Rego tests if another team evaluates Kubernetes manifests in the same pipeline.

For a multi-cloud shop, or a GitHub-only Terraform pipeline, I would pick OPA. One language can sit on Terraform plans, Kubernetes, and pipeline config. Conftest needs no extra control plane. I would not buy HCP Terraform only to obtain Sentinel.

This repo is the second shape, with Sentinel retained so the enforcement-level and mock story is real code rather than a slide.
