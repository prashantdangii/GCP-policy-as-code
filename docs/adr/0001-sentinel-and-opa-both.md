# ADR 0001: Run Sentinel and OPA together

- Status: Accepted
- Date: 2026-10-13

## Context

The hiring story for this repo needs Sentinel (imports, enforcement levels, mocks, tests) and a policy gate that runs on every pull request without a paid platform. Sentinel CLI can test policies locally. Sentinel does not enforce a plan unless the run happens inside HCP Terraform, which is a paid product for a team.

OPA and Conftest evaluate `terraform show -json` with no Terraform Cloud account. That is the check a fork can run.

## Decision

Keep both. Sentinel is the policy set with enforcement levels, shared functions, and mock tests. Conftest on `policies/opa` is the CI gate. Three controls exist in both languages: bucket exposure, open admin ports, and required labels. The other Sentinel policies are also implemented in `tools/plan_checker`, which reads the same plan JSON, so a missing HCP org does not drop those controls from CI.

## Alternatives considered

- Sentinel only, and document that enforcement waits for HCP Terraform. That leaves the public CI without a gate.
- OPA only. That drops the Sentinel interview surface (enforcement levels, `tfplan/v2`, mocks).
- Translate every Sentinel policy to Rego before calling the project done. The plan checker already covers the rest, and duplicating nine policies in two languages adds drift between them. New hard-mandatory controls should still get a Rego twin when they become CI gates. See `docs/policy-authoring-guide.md`.

## Consequences

- Security: the free gate is real. Sentinel enforcement levels are exercised in tests and recorded in `sentinel.hcl`, and they are not what blocks a GitHub pull request today.
- Cost: no HCP Terraform subscription.
- Operability: a control change can need a Sentinel test, a Rego test, and a plan-checker test. The authoring guide lists that sequence.
