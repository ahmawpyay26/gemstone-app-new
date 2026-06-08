import '../../domain/entities/gemstone_entity.dart';
import '../datasources/local/app_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GemstoneRepositoryImpl {
  final AppDatabase localDb;
  final Connectivity connectivity;

  GemstoneRepositoryImpl({
    required this.localDb,
    required this.connectivity,
  });

  // Get Gemstones - Local Only (Offline First)
  Future<List<LocalGemstone>> getGemstones() async {
    try {
      // Return local data immediately - no remote calls
      final localData = await (localDb.select(localDb.localGemstones)).get();
      return localData;
    } catch (e) {
      print('Error fetching gemstones: $e');
      return [];
    }
  }

  // Add Gemstone - Local Only (Offline First)
  Future<void> addGemstone(LocalGemstone stone) async {
    try {
      // Save to local database immediately
      // No sync to cloud - fully offline mode
      await localDb.insertOrUpdateGemstone(
        stone.copyWith(isSynced: true), // Mark as synced since no cloud
      );
    } catch (e) {
      print('Error adding gemstone: $e');
      rethrow;
    }
  }

  // Get Gemstone by ID - Local Only
  Future<LocalGemstone?> getGemstoneById(String id) async {
    try {
      return await localDb.getGemstoneById(id);
    } catch (e) {
      print('Error fetching gemstone: $e');
      return null;
    }
  }

  // Update Gemstone - Local Only
  Future<void> updateGemstone(LocalGemstone stone) async {
    try {
      await localDb.insertOrUpdateGemstone(
        stone.copyWith(isSynced: true), // Mark as synced
      );
    } catch (e) {
      print('Error updating gemstone: $e');
      rethrow;
    }
  }

  // Delete Gemstone - Local Only
  Future<void> deleteGemstone(String id) async {
    try {
      await localDb.deleteGemstone(id);
    } catch (e) {
      print('Error deleting gemstone: $e');
      rethrow;
    }
  }

  // Get All Gemstones with Pagination - Local Only
  Future<List<LocalGemstone>> getGemstonesWithPagination({
    required int page,
    required int pageSize,
  }) async {
    try {
      final allGemstones = await (localDb.select(localDb.localGemstones)).get();
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;
      
      if (startIndex >= allGemstones.length) {
        return [];
      }
      
      return allGemstones.sublist(
        startIndex,
        endIndex > allGemstones.length ? allGemstones.length : endIndex,
      );
    } catch (e) {
      print('Error fetching paginated gemstones: $e');
      return [];
    }
  }

  // Search Gemstones - Local Only
  Future<List<LocalGemstone>> searchGemstones(String query) async {
    try {
      final allGemstones = await (localDb.select(localDb.localGemstones)).get();
      return allGemstones
          .where((stone) =>
              stone.qrCode.toLowerCase().contains(query.toLowerCase()) ||
              stone.type.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching gemstones: $e');
      return [];
    }
  }

  // Sync Status - Offline Mode (Always Synced Locally)
  Future<Map<String, dynamic>> getSyncStatus() async {
    return {
      'isSynced': true,
      'lastSyncTime': DateTime.now(),
      'pendingChanges': 0,
      'isOnline': false, // Always offline mode
      'mode': 'OFFLINE_ONLY',
    };
  }

  // Sync Disabled - Offline Only Mode
  Future<void> syncToCloud() async {
    // Sync disabled in offline-only mode
    print('Sync disabled: Running in offline-only mode');
  }

  Future<void> syncFromCloud() async {
    // Sync disabled in offline-only mode
    print('Sync disabled: Running in offline-only mode');
  }

  // Check Connectivity (for information only)
  Future<bool> isOnline() async {
    try {
      final connection = await connectivity.checkConnectivity();
      return connection != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
}
