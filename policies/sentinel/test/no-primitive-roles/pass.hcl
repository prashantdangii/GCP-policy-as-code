import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-iam-compliant.sentinel"
  }
}

test {
  rules = {
		main = true
		no_primitive_roles = true
		no_public_members = true
  }
}
