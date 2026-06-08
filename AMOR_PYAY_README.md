# Amor-pyay - Offline Ecommerce Management System

## Overview

**Amor-pyay** is a fully offline Flutter-based ecommerce management system designed for gemstone trading businesses. It features a 100% offline-first architecture using SQLite for data persistence, with no external API dependencies.

## Key Features

### 🏪 Ecommerce System
- **Order Management**: Create, view, and manage customer orders
- **Product Catalog**: Manage gemstone inventory with pricing and stock tracking
- **Customer Management**: Store customer information with order history
- **Order Validation**: Mandatory fields (Name, Phone, Address) ensure data quality

### 💾 Offline-First Architecture
- **SQLite Database**: All data stored locally on device
- **No Internet Required**: Full functionality without network connection
- **Data Persistence**: All changes saved to local database automatically
- **Sync-Ready**: Infrastructure prepared for future cloud synchronization

### 👨‍💼 Super Admin Controls
- **Staff Management**: Create and manage staff accounts with roles
- **Product Management**: Add, update, and delete products
- **Order Management**: View all orders and manage order status
- **Analytics**: View total sales, expenses, and profit metrics

### 🎨 User Interface
- **Amor-pyay Branding**: Custom logo and branding throughout the app
- **Dark Theme**: Professional dark UI with gold accents
- **Myanmar Language**: Full support for Myanmar (Burmese) language
- **Responsive Design**: Works on various screen sizes

### 📊 Business Features
- **Inventory Tracking**: Real-time stock management
- **Order Status Tracking**: pending, completed, cancelled states
- **Payment Status**: Track payment status (unpaid, paid, partial)
- **Expense Tracking**: Record and categorize business expenses
- **Financial Reports**: View sales, expenses, and profit data

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                              # App entry point
│   ├── core/
│   │   ├── theme/                             # App theming
│   │   ├── services/                          # Business logic services
│   │   │   ├── admin_service.dart             # Super Admin controls
│   │   │   └── order_service.dart             # Order management & validation
│   │   └── navigation/
│   │       └── app_router.dart                # Route configuration
│   ├── data/
│   │   ├── datasources/
│   │   │   └── local/
│   │   │       └── app_database.dart          # SQLite database (Drift ORM)
│   │   └── models/
│   │       └── ecommerce_models.dart          # Data models
│   └── presentation/
│       └── pages/
│           ├── dashboard_page.dart            # Main dashboard
│           ├── order_create_page.dart         # Order creation
│           ├── orders_list_page.dart          # Orders management
│           └── [other pages]
├── android/                                   # Android configuration
├── pubspec.yaml                               # Flutter dependencies
└── .github/workflows/
    └── build-apk.yml                          # GitHub Actions CI/CD
