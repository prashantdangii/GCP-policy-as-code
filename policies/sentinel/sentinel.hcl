# Policy set for HCP Terraform. The local CLI does not load this file during
# `sentinel test`; each test file imports the common module itself.
# Enforcement levels are justified in docs/adr/0002-enforcement-levels.md.

module "common" {
  source = "./common/functions.sentinel"
}

policy "gcs-bucket-secure" {
  source            = "./gcs-bucket-secure.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "no-open-admin-ports" {
  source            = "./no-open-admin-ports.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "required-labels" {
  source            = "./required-labels.sentinel"
  enforcement_level = "soft-mandatory"
}

policy "no-external-ip-no-default-sa" {
  source            = "./no-external-ip-no-default-sa.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "cmek-required" {
  source            = "./cmek-required.sentinel"
  enforcement_level = "advisory"
}

policy "no-primitive-roles" {
  source            = "./no-primitive-roles.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "no-sa-keys" {
  source            = "./no-sa-keys.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "large-machine-advisory" {
  source            = "./large-machine-advisory.sentinel"
  enforcement_level = "advisory"
}

policy "vertex-non-default-sa" {
  source            = "./vertex-non-default-sa.sentinel"
  enforcement_level = "advisory"
}
