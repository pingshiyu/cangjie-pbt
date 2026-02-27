#!/usr/bin/env bash
# Run net PBT (main_net_testing) with a timeout so runs don't run indefinitely.
# Usage: from cangjie-pbt/, run: ./run_net_test.sh
# Prereq: source envsetup.sh and cjpm build first, or run from a shell that has cjpm.

set -e
TIMEOUT_SEC=20

if command -v timeout >/dev/null 2>&1; then
  timeout ${TIMEOUT_SEC} cjpm run "$@"
elif command -v gtimeout >/dev/null 2>&1; then
  gtimeout ${TIMEOUT_SEC} cjpm run "$@"
else
  echo "Warning: 'timeout' not found (install coreutils on macOS for gtimeout). Running without timeout."
  cjpm run "$@"
fi
