import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-firewall-compliant.sentinel"
  }
}

test {
  rules = {
		main = true
		no_open_admin = true
  }
}
