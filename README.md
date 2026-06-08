# 💎 Gemstone Trading & Processing Management System

Professional Mobile Application for Gemstone Business Management

**Language:** Burmese (Myanmar) | **Design:** Dark Luxury | **Platform:** Flutter + Node.js + PostgreSQL

---

## 🌟 Features

### Core Functionality
- ✅ **User Authentication** - Secure login/register with JWT
- ✅ **Gemstone Inventory** - Track individual stones with QR codes
- ✅ **Lot Management** - Manage bulk gemstone lots
- ✅ **Processing Workflows** - Track polishing, cutting, and modifications
- ✅ **Expense Tracking** - Record worker costs, machine maintenance, tools
- ✅ **Sales Management** - Record sales transactions with broker commissions
- ✅ **Profit/Loss Calculation** - Automatic financial calculations
- ✅ **Offline Support** - Work without internet connection
- ✅ **Cloud Synchronization** - Sync data when online
- ✅ **QR Code Tracking** - Generate and scan QR codes for stones
- ✅ **Multi-user Roles** - Owner, Accountant, Worker, Broker

### Technical Features
- Clean Architecture (Presentation, Domain, Data layers)
- BLoC State Management
- RESTful API with JWT authentication
- PostgreSQL database with Sequelize ORM
- Drift for offline SQLite storage
- Dark luxury UI theme with Poppins font
- Responsive mobile design
- Error handling and validation

---

## 🏗️ Project Structure

```
gemstone-app/
├── backend/                    # Node.js + Express + PostgreSQL
│   ├── config/                # Database configuration
│   ├── controllers/           # Business logic
│   ├── models/                # Sequelize models
│   ├── routes/                # API endpoints
│   ├── middleware/            # Auth middleware
│   ├── utils/                 # Utility functions
│   ├── database/              # SQL schema
│   └── server.js              # Main server
│
├── frontend/                  # Flutter application
│   ├── lib/
│   │   ├── core/             # Shared components
│   │   ├── features/         # Feature modules
│   │   └── main.dart         # Entry point
│   └── pubspec.yaml          # Dependencies
│
└── Documentation
    ├── PHASE_1_SETUP.md
    ├── PHASE_2_DATABASE_AUTH.md
    ├── PHASE_3_FLUTTER_AUTH_UI.md
    ├── PROJECT_SUMMARY.md
    └── README.md
```

---

## 🚀 Quick Start

### Prerequisites
- **Node.js** v14+ (we have v22.13.0 ✅)
- **npm** v6+ (we have v10.9.2 ✅)
- **Flutter** 3.0+ (needs installation)
- **PostgreSQL** 12+ (needs installation)
- **Git** (for version control)

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd gemstone-app/backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create environment file:**
   ```bash
   cp .env.example .env
   ```

4. **Update .env with your PostgreSQL credentials:**
   ```
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=gemstone_db
   DB_USER=gemstone_user
   DB_PASSWORD=your_secure_password
   JWT_SECRET=your_jwt_secret_key
   ```

5. **Create PostgreSQL database:**
   ```bash
   psql -U postgres
   CREATE DATABASE gemstone_db;
   CREATE USER gemstone_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE gemstone_db TO gemstone_user;
   \q
   ```

6. **Run database schema:**
   ```bash
   psql -U gemstone_user -d gemstone_db -f database/schema.sql
   ```

7. **Start backend server:**
   ```bash
   npm start
   # or for development with auto-reload
   npm run dev
   ```

Backend will be running at: `http://localhost:3000`

### Frontend Setup

1. **Navigate to frontend directory:**
   ```bash
   cd gemstone-app/frontend
   ```

2. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate code (for Hive, Drift, Retrofit):**
   ```bash
   flutter pub run build_runner build
   ```

4. **Run on Android emulator:**
   ```bash
   flutter run
   ```

5. **Or build APK:**
   ```bash
   flutter build apk --release
   ```

---

## 🔐 Authentication

### Register
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe",
    "role": "owner"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

### Response
```json
{
  "status": "success",
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "owner"
    }
  }
}
```

---

## 🎨 Design System

### Color Palette
- **Primary Dark:** #1a1a1a (Deep Black)
- **Accent Gold:** #d4af37 (Premium Gold)
- **Secondary Bronze:** #8b7355 (Bronze)
- **Surface Dark:** #2d2d2d (Dark Gray)
- **Text Primary:** #ffffff (White)
- **Text Secondary:** #b0b0b0 (Light Gray)

