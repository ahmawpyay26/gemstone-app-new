# 📱 Android APK Build Guide (Step-by-Step)

ကျောက်မျက်ရတနာ စီမံခန့်ခွဲမှု App ကို Android ဖုန်းမှာ ထည့်သွင်းအသုံးပြုနိုင်ရန် APK Build လုပ်နည်း လမ်းညွှန်ဖြစ်ပါတယ်။

## 🛠 အဆင့် (၁) - လိုအပ်သော Software များ တင်ခြင်း
၁။ **Flutter SDK**: [flutter.dev](https://docs.flutter.dev/get-started/install) မှ နောက်ဆုံး Version ကို Download လုပ်ပြီး Install လုပ်ပါ။
၂။ **Android Studio**: Android SDK နှင့် Build Tools များအတွက် လိုအပ်သည်။ [developer.android.com](https://developer.android.com/studio) မှ Download လုပ်ပါ။
၃။ **Git**: Code များကို စီမံခန့်ခွဲရန် လိုအပ်သည်။

## 🛠 အဆင့် (၂) - Environment Configuration
၁။ **Flutter Doctor**: Terminal တွင် `flutter doctor` ဟု ရိုက်ပြီး အားလုံး အမှန်ခြစ် (✅) ဖြစ်အောင် လုပ်ပါ။
၂။ **Android Licenses**: `flutter doctor --android-licenses` ကို ရိုက်ပြီး အားလုံးကို `y` နှိပ်၍ လက်ခံပါ။

## 🛠 အဆင့် (၃) - Firebase Setup (Backend အတွက်)
၁။ [Firebase Console](https://console.firebase.google.com/) သို့ သွားပါ။
၂။ Project အသစ်တစ်ခု တည်ဆောက်ပါ။
၃။ Android App ကို Add လုပ်ပြီး `google-services.json` ဖိုင်ကို Download လုပ်ပါ။
၄။ အဆိုပါဖိုင်ကို `android/app/` folder ထဲသို့ ထည့်ပါ။

## 🛠 အဆင့် (၄) - App Configuration
၁။ **Package Name**: `android/app/build.gradle` ရှိ `applicationId` ကို သင့်လုပ်ငန်းနာမည် (ဥပမာ - `com.gemstone.management`) သို့ ပြောင်းပါ။
၂။ **App Name**: `android/app/src/main/AndroidManifest.xml` ရှိ `android:label` တွင် App နာမည် ပြောင်းပါ။

## 🛠 အဆင့် (၅) - Build Commands
Terminal (သို့မဟုတ်) VS Code Terminal တွင် အောက်ပါ Command များကို အစဉ်လိုက် ရိုက်ပါ။

```bash
# 1. Package များ Download လုပ်ရန်
flutter pub get

# 2. Local Database Code များ Generate လုပ်ရန်
flutter pub run build_runner build --delete-conflicting-outputs

# 3. APK Build လုပ်ရန် (Debug Version)
flutter build apk --debug

# 4. Release APK Build လုပ်ရန် (စက်ရုံထုတ် Version)
flutter build apk --release
```

## 🛠 အဆင့် (၆) - APK ဖိုင်ကို ရှာဖွေခြင်း
Build ပြီးသွားပါက သင်၏ APK ဖိုင်ကို အောက်ပါ Folder လမ်းကြောင်းတွင် တွေ့နိုင်ပါသည်-
`build/app/outputs/flutter-apk/app-release.apk`

---

## 💡 အရေးကြီးသော အချက်များ
- **Signing Key**: Play Store တင်မည်ဆိုပါက `key.jks` ဖိုင် တည်ဆောက်ပြီး `android/key.properties` တွင် သတ်မှတ်ပေးရပါမည်။
- **Min SDK Version**: ကျွန်ုပ်တို့၏ App သည် Offline Database နှင့် QR Scanner သုံးထားသောကြောင့် Min SDK ကို ၂၁ သို့မဟုတ် ထို့ထက်ပို၍ သတ်မှတ်ရပါမည်။
- **Permissions**: ကင်မရာ (QR Scanner အတွက်) နှင့် အင်တာနက် (Sync အတွက်) Permission များကို `AndroidManifest.xml` တွင် ထည့်သွင်းပြီး ဖြစ်ရပါမည်။
