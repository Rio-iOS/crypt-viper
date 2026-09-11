#!/bin/bash
# Run the regression suite on an installed iPhone simulator.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${TEST_DESTINATION:-}" ]]; then
    simulator_id=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
for runtime, devices in sorted(json.load(sys.stdin)["devices"].items(), reverse=True):
    if ".iOS-" not in runtime:
        continue
    for device in devices:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
sys.exit("No available iPhone simulator. Install an iOS runtime in Xcode.")
')
    TEST_DESTINATION="platform=iOS Simulator,id=$simulator_id"
fi
xcodebuild -project CryptViper.xcodeproj -scheme CryptViper \
    -destination "$TEST_DESTINATION" \
    -derivedDataPath "${DERIVED_DATA_PATH:-build/DerivedData}" \
    CODE_SIGNING_ALLOWED=NO test
