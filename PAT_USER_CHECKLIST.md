# 🧪 Production Acceptance Test - User Checklist

**No technical commands needed. Just follow the steps and report what you see.**

---

## 📱 Installation

1. **Download APK**
   - Go to GitHub Actions (link provided)
   - Download `gemstone-app-pat-verified.apk`
   - Save to your phone

2. **Install APK**
   - Open file manager on your Android phone
   - Find the APK file
   - Tap to install
   - Allow installation from unknown sources if prompted
   - Wait for "Installation complete"

3. **Launch App**
   - Find "Gemstone Management" app icon
   - Tap to open
   - Wait for login screen to appear

---

## ✅ Test 1: Super Admin Login

**Username**: `admin`  
**Password**: `admin123`

### What you should see:
- [ ] Login screen appears
- [ ] Can enter username and password
- [ ] Login button works
- [ ] Dashboard loads
- [ ] **ALL tabs visible at bottom**:
  - Dashboard
  - Inventory
  - Sales
  - Reports
  - Settings
- [ ] Can tap each tab and see content
- [ ] Edit, Delete, Export buttons visible
- [ ] No "Access Denied" messages

**Result**: ✅ PASS / ❌ FAIL

---

## ✅ Test 2: Staff A Login

**Username**: `staff_a`  
**Password**: `password123`

### What you should see:
- [ ] Login successful
- [ ] Dashboard loads
- [ ] **ONLY 2 tabs visible**:
  - ✅ Dashboard (visible)
  - ✅ Sales (visible)
- [ ] **These tabs HIDDEN**:
  - ❌ Inventory (not visible)
  - ❌ Reports (not visible)
  - ❌ Settings (not visible)
- [ ] Can view Dashboard
- [ ] Can view Sales
- [ ] Try tapping where Inventory should be - nothing happens or shows error

**Result**: ✅ PASS / ❌ FAIL

---

## ✅ Test 3: Staff B Login

**Username**: `staff_b`  
**Password**: `password123`

### What you should see:
- [ ] Login successful
- [ ] Dashboard loads
- [ ] **ONLY 2 tabs visible**:
  - ✅ Inventory (visible)
  - ✅ Purchase Records (visible)
- [ ] **These tabs HIDDEN**:
  - ❌ Dashboard (not visible)
  - ❌ Sales (not visible)
  - ❌ Reports (not visible)
  - ❌ Settings (not visible)
- [ ] Can view Inventory
- [ ] Can view Purchase Records
- [ ] Try tapping where Sales should be - nothing happens or shows error

**Result**: ✅ PASS / ❌ FAIL

---

## ✅ Test 4: Staff C Login

**Username**: `staff_c`  
**Password**: `password123`

### What you should see:
- [ ] Login successful
- [ ] Dashboard loads
- [ ] **ONLY 1 tab visible**:
  - ✅ Reports (visible)
- [ ] **All other tabs HIDDEN**:
  - ❌ Dashboard (not visible)
  - ❌ Inventory (not visible)
  - ❌ Sales (not visible)
  - ❌ Settings (not visible)
- [ ] Can view Reports
- [ ] Try tapping where Sales should be - nothing happens or shows error

**Result**: ✅ PASS / ❌ FAIL

---

## ✅ Test 5: Access Denied Message

**As Staff A**, try to access Inventory:
- [ ] See message in Burmese: "ဤစာမျက်နှာကို အသုံးပြုခွင့် မရှိပါ။"
- [ ] Or English: "Access Denied"
- [ ] Cannot proceed to Inventory

**Result**: ✅ PASS / ❌ FAIL

---

## ✅ Test 6: Business Logic - Purchase

**As Super Admin or Staff B**:
- [ ] Can create new purchase record
- [ ] Can enter quantity
- [ ] Can save purchase
- [ ] Purchase appears in list
- [ ] Total stone count updates

**Result**: ✅ PASS / ❌ FAIL

---

## ✅ Test 7: Business Logic - Sales

**As Super Admin or Staff A**:
- [ ] Can create new sale record
- [ ] Can select items
- [ ] Can enter quantity
- [ ] Can save sale
- [ ] Sale appears in list
- [ ] Remaining stone count updates

**Result**: ✅ PASS / ❌ FAIL

---

## ✅ Test 8: Business Logic - Inventory

**As Super Admin or Staff B**:
- [ ] Can view inventory list
- [ ] Can see stone counts
- [ ] Can edit item details
- [ ] Can delete items
- [ ] Can export inventory

**Result**: ✅ PASS / ❌ FAIL

---

## ✅ Test 9: Button Permissions

**As Staff A** (Dashboard + Sales only):
- [ ] Edit button visible on Sales page
- [ ] Delete button visible on Sales page
- [ ] Export button visible (if available)
- [ ] Settings button NOT visible

**As Staff B** (Inventory + Purchase only):
- [ ] Edit button visible on Inventory page
- [ ] Delete button visible on Inventory page
- [ ] Export button visible (if available)
- [ ] Settings button NOT visible

**Result**: ✅ PASS / ❌ FAIL

---

## ✅ Test 10: Logout

**As any user**:
- [ ] Find logout button (usually in menu or settings)
- [ ] Tap logout
- [ ] Returned to login screen
- [ ] Can login as different user

**Result**: ✅ PASS / ❌ FAIL

---

## 📝 Final Report

### Summary
- Total Tests: 10
- Passed: _____ / 10
- Failed: _____ / 10

### Issues Found (if any)
```
[Describe any problems you encountered]
```

### Screenshots
Please take screenshots of:
1. Super Admin dashboard (all tabs visible)
2. Staff A dashboard (only Dashboard + Sales)
3. Staff B dashboard (only Inventory + Purchase)
4. Staff C dashboard (only Reports)
5. Access Denied message
6. Any errors or issues

### Overall Status
- ✅ **READY FOR PRODUCTION** (if all tests pass)
- ⚠️ **NEEDS FIXES** (if any tests fail)

---

## 📞 Need Help?

If you see any errors or crashes:
1. Note what you were doing
2. Take a screenshot
3. Report the issue

**Common issues**:
- App crashes on login → Try reinstalling APK
- Buttons not working → Try closing and reopening app
- Wrong tabs visible → Check you're logged in as correct user
