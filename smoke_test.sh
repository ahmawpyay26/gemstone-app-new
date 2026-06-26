#!/usr/bin/env bash
# Emulator runtime smoke test for the Gemstone app.
# Runs INSIDE the reactivecircus/android-emulator-runner "script" context,
# where the emulator is already booted and adb is available.
set -uo pipefail

PKG="com.gemstone.management"
APK="artifact/app-release.apk"

echo "=== Devices ==="
adb devices

echo "=== Confirm boot completed ==="
adb shell getprop sys.boot_completed || true

# Dismiss the lock screen (best-effort)
adb shell input keyevent 82 || true
sleep 2

echo "=== Installing APK: $APK ==="
if ! adb install -r "$APK"; then
  echo "❌ APK installation failed"
  adb logcat -d | tail -60 || true
  exit 1
fi
echo "✅ APK installed"

echo "=== Launching app via monkey ==="
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 || true
sleep 10

echo "=== Crash check ==="
if adb logcat -d | grep -i "FATAL EXCEPTION"; then
  echo "❌ Fatal crash detected in logcat"
  adb logcat -d | tail -120 || true
  exit 1
fi
echo "✅ No fatal crash detected"

echo "=== Process check ==="
if adb shell pidof "$PKG" >/dev/null 2>&1; then
  echo "✅ App process is running"
else
  echo "⚠️ App process not detected after launch (non-fatal)"
fi

echo "=== Final logcat tail ==="
adb logcat -d | tail -40 || true

echo "✅ Smoke test finished successfully"
