# Amor-pyay Deployment Guide

## Quick Start

### Prerequisites
- Git installed
- GitHub account
- Flutter SDK 3.19.0+
- Android SDK (for APK building)

## Step 1: Clone the Repository

```bash
git clone https://github.com/kyawswarhtun409-png/gemstone-app.git
cd gemstone-app
```

## Step 2: Update Your Repository

If you want to use your own GitHub repository:

### Option A: Create New Repository (Recommended)

1. Create a new repository on GitHub (e.g., `amor-pyay-app`)
2. Update the remote:
   ```bash
   git remote set-url origin https://github.com/YOUR_USERNAME/amor-pyay-app.git
   git push -u origin main
   ```

### Option B: Fork the Repository

1. Click "Fork" on the original repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/gemstone-app.git
   cd gemstone-app
   ```

## Step 3: Setup Flutter Project

```bash
cd frontend

# Install dependencies
flutter pub get

# Generate Drift database files
flutter pub run build_runner build

# Verify installation
flutter doctor
```

## Step 4: Build APK

### Local Build

#### Debug APK
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

#### Release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### GitHub Actions Build (Recommended)

1. Push code to GitHub:
   ```bash
   git add .
   git commit -m "Initial Amor-pyay setup"
   git push origin main
   ```

2. Go to GitHub repository → Actions tab
3. Select "Build Android APK" workflow
4. Click "Run workflow"
5. Wait for build to complete
6. Download APK from artifacts

## Step 5: Install APK on Android Device

### Method 1: Direct Installation
1. Download APK file to your computer
2. Connect Android device via USB
3. Enable USB debugging on device
4. Run:
   ```bash
   adb install path/to/app-release.apk
   ```

### Method 2: Manual Installation
1. Transfer APK to Android device
2. On device: Settings → Security → Enable "Unknown Sources"
3. Open file manager and tap APK file
4. Follow installation prompts

### Method 3: GitHub Artifacts
1. Go to GitHub Actions
2. Select latest successful build
3. Download APK artifact
4. Transfer to device and install

## Configuration

### Environment Variables

Create `.env` file in `frontend/` directory:

```env
# Database configuration
DB_NAME=gemstone_ecommerce.db

# App configuration
APP_NAME=Amor-pyay
APP_VERSION=1.0.0

# Feature flags
ENABLE_SYNC=false
ENABLE_CLOUD_BACKUP=false
```

### Android Configuration

Edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.amor.pyay"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

## Customization

### Change App Name

1. Edit `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <application
       android:label="Amor-pyay"
       ...
   />
   ```

2. Edit `pubspec.yaml`:
   ```yaml
   flutter:
     uses-material-design: true
   ```

### Change App Icon

1. Replace icon at: `android/app/src/main/res/mipmap-*/ic_launcher.png`
2. Rebuild APK

### Change App Colors

Edit `lib/core/theme/app_theme.dart`:

```dart
class AppTheme {
  static const Color primaryDark = Color(0xFF1a1a2e);
  static const Color primaryAccent = Color(0xFFd4af37); // Gold
  static const Color surfaceDark = Color(0xFF16213e);
  // ... more colors
}
```

## Troubleshooting

### Build Fails with "SDK not found"

```bash
flutter config --android-sdk /path/to/android/sdk
flutter doctor
```

### APK Installation Fails

1. Ensure device has enough storage (min 100MB)
2. Enable "Unknown Sources" in settings
3. Try debug APK first
4. Check Android version compatibility (min API 21)

### Database Errors

```bash
# Regenerate database
flutter clean
flutter pub get
flutter pub run build_runner build
```

### GitHub Actions Build Fails

1. Check Actions logs for errors
2. Verify `pubspec.yaml` is valid
3. Ensure all dependencies are available
4. Check Flutter version compatibility

## Testing

### Run Tests

```bash
cd frontend
flutter test
```

### Test on Emulator

```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch emulator_name

# Run app on emulator
flutter run
```

## Signing Release APK

For production release, sign the APK:

1. Create keystore:
   ```bash
   keytool -genkey -v -keystore ~/key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=../key.jks
   ```

3. Edit `android/app/build.gradle`:
   ```gradle
   signingConfigs {
       release {
           keyAlias keystoreProperties['keyAlias']
           keyPassword keystoreProperties['keyPassword']
           storeFile file(keystoreProperties['storeFile'])
           storePassword keystoreProperties['storePassword']
       }
   }
   ```

4. Build signed APK:
   ```bash
   flutter build apk --release
   ```

## Deployment Checklist

- [ ] Repository cloned/forked
- [ ] Flutter dependencies installed
- [ ] Database files generated
- [ ] APK built successfully
- [ ] APK installed on test device
- [ ] App launches without errors
- [ ] Core features tested:
  - [ ] Dashboard loads
  - [ ] Order creation works
  - [ ] Order list displays
  - [ ] Data persists after restart
- [ ] GitHub Actions configured
- [ ] Release APK signed (for production)
- [ ] Documentation updated
- [ ] Team notified of deployment

## Continuous Deployment

### Automatic APK Generation

Every push to `main` branch triggers:
1. Dependency installation
2. Code analysis
3. Test execution
4. APK building (debug & release)
5. Artifact upload (7-30 days retention)

### Manual Workflow Dispatch

Trigger build manually:
1. Go to GitHub Actions
2. Select "Build Android APK"
3. Click "Run workflow"
4. Select branch
5. Click "Run workflow"

## Version Management

### Semantic Versioning

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD`

### Release Notes

Create release notes in GitHub:

1. Go to Releases
2. Click "Create a new release"
3. Tag version: `v1.0.0`
4. Add release notes
5. Upload APK
6. Publish release

## Monitoring

### Check Build Status

```bash
# View GitHub Actions
gh run list --repo YOUR_USERNAME/amor-pyay-app

# View specific run
gh run view RUN_ID
```

### Logs

View build logs:
1. GitHub Actions → Select workflow run
2. Click job to expand logs
3. Search for errors/warnings

## Support

For issues or questions:
1. Check troubleshooting section
2. Review GitHub Issues
3. Contact development team
4. Check documentation files

## Additional Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Drift ORM**: https://drift.simonbinder.eu
- **GitHub Actions**: https://docs.github.com/en/actions
- **Android Development**: https://developer.android.com

---

**Last Updated**: June 2, 2026  
**Version**: 1.0.0
