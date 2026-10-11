import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/env_config.dart';

class ApiService {
  // Default base URL. Initialized from EnvConfig / .env file.
  static String _baseUrl = EnvConfig.backendUrl;
  static bool _hasLoadedConfig = false;

  static String get baseUrl => _baseUrl;
  static String get baseHost => _baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  static List<String> get candidateBaseUrls => [
    EnvConfig.backendUrl,
    'http://172.20.10.2:8080/api', // Mobile hotspot host IP
    'http://10.0.2.2:8080/api',    // Android Emulator host loopback
    'http://localhost:8080/api',   // Localhost (adb reverse / Desktop)
    'http://127.0.0.1:8080/api',
    'http://fedora.fritz.box:8080/api', // Home network
  ];

  static Future<File> _getConfigFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/server_config.json');
  }

  static Future<void> loadConfig() async {
    if (_hasLoadedConfig) return;
    _hasLoadedConfig = true;
    await EnvConfig.init();
    _baseUrl = EnvConfig.backendUrl;
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data['baseUrl'] != null && data['baseUrl'].toString().trim().isNotEmpty) {
          _baseUrl = data['baseUrl'].toString().trim();
        }
      }
    } catch (_) {}
  }

  static Future<void> setBaseUrl(String newUrl) async {
    var cleaned = newUrl.trim();
    if (!cleaned.endsWith('/api') && !cleaned.endsWith('/api/')) {
      if (cleaned.endsWith('/')) {
        cleaned = '${cleaned}api';
      } else {
        cleaned = '$cleaned/api';
      }
    }
    _baseUrl = cleaned;
    try {
      final file = await _getConfigFile();
      await file.writeAsString(jsonEncode({'baseUrl': _baseUrl}));
    } catch (_) {}
  }

  /// Automatically tests known candidate URLs and picks the first working one.
  static Future<String?> autoDetectWorkingBaseUrl() async {
    await loadConfig();
    final toTest = [
      _baseUrl,
      ...candidateBaseUrls.where((c) => c != _baseUrl),
    ];

    for (final candidate in toTest) {
      try {
        final testUri = Uri.parse('$candidate/projects');
        final res = await http.get(testUri).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await setBaseUrl(candidate);
          return candidate;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<File> _getCacheFile(String endpoint) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = endpoint.replaceAll('/', '_');
    return File('${dir.path}/$safeName.json');
  }

  Future<dynamic> get(String endpoint) async {
    await loadConfig();

    try {
      return await _performGet(_baseUrl, endpoint);
    } catch (primaryError) {
      print('ApiService.get error on $_baseUrl$endpoint: $primaryError. Probing candidates...');

      // Try auto-detecting working URL if network changed (e.g. hotspot IP changed or switching to emulator)
      final newUrl = await autoDetectWorkingBaseUrl();
      if (newUrl != null && newUrl != _baseUrl) {
        try {
          return await _performGet(newUrl, endpoint);
        } catch (_) {}
      }

      // If network fails completely, fallback to local cache
      try {
        final file = await _getCacheFile(endpoint);
        if (await file.exists()) {
          final data = await file.readAsString();
          return jsonDecode(data);
        }
      } catch (cacheError) {
        print('Cache read error: $cacheError');
      }
      throw Exception('Network failed ($primaryError) and no offline cache available for $endpoint');
    }
  }

  Future<dynamic> _performGet(String base, String endpoint) async {
    final response = await http.get(
      Uri.parse('$base$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = response.body;
      try {
        final file = await _getCacheFile(endpoint);
        await file.writeAsString(data);
      } catch (_) {}
      return jsonDecode(data);
    } else {
      throw Exception('Failed to load data from $endpoint. Status code: ${response.statusCode}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    await loadConfig();
    try {
      return await _performPost(_baseUrl, endpoint, body);
    } catch (e) {
      final newUrl = await autoDetectWorkingBaseUrl();
      if (newUrl != null && newUrl != _baseUrl) {
        return await _performPost(newUrl, endpoint, body);
      }
      rethrow;
    }
  }

  Future<dynamic> _performPost(String base, String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$base$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      String errMsg = 'Status code: ${response.statusCode}';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody['message'] != null) {
          errMsg = errorBody['message'];
        } else if (errorBody['error'] != null) {
          errMsg = errorBody['error'];
        } else {
          errMsg = response.body;
        }
      } catch (_) {
        errMsg = response.body;
      }
      throw Exception(errMsg);
    }
  }
}
