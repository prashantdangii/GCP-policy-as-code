import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-sa-key-absent.sentinel"
  }
}

test {
  rules = {
		main = true
		no_sa_keys = true
  }
}
