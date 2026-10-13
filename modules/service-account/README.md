# service-account

Creates a service account and, optionally, one Workload Identity Federation binding.

This module never creates `google_service_account_key`. Long-lived keys are blocked again by the org policy `iam.disableServiceAccountKeyCreation` and by the `no-sa-keys` plan rule. Pass `wif_member` when a GitHub principal or another workload identity should impersonate the account.

`description` is required.
