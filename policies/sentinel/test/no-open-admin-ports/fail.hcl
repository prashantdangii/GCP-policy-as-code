import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-firewall-open-ssh.sentinel"
  }
}

test {
  rules = {
		main = false
		no_open_admin = false
  }
}
