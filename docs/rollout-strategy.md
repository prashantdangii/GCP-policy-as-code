# Rollout strategy

## Levels

1. **Advisory.** The run prints the violation and succeeds. Use this while the blast radius is unknown. CMEK and large machine types start here.
2. **Soft-mandatory.** The run fails unless an operator overrides with a reason. Labels are here in Sentinel. The override has an owner and an expiry.
3. **Hard-mandatory.** The run fails. No override in the policy engine. A change to the policy is the only way through. Public buckets, open admin ports, public VMs, primitive roles, and service-account keys are here.

Conftest has no soft-mandatory. The Rego label policy denies, so the offline demo fails closed. If a large estate cannot meet labels in one change, move that Rego rule to `warn` and pass `--fail-on-warn` only on the production policy set. Say so in the pull request.

## Promotion

Promote one level when all of these are true for two weeks:

- Violation rate on new plans is under 5% of changed resources.
- Open exceptions are under 10, and none are past `expires`.
- The failing message names the resource and the fix. If operators need a human to interpret it, the policy is not ready.
- A test covers the pass, the fail, and a delete or no-op.

Demote one level if a false positive blocks a production fix. Add the fixture that caused it before promoting again.

## Exceptions

`landing-zone/00-org-policies` takes `var.exceptions`: constraint, parent, reason, and `expires` (`YYYY-MM-DD`). The API does not expire the override for you. A calendar reminder or the drift report has to. Empty `reason` does not validate.

Sentinel soft-mandatory overrides happen in the Terraform run UI when HCP Terraform is in use. Until then, an exception is a reviewed code change plus a catalog note. Hard-mandatory policies do not take an exception flag in the modules except the explicit `allow_public_access` / `allow_open_admin_ports` booleans, which also require a non-empty justification and still fail the hard Sentinel policy. The module escape hatch is for a lab. The policy is the control.

## Versions

Tag the policy set with semver (`policies-v1.2.0`). The changelog entry names the control id, the level, and whether existing stacks will fail. Staging uses the next tag. Production stays on the current tag until the promotion numbers above hold. Git branches are not a second source of truth. The tag is.

## 500 projects and 50 teams

- One org policy at the organization. Folder exceptions for the few teams that have a dated reason.
- Policy sets, not copy-pasted policies. A team workspace includes the production set.
- CI on every repo runs the same Conftest bundle, pinned by tag.
- Drift runs weekly per folder, not as one unbounded `search_all_resources` for the whole org. Cloud Asset Inventory queries cost money and time. Start with `folders/ID` for the noisiest folder.
- Owners in `CODEOWNERS` and in the catalog. A finding without an owner does not get fixed.

## Metrics

| Metric | Meaning |
|---|---|
| Coverage | Catalog rows whose mechanism is actually enforced, divided by rows |
| Violation trend | New findings per week, by control id |
| MTTR | Time from drift finding or failed plan to a merging fix |
| Exception count and age | Open exceptions, and how many are past `expires` |
