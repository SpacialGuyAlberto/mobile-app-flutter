import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiService {
  // Using 192.168.178.57 which is the special alias to your host loopback interface 
  // Using direct computer IP for physical phone testing.
  static const String baseUrl = 'http://192.168.178.57:8080/api';

  Future<File> _getCacheFile(String endpoint) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = endpoint.replaceAll('/', '_');
    return File('${dir.path}/$safeName.json');
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = response.body;
        // Save to cache
        try {
          final file = await _getCacheFile(endpoint);
          await file.writeAsString(data);
        } catch (e) {
          print('Cache write error: $e');
        }
        return jsonDecode(data);
      } else {
        throw Exception('Failed to load data from $endpoint. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error ($e), attempting to load from cache for $endpoint');
      try {
        final file = await _getCacheFile(endpoint);
        if (await file.exists()) {
          final data = await file.readAsString();
          return jsonDecode(data);
        }
      } catch (cacheError) {
        print('Cache read error: $cacheError');
      }
      throw Exception('Network failed and no offline cache available for $endpoint');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
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
      } catch (e) {
        errMsg = response.body;
      }
      throw Exception(errMsg);
    }
  }
}
