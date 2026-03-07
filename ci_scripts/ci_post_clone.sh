#!/bin/sh

#  ci_post_clone.sh
#  QuickCalories
#
#  This script runs in Xcode Cloud after the repository is cloned.
#  It injects environment variables into Info.plist for secure secret management.

set -e  # Exit on any error

echo "Starting post-clone script..."

# Only run in CI environment
if [ -z "$CI" ]; then
    echo "Not running in CI environment, skipping secret injection"
    exit 0
fi

echo "CI_WORKSPACE: ${CI_WORKSPACE:-not set}"

# Derive repo root from this script's location (ci_scripts/ is at repo root)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
echo "Repo root: $REPO_ROOT"

# Use CI_WORKSPACE if set, otherwise fall back to derived repo root
WORKSPACE="${CI_WORKSPACE:-$REPO_ROOT}"
INFO_PLIST="${WORKSPACE}/QuickCalories/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo "Info.plist not found at expected path: $INFO_PLIST"
    echo "Searching under $WORKSPACE..."
    FOUND=$(find "$WORKSPACE" -name "Info.plist" -not -path "*/DerivedData/*" -not -path "*/.git/*" 2>/dev/null | head -1)
    if [ -z "$FOUND" ]; then
        echo "Error: Could not locate Info.plist anywhere under $WORKSPACE"
        exit 1
    fi
    INFO_PLIST="$FOUND"
fi

echo "Found Info.plist at: $INFO_PLIST"

# Helper: inject a key/value into the plist (delete first to ensure clean add)
inject_plist_value() {
    KEY="$1"
    VALUE="$2"
    /usr/libexec/PlistBuddy -c "Delete :${KEY}" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :${KEY} string ${VALUE}" "$INFO_PLIST"
}

# Inject APP_SECRET
if [ -n "$APP_SECRET" ]; then
    echo "Injecting APP_SECRET..."
    inject_plist_value "APP_SECRET" "$APP_SECRET"
else
    echo "Warning: APP_SECRET environment variable not set"
fi

# Inject PROXY_URL
if [ -n "$PROXY_URL" ]; then
    echo "Injecting PROXY_URL..."
    inject_plist_value "PROXY_URL" "$PROXY_URL"
else
    echo "Warning: PROXY_URL environment variable not set"
fi

echo "Post-clone script completed successfully"
echo "Build can proceed with injected secrets"
