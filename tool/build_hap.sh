#!/usr/bin/env bash
# Builds the HarmonyOS debug HAP for pure_live.
#
# Wraps `flutter build hap` with the environment quirks this machine needs so
# the build is one command instead of a remembered sequence:
#   - tool/env.sh supplies the Flutter-OH SDK, DevEco SDK, JBR and ohpm shim.
#   - NODE_OPTIONS and the sandbox "safe-bin" shim are injected by the host
#     agent runtime. hvigor spawns node for its own work, inherits them, and
#     the shim's safe-delete hook blocks hvigor's temp cleanup until it times
#     out (ETIMEDOUT spawning genie-trash). Both are removed here.
#   - java must be reachable on PATH as well as JAVA_HOME, otherwise the
#     PackageHap step dies with "spawn java ENOENT".
#
# Usage: tool/build_hap.sh [extra flutter args]
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# shellcheck source=/dev/null
source tool/env.sh

unset NODE_OPTIONS
PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v 'sandbox-center-runtime-kit' | paste -sd: -)"
PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '\.workbuddy/binaries/node' | paste -sd: -)"
export PATH

echo "flutter: $(command -v flutter)"
echo "java:    $(command -v java)"
echo "node:    $(command -v node)"

flutter build hap --debug "$@"
