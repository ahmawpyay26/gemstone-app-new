# Gemstone Management App - Installation Guide

Simple step-by-step guide to install the Gemstone Management App on your Android device.

---

## System Requirements

- **Android Version**: 5.0 (API 21) or higher
- **Storage**: Minimum 50MB free space
- **RAM**: Minimum 2GB RAM
- **Internet**: Optional (for sync only, app works offline)

---

## Installation Methods

### Method 1: Direct APK Installation (Easiest)

#### Step 1: Download APK

1. Visit the [Releases Page](https://github.com/yourusername/gemstone-management/releases)
2. Find the latest release version
3. Download `gemstone-app-release.apk`

#### Step 2: Enable Unknown Sources

1. Open **Settings** on your Android device
2. Go to **Security** or **Privacy**
3. Enable **Unknown Sources** or **Install from Unknown Sources**
   - Note: This option may be in different locations depending on Android version

#### Step 3: Install APK

1. Open **File Manager** or **Downloads**
2. Locate the downloaded `gemstone-app-release.apk`
3. Tap on the APK file
4. Tap **Install** when prompted
5. Wait for installation to complete
6. Tap **Open** or find app in app drawer

#### Step 4: Launch App

1. Open app drawer
2. Find **Gemstone Management** app
3. Tap to launch
4. Grant permissions when prompted
5. Start using the app

---

### Method 2: ADB Installation (For Developers)

#### Prerequisites

- Android SDK Platform Tools installed
- USB cable
- Developer Mode enabled on device

#### Steps

```bash
# Connect device via USB
# Enable USB Debugging in Developer Options

# Install APK
adb install gemstone-app-release.apk

# Verify installation
adb shell pm list packages | grep gemstone

# Launch app
adb shell am start -n com.gemstone.app/.MainActivity
```

---

### Method 3: Google Play Store (When Available)

1. Open **Google Play Store**
2. Search for "Gemstone Management"
3. Tap **Install**
4. Wait for installation
5. Tap **Open**

---

## First Launch

### Initial Setup

1. **Grant Permissions**
   - Storage access (for data backup)
   - Camera (for QR code scanning)
   - Notifications (for alerts)

2. **Create Account** (if required)
   - Enter username
   - Create password
   - Confirm email

3. **Login**
   - Enter credentials
   - Or use offline mode without login

4. **Configure Settings** (Optional)
   - Set default currency
   - Configure sync preferences
   - Enable notifications

### Offline Mode

The app works completely offline:
- All data stored locally in SQLite database
- No internet connection required
- Sync to backend when online (if configured)

---

## Troubleshooting

### Issue: "Installation blocked"

**Solution:**
1. Go to Settings > Security
2. Enable "Unknown Sources"
3. Try installing again

### Issue: "App won't open"

**Solution:**
1. Clear app cache:
   - Settings > Apps > Gemstone Management > Storage > Clear Cache
2. Restart device
3. Try opening app again

### Issue: "Not enough storage"

**Solution:**
1. Delete unnecessary files
2. Clear app cache
3. Uninstall unused apps
4. Try installing again

### Issue: "App crashes on startup"

**Solution:**
1. Uninstall app
2. Restart device
3. Reinstall app
4. Contact support if issue persists

### Issue: "Can't access data"

**Solution:**
1. Check storage permissions
2. Clear app data (WARNING: This will delete local data)
   - Settings > Apps > Gemstone Management > Storage > Clear Data
3. Reinstall app

### Issue: "Sync not working"

**Solution:**
1. Check internet connection
2. Verify API endpoint is correct
3. Check sync settings
4. Try manual sync
5. Contact support

---

## Uninstallation

### Method 1: Settings

1. Open **Settings**
2. Go to **Apps** or **Application Manager**
3. Find **Gemstone Management**
4. Tap **Uninstall**
5. Confirm uninstallation

### Method 2: App Drawer

1. Long-press app icon
2. Tap **Uninstall**
3. Confirm uninstallation

### Method 3: ADB

```bash
adb uninstall com.gemstone.app
```

---

## Data Backup

### Backup Local Data

The app stores data locally in SQLite database:
- Location: `/data/data/com.gemstone.app/databases/gemstone_app.db`
- Access: Requires root or ADB

### Backup via ADB

```bash
# Backup app data
adb backup -f gemstone-app-backup.ab com.gemstone.app

# Restore app data
adb restore gemstone-app-backup.ab
```

### Sync to Cloud

When backend is available:
1. Open app
2. Go to Settings
3. Enable "Cloud Sync"
4. Tap "Sync Now"
5. Data synced to backend

---

## Features Overview

### Offline Features (No Internet Required)

- ✅ Create and manage gemstones
- ✅ Record sales transactions
- ✅ Track expenses
- ✅ Manage workers
- ✅ Generate reports
- ✅ QR code tracking
- ✅ Notifications

### Online Features (When Connected)

- ✅ Sync data to backend
- ✅ Cloud backup
- ✅ Multi-device sync
- ✅ Real-time updates

---

## Performance Tips

1. **Clear Cache Regularly**
   - Settings > Apps > Gemstone Management > Storage > Clear Cache

2. **Update App**
   - Check for updates regularly
   - Install latest version for bug fixes

3. **Manage Storage**
   - Delete old records
   - Archive completed transactions
   - Clear temporary files

4. **Optimize Device**
   - Close unused apps
   - Restart device periodically
   - Update Android OS

---

## Security Tips

1. **Protect Your Device**
   - Use strong PIN/password
   - Enable biometric authentication
   - Keep Android OS updated

2. **Secure Your Data**
   - Enable app encryption
   - Use secure WiFi for sync
   - Backup data regularly

3. **Account Security**
   - Use strong password
   - Change password regularly
   - Don't share credentials

---

## Getting Help

### In-App Help

1. Open app
2. Go to Settings
3. Tap "Help" or "FAQ"
4. Browse help topics

### Contact Support

- **Email**: support@gemstone-app.com
- **Phone**: +1-XXX-XXX-XXXX
- **Website**: https://gemstone-app.com/support

### Report Issues

1. Go to Settings
2. Tap "Report Issue"
3. Describe problem
4. Submit report

### Community

- Join user community forum
- Share tips and tricks
- Get help from other users

---

## FAQ

**Q: Does the app work without internet?**
A: Yes! The app works completely offline with SQLite database.

**Q: Can I use the app on multiple devices?**
A: Yes, when backend sync is enabled, data syncs across devices.

**Q: How often should I backup data?**
A: Backup at least weekly, or after important transactions.

**Q: Can I export my data?**
A: Yes, go to Settings > Export to download data as CSV or Excel.

**Q: Is my data encrypted?**
A: Yes, data is encrypted both locally and during sync.

**Q: What happens if I uninstall the app?**
A: Local data is deleted. Backup before uninstalling.

**Q: Can I reinstall the app?**
A: Yes, reinstall anytime. Restore from backup if available.

**Q: How do I update the app?**
A: Download latest APK and install over existing app.

---

## Version Information

- **Current Version**: 1.0.0
- **Release Date**: May 31, 2026
- **Android Minimum**: API 21 (Android 5.0)
- **Android Target**: API 34 (Android 14)

---

## License

This app is proprietary software. All rights reserved.

---

**Last Updated**: May 31, 2026
**Version**: 1.0.0
