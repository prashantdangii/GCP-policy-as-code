# 80-ai-workload

Disabled by default (`enable_ai_workload = false`). When enabled it creates:

- Service account `ai-runtime` with `roles/aiplatform.user` on one project. Not Editor. No JSON key.
- The Vertex AI API.
- A sample `google_vertex_ai_endpoint` with the required labels. Deploying a model is a separate, billed step and is not done here.
- An optional egress allow so that service account can reach `199.36.153.8/30` on tcp/443. Combined with `restrict_egress` in the network stack, that is the allow-listed path. The FQDNs to expect on that path are `*.googleapis.com` and `*.aiplatform.googleapis.com`, resolved by the private DNS zone in `20-network`.

Add the project number to the dry-run perimeter in `70-vpc-sc` when that stack is enabled. Audit logs come from `allServices` Data Access config in `30-logging`, which includes `aiplatform.googleapis.com`.

The threat model is `docs/threat-model-agentic-ai.md`.
