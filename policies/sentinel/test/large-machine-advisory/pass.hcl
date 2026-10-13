import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-machine-small.sentinel"
  }
}

test {
  rules = {
		main = true
  }
}
