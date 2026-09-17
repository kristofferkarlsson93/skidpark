#!/usr/bin/env bash

set -euo pipefail

readonly E2E_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly E2E_APP_ID="com.krikar.skidpark.skidpark.e2e"
readonly E2E_APK="$E2E_PROJECT_ROOT/build/app/outputs/flutter-apk/app-debug.apk"
readonly E2E_FLOWS="$E2E_PROJECT_ROOT/e2e/maestro"
readonly E2E_FLUTTER_BIN="${SKIDPARK_E2E_FLUTTER_BIN:-flutter}"
readonly E2E_MAESTRO_BIN="${SKIDPARK_E2E_MAESTRO_BIN:-maestro}"
export MAESTRO_CLI_NO_ANALYTICS=1
export MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true

E2E_ANDROID_SDK="${SKIDPARK_E2E_ANDROID_SDK:-}"
if [[ -z "$E2E_ANDROID_SDK" && -f "$E2E_PROJECT_ROOT/android/local.properties" ]]; then
  E2E_ANDROID_SDK="$(sed -n 's/^sdk.dir=//p' "$E2E_PROJECT_ROOT/android/local.properties" | head -n 1)"
fi
if [[ -z "$E2E_ANDROID_SDK" ]]; then
  echo "Android SDK not found. Set SKIDPARK_E2E_ANDROID_SDK." >&2
  exit 1
fi
readonly E2E_ADB_BIN="$E2E_ANDROID_SDK/platform-tools/adb"

run_maestro_flow() {
  if [[ -n "${SKIDPARK_E2E_DEVICE:-}" ]]; then
    "$E2E_MAESTRO_BIN" --device "$SKIDPARK_E2E_DEVICE" test "$1"
  else
    "$E2E_MAESTRO_BIN" test "$1"
  fi
}

run_adb() {
  if [[ -n "${SKIDPARK_E2E_DEVICE:-}" ]]; then
    "$E2E_ADB_BIN" -s "$SKIDPARK_E2E_DEVICE" "$@"
  else
    "$E2E_ADB_BIN" "$@"
  fi
}

send_long_volume_down() {
  run_adb shell input keyevent --duration 800 KEYCODE_VOLUME_DOWN
}

cd "$E2E_PROJECT_ROOT"

echo "Building isolated E2E APK..."
"$E2E_FLUTTER_BIN" build apk --debug --android-project-arg skidpark-e2e=true

if [[ ! -f "$E2E_APK" ]]; then
  echo "Expected APK not found: $E2E_APK" >&2
  exit 1
fi

echo "Installing $E2E_APP_ID..."
run_adb install -r "$E2E_APK"

echo "Running lifecycle flow..."
run_maestro_flow "$E2E_FLOWS/01_ski_and_test_lifecycle.yaml"

echo "Running recording and analysis flow..."
run_maestro_flow "$E2E_FLOWS/02_record_and_analyze.yaml"

echo "Running recorder navigation flow..."
run_maestro_flow "$E2E_FLOWS/03_recorder_navigation_and_cancel.yaml"

echo "Running volume ownership flow..."
run_maestro_flow "$E2E_FLOWS/volume_steps/01_setup.yaml"
send_long_volume_down
run_maestro_flow "$E2E_FLOWS/volume_steps/02_open_and_back.yaml"
send_long_volume_down
run_maestro_flow "$E2E_FLOWS/volume_steps/03_select_ski.yaml"
send_long_volume_down
run_maestro_flow "$E2E_FLOWS/volume_steps/04_save_run.yaml"
send_long_volume_down
run_maestro_flow "$E2E_FLOWS/volume_steps/05_reopen.yaml"

echo "All SkidPark Android E2E flows passed."
