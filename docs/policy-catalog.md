# Policy catalog

Owner for every row is the security team named in `CODEOWNERS`, unless the row says FinOps. Exception process: `docs/rollout-strategy.md`.

| ID | Control | Source | Type | Mechanism | Level | Automatable? | Exception |
|---|---|---|---|---|---|---|---|
| ORG-001 | No new service-account keys | CIS GCP IAM, NIST AC-2 | Preventive | Org policy `iam.disableServiceAccountKeyCreation` | Enforce | Yes. The API exposes a boolean constraint | Dated folder or project override with reason |
| ORG-002 | No uploaded service-account keys | CIS GCP IAM | Preventive | `iam.disableServiceAccountKeyUpload` | Enforce | Yes | Same as ORG-001 |
| ORG-003 | Default service accounts do not get Editor | CIS GCP IAM | Preventive | `iam.automaticIamGrantsForDefaultServiceAccounts` | Enforce | Yes | Same |
| ORG-004 | No VM external IPs | CIS GCP compute | Preventive | `compute.vmExternalIpAccess` deny all | Enforce | Yes. List constraint | List override with reason |
| ORG-005 | OS Login required | CIS GCP compute | Preventive | `compute.requireOsLogin` | Enforce | Yes | Dated override |
| ORG-006 | No default VPC | CIS GCP networking | Preventive | `compute.skipDefaultNetworkCreation` | Enforce | Yes | Dated override |
| ORG-007 | Serial port off | CIS GCP compute | Preventive | `compute.disableSerialPortAccess` | Enforce | Yes | Dated override |
| ORG-008 | Shielded VM required | CIS GCP compute | Preventive | `compute.requireShieldedVm` | Enforce | Yes | Dated override |
| ORG-009 | Uniform bucket access | CIS GCS, NIST AC-3 | Preventive | `storage.uniformBucketLevelAccess` | Enforce | Yes | Dated override |
| ORG-010 | Public access prevention | CIS GCS | Preventive | `storage.publicAccessPrevention` | Enforce | Yes | Dated override |
| ORG-011 | No public Cloud SQL | CIS Cloud SQL | Preventive | `sql.restrictPublicIp` | Enforce | Yes | Dated override |
| ORG-012 | Allowed resource locations | NIST SC-28 | Preventive | `gcp.resourceLocations` | Allow list | Yes | List override |
| GCS-001 | Uniform access and public access prevention on the plan | CIS GCS | Preventive | Sentinel hard, Rego deny, plan_checker high | Hard | Yes. Both attributes are in `change.after` | No. Fix the bucket |
| FW-001 | No world ingress to 22, 3389, or all | CIS networking, NIST SC-7 | Preventive | Sentinel hard, Rego deny, plan_checker high | Hard | Yes. Ports and ranges are on the plan | No |
| LBL-001 | `owner`, `env`, `cost-center` | FinOps | Preventive | Sentinel soft, Rego deny, plan_checker medium | Soft in Sentinel | Yes. Presence is visible. Correctness is not | Soft override with reason |
| VM-001 | No `access_config` | CIS compute | Preventive | Sentinel hard, plan_checker high | Hard | Yes | No |
| VM-002 | Non-default service account | CIS compute | Preventive | Sentinel hard, plan_checker high | Hard | Yes | No |
| IAM-001 | No `roles/owner` or `roles/editor` | CIS IAM, NIST AC-6 | Preventive | Sentinel hard, plan_checker high | Hard | Yes for those two roles | No |
| IAM-002 | No `allUsers` or `allAuthenticatedUsers` | CIS IAM | Preventive | Sentinel hard, plan_checker high | Hard | Yes | No |
| IAM-003 | No service-account key resources | CIS IAM | Preventive and detective | Org policy, Sentinel hard, plan_checker, drift | Hard | Yes for new keys. Existing keys need the scanner | No for new keys |
| IAM-004 | Custom roles instead of primitives | NIST AC-6 | Preventive | `landing-zone/40-iam` custom roles | n/a | The role exists. Whether it is minimal is a review | Pull request |
| IAM-005 | Time-bound deployer | NIST AC-2 | Preventive | IAM condition on the deployer binding | n/a | The condition is code. Choosing the date is a human | Shorten the timestamp |
| IAM-006 | Deny key creation and `setIamPolicy` except break-glass | NIST AC-6 | Preventive | `google_iam_deny_policy` | Deny | Yes | Break-glass group only |
| CMEK-001 | KMS key on buckets, datasets, disks, SQL | CIS storage | Preventive | Sentinel advisory, plan_checker low | Advisory | The attribute is visible. Forcing it blocks bootstrap | Advisory until keys exist |
| FIN-001 | Warn on very large machine types | FinOps | Preventive | Sentinel advisory, plan_checker low | Advisory | Yes for the name pattern | Budget owner confirms |
| FIN-002 | Budget alerts at 50/80/100% | FinOps | Detective | `google_billing_budget` | Alert | Yes | Raise the amount in review |
| NET-001 | Custom-mode Shared VPC, no default network | CIS networking | Preventive | `landing-zone/20-network` | n/a | Yes | `restrict_egress = false` is a reviewed tradeoff |
| NET-002 | Flow logs on subnets | CIS networking | Detective today | Drift scanner flags a gap | Gap | Yes, and the Sentinel rule is not written yet | Sampling rate, not off |
| NET-003 | Private Google Access | CIS networking | Preventive | Subnet `private_ip_google_access` | n/a | Yes | None in this lab |
| NET-004 | Admin access only from IAP | CIS networking | Preventive | `firewall-rule` module, 35.235.240.0/20 | Hard via FW-001 | Yes | None |
| NET-005 | Cloud NAT with error logging | CIS networking | Preventive | `google_compute_router_nat` | n/a | The resource is code. Whether egress is complete is a review | Documented allow |
| LOG-001 | Aggregated sink to BigQuery and GCS | CIS logging | Detective | Logging stack, `include_children` | n/a | Yes | Exclusion filters are reviewed |
| LOG-002 | Data Access audit logs | CIS logging | Detective | `allServices` ADMIN_READ, DATA_READ, DATA_WRITE | n/a | Yes. Volume is the cost question | Exempted members |
| LOG-003 | Alert on `SetIamPolicy` | NIST AU-6 | Detective | Log metric and alert | Alert | Yes | Tuning threshold |
| LOG-004 | Alert on firewall changes | NIST AU-6 | Detective | Log metric and alert | Alert | Yes | Tuning |
| LOG-005 | Alert on service-account key creation | NIST AU-6 | Detective | Log metric and alert | Alert | Yes | Should be near zero after ORG-001 |
| LOG-006 | Alert on org policy changes | NIST AU-6 | Detective | Log metric and alert | Alert | Yes | Tuning |
| LOG-007 | Alert on VPC-SC violations | NIST SC-7 | Detective | Log metric on `VpcServiceControlAuditMetadata` | Alert | Yes once the perimeter is enforced | Dry-run first |
| LOG-008 | Alert on sink or logging config changes | NIST AU-9 | Detective | Log metric and alert | Alert | Yes | Tuning |
| VPCSC-001 | Perimeter around data-sample | NIST SC-7 | Preventive when enforced | Access Context Manager, dry-run | Dry-run | The perimeter is code. The ingress rules are a design review | `enable_vpc_sc` |
| AI-001 | Non-default identity for Vertex | NIST AC-6 | Preventive | Sentinel advisory | Advisory | Yes for the attribute | The stack is off by default |

