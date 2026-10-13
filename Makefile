.DEFAULT_GOAL := help

TERRAFORM ?= terraform
SENTINEL ?= sentinel
OPA ?= opa
CONFTEST ?= conftest
TFLINT ?= tflint
PYTHON ?= python3
RUFF ?= ruff

STACKS := \
	landing-zone/bootstrap \
	landing-zone/00-org-policies \
	landing-zone/10-folders-projects \
	landing-zone/20-network \
	landing-zone/30-logging \
	landing-zone/40-iam \
	landing-zone/50-monitoring \
	landing-zone/60-finops \
	landing-zone/70-vpc-sc \
	landing-zone/80-ai-workload

MODULES := \
	modules/gcs-bucket \
	modules/compute-instance \
	modules/bigquery-dataset \
	modules/firewall-rule \
	modules/service-account \
	modules/kms-key

EXAMPLES := examples/compliant examples/non-compliant

ROOT := $(abspath .)
export PATH := $(ROOT)/.venv/bin:$(HOME)/.local/bin:$(PATH)
export TF_IN_AUTOMATION := 1
export TF_INPUT := 0
export PYTHONPATH := $(ROOT)/tools

.PHONY: help fmt lint validate scan test-sentinel test-opa test-py test \
	plan-example-compliant plan-example-bad policy-check policy-demo drift \
	terraform-test actionlint sqlfluff

help: ## List make targets
	@printf "guardrails-gcp\n\n"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

fmt: ## terraform fmt and ruff format
	@$(TERRAFORM) fmt -recursive
	@if command -v $(RUFF) >/dev/null 2>&1; then $(RUFF) format tools; fi

lint: ## tflint, ruff, and yamllint
	@$(TFLINT) --init
	@for dir in $(STACKS) $(MODULES); do \
		if [ -f $$dir/versions.tf ]; then \
			echo "==> tflint $$dir"; \
			$(TFLINT) --chdir=$$dir --config=$(ROOT)/.tflint.hcl || exit 1; \
		fi; \
	done
	@if command -v $(RUFF) >/dev/null 2>&1; then $(RUFF) check tools; fi
	@if command -v yamllint >/dev/null 2>&1; then yamllint -c .yamllint.yml .github .pre-commit-config.yaml; fi

validate: ## terraform init -backend=false && validate && fmt -check
	@$(TERRAFORM) fmt -check -recursive
	@for dir in $(STACKS) $(MODULES) $(EXAMPLES); do \
		if [ -f $$dir/versions.tf ]; then \
			echo "==> validate $$dir"; \
			$(TERRAFORM) -chdir=$$dir init -backend=false -input=false -no-color >/dev/null && \
			$(TERRAFORM) -chdir=$$dir validate -no-color || exit 1; \
		fi; \
	done

scan: ## checkov and trivy config scans
	@checkov -d landing-zone -d modules -d examples/compliant --quiet --compact
	@trivy config --exit-code 1 --severity HIGH,CRITICAL --skip-dirs examples/non-compliant --skip-dirs .venv .

test-sentinel: ## sentinel test
	@cd policies/sentinel && $(SENTINEL) test -verbose

test-opa: ## opa test and conftest verify
	@$(OPA) test policies/opa -v
	@$(CONFTEST) verify -p policies/opa

test-py: ## pytest with coverage on rules modules
	@cd tools && $(PYTHON) -m pytest

test: test-sentinel test-opa test-py terraform-test ## All offline tests

terraform-test: ## terraform test for golden modules
	@for dir in $(MODULES); do \
		echo "==> terraform test $$dir"; \
		$(TERRAFORM) -chdir=$$dir init -backend=false -input=false -no-color >/dev/null && \
		$(TERRAFORM) -chdir=$$dir test -no-color || exit 1; \
	done

plan-example-compliant: ## Show the committed compliant plan fixture
	@$(PYTHON) -m plan_checker.cli examples/compliant/plan.json --format text --fail-on high

plan-example-bad: ## Show findings for the non-compliant plan fixture
	@$(PYTHON) -m plan_checker.cli examples/non-compliant/plan.json --format text --fail-on none || true

policy-check: ## Conftest + plan_checker against a plan JSON (PLAN=path)
	@test -n "$(PLAN)" || (echo "Set PLAN=path/to/tfplan.json" && exit 2)
	@$(CONFTEST) test "$(PLAN)" -p policies/opa --all-namespaces
	@$(PYTHON) -m plan_checker.cli "$(PLAN)" --format text --fail-on high

policy-demo: ## Offline pass/fail demo, no cloud credentials
	@$(PYTHON) -m policy_demo

drift: ## Offline drift report from the non-compliant asset fixture
	@$(PYTHON) -m drift_scanner.cli --input tools/drift_scanner/tests/fixtures/assets_noncompliant.json --format md

actionlint: ## Lint GitHub Actions workflows
	@actionlint

sqlfluff: ## Lint BigQuery audit queries
	@sqlfluff lint queries/bigquery --dialect bigquery
