# 🚀 Production Acceptance Testing (PAT) - Instructions

## Overview

The RBAC system is complete and ready for testing. This document explains what has been automated and what requires manual testing.

---

## ✅ What Was Automated (GitHub Actions)

The GitHub Actions workflow (`pat-production-acceptance.yml`) automatically performs these tests:

### 1. Code Quality Checks
- `flutter analyze` - Checks for code issues
- Code formatting verification
- **Status**: ✅ Automated

### 2. Build Process
- Builds release APK
- Verifies APK file exists
- **Status**: ✅ Automated

### 3. Emulator Runtime Tests
- Starts Android emulator
- Installs APK on emulator
- Launches app
- Verifies no crashes
- Confirms app process running
- **Status**: ✅ Automated

---

## ⚠️ What Requires Manual Testing (Your Phone)

These tests **cannot** be automated and require a real Android device:

1. **Login functionality** - Can you actually log in?
2. **Permission-based UI** - Are tabs hidden correctly?
3. **Business logic** - Do purchases, sales, inventory work?
4. **Route access** - Does access denied message appear?
5. **User experience** - Is the app usable?

---

## 🔄 How to Run PAT

### Step 1: Trigger GitHub Actions

1. Go to: https://github.com/ahmawpyay26/gemstone-app-new
2. Click **Actions** tab
3. Find **"PAT - Production Acceptance Testing"** workflow
4. Click **Run workflow**
5. Select **main** branch
6. Click **Run workflow** button
7. Wait for workflow to complete (about 15-20 minutes)

### Step 2: Download APK

1. Workflow completes with ✅ or ❌
2. Scroll down to **Artifacts** section
3. Download `gemstone-app-pat-verified.apk`
4. Save to your phone

### Step 3: Install & Test

1. Open file manager on Android phone
2. Find downloaded APK
3. Tap to install
4. Follow **PAT_USER_CHECKLIST.md** for testing steps

---

## 📊 Test Accounts

| Role | Username | Password | Permissions |
|------|----------|----------|-------------|
| Super Admin | `admin` | `admin123` | All features |
| Staff A | `staff_a` | `password123` | Dashboard + Sales |
| Staff B | `staff_b` | `password123` | Inventory + Purchase |
| Staff C | `staff_c` | `password123` | Reports only |

---

## 📋 What Gets Tested Automatically

### ✅ Automated Tests (GitHub Actions)

```
1. Code Quality
   ✅ flutter analyze passes
   ✅ Code formatting correct

2. Build
   ✅ APK builds successfully
   ✅ Release configuration applied

3. Emulator Runtime
   ✅ APK installs on emulator
   ✅ App launches without crash
   ✅ App process running
   ✅ No fatal exceptions in logs
```

### ⚠️ Manual Tests (Your Phone)

```
1. Super Admin (admin/admin123)
   - All tabs visible
   - All features work
   - No restrictions

2. Staff A (staff_a/password123)
   - Only Dashboard + Sales visible
   - Other tabs hidden
   - Cannot access restricted pages

3. Staff B (staff_b/password123)
   - Only Inventory + Purchase visible
   - Other tabs hidden
   - Cannot access restricted pages

4. Staff C (staff_c/password123)
   - Only Reports visible
   - All other tabs hidden
   - Cannot access restricted pages

5. Business Logic
   - Purchases work
   - Sales work
   - Inventory works
   - Counts update correctly
   - Export works
   - Audit log works

6. Access Control
   - Access denied message appears
   - Cannot bypass restrictions
   - Buttons hidden for unauthorized users
```

---

## 🔗 Important Links

| Item | Link |
|------|------|
| GitHub Repository | https://github.com/ahmawpyay26/gemstone-app-new |
| Actions Workflows | https://github.com/ahmawpyay26/gemstone-app-new/actions |
| Latest Commit | `3225c15` (PAT workflow added) |
| PAT Workflow File | `.github/workflows/pat-production-acceptance.yml` |

---

## 📝 How to Report Results

After testing on your phone:

1. **Complete the checklist** in `PAT_USER_CHECKLIST.md`
2. **Take screenshots** of:
   - Super Admin dashboard (all tabs)
   - Staff A dashboard (Dashboard + Sales only)
   - Staff B dashboard (Inventory + Purchase only)
   - Staff C dashboard (Reports only)
   - Access denied message
   - Any errors
3. **Report status**: PASS or FAIL for each test
4. **List any issues** found

---

## ⏱️ Estimated Timeline

| Step | Time |
|------|------|
| Trigger workflow | 1 minute |
| Workflow execution | 15-20 minutes |
| Download APK | 2-5 minutes |
| Install on phone | 2-3 minutes |
| Manual testing | 10-15 minutes |
| **Total** | **30-45 minutes** |

---

## 🆘 Troubleshooting

### Workflow fails to run
- Check GitHub Actions tab
- Verify main branch is selected
- Check for any error messages

### APK won't install
- Ensure Android 5.0 or higher
- Allow installation from unknown sources
- Try uninstalling previous version first

### App crashes on launch
- Check emulator logcat output
- Verify all dependencies installed
- Try reinstalling APK

### Can't log in
- Verify username and password are correct
- Check for typos (case-sensitive)
- Try clearing app cache

### Tabs not showing correctly
- Log out and log back in
- Try closing and reopening app
- Verify you're logged in as correct user

---

## 📞 Support

If you encounter issues:
1. Note what you were doing
2. Take a screenshot
3. Check the error message
4. Report the issue with details

---

## ✅ Success Criteria

PAT is **PASSED** when:
- ✅ All automated tests pass (GitHub Actions)
- ✅ APK installs successfully
- ✅ App launches without crash
- ✅ Super Admin has full access
- ✅ Staff A sees only Dashboard + Sales
- ✅ Staff B sees only Inventory + Purchase
- ✅ Staff C sees only Reports
- ✅ Access denied message appears for restricted pages
- ✅ Business logic works correctly
- ✅ No crashes or errors

---

## 🎯 Next Steps

1. Run PAT workflow on GitHub Actions
2. Download APK
3. Install on Android phone
4. Follow PAT_USER_CHECKLIST.md
5. Report results
6. If all pass → **READY FOR PRODUCTION** ✅
7. If any fail → Fix issues and retest

---

**Last Updated**: 2026-05-29  
**Status**: Ready for Production Acceptance Testing  
**Commit**: 3225c15
