# 20-network

Custom-mode Shared VPC in the network hub.

## Baseline

- Private Google Access on every subnet.
- VPC Flow Logs on. `flow_log_sampling` defaults to `0.5` so a lab is not billed for a full packet sample. Raise it when you are investigating an incident.
- Network firewall policy: deny all ingress.
- IAP range `35.235.240.0/20` may reach tcp/22 and tcp/3389 on instances tagged `iap-ssh`. That rule is the `firewall-rule` module.
- Health-check ranges may reach tcp/80 and tcp/443 on `lb-backend`.
- Cloud NAT logs errors. NAT does not by itself authorize internet egress.

## Egress tradeoff

`restrict_egress` defaults to true. The policy allows RFC1918 and `199.36.153.8/30` (private.googleapis.com) and denies everything else. VMs can call Google APIs and talk east-west. They cannot pull arbitrary packages from the internet.

Set `restrict_egress = false` only when a workload needs general internet egress, and pair it with Cloud NAT. Document the reason. A narrower allow (for example a proxy range) is better than turning the deny off.

## Private Google Access DNS

When `enable_private_dns` is true, a private zone resolves `*.googleapis.com` to `199.36.153.8/30`. That keeps API calls on the private VIP even if a client ignores `private.googleapis.com`. Restricted VIP (`199.36.153.4/30`) is the VPC Service Controls variant; use it when the perimeter in `70-vpc-sc` is enforced.

Firewall rules and VPC Service Controls are different controls. Firewall rules filter packets. VPC-SC filters API calls by identity and project, including calls that never traverse this VPC.
