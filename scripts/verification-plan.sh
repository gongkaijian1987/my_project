#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="target/verification"
PLAN_FILE="${REPORT_DIR}/verification-plan.env"
SUMMARY_FILE="${REPORT_DIR}/summary.md"
JSON_FILE="${REPORT_DIR}/summary.json"

mkdir -p "${REPORT_DIR}"

BASE_REF="${CIRCLE_BRANCH:-}"
DEFAULT_BRANCH="${CIRCLE_DEFAULT_BRANCH:-main}"
CURRENT_BRANCH="${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)}"

if git rev-parse --verify "origin/${DEFAULT_BRANCH}" >/dev/null 2>&1; then
  COMPARE_REF="$(git merge-base HEAD "origin/${DEFAULT_BRANCH}")"
elif git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
  COMPARE_REF="HEAD~1"
else
  COMPARE_REF="HEAD"
fi

CHANGED_FILES="$(git diff --name-only "${COMPARE_REF}" HEAD || true)"
if [ -z "${CHANGED_FILES}" ]; then
  CHANGED_FILES="$(git diff-tree --no-commit-id --name-only -r HEAD || true)"
fi
if [ -z "${CHANGED_FILES}" ]; then
  CHANGED_FILES="$(git diff --name-only || true)"
fi
if [ -z "${CHANGED_FILES}" ]; then
  CHANGED_FILES="$(git diff --cached --name-only || true)"
fi
UNTRACKED_FILES="$(git ls-files --others --exclude-standard || true)"
if [ -n "${UNTRACKED_FILES}" ]; then
  if [ -n "${CHANGED_FILES}" ]; then
    CHANGED_FILES="${CHANGED_FILES}
${UNTRACKED_FILES}"
  else
    CHANGED_FILES="${UNTRACKED_FILES}"
  fi
fi

RISK_SCORE=0
TEST_TARGETS=()
REASONS=()
RUN_PACKAGE=true
NON_DOC_CHANGE=false

add_reason() {
  REASONS+=("$1")
}

add_target() {
  local target="$1"
  for existing in "${TEST_TARGETS[@]:-}"; do
    if [ "${existing}" = "${target}" ]; then
      return
    fi
  done
  TEST_TARGETS+=("${target}")
}

if [ -z "${CHANGED_FILES}" ]; then
  add_reason "No file changes detected; do not skip tests by default."
fi

