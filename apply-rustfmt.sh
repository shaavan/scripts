#!/bin/bash
set -euo pipefail

REPO_PATH="$(pwd)"
cd "$REPO_PATH"

TOOLCHAIN="1.75.0"

echo "Installing toolchain $TOOLCHAIN and rustfmt..."
rustup toolchain install "$TOOLCHAIN"
rustup component add rustfmt --toolchain "$TOOLCHAIN"

echo "Running cargo fmt check..."
cargo +"$TOOLCHAIN" fmt --all