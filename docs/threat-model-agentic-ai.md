# Threat model: agentic AI workload

`landing-zone/80-ai-workload` is off unless `enable_ai_workload` is true. It creates a service account with `roles/aiplatform.user`, no JSON key, and an optional egress rule to the private Google API range. It does not deploy a tuned model. This document is the design review for turning it on.

The research context is conceptual. Indirect prompt injection is a known class of attack against tool-using models: untrusted text that the model later treats as instructions. This page does not include payloads.

## STRIDE, plus the agent-specific cases

| Threat | What goes wrong | Control in this repo |
|---|---|---|
| Spoofing | A caller uses the default Compute service account or a leaked key | VM-002, ORG-001, IAM-003, AI-001. The runtime account is `ai-runtime` |
| Tampering | Someone changes the endpoint or the prompt log sink | LOG-003 and LOG-008 alert on IAM and logging changes. CMEK is optional on the endpoint |
| Repudiation | A tool call has no actor | Data Access audit logs (LOG-002) once the logging stack is applied. Do not log raw prompts that contain customer data into a world-readable sink |
| Information disclosure | The model reads a secret from context, or a tool returns a bucket object to an outsider | No secrets in the prompt path. IAM on the tool's service account is `roles/aiplatform.user` only. VPC-SC (VPCSC-001) can include the project when you enable the perimeter |
| Denial of service | A loop of tool calls spends the quota or the budget | FIN-001 and FIN-002. Cap tool retries in the application. This Terraform module does not set Vertex quota |
| Elevation of privilege | The agent's tools can `setIamPolicy`, create keys, or act as Editor | IAM-001, IAM-006. Do not attach those tools. Human approval for any tool that deletes or changes IAM |
| Direct prompt injection | The user asks the model to ignore its instructions | Application policy and a human for destructive tools. Not a Terraform resource |
| Indirect prompt injection | The model reads a document, ticket, or web page that contains instructions aimed at the model, then calls a tool | Treat retrieved text as data. Constrain tool schemas. Egress only to the private Google range plus names you allow. Audit the tool calls |
| Excessive agency | The tool list is wider than the task | One service account per task. `roles/aiplatform.user` is already broader than a single model call. Narrow further with a custom role when the task is known |
| Exfiltration | A tool or a prompt sends data to an unexpected host | Restricted egress in the network stack. NAT. No external IP on the VM path (VM-001). VPC-SC for storage and BigQuery |
| Secrets in context | A key or token is pasted into a prompt and then written to a log | No SA keys (IAM-003). Redact prompts before they hit the audit dataset. The logging exclusions variable is the place to drop that stream from the long-term archive if it cannot be redacted |

## What "on" should mean

Enable the stack only in `nonprod` first. Include the project in the VPC-SC dry-run perimeter and read LOG-007 before switching the perimeter to enforced. Keep the advisory AI-001 rule until every notebook and endpoint in the plan uses `ai-runtime`.
