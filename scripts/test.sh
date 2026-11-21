#!/usr/bin/env bash
# Runs the tests. With Xcode selected this is plain `swift test`. With CommandLineTools only,
# Swift Testing ships outside the default framework search path, so every target (including
# the runner SwiftPM generates) needs it added.
set -euo pipefail
cd "$(dirname "$0")/.."
developer="$(xcode-select -p)"
if [[ "$developer" != */CommandLineTools ]]; then
  exec swift test "$@"
fi
developer="$developer/Library/Developer"
exec swift test \
  -Xswiftc -F -Xswiftc "$developer/Frameworks" \
  -Xlinker -rpath -Xlinker "$developer/Frameworks" \
  -Xlinker -rpath -Xlinker "$developer/usr/lib" \
  "$@"
