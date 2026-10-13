# ADR 0005: Detective findings become preventive controls

- Status: Accepted
- Date: 2026-10-13

## Context

A scanner that files the same ticket forever is a report. A CNAPP-style loop turns a repeated runtime finding into a plan-time deny, then an org policy when the platform can express it.

## Decision

Every drift finding carries a catalog id and `preventive_exists`. When no Sentinel, OPA, or org-policy control covers that id, the report marks `preventive_gap`.

Worked example, closed:

1. The drift scanner sees `iam.googleapis.com/ServiceAccountKey` with `keyType` `USER_MANAGED`.
2. That is catalog IAM-003. The first version of the catalog had no plan-time deny for it.
3. The preventive set is now `iam.disableServiceAccountKeyCreation` and `iam.disableServiceAccountKeyUpload` (ORG-001, ORG-002), Sentinel `no-sa-keys` at hard-mandatory, and plan_checker rule IAM-003.
4. The drift rule still reports live keys, because org policy does not delete a key that already exists. The finding's `preventive_exists` is true, so it is residual risk, not a gap.

Worked example, still open:

Subnet flow logs off is NET-002. The network stack turns flow logs on for its own subnets. There is no Sentinel or OPA rule for `google_compute_subnetwork.log_config`. The drift report flags that as a preventive gap. The next policy to write is a soft-mandatory "flow logs enabled" check. It is not hard-mandatory yet because sampling rate is a cost dial (`docs/finops.md`).

## Alternatives considered

- Generate Rego from the scanner. Attractive, and easy to emit a rule that false-positives on every asset type the scanner only half understands. A human writes the policy and the test.
- Delete the detective control once the org policy exists. Rejected. Live keys and click-ops changes remain until someone removes them.

## Consequences

- Security: new runtime classes become backlog items with an owner, not an unread JSON file.
- Cost: the weekly workflow calls Cloud Asset Inventory only when `DRIFT_SCOPE` and WIF are set.
- Operability: tests use `tools/drift_scanner/tests/fixtures`. They do not call Google.
