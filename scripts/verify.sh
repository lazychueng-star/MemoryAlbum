#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly MODE="${1:-fast}"

usage() {
    cat <<'EOF'
Usage: scripts/verify.sh fast

Regenerates MemoryAlbum.xcodeproj from project.yml, builds Debug and Release,
and runs the unit-test bundle on the first available iPhone simulator.
EOF
}

if [[ "${MODE}" == "-h" || "${MODE}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "${MODE}" != "fast" ]]; then
    usage >&2
    exit 64
fi

for tool in xcodegen xcodebuild xcrun; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "error: ${tool} is required. Run this command on macOS with Xcode and XcodeGen installed." >&2
        exit 69
    fi
done

cd "${PROJECT_DIR}"

echo "Toolchain:"
xcodegen --version
xcodebuild -version
xcrun swift --version

rm -rf "${PROJECT_DIR}/MemoryAlbum.xcodeproj"
xcodegen generate --spec "${PROJECT_DIR}/project.yml" --project "${PROJECT_DIR}"

readonly DERIVED_DATA_PATH="${PROJECT_DIR}/.build/DerivedData"
readonly SIMULATOR_ID="$(
    xcrun simctl list devices available |
        awk '/iPhone/ {
            if (match($0, /\([0-9A-Fa-f-]+\)/)) {
                print substr($0, RSTART + 1, RLENGTH - 2)
                exit
            }
        }'
)"

if [[ -z "${SIMULATOR_ID}" ]]; then
    echo "error: no available iPhone simulator found." >&2
    exit 69
fi

readonly SIMULATOR_DESTINATION="platform=iOS Simulator,id=${SIMULATOR_ID}"

xcodebuild \
    -project MemoryAlbum.xcodeproj \
    -scheme MemoryAlbum \
    -resolvePackageDependencies

for configuration in Debug Release; do
    echo "Building ${configuration}..."
    xcodebuild \
        -quiet \
        -project MemoryAlbum.xcodeproj \
        -scheme MemoryAlbum \
        -configuration "${configuration}" \
        -destination "generic/platform=iOS Simulator" \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        build
done

echo "Running tests..."
xcodebuild \
    -quiet \
    -project MemoryAlbum.xcodeproj \
    -scheme MemoryAlbum \
    -configuration Debug \
    -destination "${SIMULATOR_DESTINATION}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    test
