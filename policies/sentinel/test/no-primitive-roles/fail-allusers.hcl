import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-iam-allusers.sentinel"
  }
}

test {
  rules = {
		main = false
		no_public_members = false
  }
}
