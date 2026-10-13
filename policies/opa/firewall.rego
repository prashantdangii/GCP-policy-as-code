package main

import rego.v1

# Control FW-001. No world-ingress to SSH, RDP, all TCP ports, or protocol all.

firewall_types := {
	"google_compute_firewall",
	"google_compute_firewall_policy_rule",
	"google_compute_network_firewall_policy_rule",
}

applies(rc) if {
	rc.mode == "managed"
	not "delete" in rc.change.actions
	rc.change.actions != ["no-op"]
}

world(ranges) if {
	some range in ranges
	range in {"0.0.0.0/0", "::/0"}
}

admin_ports(protocol, ports) if {
	lower(protocol) == "all"
}

admin_ports(protocol, ports) if {
	lower(protocol) == "tcp"
	count(ports) == 0
}

admin_ports(protocol, ports) if {
	lower(protocol) == "tcp"
	some port in ports
	port in {"22", "3389"}
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "google_compute_firewall"
	applies(rc)
	not rc.change.after.disabled == true
	object.get(rc.change.after, "direction", "INGRESS") == "INGRESS"
	world(object.get(rc.change.after, "source_ranges", []))
	some allow in object.get(rc.change.after, "allow", [])
	admin_ports(object.get(allow, "protocol", ""), object.get(allow, "ports", []))
	msg := sprintf("FW-001 %s: ingress allow of admin ports from 0.0.0.0/0 or ::/0", [rc.address])
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type in firewall_types
	rc.type != "google_compute_firewall"
	applies(rc)
	not rc.change.after.disabled == true
	object.get(rc.change.after, "direction", "INGRESS") == "INGRESS"
	lower(object.get(rc.change.after, "action", "")) == "allow"
	match := object.get(rc.change.after, "match", {})
	world(object.get(match, "src_ip_ranges", []))
	some layer4 in object.get(match, "layer4_configs", [])
	admin_ports(object.get(layer4, "ip_protocol", ""), object.get(layer4, "ports", []))
	msg := sprintf("FW-001 %s: ingress allow of admin ports from 0.0.0.0/0 or ::/0", [rc.address])
}
