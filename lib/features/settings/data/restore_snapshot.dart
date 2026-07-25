/// Snapshot support for Phase 2+ restore with rollback capability.
/// Captures current box state before restore and enables rollback on failure.

import 'package:hive/hive.dart';

class RestoreSnapshot {
  /// Box name being restored
  final String boxName;

  /// Snapshot of all records: key -> serialized value
  final Map<dynamic, dynamic> records;

  /// Timestamp when snapshot was created
  final DateTime createdAt;

  RestoreSnapshot({
    required this.boxName,
    required this.records,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create snapshot from a Hive box
  factory RestoreSnapshot.fromBox(Box<dynamic> box) {
    final snapshot = <dynamic, dynamic>{};
    for (final key in box.keys) {
      snapshot[key] = box.get(key);
    }
    return RestoreSnapshot(
      boxName: box.name,
      records: snapshot,
    );
  }

  /// Restore snapshot back to box
  Future<void> restoreToBox(Box<dynamic> box) async {
    // Clear current box
    await box.clear();

    // Restore all records with original keys
    for (final entry in records.entries) {
      await box.put(entry.key, entry.value);
    }
  }

  /// Get record count in snapshot
  int get recordCount => records.length;

  /// Check if snapshot is empty
  bool get isEmpty => records.isEmpty;
}
