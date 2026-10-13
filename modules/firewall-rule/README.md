# firewall-rule

Secure-by-default VPC firewall rule.

## Defaults

- Logging is always on (`INCLUDE_ALL_METADATA`).
- `description` and `priority` are required.
- `target_tags` or `target_service_accounts` is required so a rule cannot accidentally apply to every VM.
- Ingress allow of tcp/22, tcp/3389, every TCP port, or protocol `all` from `0.0.0.0/0` or `::/0` is rejected.

## Override

Set `allow_open_admin_ports = true` and a non-empty `justification`. The Sentinel policy `no-open-admin-ports` still blocks the plan in CI. The module check is the paved road; the policy is the gate.

## Example

See `examples/basic`.
