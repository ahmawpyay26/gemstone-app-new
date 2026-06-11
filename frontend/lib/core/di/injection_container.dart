import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

final sl = GetIt.instance;
final getIt = GetIt.instance;

Future<void> init() async {
  // 1. External - Offline Only
  // Removed: Dio HTTP client (not needed for offline mode)
  // Removed: Firebase Storage (not needed for offline mode)
  // Removed: connectivity_plus (dependency conflict)
  
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  
  // 2. API & Auth Services
  sl.registerLazySingleton(() => ApiClient(secureStorage: sl()));
  sl.registerLazySingleton(() => AuthService(apiClient: sl(), secureStorage: sl()));

  // 3. Data Sources
  // Removed: GemstoneApiService (not needed for offline mode)
  // Removed: AppDatabase (generated file not available)

  // 4. Repositories - Offline First Only
  // Removed: GemstoneRepositoryImpl (generated file not available)

  // 4. Blocs (Phase 5 implementation)
  // sl.registerFactory(() => InventoryBloc(repository: sl()));
}
