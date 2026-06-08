# 🗄️ Gemstone Management System - Database Schema Guide

ကျောက်မျက်ရတနာ စီမံခန့်ခွဲမှု App အတွက် Production-ready ဖြစ်စေမယ့် PostgreSQL Database တည်ဆောက်ပုံ လမ်းညွှန်ဖြစ်ပါတယ်။

## 📋 Table Modules

### 1. User & Access Control
- **`users`**: စနစ်အသုံးပြုသူများ၏ အချက်အလက်များကို သိမ်းဆည်းသည်။ Role-based Access Control (Owner, Accountant, Worker, Broker) ကို အသုံးပြုထားသည်။

### 2. Inventory & Lot Management
- **`lots`**: အစုလိုက် (Bulk) ဝယ်ယူမှုများကို သိမ်းဆည်းသည်။ ဥပမာ - ကျောက်ရိုင်းတွဲ တစ်တွဲလုံး ဝယ်ယူခြင်း။
- **`gemstones`**: ကျောက်မျက် တစ်လုံးချင်းစီ၏ အချက်အလက်များ။ `lot_id` ပါဝင်ပါက အစုလိုက်ဝယ်ယူမှုမှ ခွဲထုတ်ထားခြင်းဖြစ်ပြီး၊ မပါဝင်ပါက တစ်လုံးချင်း တိုက်ရိုက်ဝယ်ယူခြင်းဖြစ်သည်။
- **`stone_status`**: ကျောက်မျက်၏ အခြေအနေကို ခြေရာခံသည်။ (`raw`, `in_process`, `polished`, `sold`, `waste`, `damaged`)

### 3. Expenses & Processing
- **`expenses`**: ကျောက်မျက် တစ်လုံးချင်းစီအတွက် ကုန်ကျစရိတ်များကို သိမ်းဆည်းသည်။
  - အလုပ်သမားခ (Worker Cost)
  - စက်ဆီ (Machine Oil)
  - သွေးသည့်ကိရိယာ (Grinding Tools)
  - အရောင်တင်ကိရိယာ (Polishing Tools)
- **`update_gemstone_cost` Trigger**: Expense တစ်ခု ထည့်လိုက်တိုင်း သက်ဆိုင်ရာ ကျောက်မျက်၏ `total_cost` ကို အလိုအလျောက် ပေါင်းထည့်ပေးသည်။

### 4. Sales & Profit
- **`sales`**: အရောင်းပြေစာ (Invoice) အချက်အလက်များ။
- **`sale_items`**: အရောင်းပြေစာတစ်ခုတွင် ပါဝင်သော ကျောက်မျက်များ။
- **`broker_commission`**: ပွဲစားခများကိုပါ တွက်ချက်နိုင်ရန် ထည့်သွင်းထားသည်။

---

## 📈 Profit Calculation Logic

စနစ်တွင် အမြတ်အစွန်းကို နည်းလမ်း ၂ ခုဖြင့် တွက်ချက်နိုင်ရန် View များ တည်ဆောက်ထားသည်-

1. **ကျောက်တစ်လုံးချင်းစီ၏ အမြတ် (`v_stone_profit_loss`)**:
   - `Net Profit = Sale Price - Total Cost (Purchase Price + All Expenses)`
2. **စုစုပေါင်း အရောင်းအစီရင်ခံစာ (`v_sales_report`)**:
   - `Net Profit = Gross Sales - Broker Commission - Total Cost of Goods`

---

## 🚀 Lot Splitting Workflow

Lot တစ်ခုကို တစ်လုံးချင်းစီ ခွဲထုတ်သည့်အခါ (Lot Splitting):
1. `lots` table ရှိ status ကို `split` ဟု ပြောင်းလဲသည်။
2. ခွဲထုတ်လိုက်သော ကျောက်မျက်အရေအတွက်အတိုင်း `gemstones` table တွင် record အသစ်များ တည်ဆောက်သည်။
3. `lot_id` ကို သက်ဆိုင်ရာ Lot ID နှင့် ချိတ်ဆက်သည်။
4. Lot ၏ ဝယ်ယူသည့်ဈေးနှုန်းကို ကျောက်အရေအတွက် သို့မဟုတ် အလေးချိန်အလိုက် `purchase_price` အဖြစ် ခွဲဝေသတ်မှတ်သည်။

---

## 🛠 Database Setup

1. PostgreSQL တွင် Database အသစ်တစ်ခု တည်ဆောက်ပါ။
2. `production_schema.sql` ဖိုင်ကို Run ပါ။
3. UUID extension လိုအပ်သောကြောင့် Superuser permission လိုအပ်နိုင်ပါသည်။
