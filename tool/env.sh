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

export FLUTTER_OHOS_ROOT="${FLUTTER_OHOS_ROOT:-C:/Users/Administrator/dev/flutter_ohos}"
export PATH="$FLUTTER_OHOS_ROOT/bin:$PATH"

export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-C:/deveco/DevEco Studio/sdk}"
export HOS_SDK_HOME="${HOS_SDK_HOME:-$DEVECO_SDK_HOME}"

export JAVA_HOME="${JAVA_HOME:-C:/deveco/DevEco Studio/jbr}"
export PATH="$JAVA_HOME/bin:$PATH"

export ohpmBin="${ohpmBin:-C:/Users/Administrator/dev/ohpm_shim/ohpm.bat}"

# China mirrors; override to use the official endpoints.
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
export FLUTTER_GIT_URL="${FLUTTER_GIT_URL:-https://atomgit.com/CPF-Flutter/flutter_flutter.git}"

export MSYS_NO_PATHCONV=1

echo "FLUTTER_OHOS_ROOT=$FLUTTER_OHOS_ROOT" >&2
echo "DEVECO_SDK_HOME=$DEVECO_SDK_HOME" >&2
