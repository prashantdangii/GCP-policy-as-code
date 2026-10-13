import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-machine-large.sentinel"
  }
}

test {
  rules = {
		main = false
  }
}
