import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-instance-bad.sentinel"
  }
}

test {
  rules = {
		main = false
		no_external_ip = false
		no_default_sa = false
  }
}
