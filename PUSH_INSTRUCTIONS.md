# Amor-pyay - Push Instructions and Setup Guide

## 📋 Overview

This document provides step-by-step instructions for pushing the Amor-pyay Ecommerce System to your GitHub repository and setting up the APK build pipeline.

## 🔑 Prerequisites

Before proceeding, ensure you have:
- Git installed on your computer
- GitHub account with repository access
- SSH key or personal access token configured for GitHub
- Flutter SDK 3.19.0 or higher
- Android SDK (for local APK building)

## 📁 What's Included

The Amor-pyay system includes the following new and updated files:

### New Files Created
```
frontend/lib/core/services/
├── admin_service.dart              # Super Admin controls
└── order_service.dart              # Order validation and management

frontend/lib/data/models/
└── ecommerce_models.dart           # Data models (Staff, Product, Customer, Order, etc.)

frontend/lib/presentation/pages/
├── order_create_page.dart          # Order creation interface
└── orders_list_page.dart           # Order management interface

Documentation/
├── AMOR_PYAY_README.md             # Complete system documentation
├── DEPLOYMENT_GUIDE.md             # Deployment instructions
├── IMPLEMENTATION_SUMMARY.md       # Technical implementation details
└── PUSH_INSTRUCTIONS.md            # This file
```

### Updated Files
```
frontend/lib/
├── main.dart                       # Updated app title to "Amor-pyay"
├── core/navigation/app_router.dart # Added order routes
└── presentation/pages/dashboard_page.dart # Added logo and Order Here button

frontend/lib/data/datasources/local/
└── app_database.dart               # Added ecommerce tables
```

## 🚀 Quick Start (5 Minutes)

### Step 1: Clone the Repository

```bash
git clone https://github.com/kyawswarhtun409-png/gemstone-app.git
cd gemstone-app
```

### Step 2: Verify the Changes

```bash
# Check the new files
ls -la frontend/lib/core/services/
ls -la frontend/lib/data/models/
ls -la frontend/lib/presentation/pages/

# View the documentation
cat AMOR_PYAY_README.md
```

### Step 3: Setup Flutter Project

```bash
cd frontend

# Install dependencies
flutter pub get

# Generate Drift database files
flutter pub run build_runner build

# Verify setup
flutter doctor
```

### Step 4: Build APK

#### Option A: GitHub Actions (Recommended)
```bash
# Push code to trigger automatic build
git add .
git commit -m "Setup Amor-pyay Ecommerce System"
git push origin main

# Go to GitHub Actions tab to monitor build
# Download APK from artifacts after build completes
```

#### Option B: Local Build
```bash
# Build release APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

## 📝 Detailed Push Instructions

### For New Repository

If you want to create a new repository for Amor-pyay:

#### 1. Create Repository on GitHub

1. Go to https://github.com/new
2. Enter repository name: `amor-pyay-app`
3. Add description: "Offline Ecommerce System for Gemstone Trading"
4. Choose visibility: Public or Private
5. Click "Create repository"

#### 2. Update Remote and Push

```bash
# Navigate to project
cd /home/ubuntu/gemstone-app

# Remove old remote
git remote remove origin

# Add new remote
git remote add origin https://github.com/YOUR_USERNAME/amor-pyay-app.git

# Verify remote
git remote -v

# Push code
git branch -M main
git push -u origin main
```

### For Existing Repository

If you're updating an existing repository:

#### 1. Update Remote (if needed)

```bash
# Check current remote
git remote -v

# Update if necessary
git remote set-url origin https://github.com/YOUR_USERNAME/gemstone-app.git
```

#### 2. Push Changes

```bash
# Navigate to project
cd /home/ubuntu/gemstone-app

# Check status
git status

# Add all changes
git add .

# Commit with descriptive message
git commit -m "Refactor to Amor-pyay Ecommerce System: 
- Add offline SQLite database with Drift ORM
- Implement Super Admin controls
- Add order validation and management
- Update UI with Amor-pyay branding
- Add Myanmar language support
- Include comprehensive documentation"

# Push to repository
git push origin main
```

## 🔧 Configuration Steps

### Step 1: Verify GitHub Actions

After pushing, verify that GitHub Actions is configured:

```bash
# Check if workflow file exists
ls -la .github/workflows/

