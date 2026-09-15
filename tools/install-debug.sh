#!/usr/bin/env bash
#
# Builds the debug APK once and installs it on every phone reachable over
# Wi-Fi, without wiping the app's data.
#
# The debug build is used by more than one person, each on their own phone,
# so every run brings all of them to the same build: every paired phone on the
# network gets it, including ones added later. tools/debug-devices.local names
# the phones that are expected every time — a listed phone that cannot be
# reached is reported and fails the run. The file is not committed because
# device serials are personal; tools/debug-devices.example shows the format.
#
# `flutter install` uninstalls the app before installing, which drops the
# saved login and all persisted state. `adb install -r` replaces the app in
# place instead — every debug build is signed with the same debug keystore,
# so Android accepts the update.
#
# Wireless debugging has to be paired once per phone: Developer options →
# Wireless debugging → Pair device with pairing code, then
# `adb pair <ip:port> <code>`. After that the phone announces itself on the
# network and is connected here whenever wireless debugging is on.
#
# Usage:
#   tools/install-debug.sh             every phone on Wi-Fi, plus listed ones
#   tools/install-debug.sh SERIAL...   only these phones
#   tools/install-debug.sh --list      reachable phones with their serial
set -euo pipefail

cd "$(dirname "$0")/.."

readonly APK="build/app/outputs/flutter-apk/app-debug.apk"
# applicationId plus the applicationIdSuffix that android/app/build.gradle
# adds for debug builds, so debug and release can coexist on one device.
readonly APP_ID="io.wertwerk.digitalesregister.debug"
readonly DEVICES_FILE="tools/debug-devices.local"

attached() {
  adb devices | tr -d '\r' | awk 'NR > 1 && $2 == "device" { print $1 }'
}

# Connects every paired phone that announces itself on the network but is not
# attached to adb yet. adb usually does this on its own; not always right
# after wireless debugging was switched on.
connect_announced() {
  local present name address
  present=$(attached)
  while IFS=$'\t' read -r name type address; do
    [[ "$type" == _adb-tls-connect* ]] || continue
    grep -qxF -e "$name.$type" -e "$address" <<<"$present" && continue
    adb connect "$address" >/dev/null </dev/null || true
    timeout 10 adb -s "$address" wait-for-device </dev/null || true
  done < <(adb mdns services | tr -d '\r' | tail -n +2)
}

# One line per attached phone: transport, serial, model. The transport name
# differs by connection (mDNS name, ip:port, USB serial), so phones are
# recognised by the serial they report themselves.
connected() {
  attached | while read -r transport; do
    printf '%s\t%s\t%s\n' "$transport" \
      "$(adb -s "$transport" shell getprop ro.serialno </dev/null | tr -d '\r')" \
      "$(adb -s "$transport" shell getprop ro.product.model </dev/null | tr -d '\r')"
  done
}

over_wifi() { # transport
  [[ "$1" == *._adb-tls-connect._tcp || "$1" =~ ^[0-9.]+:[0-9]+$ ]]
}

connect_announced
table=$(connected)

if [ "${1:-}" = "--list" ]; then
  awk -F'\t' 'NF { printf "%-20s %-20s %s\n", $2, $3, $1 }' <<<"$table"
  exit 0
fi

# Targets: serial, name and transport (empty when not reachable).
serials=()
labels=()
transports=()
add_target() { # serial label
  local transport
  transport=$(awk -F'\t' -v serial="$1" '$2 == serial { print $1; exit }' <<<"$table")
  serials+=("$1")
  labels+=("$2")
  transports+=("$transport")
}

if [ $# -gt 0 ]; then
  for serial in "$@"; do add_target "$serial" "$serial"; done
else
  if [ -f "$DEVICES_FILE" ]; then
    while read -r serial label; do
      [[ -z "$serial" || "$serial" == \#* ]] && continue
      add_target "$serial" "${label:-$serial}"
    done < <(tr -d '\r' <"$DEVICES_FILE")
  fi
  while IFS=$'\t' read -r transport serial model; do
    [ -n "$transport" ] && over_wifi "$transport" || continue
    [[ " ${serials[*]} " == *" $serial "* ]] && continue
    add_target "$serial" "$model ($serial)"
  done <<<"$table"
fi

if [ ${#serials[@]} -eq 0 ]; then
  echo "No phone on Wi-Fi and none listed in $DEVICES_FILE, nothing built." >&2
  exit 1
fi

# Report every phone before building, so one that is off the network shows up
# right away rather than after the build.
reachable=0
for i in "${!serials[@]}"; do
  if [ -n "${transports[$i]}" ]; then
    echo "Found ${labels[$i]} (${transports[$i]})"
    reachable=$((reachable + 1))
  else
    echo "Not reachable: ${labels[$i]} (${serials[$i]}) — wireless debugging off, other network, or not paired yet" >&2
  fi
done
if [ "$reachable" -eq 0 ]; then
  echo "No phone reachable, nothing built." >&2
  exit 1
fi

flutter build apk --debug

failed=0
summary=()
for i in "${!serials[@]}"; do
  label=${labels[$i]}
  transport=${transports[$i]}
  if [ -z "$transport" ]; then
    summary+=("NOT REACHABLE  $label")
    failed=1
    continue
  fi

  echo "Installing on $label..."
  out=$(adb -s "$transport" install -r "$APK" 2>&1 </dev/null) || true
  echo "$out"
  if grep -q '^Success' <<<"$out"; then
    summary+=("OK             $label")
    continue
  fi

  failed=1
  summary+=("FAILED         $label")
  if grep -q 'INSTALL_FAILED_UPDATE_INCOMPATIBLE' <<<"$out"; then
    cat >&2 <<MSG

The app on $label is signed differently, so it cannot be replaced.
Uninstalling is the only way forward — that DOES drop login and saved state:

  adb -s $transport uninstall $APP_ID
MSG
  fi
done

echo
printf '%s\n' "${summary[@]}"
exit "$failed"
