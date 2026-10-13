import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-bucket-delete.sentinel"
  }
}

test {
  rules = {
		main = true
  }
}
