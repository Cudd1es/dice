#!/usr/bin/env bash
# Build and upload a TestFlight release.
#
#   scripts/release.sh [VERSION] [--yes] [--no-upload]
#
#   VERSION      new MARKETING_VERSION (SemVer X.Y.Z); omit to keep the current one
#   --yes        upload without asking
#   --no-upload  stop after the archive (nothing leaves this Mac, nothing is committed)
#
# The build number (CURRENT_PROJECT_VERSION) always goes up by one. After a successful upload the
# version bump is committed; if anything fails, project.yml is restored.
set -euo pipefail

cd "$(dirname "$0")/.."

version=""
assume_yes=false
upload=true
for arg in "$@"; do
    case "$arg" in
        --yes) assume_yes=true ;;
        --no-upload) upload=false ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        -*) echo "Unknown option: $arg" >&2; exit 2 ;;
        *) version="$arg" ;;
    esac
done

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree is not clean; commit or stash first." >&2
    exit 1
fi

current_version=$(sed -n 's/^ *MARKETING_VERSION: "\(.*\)"/\1/p' project.yml)
current_build=$(sed -n 's/^ *CURRENT_PROJECT_VERSION: "\(.*\)"/\1/p' project.yml)
version=${version:-$current_version}
build=$((current_build + 1))

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Version must be SemVer X.Y.Z (App Store Connect rejects suffixes such as -beta): $version" >&2
    exit 2
fi

echo "DND Dice $current_version ($current_build) -> $version ($build)"

restore() {
    git checkout -- project.yml 2>/dev/null || true
    echo "Restored project.yml." >&2
}
trap restore ERR

sed -i '' \
    -e "s/^\( *MARKETING_VERSION: \)\".*\"/\1\"$version\"/" \
    -e "s/^\( *CURRENT_PROJECT_VERSION: \)\".*\"/\1\"$build\"/" \
    project.yml
xcodegen generate >/dev/null

echo "Running tests..."
(cd DiceKit && swift test >/dev/null)
simulator=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
ios = [d for runtime, ds in devices.items() if "iOS" in runtime for d in ds if d["name"].startswith("iPhone")]
print(ios[-1]["udid"])')
xcodebuild test -project Dice.xcodeproj -scheme DiceApp -destination "id=$simulator" \
    -derivedDataPath .build/DD -only-testing:DiceMessagesTests -quiet

archive=".build/release/DiceApp-$version-$build.xcarchive"
echo "Archiving $archive..."
rm -rf "$archive"
xcodebuild archive -project Dice.xcodeproj -scheme DiceApp -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "$archive" -allowProvisioningUpdates -quiet

if ! $upload; then
    trap - ERR
    restore
    echo "Archive only: $archive (not uploaded, nothing committed)."
    exit 0
fi

if ! $assume_yes; then
    read -r -p "Upload DND Dice $version ($build) to App Store Connect? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        trap - ERR
        restore
        echo "Not uploaded."
        exit 0
    fi
fi

xcodebuild -exportArchive -archivePath "$archive" -exportOptionsPlist scripts/ExportOptions.plist \
    -exportPath ".build/release/export" -allowProvisioningUpdates

trap - ERR
git add project.yml
git commit -q -m "build: version $version (build $build) for TestFlight"
echo "Uploaded DND Dice $version ($build) and committed the version bump."
echo "Next: add the build to a TestFlight group and update What to Test (docs/testflight/beta-info.md)."
