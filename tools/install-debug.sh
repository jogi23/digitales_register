#!/usr/bin/env bash
#
# Builds and installs the debug APK without wiping the app's data.
#
# `flutter install` uninstalls the app before installing, which drops the
# saved login and all persisted state. `adb install -r` replaces the app in
# place instead — every debug build is signed with the same debug keystore,
# so Android accepts the update.
#
# Usage: tools/install-debug.sh [device-id]
#   The device id is only needed when more than one device is attached
#   (`adb devices -l` lists them).
set -euo pipefail

cd "$(dirname "$0")/.."

readonly APK="build/app/outputs/flutter-apk/app-debug.apk"
# applicationId plus the applicationIdSuffix that android/app/build.gradle
# adds for debug builds, so debug and release can coexist on one device.
readonly APP_ID="io.wertwerk.digitalesregister.debug"

device_args=()
[ $# -gt 0 ] && device_args=(-s "$1")

flutter build apk --debug

echo "Installing to device..."
out=$(adb "${device_args[@]}" install -r "$APK" 2>&1) || true
echo "$out"

if ! grep -q '^Success' <<<"$out"; then
  if grep -q 'INSTALL_FAILED_UPDATE_INCOMPATIBLE' <<<"$out"; then
    cat >&2 <<MSG

The installed app is signed differently, so it cannot be replaced.
Uninstalling is the only way forward — that DOES drop login and saved state:

  adb ${device_args[*]} uninstall $APP_ID
MSG
  fi
  exit 1
fi
