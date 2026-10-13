# Sentinel tests

One directory per policy: `pass.hcl`, `fail.hcl`, and edge cases. Each file imports `common/functions.sentinel` and mocks `tfplan/v2`. `sentinel test` does not read `sentinel.hcl`.
