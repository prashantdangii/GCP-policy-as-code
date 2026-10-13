package main_test

import rego.v1

import data.main

test_labels_present if {
	count(main.deny) == 0 with input as {"resource_changes": [{
		"address": "google_storage_bucket.good",
		"mode": "managed",
		"type": "google_storage_bucket",
		"change": {"actions": ["create"], "after": {
			"uniform_bucket_level_access": true,
			"public_access_prevention": "enforced",
			"labels": {"owner": "platform", "env": "prod", "cost-center": "security"},
		}},
	}]}
}

test_labels_missing if {
	deny := main.deny with input as {"resource_changes": [{
		"address": "google_compute_instance.bare",
		"mode": "managed",
		"type": "google_compute_instance",
		"change": {"actions": ["update"], "after": {"labels": {"env": "prod"}}},
	}]}
	count(deny) == 2
}

test_delete_skips_labels if {
	count(main.deny) == 0 with input as {"resource_changes": [{
		"address": "google_project.gone",
		"mode": "managed",
		"type": "google_project",
		"change": {"actions": ["delete"], "after": {"labels": {}}},
	}]}
}
