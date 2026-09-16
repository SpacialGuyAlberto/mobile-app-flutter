import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Using 10.0.2.2 which is the special alias to your host loopback interface 
  // on the Android emulator. Use 'http://localhost:8080' if running on iOS simulator.
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data from $endpoint. Status code: ${response.statusCode}');
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
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to post data to $endpoint. Status code: ${response.statusCode}');
    }
  }
}
