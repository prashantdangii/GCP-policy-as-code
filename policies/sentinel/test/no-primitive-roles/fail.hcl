import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-iam-editor.sentinel"
  }
}

test {
  rules = {
		main = false
		no_primitive_roles = false
  }
}
