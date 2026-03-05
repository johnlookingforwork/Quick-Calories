#!/bin/sh

#  ci_post_clone.sh
#  QuickCalories
#
#  This script runs in Xcode Cloud after the repository is cloned.
#  It injects environment variables into Info.plist for secure secret management.

set -e  # Exit on any error

echo "🔧 Starting post-clone script..."

# Only run in CI environment
if [ -z "$CI" ]; then
    echo "⚠️  Not running in CI environment, skipping secret injection"
    exit 0
fi

# Define Info.plist path (adjust target name if different)
INFO_PLIST="${CI_WORKSPACE}/QuickCalories/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo "❌ Error: Info.plist not found at $INFO_PLIST"
    exit 1
fi

echo "📝 Found Info.plist at: $INFO_PLIST"

# Inject APP_SECRET
if [ -n "$APP_SECRET" ]; then
    echo "🔐 Injecting APP_SECRET..."
    /usr/libexec/PlistBuddy -c "Add :APP_SECRET string ${APP_SECRET}" "$INFO_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :APP_SECRET ${APP_SECRET}" "$INFO_PLIST"
else
    echo "⚠️  Warning: APP_SECRET environment variable not set"
fi

# Inject PROXY_URL
if [ -n "$PROXY_URL" ]; then
    echo "🌐 Injecting PROXY_URL..."
    /usr/libexec/PlistBuddy -c "Add :PROXY_URL string ${PROXY_URL}" "$INFO_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :PROXY_URL ${PROXY_URL}" "$INFO_PLIST"
else
    echo "⚠️  Warning: PROXY_URL environment variable not set"
fi

echo "✅ Post-clone script completed successfully"
echo "📦 Build can proceed with injected secrets"
