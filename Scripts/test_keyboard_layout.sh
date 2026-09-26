#!/bin/bash
#
# Checks the keyboard's layout against the iOS 26 system keyboard.
#
# Compiles Scripts/test_keyboard_layout.swift together with the keyboard's layout
# sources for Mac Catalyst, where UIKit runs without a simulator, and runs it.
#
# Usage: Scripts/test_keyboard_layout.sh

set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

sdk=$(xcrun --sdk macosx --show-sdk-path)
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

xcrun -sdk macosx swiftc \
    -target "$(uname -m)-apple-ios18.0-macabi" \
    -sdk "$sdk" \
    -F "$sdk/System/iOSSupport/System/Library/Frameworks" \
    -parse-as-library \
    Keyboard/KeyboardModel.swift \
    Keyboard/DefaultKeyboard.swift \
    Keyboard/KeyboardLayout.swift \
    Keyboard/KeyboardKey.swift \
    Keyboard/ImageKey.swift \
    Keyboard/KeyboardKeyBackground.swift \
    Keyboard/CQNSHelper.swift \
    Scripts/test_keyboard_layout.swift \
    -o "$build/test_keyboard_layout"

"$build/test_keyboard_layout"
