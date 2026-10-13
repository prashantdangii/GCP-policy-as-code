import "module" "common" {
  source = "../../common/functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "../../testdata/mock-bucket-public.sentinel"
  }
}

test {
  rules = {
		main = false
		uniform_access = false
		public_access_prevention = false
  }
}
