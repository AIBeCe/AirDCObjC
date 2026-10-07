#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT/Build/RunDerivedData"
APP="$DERIVED_DATA/Build/Products/Debug/AirDCExample.app"
APP_BINARY="$APP/Contents/MacOS/AirDCExample"
mkdir -p "$ROOT/Build/Logs"

"$ROOT/scripts/generate-project"
xcodebuild build -quiet \
  -workspace "$ROOT/AirDCObjC.xcworkspace" \
  -scheme AirDCObjC \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  2>&1 | tee "$ROOT/Build/Logs/run-build.log"
test -d "$APP" || { echo "Built app not found at $APP" >&2; exit 1; }

open_app() { /usr/bin/open -n "$APP"; }
launched_app_pid() {
  local pid app_pids command
  app_pids="$(pgrep -x AirDCExample || true)"
  for pid in $app_pids; do
    command="$(/bin/ps -p "$pid" -o command= || true)"
    case "$command" in
      "$APP_BINARY"*) printf '%s\n' "$pid"; return 0 ;;
    esac
  done
  return 1
}
case "$MODE" in
  run) open_app ;;
  --debug|debug)
    open_app
    xcrun lldb --attach-name AirDCExample
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate 'process == "AirDCExample"'
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate 'subsystem == "org.airdcpp.AirDCExample"'
    ;;
  --verify|verify)
    open_app
    sleep 1
    launched_app_pid >/dev/null || { echo "Built AirDCExample did not launch from $APP_BINARY" >&2; exit 1; }
    ;;
  *) echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;;
esac
