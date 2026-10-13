import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-cmek-compliant.sentinel"
  }
}

test {
  rules = {
		main = true
		cmek_set = true
  }
}
