import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-instance-compliant.sentinel"
  }
}

test {
  rules = {
		main = true
		no_external_ip = true
		no_default_sa = true
  }
}