```

## Database Schema

### Tables
1. **LocalStaff**: Staff/user accounts with roles
2. **LocalProducts**: Gemstone inventory with pricing
3. **LocalCustomers**: Customer information
4. **LocalOrders**: Order records
5. **LocalOrderItems**: Individual items in orders
6. **LocalExpenses**: Business expense tracking
7. **LocalGemstones**: Legacy gemstone data (backward compatibility)

## Installation & Setup

### Prerequisites
- Flutter SDK 3.19.0 or higher
- Android SDK (for APK building)
- Git

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/kyawswarhtun409-png/gemstone-app.git
   cd gemstone-app/frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Drift database files**
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Building APK

### Debug APK
```bash
cd frontend
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK
```bash
cd frontend
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Using GitHub Actions
1. Push code to GitHub
2. GitHub Actions automatically builds APK on push to `main` or `develop`
3. Download APK from Actions artifacts

## API Services

### AdminService
Provides Super Admin controls:
- `createStaff()`: Create new staff account
- `updateStaff()`: Update staff information
- `deleteStaff()`: Remove staff account
- `createProduct()`: Add new product
- `updateProduct()`: Modify product details
- `deleteProduct()`: Remove product
- `deleteOrder()`: Remove order
- `updateOrderStatus()`: Change order status
- `getTotalSales()`: Get total sales amount
- `getTotalExpenses()`: Get total expenses
- `getProfit()`: Calculate profit

### OrderService
Handles order management and validation:
- `validateCustomerInfo()`: Validate customer data (Name, Phone, Address)
- `validateOrderItems()`: Validate order items and stock
- `createOrder()`: Create new order with validation
- `getOrderById()`: Retrieve specific order
- `getCustomerOrders()`: Get orders for a customer
- `updateOrderStatus()`: Update order status
- `deleteOrder()`: Delete order and restore inventory

## Data Models

### CustomerModel
```dart
CustomerModel({
  required String id,
  required String name,           // Mandatory
  required String phone,          // Mandatory
  String? email,
  required String address,        // Mandatory
  String? city,
  String? state,
  String? zipCode,
  required DateTime createdAt,
  required DateTime lastUpdated,
})
```

### OrderModel
```dart
OrderModel({
  required String id,
  required String customerId,
  required String staffId,
  required double totalAmount,
  required double discountAmount,
  required double finalAmount,
  required String status,         // pending, completed, cancelled
  required String paymentStatus,  // unpaid, paid, partial
  String? notes,
  required DateTime orderDate,
  DateTime? deliveryDate,
  required DateTime createdAt,
  required DateTime lastUpdated,
  List<OrderItemModel>? items,
})
```

### ProductModel
```dart
ProductModel({
  required String id,
  required String name,
  String? description,
  required String category,
  required double price,
  required int quantity,
  required String sku,
  String? qrCode,
  String? imageUrl,
  required bool isActive,
  required DateTime createdAt,
  required DateTime lastUpdated,
})
```

## Order Validation Rules

1. **Customer Information** (All mandatory):
   - Name: Cannot be empty
   - Phone: Must be valid format (min 7 digits)
   - Address: Cannot be empty

2. **Order Items**:
   - At least one item required
   - Quantity must be > 0
   - Stock must be available
   - Product must exist in database

3. **Order Status**:
   - Valid states: `pending`, `completed`, `cancelled`
   - Default: `pending`

4. **Payment Status**:
   - Valid states: `unpaid`, `paid`, `partial`
   - Default: `unpaid`

## Navigation Routes

| Route | Page | Description |
|-------|------|-------------|
| `/login` | LoginPage | User authentication |
| `/` | DashboardPage | Main dashboard with overview |
| `/order-create` | OrderCreatePage | Create new order |
| `/orders` | OrdersListPage | View and manage orders |
| `/inventory` | InventoryPage | Manage products |
| `/lots` | LotPage | Manage lots |
| `/expenses` | ExpensePage | Track expenses |
| `/sales` | SalesPage | View sales data |
| `/reports` | ReportsPage | Generate reports |
| `/qr-scanner` | QrScannerImpl | QR code scanning |
| `/settings` | SettingsPage | App settings |

## Offline Features

### Data Sync Strategy
- All data stored in SQLite database
- `isSynced` flag tracks sync status
- Ready for future backend integration
- No data loss without internet

### Supported Offline Operations
- ✅ Create orders
- ✅ Manage inventory
- ✅ Track expenses
- ✅ View reports
- ✅ Manage staff
- ✅ View order history
- ✅ Generate analytics

## Myanmar Language Support

The app includes full Myanmar language support:
- Dashboard labels and buttons
- Form validation messages
- Order status labels
- Error messages
- Navigation labels

## Dependencies

Key dependencies used:
- **flutter_bloc**: State management
- **drift**: SQLite ORM
- **go_router**: Navigation
- **uuid**: Unique ID generation
- **json_annotation**: JSON serialization
- **flutter_secure_storage**: Secure data storage
- **connectivity_plus**: Network detection

## GitHub Actions CI/CD

The project includes automated APK building via GitHub Actions:

### Workflows
1. **build-apk.yml**: Builds debug and release APKs on push
2. **build-signed-apk.yml**: Builds signed release APK

### Artifacts
- Debug APK: Retained for 7 days
- Release APK: Retained for 30 days

## Troubleshooting

### Database Issues
```bash
# Regenerate database files
flutter clean
flutter pub get
flutter pub run build_runner build
```

### Build Errors
```bash
# Clear build cache
flutter clean
flutter pub get
flutter build apk --release
```

### APK Installation
1. Enable "Unknown Sources" in Android settings
2. Download APK file
3. Tap to install
4. Grant necessary permissions

## Future Enhancements

- [ ] Cloud synchronization
- [ ] Multi-branch support
- [ ] Advanced reporting
- [ ] Mobile payment integration
- [ ] Customer portal
- [ ] Real-time notifications
- [ ] Backup and restore
- [ ] Multi-language support expansion

## Support & Documentation

- **Installation Guide**: See `INSTALLATION_GUIDE.md`
- **GitHub Setup**: See `GITHUB_SETUP_GUIDE.md`
- **Android Signing**: See `ANDROID_SIGNING_GUIDE.md`
- **CI/CD Documentation**: See `CI_CD_DOCUMENTATION.md`

## License

This project is proprietary and confidential.

## Contact

For support and inquiries, please contact the development team.

---

**Version**: 1.0.0  
**Last Updated**: June 2, 2026  
**Platform**: Android (Flutter)  
**Database**: SQLite (Drift ORM)  
**Architecture**: Offline-First Ecommerce System
