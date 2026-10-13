package main

import rego.v1

# Control LBL-001. owner, env, and cost-center are required on labelable resources.
# Soft-mandatory in Sentinel. Conftest denies so the offline demo fails closed;
# promotion back to warn is a rollout decision, documented in docs/rollout-strategy.md.

labelable := {
	"google_storage_bucket",
	"google_compute_instance",
	"google_compute_disk",
	"google_bigquery_dataset",
	"google_sql_database_instance",
	"google_project",
	"google_vertex_ai_endpoint",
}

required := {"owner", "env", "cost-center"}

applies(rc) if {
	rc.mode == "managed"
	not "delete" in rc.change.actions
	rc.change.actions != ["no-op"]
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type in labelable
	applies(rc)
	labels := object.get(rc.change.after, "labels", {})
	some key in required
	object.get(labels, key, "") == ""
	msg := sprintf("LBL-001 %s: missing label %s", [rc.address, key])
}
