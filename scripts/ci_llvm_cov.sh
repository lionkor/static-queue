#!/bin/sh
set -e

# Ensure cargo-llvm-cov is installed
if ! command -v cargo-llvm-cov >/dev/null 2>&1; then
    echo "cargo-llvm-cov not found, installing..."
    cargo install cargo-llvm-cov
fi

# Run coverage and output JSON summary (no HTML report)
cargo llvm-cov --json --no-report > coverage.json

# Check for jq
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found, installing..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y jq
    else
        echo "Please install jq manually."
        exit 1
    fi
fi

# Check all percent_covered fields in the totals for 100
NOT_FULL=$(jq -e '
  .data[].totals[] | 
  select(.percent_covered < 100)
' coverage.json || true)

if [ -z "$NOT_FULL" ]; then
    echo "Coverage is 100% for all metrics."
    exit 0
else
    echo "Coverage is NOT 100% for all metrics:"
    echo "$NOT_FULL"
    exit 1
fi