#!/usr/bin/env bash
set -euo pipefail

PLAN_FILE="target/verification/verification-plan.env"

if [ ! -f "${PLAN_FILE}" ]; then
  echo "Verification plan not found: ${PLAN_FILE}"
  exit 1
fi

source "${PLAN_FILE}"

if command -v powershell.exe >/dev/null 2>&1; then
  MVN_CMD=(powershell)
elif command -v mvn >/dev/null 2>&1; then
  MVN_CMD=(mvn)
elif command -v mvn.cmd >/dev/null 2>&1 && command -v cmd.exe >/dev/null 2>&1; then
  MVN_CMD=(cmd)
else
  echo "Maven executable not found."
  exit 1
fi

run_maven() {
  if [ "${MVN_CMD[0]}" = "powershell" ]; then
    local ps_args=""
    local arg
    for arg in "$@"; do
      ps_args="${ps_args} '${arg}'"
    done
    powershell.exe -NoProfile -Command "& mvn${ps_args}"
  elif [ "${MVN_CMD[0]}" = "cmd" ]; then
    cmd.exe /c mvn.cmd "$@"
  else
    "${MVN_CMD[@]}" "$@"
  fi
}

run_full_suite() {
  run_maven -B -ntp clean test
}

run_targeted_suite() {
  local csv_targets="$1"
  if printf '%s' "${csv_targets}" | grep -q 'full'; then
    run_full_suite
    return
  fi

  local test_selector
  test_selector="$(printf '%s' "${csv_targets}" | tr ',' '\n' | sed 's/^test=//' | paste -sd ',' -)"
  if [ -z "${test_selector}" ]; then
    run_full_suite
    return
  fi

  echo "Running targeted tests: ${test_selector}"
  run_maven -B -ntp clean -Dtest="${test_selector}" test
}

run_lightweight_checks() {
  run_maven -B -ntp -q validate
}

case "${VERIFICATION_MODE}" in
  full)
    echo "Running full verification because risk score is ${RISK_SCORE}."
    run_full_suite
    ;;
  targeted)
    echo "Running targeted verification because risk score is ${RISK_SCORE}."
    run_targeted_suite "${TEST_TARGETS}"
    ;;
  lightweight)
    echo "Running lightweight verification because detected risk is low."
    run_lightweight_checks
    ;;
  *)
    echo "Unknown verification mode: ${VERIFICATION_MODE}"
    exit 1
    ;;
esac

if [ "${RUN_PACKAGE}" = "true" ]; then
  run_maven -B -ntp package -DskipTests
else
  echo "Skipping package build for low-impact documentation-only changes."
fi
