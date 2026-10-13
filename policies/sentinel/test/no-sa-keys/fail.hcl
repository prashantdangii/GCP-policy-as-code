import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-sa-key.sentinel"
  }
}

test {
  rules = {
		main = false
		no_sa_keys = false
  }
}
