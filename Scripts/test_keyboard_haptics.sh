#!/bin/bash
#
# Checks when the keyboard plays haptics, and that it reads the settings the
# app saves.
#
# Compiles Scripts/test_keyboard_haptics.swift together with all of the
# keyboard's sources for Mac Catalyst, where UIKit runs without a simulator, and
# runs it. The keyboard target builds in the Swift 5 language mode, and so does
# this.
#
# The checks change the keyboard's settings, which a program outside an app
# bundle keeps in ~/Library/Preferences under its own name. Each run takes a name
# of its own, so that two runs at once cannot change each other's settings, and
# deletes its preferences when it ends.
#
# Usage: Scripts/test_keyboard_haptics.sh

set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

name="test_keyboard_haptics_$$"
sdk=$(xcrun --sdk macosx --show-sdk-path)
build=$(mktemp -d)
trap 'rm -rf "$build"; defaults delete "$name" >/dev/null 2>&1 || true; rm -f "$HOME/Library/Preferences/$name.plist"' EXIT

xcrun -sdk macosx swiftc \
    -target "$(uname -m)-apple-ios18.0-macabi" \
    -sdk "$sdk" \
    -F "$sdk/System/iOSSupport/System/Library/Frameworks" \
    -parse-as-library \
    -swift-version 5 \
    Keyboard/*.swift \
    Scripts/test_keyboard_haptics.swift \
    -o "$build/$name"

"$build/$name"
