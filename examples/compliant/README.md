# Compliant example

Uses the golden modules: a dedicated service account, a rotated KMS key, a private bucket, a BigQuery dataset shared with a group, an IAP-only SSH rule, and a Shielded VM with no external IP.

`plan.json` is a committed `terraform show -json` fixture. `make policy-demo` evaluates it with Conftest and `plan_checker` and expects zero findings. Generating the fixture with `terraform plan` needs a real project; this copy is the offline stand-in and matches the resources in `main.tf`.
