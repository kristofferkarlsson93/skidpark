#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../../../.." && pwd)"
local_properties="$repo_root/android/local.properties"
package_name="com.krikar.skidpark.skidpark"

read_property() {
  local key="$1"
  sed -n "s/^${key}=//p" "$local_properties" | tail -n 1
}

sdk_dir="${ANDROID_SDK_ROOT:-$(read_property sdk.dir)}"
flutter_sdk="$(read_property flutter.sdk)"
adb_path="$sdk_dir/platform-tools/adb"
emulator_path="$sdk_dir/emulator/emulator"
flutter_path="$flutter_sdk/bin/flutter"

adb_for_device() {
  if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    "$adb_path" -s "$ANDROID_SERIAL" "$@"
  else
    "$adb_path" "$@"
  fi
}

require_executable() {
  local path="$1"
  local description="$2"

  if [[ ! -x "$path" ]]; then
    echo "$description hittades inte: $path" >&2
    exit 1
  fi
}

require_argument() {
  local value="${1:-}"
  local description="$2"

  if [[ -z "$value" ]]; then
    echo "Argument saknas: $description" >&2
    exit 1
  fi
}

usage() {
  cat <<'EOF'
Användning: android_ui.sh <kommando> [argument]

  devices                         Lista anslutna Android-enheter
  avds                            Lista tillgängliga emulatorer
  boot [avd]                      Starta AVD, standard: Medium_Phone
  wait                            Vänta tills emulatorn har startat
  build                           Bygg en debug-APK
  install [apk]                   Installera APK, standard: projektets debug-APK
  launch                          Starta SkidPark
  stop                            Stoppa SkidPark-processen
  tap <x> <y>                     Tryck på skärmkoordinat
  swipe <x1> <y1> <x2> <y2> [ms] Svep, standardtid: 300 ms
  back                            Androids tillbaka-kommando
  screenshot [fil]                Spara PNG, standard: /private/tmp/skidpark-ui.png
  dump-ui [fil]                   Spara UI-hierarki som XML

Sätt ANDROID_SERIAL om flera enheter är anslutna.
EOF
}

command="${1:-help}"

case "$command" in
  devices)
    require_executable "$adb_path" "ADB"
    "$adb_path" devices -l
    ;;
  avds)
    require_executable "$emulator_path" "Android-emulatorn"
    "$emulator_path" -list-avds
    ;;
  boot)
    require_executable "$emulator_path" "Android-emulatorn"
    avd_name="${2:-Medium_Phone}"
    exec "$emulator_path" -avd "$avd_name" -no-snapshot-save
    ;;
  wait)
    require_executable "$adb_path" "ADB"
    adb_for_device wait-for-device
    for _ in {1..120}; do
      if [[ "$(adb_for_device shell getprop sys.boot_completed | tr -d '\r')" == "1" ]]; then
        echo "Emulatorn är klar."
        exit 0
      fi
      sleep 1
    done
    echo "Emulatorn blev inte klar inom 120 sekunder." >&2
    exit 1
    ;;
  build)
    require_executable "$flutter_path" "Flutter"
    cd "$repo_root"
    "$flutter_path" build apk --debug
    ;;
  install)
    require_executable "$adb_path" "ADB"
    apk_path="${2:-$repo_root/build/app/outputs/flutter-apk/app-debug.apk}"
    if [[ ! -f "$apk_path" ]]; then
      echo "APK hittades inte: $apk_path. Kör build först." >&2
      exit 1
    fi
    adb_for_device install -r "$apk_path"
    ;;
  launch)
    require_executable "$adb_path" "ADB"
    adb_for_device shell monkey -p "$package_name" -c android.intent.category.LAUNCHER 1
    ;;
  stop)
    require_executable "$adb_path" "ADB"
    adb_for_device shell am force-stop "$package_name"
    ;;
  tap)
    require_executable "$adb_path" "ADB"
    require_argument "${2:-}" "x"
    require_argument "${3:-}" "y"
    adb_for_device shell input tap "$2" "$3"
    ;;
  swipe)
    require_executable "$adb_path" "ADB"
    require_argument "${2:-}" "x1"
    require_argument "${3:-}" "y1"
    require_argument "${4:-}" "x2"
    require_argument "${5:-}" "y2"
    adb_for_device shell input swipe "$2" "$3" "$4" "$5" "${6:-300}"
    ;;
  back)
    require_executable "$adb_path" "ADB"
    adb_for_device shell input keyevent BACK
    ;;
  screenshot)
    require_executable "$adb_path" "ADB"
    output_path="${2:-/private/tmp/skidpark-ui.png}"
    mkdir -p "$(dirname "$output_path")"
    adb_for_device exec-out screencap -p > "$output_path"
    echo "$output_path"
    ;;
  dump-ui)
    require_executable "$adb_path" "ADB"
    output_path="${2:-/private/tmp/skidpark-ui.xml}"
    remote_path="/sdcard/skidpark-window.xml"
    mkdir -p "$(dirname "$output_path")"
    adb_for_device shell uiautomator dump "$remote_path"
    adb_for_device pull "$remote_path" "$output_path"
    echo "$output_path"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Okänt kommando: $command" >&2
    usage >&2
    exit 1
    ;;
esac
