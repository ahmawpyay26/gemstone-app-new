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

# Clear logcat so we only inspect events from THIS test run.
adb logcat -c || true

echo "=== Installing APK: $APK ==="
if ! adb install -r "$APK"; then
  echo "❌ APK installation failed"
  adb logcat -d | tail -60 || true
  exit 1
fi
echo "✅ APK installed"

echo "=== Launching app via monkey ==="
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 || true
sleep 12

# Resolve our app's PID (if running).
APP_PID="$(adb shell pidof "$PKG" 2>/dev/null | tr -d '\r')"
echo "App PID: '${APP_PID:-<none>}'"

echo "=== Crash check (scoped to our package only) ==="
# Pull the full logcat dump, then look for a FATAL EXCEPTION block that is
# attributable to OUR application. We deliberately ignore FATAL exceptions
# raised by unrelated system/Google services (e.g. UiThreadHelper in the
# Google app), which are background noise on GitHub-hosted emulators.
adb logcat -d > full_logcat.txt 2>/dev/null || true

CRASH=0
# Case 1: an AndroidRuntime crash block that names our package directly.
if grep -A 30 "FATAL EXCEPTION" full_logcat.txt | grep -q "$PKG"; then
  CRASH=1
fi
# Case 2: a crash line emitted by our PID.
if [ -n "${APP_PID:-}" ]; then
  if grep "FATAL EXCEPTION" full_logcat.txt | grep -qw "$APP_PID"; then
    CRASH=1
  fi
fi

if [ "$CRASH" = "1" ]; then
  echo "❌ Fatal crash detected for $PKG"
  grep -B2 -A40 "FATAL EXCEPTION" full_logcat.txt | tail -120 || true
  exit 1
fi
echo "✅ No fatal crash attributable to $PKG"

echo "=== Process check ==="
if [ -n "${APP_PID:-}" ]; then
  echo "✅ App process is running (pid $APP_PID)"
else
  # Re-check once more; the launcher activity may still be settling.
  sleep 3
  APP_PID="$(adb shell pidof "$PKG" 2>/dev/null | tr -d '\r')"
  if [ -n "${APP_PID:-}" ]; then
    echo "✅ App process is running (pid $APP_PID)"
  else
    echo "⚠️ App process not detected after launch (non-fatal signal)"
  fi
fi

echo "=== App-scoped logcat tail ==="
grep -i "$PKG\|flutter" full_logcat.txt | tail -30 || true

echo "✅ Smoke test finished successfully"
