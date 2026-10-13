#!/usr/bin/env bash
# Install the pinned CLIs used by CI. Versions match the ones verified locally.
set -euo pipefail

dest="${1:-$HOME/.local/bin}"
mkdir -p "$dest"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fetch() {
  curl --fail --silent --show-error --location "$1" --output "$2"
}

fetch "https://releases.hashicorp.com/sentinel/0.41.0/sentinel_0.41.0_linux_amd64.zip" "$tmp/sentinel.zip"
unzip -q "$tmp/sentinel.zip" -d "$tmp/sentinel"
install -m 0755 "$tmp/sentinel/sentinel" "$dest/sentinel"

fetch "https://github.com/open-policy-agent/opa/releases/download/v1.21.2/opa_linux_amd64_static" "$dest/opa"
chmod 0755 "$dest/opa"

fetch "https://github.com/open-policy-agent/conftest/releases/download/v0.71.1/conftest_0.71.1_Linux_x86_64.tar.gz" "$tmp/conftest.tar.gz"
tar -xzf "$tmp/conftest.tar.gz" -C "$tmp"
install -m 0755 "$tmp/conftest" "$dest/conftest"

fetch "https://github.com/terraform-linters/tflint/releases/download/v0.64.0/tflint_linux_amd64.zip" "$tmp/tflint.zip"
unzip -q "$tmp/tflint.zip" -d "$tmp"
install -m 0755 "$tmp/tflint" "$dest/tflint"

fetch "https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz" "$tmp/gitleaks.tar.gz"
tar -xzf "$tmp/gitleaks.tar.gz" -C "$tmp"
install -m 0755 "$tmp/gitleaks" "$dest/gitleaks"

fetch "https://github.com/aquasecurity/trivy/releases/download/v0.75.0/trivy_0.75.0_Linux-64bit.tar.gz" "$tmp/trivy.tar.gz"
tar -xzf "$tmp/trivy.tar.gz" -C "$tmp"
install -m 0755 "$tmp/trivy" "$dest/trivy"

echo "installed sentinel opa conftest tflint gitleaks trivy into $dest"
