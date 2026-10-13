# Policy authoring guide

Add a control in this order. Skipping the catalog row is how two tools end up with different ids.

1. **Catalog.** Add a row to `docs/policy-catalog.md`. Answer the six questions in "How to assess whether a control can be automated". If the answer to the first question is no, stop and write the human process instead.
2. **Sentinel.** New file in `policies/sentinel`. Header comment: control id, intent, risk, CIS or NIST source, enforcement rationale, remediation, exception path. `main` prints the address even when it fails. Use `common/functions.sentinel`.
3. **Mock.** Add `testdata/mock-<name>.sentinel` with realistic `change.after` attributes. Tests live in `test/<policy>/{pass,fail,edge}.hcl` and import the common module themselves, because `sentinel test` does not load `sentinel.hcl`.
4. **Level.** Register the policy in `sentinel.hcl` and add a sentence to ADR 0002 if the level is not obvious.
5. **Rego.** If the control should block a GitHub pull request, add `policies/opa/<name>.rego` and `*_test.rego`. `package main`, `deny contains msg if`, message starts with the control id and the address.
6. **Plan checker.** Add a function in `tools/plan_checker/rules.py` returning `rule_id`, `severity`, `resource_address`, `message`, `remediation`. Unknown values become `UNVERIFIED` at low severity. Extend `tests/fixtures` or the unit tests. Coverage on `rules.py` stays at or above 90%.
7. **Drift.** If the bad state can exist outside Terraform, add a detection in `tools/drift_scanner/rules.py` with `preventive_exists` true once the plan rule lands. A missing plan rule sets `preventive_gap`.
8. **Examples.** One bad file under `examples/non-compliant` with a comment naming the policy, and a matching object in `plan.json`. Update `EXPECTED_BAD` in `tools/policy_demo.py`.
9. **CI.** The existing jobs pick up new files under `policies/` and `tools/`. Say so in the pull request template.
10. **Rollout.** Advisory first unless the control is data exposure or a public admin path. Record the promotion bar from `docs/rollout-strategy.md`.

Run:

```bash
cd policies/sentinel && sentinel test -verbose
opa test policies/opa -v
conftest verify -p policies/opa
cd tools && python -m pytest
make policy-demo
```
