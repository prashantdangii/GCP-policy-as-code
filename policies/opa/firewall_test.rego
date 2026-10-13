package main_test

import rego.v1

import data.main

test_iap_firewall_allowed if {
	count(main.deny) == 0 with input as {"resource_changes": [{
		"address": "google_compute_firewall.iap",
		"mode": "managed",
		"type": "google_compute_firewall",
		"change": {"actions": ["create"], "after": {
			"direction": "INGRESS",
			"source_ranges": ["35.235.240.0/20"],
			"allow": [{"protocol": "tcp", "ports": ["22", "3389"]}],
		}},
	}]}
}

test_world_ssh_denied if {
	deny := main.deny with input as {"resource_changes": [{
		"address": "google_compute_firewall.bad",
		"mode": "managed",
		"type": "google_compute_firewall",
		"change": {"actions": ["create"], "after": {
			"direction": "INGRESS",
			"source_ranges": ["0.0.0.0/0"],
			"allow": [{"protocol": "tcp", "ports": ["22"]}],
		}},
	}]}
	count(deny) == 1
}

test_noop_firewall_ignored if {
	count(main.deny) == 0 with input as {"resource_changes": [{
		"address": "google_compute_firewall.same",
		"mode": "managed",
		"type": "google_compute_firewall",
		"change": {"actions": ["no-op"], "after": {
			"direction": "INGRESS",
			"source_ranges": ["0.0.0.0/0"],
			"allow": [{"protocol": "tcp", "ports": ["22"]}],
		}},
	}]}
}
