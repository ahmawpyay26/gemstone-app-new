# 🚀 Gemstone Management System - Backend Architecture

ကျောက်မျက်ရတနာ စီမံခန့်ခွဲမှု App အတွက် **Production-ready REST API Backend** တည်ဆောက်ပုံ ဖြစ်ပါတယ်။

## 🛠 Technology Stack
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** PostgreSQL
- **ORM:** Sequelize
- **Authentication:** JWT (JSON Web Token)

## 📂 Architecture Modules

### 1. Authentication Module
- User Registration & Login
- Role-based Access Control (Owner, Accountant, Worker, Broker)
- JWT Token verification middleware

### 2. Inventory & Lot Module
- **Gemstones:** တစ်လုံးချင်းစီ စီမံခန့်ခွဲခြင်း (CRUD)
- **Lots:** အစုလိုက်ဝယ်ယူမှုများနှင့် Lot Splitting logic
- **QR Code:** ကျောက်မျက်တစ်လုံးချင်းစီအတွက် QR code ခြေရာခံခြင်း

### 3. Expense Tracking Module
- ကျောက်တစ်လုံးချင်းစီအလိုက် ကုန်ကျစရိတ်မှတ်တမ်းတင်ခြင်း
- အလုပ်သမားခ၊ စက်ခ၊ ဆီ၊ ကိရိယာတန်ဆာပလာ စရိတ်များ
- Expense ထည့်လိုက်တိုင်း ကျောက်၏ `total_cost` ကို အလိုအလျောက် Update လုပ်ပေးခြင်း (Atomic Transactions)

### 4. Sales & Transactions Module
- Invoice အခြေခံ အရောင်းမှတ်တမ်းများ
- ကျောက်မျက်အများအပြားကို Invoice တစ်ခုတည်းဖြင့် ရောင်းချနိုင်ခြင်း
- ပွဲစားခ (Broker Commission) တွက်ချက်မှု

### 5. Reports & Analytics Module
- **Profit/Loss Report:** အသားတင် အမြတ်/အရှုံး တွက်ချက်မှု
- **Inventory Summary:** လက်ကျန်ကျောက်စာရင်းနှင့် တန်ဖိုး တွက်ချက်မှု

---

## 🔒 Security & Performance
- **Database Transactions:** ငွေရေးကြေးရေးနှင့် Lot Splitting ကဲ့သို့သော အရေးကြီးသည့် လုပ်ဆောင်ချက်များတွင် Data တိကျစေရန် Transactions များ အသုံးပြုထားသည်။
- **Password Hashing:** Bcryptjs အသုံးပြု၍ စကားဝှက်များကို လုံခြုံစွာ သိမ်းဆည်းသည်။
- **Validation:** API Request တိုင်းကို စနစ်တကျ စစ်ဆေးသည်။
- **Indexes:** PostgreSQL Indexes များဖြင့် Query Performance ကို မြှင့်တင်ထားသည်။

---

## 🚀 How to Run
1. `.env` ဖိုင်တွင် Database Connection အချက်အလက်များ ဖြည့်ပါ။
2. `npm install` လုပ်ပါ။
3. `npm start` ဖြင့် Server ကို စတင်ပါ။