### Typography
- **Font Family:** Poppins
- **Weights:** Regular (400), Medium (500), Semi-Bold (600), Bold (700)

### Components
- Rounded corners (8px for inputs, 12px for cards)
- Elevation (8px for cards)
- Gold accents for interactive elements
- Consistent spacing and padding

---

## 📊 Database Schema

### Main Tables
1. **users** - User authentication and roles
2. **gemstones** - Individual stone inventory
3. **lots** - Bulk gemstone lots
4. **lot_splits** - Lot splitting operations
5. **processing_records** - Polishing/cutting workflows
6. **workers** - Worker management
7. **machines** - Machine inventory
8. **expenses** - Cost tracking
9. **sales** - Sales transactions
10. **sale_items** - Items in each sale
11. **brokers** - Broker management
12. **waste_stones** - Waste/damaged tracking

See `backend/database/schema.sql` for complete schema.

---

## 📱 User Roles

| Role | Permissions |
|------|------------|
| **Owner** | Full system access, financial reports |
| **Accountant** | Expense tracking, financial reports |
| **Worker** | Process stones, record expenses |
| **Broker** | View sales, commission tracking |

---

## 🔄 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/refresh-token` - Refresh access token
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - Logout user

### Gemstones (Phase 4)
- `GET /api/gemstones` - List all gemstones
- `POST /api/gemstones` - Create gemstone
- `GET /api/gemstones/:id` - Get gemstone details
- `PUT /api/gemstones/:id` - Update gemstone
- `DELETE /api/gemstones/:id` - Delete gemstone

### Lots (Phase 4)
- `GET /api/lots` - List all lots
- `POST /api/lots` - Create lot
- `POST /api/lots/:id/split` - Split lot

### Sales (Phase 6)
- `GET /api/sales` - List sales
- `POST /api/sales` - Create sale
- `GET /api/sales/:id/profit-loss` - Calculate profit/loss

### Reports (Phase 6)
- `GET /api/reports/profit-loss` - Profit/Loss report
- `GET /api/reports/inventory-valuation` - Inventory report
- `GET /api/reports/expenses-summary` - Expenses report

---

## 🧪 Testing

### Backend Testing
```bash
cd backend
npm test
```

### Frontend Testing
```bash
cd frontend
flutter test
```

---

## 📦 Building for Production

### APK Build
```bash
cd frontend
flutter build apk --release
```

APK will be generated at: `frontend/build/app/outputs/apk/release/app-release.apk`

### Backend Deployment
```bash
# Build Docker image
docker build -t gemstone-api .

# Run container
docker run -p 3000:3000 gemstone-api
```

---

## 🐛 Troubleshooting

### Backend Issues
- **Database connection error:** Check PostgreSQL is running and credentials are correct
- **Port already in use:** Change PORT in .env file
- **JWT errors:** Ensure JWT_SECRET is set in .env

### Frontend Issues
- **Flutter not found:** Install Flutter SDK
- **Build errors:** Run `flutter clean` then `flutter pub get`
- **Android build fails:** Update Android SDK in Android Studio

---

## 📚 Documentation

- **Phase 1:** [Backend Initialization](PHASE_1_SETUP.md)
- **Phase 2:** [Database & Authentication](PHASE_2_DATABASE_AUTH.md)
- **Phase 3:** [Flutter UI & Theme](PHASE_3_FLUTTER_AUTH_UI.md)
- **Summary:** [Project Overview](PROJECT_SUMMARY.md)

---

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Commit changes: `git commit -m 'Add your feature'`
3. Push to branch: `git push origin feature/your-feature`
4. Submit pull request

---

## 📄 License

This project is proprietary software for Gemstone Trading Management.

---

## 📞 Support

For issues or questions:
1. Check the documentation files
2. Review the code comments
3. Check error logs in console

---

## 🎯 Roadmap

- [x] Phase 1: Backend initialization
- [x] Phase 2: Database & authentication
- [x] Phase 3: Flutter UI & theme
- [ ] Phase 4: Gemstone & lot management
- [ ] Phase 5: Processing & expenses
- [ ] Phase 6: Sales & reports
- [ ] Phase 7: Offline sync & QR integration
- [ ] Production deployment

---

**Version:** 1.0.0-alpha

**Last Updated:** May 27, 2026

**Status:** 🟡 In Development (Phase 3 Complete)

---

Made with 💎 by Gemstone Development Team
