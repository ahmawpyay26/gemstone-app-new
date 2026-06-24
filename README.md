# Gemstone Management Mobile App

Professional Gemstone Trading and Processing Management Mobile Application built with Flutter.

## Features

- **Offline-First Architecture**: Full SQLite database for offline functionality
- **Inventory Management**: Track gemstones, lots, and stock
- **Sales Module**: Record and manage sales transactions
- **Expense Tracking**: Monitor business expenses
- **Profit/Loss Reports**: Generate financial reports
- **Worker Management**: Manage team and payroll
- **QR Code Tracking**: Track gemstones with QR codes
- **Notifications**: Real-time alerts and updates
- **Sync Engine**: Hybrid offline-online synchronization (when backend is available)

## Requirements

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android SDK 21 or higher
- Java 11 or higher

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/gemstone-management.git
cd gemstone-management/frontend
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Code (if needed)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run Development App
```bash
flutter run
```

## Building

### Build Debug APK
```bash
flutter build apk --debug
```

### Build Release APK
```bash
flutter build apk --release
```

The APK will be available at: `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
├── services/                 # Business logic services
│   ├── database/            # SQLite database service
│   ├── sync/                # Sync engine service
│   └── api/                 # API client
├── widgets/                 # Reusable widgets
├── utils/                   # Utility functions
└── constants/               # App constants

assets/
├── images/                  # Image assets
├── icons/                   # Icon assets
└── fonts/                   # Custom fonts
```

## Database

The app uses SQLite for local data storage with the following tables:
- gemstones
- sales
- expenses
- workers
- lots
- sync_metadata
- sync_queue
- sync_conflicts

See `OFFLINE_DATABASE_SCHEMA.sql` for complete schema.

## Offline Mode

The app works completely offline with SQLite. All data is stored locally and synced to the backend when internet is available.

### Offline Features
- Create, read, update, delete gemstones
- Record sales and expenses
- Manage workers
- Generate reports
- Track inventory

### Sync Features (when online)
- Automatic sync in background
- Manual sync with sync button
- Conflict resolution
- Data validation

## Configuration

### API Base URL

Set the API base URL in `lib/constants/app_constants.dart`:

```dart
const String API_BASE_URL = 'https://api.gemstone-app.com';
```

### App Version

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `major.minor.patch+buildNumber`

## Testing

Run tests with:
```bash
flutter test
```

## Troubleshooting

### Build Errors

1. **Flutter not found**
   ```bash
   flutter pub get
   flutter clean
   flutter pub get
   ```

2. **Android build errors**
   ```bash
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   flutter build apk --release
   ```

3. **Dependency conflicts**
   ```bash
   flutter pub upgrade
   flutter pub get
   ```

### Runtime Issues

1. **Database errors**: Clear app data and restart
2. **Sync issues**: Check internet connection and API endpoint
3. **UI issues**: Run `flutter clean` and rebuild

## Performance Optimization

- Lazy loading of data
- Image caching
- Database indexing
- Batch operations
- Efficient state management

## Security

- JWT authentication
- Encrypted local storage
- HTTPS for API calls
- Input validation
- Secure token storage

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is proprietary software. All rights reserved.

## Support

For support, email support@gemstone-app.com

---

**Version**: 1.0.0
**Last Updated**: May 31, 2026
