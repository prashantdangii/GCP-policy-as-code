package main

import rego.v1

# Control GCS-001. Buckets need uniform access and public access prevention.
# Remediate with modules/gcs-bucket.

applies(rc) if {
	rc.mode == "managed"
	not "delete" in rc.change.actions
	rc.change.actions != ["no-op"]
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "google_storage_bucket"
	applies(rc)
	not rc.change.after.uniform_bucket_level_access == true
	msg := sprintf("GCS-001 %s: uniform_bucket_level_access must be true", [rc.address])
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "google_storage_bucket"
	applies(rc)
	object.get(rc.change.after, "public_access_prevention", "inherited") != "enforced"
	msg := sprintf("GCS-001 %s: public_access_prevention must be enforced", [rc.address])
}
