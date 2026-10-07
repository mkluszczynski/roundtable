#!/usr/bin/env bash
# Runs the panel's E2E UI tests (docs/DEVELOPMENT.md "E2E tests") on the
# Linux desktop, one file per `flutter test` call: a second file in the same
# call can't start the app on the Linux device.
set -euo pipefail
cd "$(dirname "$0")/../roundtable_flutter"
status=0
for test in integration_test/*_test.dart; do
  echo "== $test"
  flutter test "$test" -d linux || status=1
done
exit $status
