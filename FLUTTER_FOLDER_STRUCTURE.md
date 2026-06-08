# 💎 Flutter Enterprise Clean Architecture Folder Structure

ကျောက်မျက်ရတနာ စီမံခန့်ခွဲမှု App အတွက် ရေရှည်ထိန်းသိမ်းရလွယ်ကူပြီး Scalable ဖြစ်စေမယ့် **Enterprise-level Clean Architecture** တည်ဆောက်ပုံ ဖြစ်ပါတယ်။

## 📂 Folder Overview

```text
lib/
├── core/                         # Shared components (တစ်စနစ်လုံးမှာ သုံးမယ့် အရာများ)
│   ├── constants/                # App constants, API endpoints
│   ├── errors/                   # Custom exceptions & failures
│   ├── network/                  # Dio client, interceptors
│   ├── usecases/                 # Base UseCase class
│   ├── utils/                    # Helper functions, formatters
│   ├── theme/                    # Dark Luxury theme configuration
│   ├── widgets/                  # Common UI components (Buttons, Inputs)
│   └── di/                       # Dependency Injection (GetIt)
│
├── features/                     # Feature-based Modules (လုပ်ဆောင်ချက်တစ်ခုချင်းစီအလိုက်)
│   ├── auth/                     # Authentication (Login, Register)
│   ├── inventory/                # Stone Inventory Management
│   ├── lot/                      # Bulk Lot Management
│   ├── expense/                  # Expense Tracking
│   ├── sales/                    # Sales & Commissions
│   ├── reports/                  # Profit/Loss & Reports
│   ├── worker/                   # Worker Management
│   ├── machine/                  # Machine Tracking
│   └── broker/                   # Broker Management
│
│   # Feature တစ်ခုချင်းစီအတွင်းရှိ Layers များ:
│   ├── data/                     # Data Layer
│   │   ├── datasources/          # Remote (API) & Local (Database)
│   │   ├── models/               # Data Transfer Objects (DTOs)
│   │   └── repositories/         # Repository Implementations
│   ├── domain/                   # Domain Layer (Business Logic)
│   │   ├── entities/             # Plain Dart Objects
│   │   ├── repositories/         # Repository Interfaces
│   │   └── usecases/             # Feature-specific business logic
│   └── presentation/             # Presentation Layer (UI)
│       ├── bloc/                 # BLoC/Cubit State Management
│       ├── pages/                # Screens
│       └── widgets/              # Feature-specific widgets
│
└── main.dart                     # App Entry Point
```

## 🛠 Key Architecture Components

### 1. State Management (BLoC)
- **BLoC (Business Logic Component)** ကို အသုံးပြုပြီး UI နဲ့ Business Logic ကို သီးခြားစီ ခွဲထုတ်ထားပါတယ်။
- Feature တစ်ခုချင်းစီမှာ သူ့ရဲ့ကိုယ်ပိုင် `bloc` folder ပါဝင်ပါတယ်။

### 2. Repository Pattern
- **Domain Layer** မှာ Interface (Abstract Class) အနေနဲ့ သတ်မှတ်ပြီး **Data Layer** မှာ အကောင်အထည်ဖော် (Implementation) ထားပါတယ်။
- ဒါဟာ UI ကို Data Source (API သို့မဟုတ် Database) ကနေ လွတ်လပ်စေပါတယ်။

### 3. API Layer (Remote Data Source)
- **Dio** နဲ့ **Retrofit** ကို အသုံးပြုပြီး Backend APIs တွေနဲ့ ချိတ်ဆက်ပါတယ်။
- `core/network` မှာ Interceptors တွေနဲ့ Error Handling တွေကို ဗဟိုကနေ ထိန်းချုပ်ပါတယ်။

### 4. Offline Database (Local Data Source)
- **Drift (SQLite)** သို့မဟုတ် **Hive** ကို အသုံးပြုပြီး Offline Support အတွက် Local Data တွေကို သိမ်းဆည်းပါတယ်။
- `data/datasources/local` မှာ အလုပ်လုပ်ပါတယ်။

### 5. Dependency Injection (DI)
- **GetIt** ကို အသုံးပြုပြီး Class Instance တွေကို တစ်နေရာတည်းကနေ စီမံခန့်ခွဲပါတယ်။
- `core/di` မှာ Injection Container ကို တည်ဆောက်ပါတယ်။

---

## 🚀 Module Details

| Module | Purpose |
|--------|---------|
| **Auth** | Login, Register, Token Management, User Profile |
| **Inventory** | Stone List, Add/Edit Stone, QR Scanning |
| **Lot** | Bulk Purchase, Lot Splitting to Individual Stones |
| **Expense** | Recording worker costs, machines, oil, tools |
| **Sales** | Individual/Lot Sales, Broker Commissions |
| **Reports** | Automated Profit/Loss, Stock Reports |

---

ဒီတည်ဆောက်ပုံဟာ ကြီးမားတဲ့ Project တွေအတွက် အကောင်းဆုံးဖြစ်ပြီး Developer အများအပြား အတူတူ အလုပ်လုပ်ရာမှာလည်း ပဋိပက္ခမဖြစ်စေဘဲ အဆင်ပြေစေပါတယ်။
