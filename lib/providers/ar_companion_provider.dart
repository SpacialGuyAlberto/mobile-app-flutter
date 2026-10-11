import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/config/env_config.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final arCompanionProvider = StateNotifierProvider<ARCompanionNotifier, ARCompanionState>((ref) {
  return ARCompanionNotifier();
});

class ARCompanionState {
  final bool isBroadcasting;
  final String targetIp;
  final int targetPort;
  final String lastMessage;
  final int? projectId;

  ARCompanionState({
    this.isBroadcasting = false,
    this.targetIp = '172.20.10.5',
    this.targetPort = 8000,
    this.lastMessage = '',
    this.projectId,
  });

  ARCompanionState copyWith({
    bool? isBroadcasting,
    String? targetIp,
    int? targetPort,
    String? lastMessage,
    int? projectId,
  }) {
    return ARCompanionState(
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      targetIp: targetIp ?? this.targetIp,
      targetPort: targetPort ?? this.targetPort,
      lastMessage: lastMessage ?? this.lastMessage,
      projectId: projectId ?? this.projectId,
    );
  }
}

class ARCompanionNotifier extends StateNotifier<ARCompanionState> {
  ARCompanionNotifier() : super(ARCompanionState()) {
    loadConfig();
  }

  static Future<File> _getConfigFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/ar_companion_config.json');
  }

  Future<void> loadConfig() async {
    await EnvConfig.init();
    state = state.copyWith(
      targetIp: EnvConfig.glassesIp,
      targetPort: EnvConfig.headsetPort,
    );
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data['targetIp'] != null && data['targetIp'].toString().trim().isNotEmpty) {
          state = state.copyWith(
            targetIp: data['targetIp'].toString().trim(),
            targetPort: data['targetPort'] != null ? int.tryParse(data['targetPort'].toString()) ?? EnvConfig.headsetPort : EnvConfig.headsetPort,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> saveConfig(String ip, int port) async {
    try {
      final file = await _getConfigFile();
      await file.writeAsString(jsonEncode({'targetIp': ip, 'targetPort': port}));
    } catch (_) {}
  }

  StreamSubscription<Position>? _positionSubscription;
  RawDatagramSocket? _socket;
  
  double? _lastGoogleElevation;
  Position? _lastElevationPosition;

  void setProjectId(int? id) {
    state = state.copyWith(projectId: id);
  }

  Future<void> _fetchGoogleElevation(double lat, double lng) async {
    try {
      final url = Uri.parse('https://maps.googleapis.com/maps/api/elevation/json?locations=$lat,$lng&key=AIzaSyClkdHOLWnKrRwkAHE5_aJyw-xboEnA7dw');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          _lastGoogleElevation = data['results'][0]['elevation']?.toDouble();
        }
      }
    } catch (e) {
      print('Error fetching Google elevation: $e');
    }
  }

  Timer? _heartbeatTimer;

  Future<String?> startBroadcasting(String ip, int port) async {
    await saveConfig(ip, port);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(lastMessage: 'Location services are disabled.');
      return 'Location services are disabled. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(lastMessage: 'Location permissions are denied');
        return 'Location permissions are denied. Cannot broadcast GPS.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(lastMessage: 'Location permissions are permanently denied, we cannot request permissions.');
      return 'Location permissions are permanently denied. Please enable them in Settings.';
    }

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = true;

      state = state.copyWith(isBroadcasting: true, targetIp: ip, targetPort: port, lastMessage: 'Started broadcasting to $ip:$port');

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).listen((Position position) {
        if (!state.isBroadcasting) return;
        _lastElevationPosition = position;
        _sendUdpPacket(position);
      });

      // HEARTBEAT para el Emulador: Enviar cada 2 segundos forzosamente aunque no haya movimiento
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (state.isBroadcasting && _lastElevationPosition != null) {
          _sendUdpPacket(_lastElevationPosition!);
        }
      });
      
      return null;
    } catch (e) {
      state = state.copyWith(lastMessage: 'Failed to bind socket: $e');
      return 'Failed to start broadcasting: $e';
    }
  }

  String? _lastNotificationTitle;
  String? _lastNotificationBody;
  String? _lastNotificationEntityId;
  String? _lastNotificationId;

  void triggerUdpNotification(String title, String body, String entityId) {
    _lastNotificationTitle = title;
    _lastNotificationBody = body;
    _lastNotificationEntityId = entityId;
    _lastNotificationId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Force immediate broadcast
    if (state.isBroadcasting && _lastElevationPosition != null) {
      _sendUdpPacket(_lastElevationPosition!);
    }
  }

  void _sendUdpPacket(Position position) {
    if (_lastGoogleElevation == null || 
        Geolocator.distanceBetween(_lastElevationPosition!.latitude, _lastElevationPosition!.longitude, position.latitude, position.longitude) > 5) {
      _fetchGoogleElevation(position.latitude, position.longitude); 
    }

    final altToSend = _lastGoogleElevation ?? position.altitude;

    final Map<String, dynamic> data = {
      'lat': position.latitude,
      'lng': position.longitude,
      'alt': altToSend,
      'heading': position.heading,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'projectId': state.projectId,
    };

    if (_lastNotificationTitle != null) {
      data['notificationTitle'] = _lastNotificationTitle;
      data['notificationBody'] = _lastNotificationBody;
      data['notificationEntityId'] = _lastNotificationEntityId;
      data['notificationId'] = _lastNotificationId;
      // We do NOT clear it. It will be sent continuously to guarantee UDP delivery!
    }

    final bytes = utf8.encode(jsonEncode(data));
    
    try {
      final targetAddress = InternetAddress(state.targetIp);
      _socket?.send(bytes, targetAddress, state.targetPort);

      // Also try general subnet broadcast to guarantee arrival on hotspot network
      if (state.targetIp != '255.255.255.255') {
        try {
          _socket?.send(bytes, InternetAddress('255.255.255.255'), state.targetPort);
        } catch (_) {}
      }
      
      state = state.copyWith(lastMessage: 'Sent: lat: ${position.latitude.toStringAsFixed(6)}, lng: ${position.longitude.toStringAsFixed(6)} (Proj: ${state.projectId})');
    } catch (e) {
      state = state.copyWith(lastMessage: 'Error sending UDP: $e');
    }
  }

  void stopBroadcasting() {
    _positionSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _socket?.close();
    _positionSubscription = null;
    _heartbeatTimer = null;
    _socket = null;
    state = state.copyWith(isBroadcasting: false, lastMessage: 'Broadcasting stopped.');
  }

  @override
  void dispose() {
    stopBroadcasting();
    super.dispose();
  }
}
