package main

import rego.v1

# Advisory controls. Conftest does not fail on warn unless --fail-on-warn is set.
# FIN-001 large machine types. CMEK-001 missing customer-managed keys.

applies(rc) if {
	rc.mode == "managed"
	not "delete" in rc.change.actions
	rc.change.actions != ["no-op"]
}

large(machine_type) if {
	contains(machine_type, "custom-")
}

large(machine_type) if {
	some suffix in {"-32", "-48", "-64", "-96", "-128"}
	endswith(machine_type, suffix)
}

warn contains msg if {
	some rc in input.resource_changes
	rc.type == "google_compute_instance"
	applies(rc)
	large(object.get(rc.change.after, "machine_type", ""))
	msg := sprintf("FIN-001 %s: machine type looks expensive", [rc.address])
}

warn contains msg if {
	some rc in input.resource_changes
	rc.type == "google_storage_bucket"
	applies(rc)
	enc := object.get(rc.change.after, "encryption", [])
	count(enc) == 0
	msg := sprintf("CMEK-001 %s: bucket is missing a Cloud KMS key", [rc.address])
}
