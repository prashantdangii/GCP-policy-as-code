package main_test

import rego.v1

import data.main

test_compliant_bucket if {
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

test_public_bucket_denied if {
	deny := main.deny with input as {"resource_changes": [{
		"address": "google_storage_bucket.bad",
		"mode": "managed",
		"type": "google_storage_bucket",
		"change": {"actions": ["create"], "after": {
			"uniform_bucket_level_access": false,
			"public_access_prevention": "inherited",
			"labels": {"owner": "platform", "env": "prod", "cost-center": "security"},
		}},
	}]}
	count(deny) == 2
}

test_deleted_bucket_ignored if {
	count(main.deny) == 0 with input as {"resource_changes": [{
		"address": "google_storage_bucket.gone",
		"mode": "managed",
		"type": "google_storage_bucket",
		"change": {"actions": ["delete"], "after": null},
	}]}
}
