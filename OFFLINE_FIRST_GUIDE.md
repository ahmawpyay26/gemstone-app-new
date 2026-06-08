# 📱 Offline-first Architecture for Gemstone App

ကျောက်မျက်ရတနာ စီမံခန့်ခွဲမှု App အတွက် အင်တာနက်မရှိချိန်တွင်လည်း အလုပ်လုပ်နိုင်ပြီး Data ပျောက်ဆုံးမှုမရှိစေမယ့် **Offline-first Architecture** လမ်းညွှန်ဖြစ်ပါတယ်။

## 🛠 Architecture Components

### 1. Local Database (Drift/SQLite)
- **`app_database.dart`**: Local SQLite database schema ကို သတ်မှတ်ထားသည်။
- **Reactive Persistence**: Data ပြောင်းလဲမှုတိုင်းကို UI မှာ အချိန်နဲ့တပြေးညီ ပြသပေးသည်။
- **Conflict Resolution**: `insertOnConflictUpdate` ကို သုံးပြီး Local နဲ့ Cloud data ထပ်နေပါက နောက်ဆုံးအချက်အလက်ကိုသာ သိမ်းဆည်းသည်။

### 2. Sync Logic (Flag-based)
- **`isSynced` Flag**: Record တစ်ခုချင်းစီမှာ Cloud နဲ့ ချိတ်ဆက်ပြီး/မပြီး သိနိုင်ရန် Flag တစ်ခု ထည့်ထားသည်။
- **Offline Entry**: အင်တာနက်မရှိချိန်တွင် `isSynced = false` ဖြင့် Local မှာ သိမ်းသည်။
- **Background Sync**: အင်တာနက်ပြန်ရချိန်တွင် `isSynced = false` ဖြစ်နေသော record များကို Cloud သို့ အလိုအလျောက် ပေးပို့ (Push) သည်။

### 3. Repository Pattern (Local-First Strategy)
- **Fast Performance**: UI က အမြဲတမ်း Local Database ကနေ အရင်ဖတ်တဲ့အတွက် အင်တာနက်နှေးနေရင်တောင် App က မြန်ဆန်နေမည်။
- **Background Refresh**: Local data ကို ပြသနေစဉ်မှာပင် နောက်ကွယ်မှ Cloud data နဲ့ တိုက်ဆိုင်စစ်ဆေးပြီး လိုအပ်ပါက Update လုပ်ပေးသည်။

---

## 🚀 Data Loss Prevention (ဒေတာမပျောက်စေရန်)

၁။ **Atomic Writes**: Local Database မှာ အရင်ဆုံး အောင်မြင်စွာ သိမ်းပြီးမှသာ Cloud Sync ကို စတင်သည်။
၂။ **Retry Mechanism**: Cloud Sync မအောင်မြင်ပါက Flag ကို `false` အတိုင်းထားပြီး နောက်တစ်ကြိမ် အင်တာနက်ရချိန်တွင် ထပ်မံကြိုးစားသည်။
၃။ **Idempotent APIs**: Backend APIs များသည် တူညီသော ID ဖြင့် Request ထပ်လာပါက Data ပွားမသွားစေရန် (Idempotent) တည်ဆောက်ထားသည်။

---

## 🛠 How to Implement

1. `pubspec.yaml` တွင် `drift`, `native_device_context`, `connectivity_plus` တို့ကို ထည့်ပါ။
2. `AppDatabase` class ကို အသုံးပြု၍ Local Tables များ တည်ဆောက်ပါ။
3. `GemstoneRepositoryImpl` တွင် ဖော်ပြထားသော Sync logic ကို အသုံးပြု၍ Data Flow ကို ထိန်းချုပ်ပါ။
