#!/bin/sh
# Builds a signed test APK without the Android SDK (only Java + Godot 4.6.2 with its
# export templates installed). Usage: tools/android/build_apk.sh <godot-binary> [out.apk]
#
# Godot exports the APK unsigned (the SDK checks are satisfied by a stub folder), then
# Sign.java signs it with APK Signature Scheme v2 (enough for Android 7+, the game's
# minimum) using apksig from Maven Central and tools/android/test-key.p12.
# test-key.p12 (password "android", alias "crimson") is a TEST key, public on purpose so
# every build installs over the last one. Never use it for a store release.
set -e
GODOT="$1"; OUT="${2:-ProtocolCrimson.apk}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"; WORK="$(mktemp -d)"
mkdir -p "$WORK/sdk/platform-tools" "$WORK/sdk/build-tools/35.0.0"
printf '#!/bin/sh\nexit 0\n' > "$WORK/sdk/platform-tools/adb"
printf '#!/bin/sh\nexit 0\n' > "$WORK/sdk/build-tools/35.0.0/apksigner"
chmod +x "$WORK/sdk/platform-tools/adb" "$WORK/sdk/build-tools/35.0.0/apksigner"
SETTINGS="$(ls "$HOME"/.config/godot/editor_settings-4*.tres | head -1)"
sed -i "s|^export/android/android_sdk_path = .*|export/android/android_sdk_path = \"$WORK/sdk\"|" "$SETTINGS"

cp "$ROOT/export_presets.cfg" "$WORK/presets.bak"
sed -i 's/^package\/signed=true/package\/signed=false/' "$ROOT/export_presets.cfg"
"$GODOT" --headless --path "$ROOT" --export-release "Android" "$WORK/unsigned.apk" || true
cp "$WORK/presets.bak" "$ROOT/export_presets.cfg"
[ -s "$WORK/unsigned.apk" ] || { echo "export failed"; exit 1; }

curl -sSL -o "$WORK/apksig.jar" https://repo1.maven.org/maven2/com/android/tools/build/apksig/2.3.0/apksig-2.3.0.jar
javac -d "$WORK" -cp "$WORK/apksig.jar" "$ROOT/tools/android/Sign.java"
java --add-exports java.base/sun.security.x509=ALL-UNNAMED \
     --add-exports java.base/sun.security.pkcs=ALL-UNNAMED \
     --add-exports java.base/sun.security.util=ALL-UNNAMED \
     -cp "$WORK/apksig.jar:$WORK" Sign "$ROOT/tools/android/test-key.p12" android crimson "$WORK/unsigned.apk" "$OUT"
rm -rf "$WORK"
