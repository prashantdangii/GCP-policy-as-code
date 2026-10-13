# ADR 0003: Workload Identity Federation instead of service-account keys

- Status: Accepted
- Date: 2026-10-13

## Context

A JSON key for `sa-terraform-ci` would be a long-lived credential in GitHub Actions. The same repo forbids service-account keys with an org policy and a Sentinel rule. CI cannot be the exception that the policies exist to stop.

## Decision

`landing-zone/bootstrap` creates a workload identity pool and provider for `https://token.actions.githubusercontent.com`. The attribute condition is `assertion.repository == "GITHUB_ORG/REPO"`. The CI service account grants `roles/iam.workloadIdentityUser` to the `principalSet` for that repository. No key resource exists.

The condition is repository-scoped, not ref-scoped. Pull-request plans from this repository present a different `ref` than `refs/heads/main`. Pinning `assertion.sub` to `repo:ORG/REPO:ref:refs/heads/main` would make those plans fail. Forks fail the repository condition because `assertion.repository` is the fork. Apply is a separate control: the `production` GitHub Environment requires reviewers. Checkov CKV_GCP_125 wants a `sub` equality that real tokens do not match; the skip comment on the provider records that.

## Alternatives considered

- A downloaded JSON key in `GCP_SA_KEY`. Rejected. It contradicts ORG-001 and IAM-003, and a leaked key is reusable outside GitHub.
- `assertion.ref == "refs/heads/main"` only. Rejected for pull-request plans. A second provider bound to `main` would split plan and apply identities. The environment reviewers already gate apply, which is the dangerous operation.
- HCP Terraform dynamic credentials. Viable later. This repo's CI uses GitHub-hosted runners and the google-github-actions auth action.

## Consequences

- Security: a stolen GitHub Actions run can impersonate the CI account only for the length of the OIDC token, and only from this repository.
- Cost: none beyond the IAM API.
- Operability: the human sets `WIF_PROVIDER` and `WIF_SERVICE_ACCOUNT` after the first bootstrap apply. Until those variables exist, the plan job skips and the offline demo still runs.
