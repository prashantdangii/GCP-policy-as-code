import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-instance-delete.sentinel"
  }
}

test {
  rules = {
		main = true
  }
}