## How to assess whether a control can be automated

Ask, in order:

1. Can the bad state be read from config or from an inventory API, or does it live in someone's judgment?
2. Is the data source reliable on a partial plan (`after_unknown`) and on delete?
3. What is the false-positive cost? A hard fail on a maybe is worse than a miss.
4. Is the remediation a one-line change a developer can make from the error message?
5. Who owns the exception, and when does it expire?
6. Is the decision at plan time, or only visible at runtime? Plan-time belongs in Sentinel, Rego, or org policy. Runtime belongs in the drift scanner or an alert, and should create a plan-time rule if the same fact shows up in Terraform.

## Controls that were not automated

**"The data-classification label is accurate."** LBL-001 checks that `owner`, `env`, and `cost-center` are present and that `env` is one of three values. It cannot know that a bucket full of customer documents is labeled `public`. The bytes are not in the plan. A reviewer, or a separate DLP job, owns that. Automating presence and leaving accuracy to a human is the honest split.

**"Least privilege is appropriate."** IAM-001 can ban `roles/owner` and `roles/editor`. It cannot decide that `roles/compute.admin` is the right size for a deploy pipeline. Appropriate depends on the job the identity does. The custom roles in `landing-zone/40-iam` are a reviewed baseline, not a proof. A CI check that banned every role outside an allow list would freeze the platform the first week.
