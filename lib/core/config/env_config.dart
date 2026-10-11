import 'dart:io';
import 'package:flutter/services.dart';

class EnvConfig {
  static String laptopIp = '172.20.10.2';
  static int backendPort = 8080;
  static String backendUrl = 'http://172.20.10.2:8080/api';

  static String glassesIp = '172.20.10.5';
  static int headsetPort = 8000;

  static bool _isLoaded = false;

  static Future<void> init() async {
    if (_isLoaded) return;
    _isLoaded = true;

    String? content;

    // 1. Try reading directly from file (useful during local execution/tests)
    try {
      final file = File('.env');
      if (await file.exists()) {
        content = await file.readAsString();
      }
    } catch (_) {}

    // 2. If not found from File, load from Flutter asset bundle
    if (content == null || content.isEmpty) {
      try {
        content = await rootBundle.loadString('.env');
      } catch (_) {}
    }

    if (content != null && content.isNotEmpty) {
      _parse(content);
    }
  }

  static void _parse(String content) {
    bool hasExplicitBackendUrl = false;
    for (var line in content.split('\n')) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eqIdx = line.indexOf('=');
      if (eqIdx == -1) continue;

      final key = line.substring(0, eqIdx).trim().toUpperCase();
      final val = line.substring(eqIdx + 1).trim();

      switch (key) {
        case 'LAPTOP_IP':
          laptopIp = val;
          break;
        case 'BACKEND_PORT':
          backendPort = int.tryParse(val) ?? backendPort;
          break;
        case 'BACKEND_URL':
          backendUrl = val;
          hasExplicitBackendUrl = true;
          break;
        case 'GLASSES_IP':
        case 'HEADSET_IP':
          glassesIp = val;
          break;
        case 'HEADSET_PORT':
        case 'GLASSES_PORT':
          headsetPort = int.tryParse(val) ?? headsetPort;
          break;
      }
    }

    if (!hasExplicitBackendUrl && laptopIp.isNotEmpty) {
      backendUrl = 'http://$laptopIp:$backendPort/api';
    }
  }
}
