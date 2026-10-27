#!/usr/bin/env bash

set -euo pipefail

readonly IOS_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$IOS_PROJECT_ROOT"

# Apply the geolocator SwiftPM flag while resolving and building its package.
export BYPASS_PERMISSION_LOCATION_ALWAYS=1

if [[ $# -eq 0 ]]; then
  set -- run
fi

exec flutter "$@"
