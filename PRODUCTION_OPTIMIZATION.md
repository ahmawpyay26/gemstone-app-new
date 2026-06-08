# 🚀 Production Optimization Guide

App ကို Play Store တင်ရန် သို့မဟုတ် Release APK ထုတ်ရန်အတွက် အကောင်းဆုံး Optimization များ ဖြစ်ပါသည်။

## ၁။ APK အရွယ်အစား လျှော့ချခြင်း (Reduce APK Size)
App Size ကို သေးငယ်စေရန် အောက်ပါ Command ကို အသုံးပြု၍ Build လုပ်ပါ။
```bash
flutter build apk --release --split-debug-info=./debug-info --tree-shake-icons
```
- **Split Debug Info**: Debugging အချက်အလက်များကို သီးခြားခွဲထုတ်သဖြင့် APK Size သက်သာစေသည်။
- **Tree Shake Icons**: အသုံးမပြုသော Icon များကို ဖယ်ထုတ်ပေးသည်။

## ၂။ Performance & Startup Speed
- **AOT Compilation**: Flutter သည် Release mode တွင် Ahead-of-Time compilation ကို သုံးသဖြင့် အလွန်မြန်ဆန်သည်။
- **Image Optimization**: ပုံများကို WebP format သို့မဟုတ် Compressed PNG များအဖြစ်သာ အသုံးပြုပါ။
- **Memory Management**: အသုံးမပြုတော့သော Controller များနှင့် Streams များကို `dispose()` လုပ်ရန် မမေ့ပါနှင့်။

## ၃။ Code Shrinking & Security
- **R8/ProGuard**: မလိုအပ်သော Code များကို ဖယ်ထုတ်ရန် `android/app/build.gradle` တွင် `minifyEnabled true` ဟု သတ်မှတ်ပါ။
- **Obfuscation**: Code များကို Reverse Engineering လုပ်၍ မရအောင် အောက်ပါအတိုင်း Build လုပ်ပါ။
```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

## ၄။ Release Build Configurations
`android/app/build.gradle` တွင် အောက်ပါတို့ကို စစ်ဆေးပါ။
- `targetSdkVersion`: နောက်ဆုံး version (ဥပမာ - 34) ဖြစ်ရမည်။
- `ndk`: လိုအပ်သော Architecture (arm64-v8a) များသာ ထည့်သွင်းပါ။

---

## 🛠 Summary Checklist
- [ ] `minifyEnabled true` သတ်မှတ်ထားခြင်း။
- [ ] Debug print များ အားလုံးကို ဖယ်ရှားထားခြင်း။
- [ ] App Icon နှင့် Splash Screen များကို Optimize လုပ်ထားခြင်း။
- [ ] ProGuard Rules များ ထည့်သွင်းထားခြင်း။
