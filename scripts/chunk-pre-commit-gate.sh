#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v chunk >/dev/null 2>&1; then
  echo "Chunk CLI is not installed or not in PATH."
  echo "Install it with: brew install CircleCI-Public/circleci/chunk"
  exit 1
fi

echo "Running Chunk pre-commit validations for my_project..."

chunk validate tests --no-check --override-cmd "bash scripts/chunk-validate-tests.sh"
chunk validate package --no-check --override-cmd "bash scripts/chunk-validate-package.sh"
chunk validate circleci-config --no-check --override-cmd "bash scripts/chunk-validate-circleci.sh"

echo "All Chunk pre-commit validations passed."

