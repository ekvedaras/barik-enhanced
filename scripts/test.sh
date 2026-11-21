#!/usr/bin/env bash
# Runs the Swift Testing tests with CommandLineTools only. Swift Testing ships there,
# outside the default framework search path, so every target (including the runner
# SwiftPM generates) needs it added.
set -euo pipefail
cd "$(dirname "$0")/.."
developer=/Library/Developer/CommandLineTools/Library/Developer
exec swift test \
  -Xswiftc -F -Xswiftc "$developer/Frameworks" \
  -Xlinker -rpath -Xlinker "$developer/Frameworks" \
  -Xlinker -rpath -Xlinker "$developer/usr/lib" \
  "$@"
