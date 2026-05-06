#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: bash scripts/chunk-run-maven.sh <maven-args...>"
  exit 1
fi

if command -v powershell.exe >/dev/null 2>&1; then
  ps_args=""
  for arg in "$@"; do
    ps_args="${ps_args} '${arg}'"
  done
  powershell.exe -NoProfile -Command "& mvn${ps_args}"
elif command -v mvn >/dev/null 2>&1; then
  mvn "$@"
elif command -v mvn.cmd >/dev/null 2>&1 && command -v cmd.exe >/dev/null 2>&1; then
  cmd.exe /c mvn.cmd "$@"
else
  echo "Maven executable not found."
  exit 1
fi

