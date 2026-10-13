import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-bucket-compliant.sentinel"
  }
}

test {
  rules = {
		main = true
		uniform_access = true
		public_access_prevention = true
  }
}
