import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../db/database_helper.dart';
import 'api_service.dart';

abstract class OfflineFirstRepository<T> {
  final ApiService apiService;
  final DatabaseHelper dbHelper;

  OfflineFirstRepository({
    required this.apiService,
    required this.dbHelper,
  });

  /// The endpoint to fetch data from (e.g., '/projects')
  String get endpoint;

  /// The unique entity type identifier for the local cache (e.g., 'Project')
  String get entityType;

  /// Convert a JSON map from the API/Cache to the Dart model
  T fromJson(Map<String, dynamic> json);

  /// Convert the Dart model to a JSON map for caching
  Map<String, dynamic> toJson(T model);

  /// Extract the unique ID from the model
  String extractId(T model);

  Future<List<T>> fetchAll({bool forceRefresh = false}) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline || forceRefresh) {
      try {
        // 1. Fetch from Remote
        final responseData = await apiService.get(endpoint);
        
        List<T> models = [];
        if (responseData is List) {
          models = responseData.map((json) => fromJson(json)).toList();
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('content')) {
           // Handle paginated responses from Spring Boot
           models = (responseData['content'] as List).map((json) => fromJson(json)).toList();
        }

        // 2. Clear old cache and save new data
        if (models.isNotEmpty) {
           await dbHelper.clearCacheByType(entityType);
           for (var model in models) {
             final id = extractId(model);
             final jsonStr = jsonEncode(toJson(model));
             await dbHelper.upsertCache(id, entityType, jsonStr);
           }
        }
        
        return models;
      } catch (e) {
        // Fallback to local cache on API error (e.g., server unreachable despite having connection)
        print("API Fetch failed, falling back to cache. Error: $e");
        return _fetchFromCache();
      }
    } else {
      // 3. Offline Mode: Fetch from Local Cache
      return _fetchFromCache();
    }
  }

  Future<List<T>> _fetchFromCache() async {
    final cachedData = await dbHelper.getCacheByType(entityType);
    return cachedData.map((row) {
      final jsonPayload = jsonDecode(row[DatabaseHelper.columnPayload]);
      return fromJson(jsonPayload);
    }).toList();
  }
}
