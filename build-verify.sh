#!/bin/bash
#
# Pre-flight checks for The Na'vi Kit.
#
# Runs Scripts/preflight.py — project integrity, scene life cycle, App Store
# property list keys, privacy manifests, target membership and deprecated API —
# Scripts/test_keyboard_layout.sh and Scripts/test_keyboard_haptics.sh, then
# builds with xcodebuild when a toolchain is available.
#
# Usage: ./build-verify.sh

set -uo pipefail

cd "$(dirname "$0")" || exit 1

GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
BOLD=$'\033[1m'
NC=$'\033[0m'

if ! command -v python3 >/dev/null 2>&1; then
    printf '%spython3 is required to run these checks.%s\n' "$RED" "$NC"
    exit 1
fi

python3 Scripts/preflight.py
preflight_status=$?

printf '\n%sKeyboard layout%s\n' "$BOLD" "$NC"

if command -v xcrun >/dev/null 2>&1; then
    Scripts/test_keyboard_layout.sh | tail -n 1 | sed 's/^/  /'
    layout_status=${PIPESTATUS[0]}
else
    printf '  %s!%s xcrun not found — run this on a Mac with Xcode to check the layout.\n' \
        "$YELLOW" "$NC"
    layout_status=0
fi

printf '\n%sKeyboard haptics%s\n' "$BOLD" "$NC"

if command -v xcrun >/dev/null 2>&1; then
    Scripts/test_keyboard_haptics.sh | tail -n 1 | sed 's/^/  /'
    haptics_status=${PIPESTATUS[0]}
else
    printf '  %s!%s xcrun not found — run this on a Mac with Xcode to check the haptics.\n' \
        "$YELLOW" "$NC"
    haptics_status=0
fi

printf '\n%sBuild%s\n' "$BOLD" "$NC"

if ! command -v xcodebuild >/dev/null 2>&1; then
    printf '  %s!%s xcodebuild not found — run this on a Mac with Xcode 26 or later to compile.\n' \
        "$YELLOW" "$NC"
    exit "$preflight_status"
fi

xcodebuild -project Na-vi.xcodeproj \
    -scheme Na-vi \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | grep -E '(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)'
build_status=${PIPESTATUS[0]}

if [ "$build_status" -eq 0 ]; then
    printf '  %s✓%s xcodebuild succeeded\n' "$GREEN" "$NC"
else
    printf '  %s✗%s xcodebuild failed\n' "$RED" "$NC"
fi

if [ "$preflight_status" -ne 0 ] || [ "$layout_status" -ne 0 ] || [ "$haptics_status" -ne 0 ] || [ "$build_status" -ne 0 ]; then
    exit 1
fi
exit 0
