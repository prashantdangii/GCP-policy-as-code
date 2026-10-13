# OPA policies

These are the CI gate. They read `terraform show -json` output (`input.resource_changes`).

```bash
opa test policies/opa -v
conftest verify -p policies/opa
conftest test examples/compliant/plan.json -p policies/opa
```

`deny` fails the gate. `warn` (CMEK and large machine types) does not, unless you pass `--fail-on-warn`.