# Should show:
# build-apk.yml
# build-signed-apk.yml
```

### Step 2: Monitor First Build

1. Go to your GitHub repository
2. Click "Actions" tab
3. Select "Build Android APK" workflow
4. Monitor the build progress
5. Download APK from artifacts when complete

### Step 3: Configure Secrets (Optional)

For signed APK builds, add GitHub secrets:

1. Go to Repository Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `KEYSTORE_BASE64`: Base64 encoded keystore file
   - `KEYSTORE_PASSWORD`: Keystore password
   - `KEY_ALIAS`: Key alias
   - `KEY_PASSWORD`: Key password

## 📦 APK Download Options

### Option 1: GitHub Actions Artifacts

```bash
# After successful build:
1. Go to GitHub Actions
2. Select latest successful build
3. Download APK artifact
4. Transfer to Android device
5. Install APK
```

### Option 2: GitHub Releases

```bash
# Create a release:
1. Go to Releases
2. Click "Create a new release"
3. Tag: v1.0.0
4. Upload APK file
5. Publish release
```

### Option 3: Direct Download Link

After build completes, GitHub provides direct download link:
```
https://github.com/YOUR_USERNAME/amor-pyay-app/actions/runs/{RUN_ID}
```

## 🔄 Continuous Integration Setup

### Automatic Builds

Every push to `main` branch triggers:
- Dependency installation
- Code analysis
- Test execution
- APK building (debug & release)
- Artifact upload

### Manual Trigger

To manually trigger a build:

```bash
# Using GitHub CLI
gh workflow run build-apk.yml --repo YOUR_USERNAME/amor-pyay-app

# Or through GitHub UI:
# 1. Go to Actions
# 2. Select "Build Android APK"
# 3. Click "Run workflow"
# 4. Select branch
# 5. Click "Run workflow"
```

## ✅ Verification Checklist

After pushing, verify the following:

- [ ] Repository created/updated on GitHub
- [ ] Code pushed successfully
- [ ] GitHub Actions workflow triggered
- [ ] Build completed without errors
- [ ] APK artifact available for download
- [ ] Documentation files present in repository
- [ ] All new files committed
- [ ] Git history shows commits

## 🐛 Troubleshooting

### Push Fails with "Permission Denied"

```bash
# Verify SSH key
ssh -T git@github.com

# Or use HTTPS with personal access token
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/amor-pyay-app.git
```

### Build Fails on GitHub Actions

1. Check Actions logs for error details
2. Verify `pubspec.yaml` is valid
3. Ensure all dependencies are available
4. Check Flutter version compatibility

### APK Installation Fails

1. Enable "Unknown Sources" in Android settings
2. Ensure device has sufficient storage (min 100MB)
3. Check Android version (min API 21)
4. Try debug APK first

## 📚 Documentation Files

Three comprehensive documentation files are included:

### AMOR_PYAY_README.md
Complete system overview including:
- Feature descriptions
- Architecture overview
- Database schema
- API documentation
- Installation guide
- Troubleshooting

### DEPLOYMENT_GUIDE.md
Step-by-step deployment instructions:
- Repository setup
- Flutter configuration
- APK building
- Installation methods
- Customization options
- Troubleshooting

### IMPLEMENTATION_SUMMARY.md
Technical implementation details:
- Architecture overview
- Database schema details
- Data models
- Business logic services
- UI updates
- File structure

## 🎯 Next Steps

1. **Review Documentation**
   ```bash
   cat AMOR_PYAY_README.md
   cat DEPLOYMENT_GUIDE.md
   cat IMPLEMENTATION_SUMMARY.md
   ```

2. **Setup Local Environment**
   ```bash
   cd frontend
   flutter pub get
   flutter pub run build_runner build
   ```

3. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Initial Amor-pyay setup"
   git push origin main
   ```

4. **Monitor Build**
   - Go to GitHub Actions
   - Wait for build completion
   - Download APK

5. **Test on Device**
   - Transfer APK to Android device
   - Enable Unknown Sources
   - Install and test

## 💡 Tips & Best Practices

### Commit Messages
Use descriptive commit messages:
```bash
git commit -m "Add order validation and management features"
git commit -m "Update dashboard with Amor-pyay branding"
git commit -m "Fix order creation validation logic"
```

### Branch Management
Create feature branches for development:
```bash
git checkout -b feature/payment-integration
# Make changes
git commit -m "Add payment integration"
git push origin feature/payment-integration
# Create pull request on GitHub
```

### Version Management
Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # MAJOR.MINOR.PATCH+BUILD
```

## 📞 Support

For issues or questions:

1. Check documentation files
2. Review GitHub Issues
3. Check Flutter documentation
4. Review Drift ORM documentation

## 🎉 Success Indicators

You've successfully completed setup when:

✅ Code pushed to GitHub  
✅ GitHub Actions build completed  
✅ APK artifact available for download  
✅ APK installed on Android device  
✅ App launches without errors  
✅ Dashboard displays with Amor-pyay branding  
✅ Order creation works  
✅ Data persists after app restart  

## 📄 Additional Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Drift ORM**: https://drift.simonbinder.eu
- **GitHub Actions**: https://docs.github.com/en/actions
- **Android Development**: https://developer.android.com
- **Git Documentation**: https://git-scm.com/doc

## 🔐 Security Notes

- Keep GitHub credentials secure
- Use personal access tokens instead of passwords
- Protect keystore files for signed APKs
- Review GitHub Actions secrets configuration
- Enable branch protection rules

---

**Version**: 1.0.0  
**Last Updated**: June 2, 2026  
**System**: Amor-pyay Ecommerce System  
**Platform**: Android (Flutter)

**Ready to deploy? Follow the Quick Start section above! 🚀**
