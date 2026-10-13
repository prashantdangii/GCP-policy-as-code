# 40-iam

Group bindings, two custom roles, one IAM condition, and one deny policy. There is no `roles/owner` or `roles/editor` in this stack.

## Custom roles

`customSecurityViewer` can search assets, read logs, and list IAM configuration. It cannot change them.

`customDeployer` can create and delete compute and storage objects and can `iam.serviceAccounts.actAs`. It cannot create keys or set IAM policy. Comments in `main.tf` group those permissions.

Folder scope is accepted by `scope_type` for documentation parity, but custom roles in this stack are created at organization or project scope. Folder-level custom roles are not a Cloud IAM feature. Use organization scope, or project scope for a lab.

## Condition

The deployer group binding on `security_project_id` expires at `deployer_access_until` (`request.time < timestamp(...)`). Renew it by changing the variable after a review. This is an expiry, not a standing grant.

## Deny policy

`deny-sensitive-iam` denies `serviceAccountKeys.create` and `serviceAccounts.setIamPolicy` to `principalSet://goog/public:all`, with an exception for `break_glass_principal`.

## Break glass

Keep the break-glass group empty. Membership changes should page the security on-call. The deny exception is the only path that can create a key after the org policy and this deny are both in place. Prefer impersonation over a key even then. Remove the member when the incident ends.
