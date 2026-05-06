#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v circleci >/dev/null 2>&1; then
  echo "CircleCI CLI not found; skipping local config validation."
  echo "Install it with: brew install circleci"
  exit 0
fi

circleci config validate .circleci/config.yml
circleci config validate .circleci/cci-agent-setup.yml
