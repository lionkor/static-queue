#!/bin/sh
set -e

export CARGO_INCREMENTAL=0
export RUSTFLAGS="-C instrument-coverage"
export LLVM_PROFILE_FILE="coverage-%p-%m.profraw"

# Clean previous artifacts
rm -f ./*.profraw
cargo clean

# Run tests with coverage instrumentation
cargo test

# Find the test binary
TEST_BIN=$(find target/debug/deps/ -maxdepth 1 -type f -executable -name 'static_queue-*' ! -name '*.d' ! -name '*.rlib' | head -n1)

if [ -z "$TEST_BIN" ]; then
    echo "Test binary not found."
    exit 1
fi

# Merge raw profiles
llvm-profdata merge -sparse ./*.profraw -o coverage.profdata

# Generate coverage report
llvm-cov report \
    --use-color \
    --ignore-filename-regex='/.cargo/registry' \
    --instr-profile=coverage.profdata \
    "$TEST_BIN"

# Optionally, generate HTML report
llvm-cov show \
    --use-color \
    --ignore-filename-regex='/.cargo/registry' \
    --instr-profile=coverage.profdata \
    --format=html \
    --output-dir=coverage-html \
    "$TEST_BIN"

echo "HTML report generated in coverage-html/index.html"
