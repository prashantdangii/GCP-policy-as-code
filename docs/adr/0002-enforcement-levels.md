# ADR 0002: Enforcement levels

- Status: Accepted
- Date: 2026-10-13

## Context

A hard-mandatory policy on day one blocks every existing deviation, including ones a team cannot fix in the same pull request. An advisory policy that never gets promoted teaches people to ignore the tool.

## Decision

| Policy | Level | Why |
|---|---|---|
| `gcs-bucket-secure` | hard-mandatory | A public or ACL-based bucket is a data-exposure incident. |
| `no-open-admin-ports` | hard-mandatory | SSH or RDP from the internet is a direct admin path. |
| `no-external-ip-no-default-sa` | hard-mandatory | Public VMs and the default Compute service account are a known breach path. |
| `no-primitive-roles` | hard-mandatory | `roles/owner` and `roles/editor` bypass every finer control. |
| `no-sa-keys` | hard-mandatory | Added after the drift scanner treated user-managed keys as a finding. Long-lived keys outlive the person who created them. |
| `required-labels` | soft-mandatory | Cost allocation needs the labels, and a justified override must stay possible. |
| `cmek-required` | advisory | CMEK has a key-before-bucket bootstrap cycle and a per-request cost. Promote after keys exist. |
| `large-machine-advisory` | advisory | A large machine is a cost signal, not a security defect. |
| `vertex-non-default-sa` | advisory | The AI stack is off by default. The rule is ready when that stack is enabled. |

Conftest denies the three Rego policies, including labels, so the offline demo fails closed. Sentinel still records labels as soft-mandatory. That difference is intentional and written down in `policies/opa/labels.rego` and `docs/rollout-strategy.md`.

## Alternatives considered

- Make CMEK hard-mandatory now. The first apply cannot create a bucket that references a key the same configuration has not created yet, and Checkov-style "always CMEK" fights the bootstrap stack.
- Make labels advisory. Teams then ship untagged projects and the billing export cannot group spend.

## Consequences

- Security: exposure and privilege controls block. Encryption and machine size warn.
- Cost: teams can still launch a large machine; FinOps sees the advisory and the budget alert.
- Operability: promotion criteria live in the rollout doc. Changing a level is a reviewed edit to `sentinel.hcl`.
