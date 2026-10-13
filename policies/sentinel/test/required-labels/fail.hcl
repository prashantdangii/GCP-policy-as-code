import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-labels-missing.sentinel"
  }
}

test {
  rules = {
		main = false
  }
}
