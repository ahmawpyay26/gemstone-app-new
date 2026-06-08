# GitHub Setup and Deployment Guide

Complete guide for setting up the Gemstone Management App on GitHub and configuring CI/CD pipeline.

---

## Prerequisites

- GitHub account
- Git installed locally
- Flutter SDK installed
- Android SDK installed
- Java 11 or higher

---

## Step 1: Create GitHub Repository

### 1.1 Create New Repository

1. Go to [GitHub](https://github.com/new)
2. Enter repository name: `gemstone-management`
3. Add description: `Professional Gemstone Trading and Processing Management Mobile Application`
4. Choose visibility: **Private** (recommended for production apps)
5. Initialize with:
   - [ ] Add .gitignore (already provided)
   - [ ] Add README (already provided)
   - [ ] Choose license (MIT or proprietary)
6. Click **Create repository**

### 1.2 Clone Repository

```bash
git clone https://github.com/yourusername/gemstone-management.git
cd gemstone-management
```

---

## Step 2: Push Code to GitHub

### 2.1 Initialize Git (if not cloned)

```bash
cd /home/ubuntu/gemstone-app/frontend
git init
git remote add origin https://github.com/yourusername/gemstone-management.git
```

### 2.2 Add Files

```bash
git add .
git commit -m "Initial commit: Flutter app with offline-first architecture"
```

### 2.3 Push to GitHub

```bash
git branch -M main
git push -u origin main
```

---

## Step 3: Configure GitHub Secrets

GitHub Secrets are used to securely store sensitive information like keystore passwords.

### 3.1 Generate Android Keystore

```bash
# Generate keystore (if not already done)
keytool -genkey -v -keystore ~/gemstone-app-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gemstone-app-key

# Encode to base64
base64 -i ~/gemstone-app-key.jks -o keystore-base64.txt
```

### 3.2 Add Secrets to GitHub

1. Go to repository **Settings**
2. Click **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

| Secret Name | Value |
|------------|-------|
| `KEYSTORE_BASE64` | Base64 encoded keystore file (from `keystore-base64.txt`) |
| `KEYSTORE_PASSWORD` | Your keystore password |
| `KEY_ALIAS` | `gemstone-app-key` |
| `KEY_PASSWORD` | Your key password |

### 3.3 Verify Secrets

```bash
# List secrets (GitHub CLI)
gh secret list
```

---

## Step 4: Configure Workflow

### 4.1 Workflow Files

The following workflow files are already created:

- `.github/workflows/build-apk.yml` - Automatic build on push
- `.github/workflows/build-signed-apk.yml` - Manual signed build

### 4.2 Workflow Triggers

**build-apk.yml** triggers on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual trigger (workflow_dispatch)

**build-signed-apk.yml** triggers on:
- Manual trigger with version input (workflow_dispatch)

### 4.3 Update Workflow (if needed)

Edit `.github/workflows/build-apk.yml` to customize:

```yaml
# Change Flutter version
flutter-version: '3.19.0'

# Change build targets
--target-platform android-arm64

# Change artifact retention
retention-days: 30
```

---

## Step 5: Build APK via GitHub Actions

### 5.1 Automatic Build (on Push)

1. Make changes and commit:
   ```bash
   git add .
   git commit -m "Update app features"
   git push origin main
   ```

2. GitHub Actions automatically triggers
3. Monitor build in **Actions** tab
4. Download APK from artifacts when complete

### 5.2 Manual Build (Workflow Dispatch)

1. Go to **Actions** tab
2. Select **Build Android APK** workflow
3. Click **Run workflow**
4. Wait for build to complete
5. Download APK from artifacts

### 5.3 Signed Release Build

1. Go to **Actions** tab
2. Select **Build Signed Release APK** workflow
3. Click **Run workflow**
4. Enter version (e.g., `1.0.0`)
5. Wait for build to complete
6. Download APK and AAB from artifacts

---

## Step 6: Create Release

### 6.1 Create Git Tag

```bash
# Create tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tag to GitHub
git push origin v1.0.0
```

### 6.2 Automatic Release Creation

When you push a tag, GitHub Actions automatically:
1. Builds signed APK
2. Creates GitHub Release
3. Uploads APK and AAB files
4. Adds release notes

### 6.3 Manual Release Creation

1. Go to **Releases** tab
2. Click **Create a new release**
3. Enter tag: `v1.0.0`
4. Enter title: `Gemstone Management v1.0.0`
5. Add release notes (see template below)
6. Upload APK and AAB files
7. Click **Publish release**

#### Release Notes Template

```markdown
# Gemstone Management App v1.0.0

## Features
- ✅ Offline-first SQLite database
- ✅ Full inventory management
- ✅ Sales and expense tracking
- ✅ Worker management
- ✅ Profit/Loss reports
- ✅ QR code tracking
- ✅ Notifications system

## Installation
1. Download `gemstone-app-release.apk`
2. Enable "Unknown Sources" in Android settings
3. Install the APK

## System Requirements
- Android 5.0 (API 21) or higher
- Minimum 50MB free storage

## Offline Mode
The app works completely offline with SQLite.

## Known Issues
- None reported

## Support
support@gemstone-app.com
```

---

## Step 7: Download and Install APK

### 7.1 Download from GitHub

1. Go to **Actions** tab
2. Select latest successful build
3. Scroll to **Artifacts** section
4. Download `gemstone-app-release` (or `gemstone-app-debug`)

### 7.2 Download from Releases

1. Go to **Releases** tab
2. Select release version
3. Download `gemstone-app-release.apk`

### 7.3 Install on Android Device

#### Method 1: ADB (via USB)

```bash
adb install gemstone-app-release.apk
```

#### Method 2: Manual Installation

1. Copy APK to device via USB
2. Enable "Unknown Sources" in Settings > Security
3. Open file manager
4. Tap APK file
5. Follow installation prompts

#### Method 3: Email/Cloud

1. Upload APK to cloud storage (Google Drive, Dropbox)
2. Share link with users
3. Users download and install

---

## Step 8: Continuous Integration

### 8.1 Branch Protection

1. Go to **Settings** → **Branches**
2. Add rule for `main` branch
3. Enable:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

### 8.2 Status Checks

Configure required checks:
- build-apk (must pass)
- flutter analyze (optional)
- flutter test (optional)

### 8.3 Deployment Protection

1. Go to **Settings** → **Environments**
2. Create `production` environment
3. Add deployment reviewers
4. Require manual approval for releases

---

## Step 9: Monitoring and Troubleshooting

### 9.1 Monitor Build Status

1. Go to **Actions** tab
2. View workflow runs
3. Click on run to see details
4. Check logs for errors

### 9.2 Common Issues

#### Issue: Build fails with "Flutter not found"

**Solution:**
```yaml
# Check workflow uses correct Flutter version
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.19.0'
```

#### Issue: APK not found in artifacts

**Solution:**
```bash
# Check build output path in workflow
path: frontend/build/app/outputs/flutter-apk/
```

#### Issue: Signing fails

**Solution:**
1. Verify secrets are set correctly
2. Check keystore is valid
3. Verify passwords are correct

### 9.3 View Logs

```bash
# Download workflow logs
gh run download <run-id>

# View specific workflow
gh run view <run-id>
```

---

## Step 10: Maintenance

### 10.1 Update Dependencies

```bash
cd frontend
flutter pub upgrade
git add pubspec.lock
git commit -m "Update dependencies"
git push origin main
```

### 10.2 Update Flutter Version

```yaml
# Update in workflow file
flutter-version: '3.20.0'
```

### 10.3 Rotate Keystore

Every 2-3 years:
1. Create new keystore
2. Update GitHub secrets
3. Release new version with new keystore

### 10.4 Monitor Releases

- Track download statistics
- Monitor crash reports
- Collect user feedback
- Plan improvements

---

## Quick Reference

### Common Commands

```bash
# Clone repository
git clone https://github.com/yourusername/gemstone-management.git

# Create and push tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# View workflow status
gh run list

# Download artifacts
gh run download <run-id>

# Create release
gh release create v1.0.0 gemstone-app-release.apk
```

### Workflow Status Badges

Add to README.md:

```markdown
![Build Status](https://github.com/yourusername/gemstone-management/workflows/Build%20Android%20APK/badge.svg)
```

---

## Support

For issues or questions:
- Check GitHub Issues
- Review workflow logs
- Contact support@gemstone-app.com

---

**Last Updated**: May 31, 2026
**Version**: 1.0.0
