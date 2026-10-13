# Troubleshooting a blocked deployment

Use this when someone says the pipeline rejected a change they believe is legitimate.

## Steps

1. Get the plan JSON. Locally, `terraform show -json tfplan > tfplan.json`. In CI, download the `tfplan` artifact. Do not paste the file into chat if it contains names you would not put in a ticket. The examples in this repo are safe fixtures.
2. Re-run the same gates: `conftest test tfplan.json -p policies/opa` and `python -m plan_checker.cli tfplan.json --format text --fail-on none`.
3. Read the control id and the resource address. `GCS-001 google_storage_bucket.public` is a bucket problem, not a general Terraform failure.
4. Open `policies/sentinel/sentinel.hcl` or the Rego header and note the enforcement level.
5. Decide.
   - **Fix.** The message says what to change. Prefer the golden module.
   - **Exception.** Only if the level is soft or advisory, or the catalog says an org-policy override is allowed. Write the reason and the expiry. Hard-mandatory exposure controls do not get an exception in this repo.
6. Add a failing fixture that matches the blocked plan, and a passing fixture for the fix. `sentinel test` or `opa test` must cover it.
7. Reply on the pull request with the control id, the level, and either the fix or the exception. Link the catalog row.

## Worked example

`examples/non-compliant/open_ssh.tf` is the demo pull request. The plan fixture allows tcp/22 from `0.0.0.0/0`.

Conftest reports:

```text
FW-001 google_compute_firewall.ssh_world: ingress allow of admin ports from 0.0.0.0/0 or ::/0
```

`plan_checker` reports the same id at severity high. Sentinel `no-open-admin-ports` is hard-mandatory. The fix is the IAP rule in `examples/compliant`: source `35.235.240.0/20`, target tag `iap-ssh`, description required. There is no exception. A justification variable on the module does not bypass the policy.

`make policy-demo` reproduces this without credentials. The compliant fixture prints no findings. The non-compliant fixture must include FW-001 and the other ids listed in `tools/policy_demo.py`.