while IFS= read -r file; do
  [ -z "${file}" ] && continue
  case "${file}" in
    pom.xml)
      RISK_SCORE=$((RISK_SCORE + 40))
      NON_DOC_CHANGE=true
      add_reason "Build configuration changed: ${file}"
      add_target "full"
      ;;
    .circleci/*|scripts/*)
      RISK_SCORE=$((RISK_SCORE + 25))
      NON_DOC_CHANGE=true
      add_reason "Pipeline or automation script changed: ${file}"
      add_target "full"
      ;;
    src/main/java/com/example/demo/controller/*)
      RISK_SCORE=$((RISK_SCORE + 25))
      NON_DOC_CHANGE=true
      add_reason "Controller code changed: ${file}"
      add_target "test=com.example.demo.controller.HealthControllerTest"
      ;;
    src/main/java/com/example/demo/service/*)
      RISK_SCORE=$((RISK_SCORE + 15))
      NON_DOC_CHANGE=true
      add_reason "Service logic changed: ${file}"
      add_target "test=com.example.demo.service.GreetingServiceTest"
      ;;
    src/main/resources/*)
      RISK_SCORE=$((RISK_SCORE + 20))
      NON_DOC_CHANGE=true
      add_reason "Application configuration changed: ${file}"
      add_target "full"
      ;;
    src/test/*)
      RISK_SCORE=$((RISK_SCORE + 10))
      NON_DOC_CHANGE=true
      add_reason "Test code changed: ${file}"
      ;;
    README.md|*.md)
      RISK_SCORE=$((RISK_SCORE + 1))
      add_reason "Documentation changed: ${file}"
      ;;
    src/main/*)
      RISK_SCORE=$((RISK_SCORE + 20))
      NON_DOC_CHANGE=true
      add_reason "Application source changed: ${file}"
      add_target "full"
      ;;
    *)
      RISK_SCORE=$((RISK_SCORE + 5))
      NON_DOC_CHANGE=true
      add_reason "Other file changed: ${file}"
      ;;
  esac
done <<EOF
${CHANGED_FILES}
EOF

CHANGED_FILES="$(printf '%s\n' "${CHANGED_FILES}" | awk 'NF && !seen[$0]++')"

if [ "${NON_DOC_CHANGE}" = "false" ] && [ -n "${CHANGED_FILES}" ]; then
  RUN_PACKAGE=false
fi

VERIFICATION_MODE="targeted"
if [ "${CURRENT_BRANCH}" = "${DEFAULT_BRANCH}" ]; then
  VERIFICATION_MODE="full"
  add_reason "Default branch builds always run full verification."
  add_target "full"
elif [ -z "${CHANGED_FILES}" ]; then
  VERIFICATION_MODE="targeted"
  add_reason "Empty diff detected; fall back to targeted tests instead of lightweight validation."
elif [ ${RISK_SCORE} -ge 40 ]; then
  VERIFICATION_MODE="full"
  add_target "full"
elif [ ${RISK_SCORE} -le 5 ]; then
  VERIFICATION_MODE="lightweight"
fi

if [ ${#TEST_TARGETS[@]} -eq 0 ] && [ "${VERIFICATION_MODE}" = "targeted" ]; then
  add_target "test=com.example.demo.controller.HealthControllerTest"
  add_target "test=com.example.demo.service.GreetingServiceTest"
fi

TARGETS_JOINED="$(printf '%s,' "${TEST_TARGETS[@]:-}")"
TARGETS_JOINED="${TARGETS_JOINED%,}"

{
  echo "COMPARE_REF=${COMPARE_REF}"
  echo "RISK_SCORE=${RISK_SCORE}"
  echo "VERIFICATION_MODE=${VERIFICATION_MODE}"
  echo "RUN_PACKAGE=${RUN_PACKAGE}"
  echo "TEST_TARGETS=${TARGETS_JOINED}"
} > "${PLAN_FILE}"

{
  echo "# Automated Verification Summary"
  echo
  echo "- Branch: ${BASE_REF:-unknown}"
  echo "- Compare ref: ${COMPARE_REF}"
  echo "- Risk score: ${RISK_SCORE}"
  echo "- Verification mode: ${VERIFICATION_MODE}"
  echo "- Package build enabled: ${RUN_PACKAGE}"
  echo
  echo "## Changed Files"
  if [ -n "${CHANGED_FILES}" ]; then
    printf '%s\n' "${CHANGED_FILES}" | sed 's/^/- /'
  else
    echo "- None"
  fi
  echo
  echo "## Risk Reasons"
  if [ ${#REASONS[@]} -gt 0 ]; then
    printf '%s\n' "${REASONS[@]}" | sed 's/^/- /'
  else
    echo "- No specific risk signals."
  fi
  echo
  echo "## Planned Tests"
  if [ -n "${TARGETS_JOINED}" ]; then
    printf '%s\n' "${TARGETS_JOINED}" | tr ',' '\n' | sed 's/^/- /'
  else
    echo "- No test execution required"
  fi
} > "${SUMMARY_FILE}"

cat > "${JSON_FILE}" <<EOF
{
  "compareRef": "${COMPARE_REF}",
  "riskScore": ${RISK_SCORE},
  "verificationMode": "${VERIFICATION_MODE}",
  "runPackage": "${RUN_PACKAGE}",
  "testTargets": "${TARGETS_JOINED}"
}
EOF

cat "${SUMMARY_FILE}"
