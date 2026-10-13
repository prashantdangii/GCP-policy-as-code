import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-labels-compliant.sentinel"
  }
}

test {
  rules = {
		main = true
		labels_present = true
  }
}
