#!/usr/bin/env bash
set -euo pipefail

if ! command -v circleci >/dev/null 2>&1; then
  echo "circleci CLI is required in the CircleCI executor."
  exit 1
fi

TEST_CLASSES="$(
  circleci tests glob "src/test/java/**/*Test.java" \
    | sed 's#src/test/java/##' \
    | sed 's#/#.#g' \
    | sed 's#\.java$##' \
    | circleci tests run --command="xargs echo" --split-by=timings --timings-type=classname
)"

TEST_CLASSES_CSV="$(printf '%s' "${TEST_CLASSES}" | tr ' \n' ',' | sed 's/,,*/,/g; s/^,//; s/,$//')"

if [ -z "${TEST_CLASSES_CSV}" ]; then
  echo "No test classes were assigned to this node."
  exit 0
fi

echo "Running test classes on this node: ${TEST_CLASSES_CSV}"
mvn -B -ntp -Dtest="${TEST_CLASSES_CSV}" test
