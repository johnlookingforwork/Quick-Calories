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

echo "CI_WORKSPACE: ${CI_WORKSPACE}"
echo "CI_DERIVED_DATA_PATH: ${CI_DERIVED_DATA_PATH:-not set}"

# Try the standard path first, then fall back to finding it
INFO_PLIST="${CI_WORKSPACE}/QuickCalories/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo "Info.plist not found at expected path, searching..."
    FOUND=$(find "${CI_WORKSPACE}" -name "Info.plist" -not -path "*/DerivedData/*" -not -path "*/.git/*" 2>/dev/null | head -1)
    if [ -z "$FOUND" ]; then
        echo "Error: Could not locate Info.plist anywhere under ${CI_WORKSPACE}"
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
