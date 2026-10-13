import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-vertex-custom-sa.sentinel"
  }
}

test {
  rules = {
		main = true
		dedicated_sa = true
  }
}
