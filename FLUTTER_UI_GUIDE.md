# 💎 Flutter UI Screens Guide (Dark Luxury Style)

ကျောက်မျက်ရတနာ စီမံခန့်ခွဲမှု App အတွက် **Modern Dark Luxury UI** Screens များကို အောက်ပါအတိုင်း အသေးစိတ် တည်ဆောက်ထားပါသည်။

## 🎨 Visual Concept
- **Primary Background:** Deep Black (`#1a1a1a`) - ဇိမ်ခံဆန်ပြီး ကျောက်မျက်များ၏ အရောင်ကို ပိုမိုပေါ်လွင်စေသည်။
- **Accent Color:** Gold (`#d4af37`) - လုပ်ငန်း၏ အဆင့်အတန်းကို ဖော်ပြသည်။
- **Typography:** Poppins Font - ခေတ်မီပြီး ဖတ်ရလွယ်ကူသည်။
- **Components:** Rounded corners (16px), Subtle borders, Glassmorphism effects.

## 📱 Screens Overview

### 1. Dashboard (`dashboard_page.dart`)
- လုပ်ငန်း၏ စုစုပေါင်း အရောင်းနှင့် အမြတ်အစွန်း Summary များ။
- Quick Action Grid များဖြင့် လိုအပ်သော လုပ်ဆောင်ချက်များသို့ အမြန်သွားနိုင်ခြင်း။
- လတ်တလော အရောင်းအဝယ်မှတ်တမ်းများ။

### 2. Stone Inventory (`inventory_page.dart`)
- ကျောက်မျက်စာရင်းကို Filter များဖြင့် ကြည့်ရှုနိုင်ခြင်း။
- ကျောက်တစ်လုံးချင်းစီ၏ အသေးစိတ် (အလေးချိန်၊ အမျိုးအစား၊ အခြေအနေ)။
- QR Code icon နှင့် အမြန်အရောင်းခလုတ်များ။

### 3. Lot Management (`lot_page.dart`)
- အစုလိုက်ဝယ်ယူထားသော Lot စာရင်းများ။
- Lot Splitting (တစ်လုံးချင်းခွဲထုတ်ခြင်း) လုပ်ဆောင်ချက်။
- Lot တစ်ခုချင်းစီ၏ ဝယ်ယူသည့်ဈေးနှင့် အခြေအနေ။

### 4. Expense Tracking (`expense_page.dart`)
- ကုန်ကျစရိတ် Summary Header။
- လုပ်သားခ၊ စက်ခ၊ အထွေထွေစရိတ်များကို ကျောက်မျက် ID နှင့် ချိတ်ဆက်မှတ်တမ်းတင်ခြင်း။

### 5. Sales (`sales_page.dart`)
- အရောင်းပြေစာ (Invoice) ပုံစံ ဒီဇိုင်း။
- ပွဲစားခ (Broker Commission) နှင့် အသားတင်ရရှိငွေ တွက်ချက်မှုပြရပ်။
- Share နှင့် Print လုပ်ဆောင်ချက်များ။

### 6. Reports (`reports_page.dart`)
- အမြတ်/အရှုံး Chart များ။
- အမျိုးအစားအလိုက် အစီရင်ခံစာများ (Sales, Stock, Expenses)။

### 7. QR Scanner (`qr_scanner_page.dart`)
- ကင်မရာဖြင့် ကျောက်မျက် QR Code များကို စကင်ဖတ်နိုင်သည့် Interface။
- Flashlight နှင့် Manual Entry ထိန်းချုပ်မှုများ။

### 8. Settings (`settings_page.dart`)
- User Profile စီမံခန့်ခွဲမှု။
- လုပ်ငန်းဆက်တင်များ (Workers, Machines, Brokers)။
- Cloud Sync နှင့် Language ဆက်တင်များ။

---

## 🛠 How to Use
ဤ Screens များသည် `AppTheme` ပေါ်တွင် အခြေခံထားသောကြောင့် UI တစ်ခုလုံးသည် တစ်ပြေးညီဖြစ်နေမည်။ Navigation အတွက် `GoRouter` သို့မဟုတ် `Navigator` ကို အသုံးပြု၍ ချိတ်ဆက်နိုင်ပါသည်။
