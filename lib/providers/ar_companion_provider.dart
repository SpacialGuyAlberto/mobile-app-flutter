import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  ARCompanionState({
    this.isBroadcasting = false,
    this.targetIp = '192.168.1.100',
    this.targetPort = 8000,
    this.lastMessage = '',
  });

  ARCompanionState copyWith({
    bool? isBroadcasting,
    String? targetIp,
    int? targetPort,
    String? lastMessage,
  }) {
    return ARCompanionState(
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      targetIp: targetIp ?? this.targetIp,
      targetPort: targetPort ?? this.targetPort,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class ARCompanionNotifier extends StateNotifier<ARCompanionState> {
  ARCompanionNotifier() : super(ARCompanionState());

  StreamSubscription<Position>? _positionSubscription;
  RawDatagramSocket? _socket;

  Future<void> startBroadcasting(String ip, int port) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(lastMessage: 'Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(lastMessage: 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(lastMessage: 'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = true;

      state = state.copyWith(isBroadcasting: true, targetIp: ip, targetPort: port, lastMessage: 'Started broadcasting to $ip:$port');

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0, // Update immediately
        ),
      ).listen((Position position) {
        if (!state.isBroadcasting) return;

        final Map<String, dynamic> data = {
          'lat': position.latitude,
          'lng': position.longitude,
          'alt': position.altitude,
          'heading': position.heading,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        };

        final bytes = utf8.encode(jsonEncode(data));
        
        try {
          final targetAddress = InternetAddress(state.targetIp);
          _socket?.send(bytes, targetAddress, state.targetPort);
          
          state = state.copyWith(lastMessage: 'Sent: lat: ${position.latitude.toStringAsFixed(6)}, lng: ${position.longitude.toStringAsFixed(6)}');
        } catch (e) {
          state = state.copyWith(lastMessage: 'Error sending UDP: $e');
        }
      });
    } catch (e) {
      state = state.copyWith(lastMessage: 'Failed to bind socket: $e');
    }
  }

  void stopBroadcasting() {
    _positionSubscription?.cancel();
    _socket?.close();
    _positionSubscription = null;
    _socket = null;
    state = state.copyWith(isBroadcasting: false, lastMessage: 'Broadcasting stopped.');
  }

  @override
  void dispose() {
    stopBroadcasting();
    super.dispose();
  }
}
