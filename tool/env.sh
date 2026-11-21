#!/usr/bin/env bash
# Environment for building pure_live against the Flutter-OH SDK.
#
# All paths are overridable via environment variables so this works on any
# machine. Set these before building (or edit the defaults below):
#
#   FLUTTER_OHOS_ROOT   root of the flutter_ohos checkout
#   DEVECO_SDK_HOME     DevEco Studio HarmonyOS SDK (Windows path)
#   JAVA_HOME           DevEco bundled JBR
#   ohpmBin             path to an ohpm shim used by hvigor
#
# Why these settings exist (each fixed a concrete build failure):
#   - DEVECO_SDK_HOME must be a Windows path; hvigor rejects /c/... input
#   - ohpmBin must point at a shim; DevEco's own ohpm.bat hits the cmd
#     recursion limit when hvigor calls it
#   - JAVA_HOME plus java on PATH is needed or PackageHap dies with
#     "spawn java ENOENT"
#
# The defaults are the original author's machine, kept only as examples.

# Git Bash PATH needs /c/... form, while these variables must stay as Windows
# paths for hvigor. Convert only for PATH; keep the originals untouched.
msys_path() {
  # Accept both C:/foo and C:\foo; Git Bash PATH always needs /c/foo.
  local p="${1//\\//}"
  case "$p" in
    [A-Za-z]:/*)
      local drive="${p%%:*}"
      printf '/%s%s' "$(printf '%s' "$drive" | tr 'A-Z' 'a-z')" "${p#*:}"
      ;;
    *) printf '%s' "$p" ;;
  esac
}

export FLUTTER_OHOS_ROOT="${FLUTTER_OHOS_ROOT:-C:/Users/Administrator/dev/flutter_ohos}"
export PATH="$(msys_path "$FLUTTER_OHOS_ROOT")/bin:$PATH"

export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-C:/deveco/DevEco Studio/sdk}"
export HOS_SDK_HOME="${HOS_SDK_HOME:-$DEVECO_SDK_HOME}"

# Some hosts inject a stale JAVA_HOME (e.g. an Adoptium path with no java.exe).
# Fall back to DevEco's bundled JBR whenever the configured home has no java.
fallback_jbr="C:/deveco/DevEco Studio/jbr"
configured_java="${JAVA_HOME:-$fallback_jbr}"
if [ ! -x "$(msys_path "$configured_java")/bin/java" ] && \
   [ ! -f "$(msys_path "$configured_java")/bin/java.exe" ]; then
  configured_java="$fallback_jbr"
fi
export JAVA_HOME="$configured_java"
export PATH="$(msys_path "$JAVA_HOME")/bin:$PATH"

export ohpmBin="${ohpmBin:-C:/Users/Administrator/dev/ohpm_shim/ohpm.bat}"

# China mirrors; override to use the official endpoints.
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
export FLUTTER_GIT_URL="${FLUTTER_GIT_URL:-https://atomgit.com/CPF-Flutter/flutter_flutter.git}"

export MSYS_NO_PATHCONV=1

echo "FLUTTER_OHOS_ROOT=$FLUTTER_OHOS_ROOT" >&2
echo "DEVECO_SDK_HOME=$DEVECO_SDK_HOME" >&2
