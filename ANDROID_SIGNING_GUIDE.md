# Android APK Signing Guide

This guide explains how to set up Android APK signing for production releases.

## Overview

Android requires all APKs to be digitally signed before installation on devices. This guide covers two approaches:

1. **Debug Signing** (for development/testing)
2. **Release Signing** (for production)

---

## Option 1: Debug Signing (Development)

Debug APKs are automatically signed with a debug keystore. This is suitable for testing but not for production.

### Build Debug APK

```bash
cd frontend
flutter build apk --debug
```

The APK will be available at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## Option 2: Release Signing (Production)

For production releases, you need to create a keystore and configure signing.

### Step 1: Create Keystore

Generate a keystore file using keytool:

```bash
keytool -genkey -v -keystore ~/gemstone-app-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gemstone-app-key
```

**Parameters:**
- `-keystore`: Path to keystore file
- `-keyalg`: Key algorithm (RSA)
- `-keysize`: Key size (2048 bits)
- `-validity`: Valid for 10000 days (~27 years)
- `-alias`: Key alias name

**You will be prompted for:**
- Keystore password
- Key password
- First and last name
- Organizational unit
- Organization name
- City
- State
- Country code

### Step 2: Store Keystore Securely

Keep the keystore file in a secure location. **Never commit it to version control.**

```bash
# Move keystore to secure location
mv ~/gemstone-app-key.jks ~/.android/gemstone-app-key.jks

# Set permissions
chmod 600 ~/.android/gemstone-app-key.jks
```

### Step 3: Configure Signing in Flutter

Create or update `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=gemstone-app-key
storeFile=~/.android/gemstone-app-key.jks
```

### Step 4: Update android/app/build.gradle

Ensure signing configuration is present:

```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Step 5: Build Release APK

```bash
cd frontend
flutter build apk --release
```

The signed APK will be available at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## GitHub Actions Setup

### Step 1: Encode Keystore for GitHub Secrets

```bash
base64 -i ~/.android/gemstone-app-key.jks -o keystore-base64.txt
```

### Step 2: Add GitHub Secrets

In your GitHub repository settings, add the following secrets:

1. **KEYSTORE_BASE64**: Base64 encoded keystore file
2. **KEYSTORE_PASSWORD**: Keystore password
3. **KEY_ALIAS**: Key alias (e.g., gemstone-app-key)
4. **KEY_PASSWORD**: Key password

### Step 3: Update Workflow

The workflow will automatically use these secrets to sign the APK.

### Step 4: Trigger Build

Push a tag to trigger the signed build:

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## APK Information

### Check APK Signature

```bash
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

### Get APK Details

```bash
aapt dump badging build/app/outputs/flutter-apk/app-release.apk
```

### Get Certificate Information

```bash
keytool -list -v -keystore ~/.android/gemstone-app-key.jks
```

---

## Installation on Android Device

### Method 1: Direct Installation

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Manual Installation

1. Copy APK to device
2. Enable "Unknown Sources" in Settings > Security
3. Open file manager and tap APK
4. Follow installation prompts

### Method 3: Google Play Store

1. Create Google Play Console account
2. Create app listing
3. Upload AAB (App Bundle) file:
   ```bash
   flutter build appbundle --release
   ```
4. Follow Play Store submission process

---

## Troubleshooting

### Issue: "Keystore not found"

**Solution:**
```bash
# Verify keystore path
ls -la ~/.android/gemstone-app-key.jks

# Update key.properties with correct path
```

### Issue: "Invalid keystore format"

**Solution:**
```bash
# Recreate keystore
keytool -genkey -v -keystore ~/.android/gemstone-app-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gemstone-app-key
```

### Issue: "Wrong password"

**Solution:**
```bash
# Verify password
keytool -list -v -keystore ~/.android/gemstone-app-key.jks

# Update key.properties with correct password
```

### Issue: "Build fails with signing error"

**Solution:**
```bash
# Clean and rebuild
flutter clean
cd android && ./gradlew clean && cd ..
flutter build apk --release
```

---

## Security Best Practices

1. **Never commit keystore** to version control
2. **Use strong passwords** (minimum 8 characters)
3. **Keep backups** of keystore in secure location
4. **Use GitHub Secrets** for CI/CD pipelines
5. **Rotate keys** periodically (annually)
6. **Monitor certificate expiration** (10000 days from creation)

---

## Certificate Expiration

The generated certificate is valid for 10000 days (~27 years). Before expiration, you'll need to:

1. Create new keystore
2. Update signing configuration
3. Release new version with new certificate

---

## Additional Resources

- [Flutter APK Signing Documentation](https://flutter.dev/docs/deployment/android)
- [Android App Signing Guide](https://developer.android.com/studio/publish/app-signing)
- [Keytool Documentation](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html)

---

**Last Updated**: May 31, 2026
**Version**: 1.0.0
