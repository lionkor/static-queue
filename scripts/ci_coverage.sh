#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Run main coverage script
./scripts/coverage.sh

# Parse the summary line from llvm-cov report
REPORT_OUT=$(LLVM_PROFILE_FILE="ci-coverage-%p-%m.profraw" ./coverage.sh 2>/dev/null | tee /dev/stderr)

# If coverage.sh already prints the report, capture it from the output
# Otherwise, run llvm-cov report again and capture output
if ! echo "$REPORT_OUT" | grep -q '^TOTAL'; then
    # Find the test binary
    TEST_BIN=$(find target/debug/deps/ -maxdepth 1 -type f -executable -name 'static_queue-*' ! -name '*.d' ! -name '*.rlib' | head -n1)
    LLVM_COV_BIN=$(find ~/.rustup/toolchains/nightly-*/lib/rustlib/*/bin/llvm-cov | head -n1)
    REPORT_LINE=$($LLVM_COV_BIN report \
        --use-color \
        --ignore-filename-regex='/.cargo/registry' \
        --instr-profile=coverage.profdata \
        "$TEST_BIN" | grep '^TOTAL')
else
    REPORT_LINE=$(echo "$REPORT_OUT" | grep '^TOTAL')
fi

echo "$REPORT_LINE"

# Extract coverage percentages (columns: lines, functions, branches)
# Example: TOTAL  23  23  100.0%  7  7  100.0%  12  12  100.0%
COVERAGE_OK=1
for pct in $(echo "$REPORT_LINE" | grep -oE '[0-9]+\.[0-9]+%'); do
    if [ "$pct" != "100.0%" ] && [ "$pct" != "100.00%" ]; then
        COVERAGE_OK=0
    fi
done

if [ "$COVERAGE_OK" -eq 1 ]; then
    echo "Coverage is 100% for all metrics."
    exit 0
else
    echo "Coverage is NOT 100% for all metrics."
    exit 1
fi
