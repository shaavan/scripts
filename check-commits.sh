#!/bin/bash
set -euo pipefail

###############################################################################
# check-commits.sh
#
# Local validation script for commit sequences.
#
# Purpose
# -------
# Validates that a sequence of commits builds correctly. This ensures each
# commit represents a valid repository state.
#
# Supported Inputs
# ----------------
# 1. <number-of-commits>
#    Validate the last N commits relative to HEAD.
#
# 2. <commit-hash>
#    Validate all commits from the given commit (exclusive) to HEAD.
#
# Validation Steps Per Commit
# ---------------------------
# • cargo check
# • documentation build
# • fuzz target compilation
# • lightning crate compilation without default features
# • c_bindings compilation
#
# The repository state is restored after execution or interruption.
###############################################################################

REPO_PATH="$(pwd)"
TOOLCHAIN="stable"

###############################################################################
# Argument validation
###############################################################################

if [ "$#" -ne 1 ]; then
	echo "Usage: check-commits.sh <number-of-commits | commit-hash>"
	exit 1
fi

INPUT=$1

###############################################################################
# Ensure repository exists
###############################################################################

if [ ! -d "$REPO_PATH" ]; then
	echo "Repository path does not exist: $REPO_PATH"
	exit 1
fi

cd "$REPO_PATH"

###############################################################################
# Capture current repository state
#
# We record either:
# • the current branch name
# • or the current commit (if in detached HEAD)
#
# This allows the script to restore the repository after execution.
###############################################################################

ORIGINAL_STATE=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || git rev-parse HEAD)

###############################################################################
# Ensure working tree is clean
#
# Checking out multiple commits during validation will overwrite files.
# To avoid accidental data loss, the repository must have no uncommitted
# changes before running the script.
###############################################################################

if ! git diff-index --quiet HEAD --; then
	echo "Repository has uncommitted changes. Please commit or stash them first."
	exit 1
fi

###############################################################################
# Cleanup handler
#
# Restores the repository to its original state when:
# • the script is interrupted (Ctrl+C)
# • validation fails
#
# Note: This function exits with code 1 because it is triggered only when
# validation is interrupted or aborted.
###############################################################################

cleanup() {
	echo "Restoring original state..."
	git checkout "$ORIGINAL_STATE" &>/dev/null || {
		echo "Failed to restore to $ORIGINAL_STATE"
		exit 1
	}
	echo "Restored to $ORIGINAL_STATE"
	exit 1
}

trap cleanup SIGINT

###############################################################################
# Ensure required Rust toolchain exists
###############################################################################

echo "Ensuring Rust toolchain $TOOLCHAIN is installed..."
rustup toolchain install "$TOOLCHAIN"

###############################################################################
# Determine commit range
#
# Two supported modes:
#
# 1. Numeric input:
#    Validate the last N commits relative to HEAD.
#
# 2. Commit hash:
#    Validate commits from the specified commit (exclusive) to HEAD.
#
# Commits are returned in chronological order using --reverse so validation
# follows the same sequence in which commits were created.
###############################################################################

if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
	COMMITS=$(git log --reverse --pretty=format:"%H %s" HEAD~"$INPUT"..HEAD)
	echo "Validating the last $INPUT commits."
else
	if ! git rev-parse "$INPUT" &>/dev/null; then
		echo "Invalid commit hash: $INPUT"
		exit 1
	fi
	COMMITS=$(git log --reverse --pretty=format:"%H %s" "$INPUT"^..HEAD)
	echo "Validating commits from $INPUT to HEAD."
fi

###############################################################################
# Ensure commits exist
###############################################################################

if [ -z "$COMMITS" ]; then
	echo "No commits found to validate."
	exit 1
fi

COMMIT_COUNT=$(echo "$COMMITS" | wc -l)
echo "Found $COMMIT_COUNT commits to validate."

COUNT=0
SUCCESSFUL=true

###############################################################################
# Main validation loop
#
# For each commit:
# 1. Checkout the commit
# 2. Run validation steps
# 3. Abort early if validation fails
###############################################################################

while read -r COMMIT_HASH COMMIT_MESSAGE; do
	COUNT=$((COUNT + 1))
	echo "[$COUNT/$COMMIT_COUNT] Checking commit: $COMMIT_HASH - $COMMIT_MESSAGE"

	###############################################################################
	# Checkout commit
	#
	# Errors are captured so the user can inspect them if checkout fails.
	###############################################################################

	git checkout "$COMMIT_HASH" &>/tmp/checkout-error.log || {
		echo "Failed to checkout $COMMIT_HASH:"
		cat /tmp/checkout-error.log
		SUCCESSFUL=false
		break
	}

	###############################################################################
	# Run all validation steps
	#
	# Output is captured so that failures can be inspected after validation.
	###############################################################################

	if ! (
		cargo check &&
		cargo doc &&
		cargo doc --document-private-items &&
		cd fuzz &&
		RUSTFLAGS="--cfg=fuzzing --cfg=secp256k1_fuzz --cfg=hashes_fuzz" \
			cargo check --features=stdin_fuzz &&
		cd ../lightning &&
		cargo check --no-default-features &&
		cd .. &&
		RUSTC_BOOTSTRAP=1 RUSTFLAGS="--cfg=c_bindings" \
			cargo check -Z avoid-dev-deps
	) &>/tmp/validation-error.log; then
		echo "Error during validation of $COMMIT_HASH:"
		cat /tmp/validation-error.log
		SUCCESSFUL=false
		break
	fi

	echo "[$COUNT/$COMMIT_COUNT] Commit validated successfully."

done <<< "$COMMITS"

###############################################################################
# Restore repository state
###############################################################################

cleanup

###############################################################################
# Final result
###############################################################################

if [ "$SUCCESSFUL" = true ]; then
	echo "Validation completed successfully for $COUNT commits."
else
	echo "Validation encountered errors."
	exit 1
fi