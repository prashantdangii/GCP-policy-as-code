# Sentinel policies

`sentinel test` is the local proof. HCP Terraform is what enforces `sentinel.hcl` on a real plan. This repo does not require HCP Terraform. CI uses the same controls in Rego via Conftest, which is free.

## Layout

- `sentinel.hcl` is the HCP policy set. It uses `module` and `policy` blocks.
- `sentinel test` ignores that file. Each file under `test/<policy>/` imports `common` with `import "module"`.
- Mocks live in `testdata/` and use Sentinel map syntax (`key: value`).

## Run

```bash
cd policies/sentinel && sentinel test -verbose
```

Violation messages print when `main` fails. A saved run is `docs/sentinel-test-output.txt`.
