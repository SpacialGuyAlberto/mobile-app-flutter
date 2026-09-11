import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_service.dart';

// Provides the SyncManager instance
final syncManagerProvider = Provider((ref) => SyncManager());

class SyncManager {
  final DatabaseService _dbService = DatabaseService.instance;
  bool _isSyncing = false;

  /// Starts the synchronization process for offline stored data.
  Future<void> syncOfflineData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final db = await _dbService.database;
      
      // Fetch unsynced evidences
      final List<Map<String, dynamic>> unsynced = await db.query(
        'evidences',
        where: 'isSynced = ?',
        whereArgs: [0],
      );

      if (unsynced.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (var evidence in unsynced) {
        bool success = await _uploadEvidence(evidence);
        if (success) {
          // Mark as synced
          await db.update(
            'evidences',
            {'isSynced': 1},
            where: 'id = ?',
            whereArgs: [evidence['id']],
          );
        }
      }
    } catch (e) {
      print('Sync Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Mock upload function. In a real scenario, this would make HTTP multipart requests.
  Future<bool> _uploadEvidence(Map<String, dynamic> evidence) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    print('Uploaded evidence: ${evidence["id"]}');
    return true; // Return true if successful
  }

  /// Helper to insert a new evidence and attempt immediate sync
  Future<void> saveAndSyncEvidence(Map<String, dynamic> evidenceData) async {
    final db = await _dbService.database;
    await db.insert('evidences', evidenceData);
    
    // Attempt to sync immediately
    syncOfflineData();
  }
}
