import '../../../../core/local/models.dart';

/// Helper to get valid photo count for a broker consignment item.
/// photoPaths is non-nullable List<String> — no null check needed.
/// Removes blank entries and duplicates before counting.
int validPhotoCount(BrokerConsignment item) {
  if (item.photoPaths.isEmpty) return 0;
  return item.photoPaths
      .where((path) => path.trim().isNotEmpty)
      .toSet()
      .length;
}

/// Helper to get valid photo paths for a broker consignment item.
/// Removes blank entries and duplicates.
List<String> getValidPhotoPaths(BrokerConsignment item) {
  if (item.photoPaths.isEmpty) return [];
  return item.photoPaths
      .where((path) => path.trim().isNotEmpty)
      .toSet()
      .toList();
}

/// Helper to get combined valid photos from all items in a voucher.
/// Used for voucher-level photo viewer.
List<String> getVoucherPhotoPaths(List<BrokerConsignment> items) {
  final allPhotos = <String>{};
  for (final item in items) {
    if (item.photoPaths.isNotEmpty) {
      allPhotos.addAll(
        item.photoPaths.where((path) => path.trim().isNotEmpty),
      );
    }
  }
  return allPhotos.toList();
}
