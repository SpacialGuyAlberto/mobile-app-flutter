import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/notification_message.dart';
import 'ar_companion_provider.dart';

class NotificationState {
  final List<NotificationMessage> notifications;
  final int unreadCount;
  
  NotificationState({this.notifications = const [], this.unreadCount = 0});

  NotificationState copyWith({
    List<NotificationMessage>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  // Use http client to read SSE stream
  final http.Client _client = http.Client();
  final Ref ref;
  
  NotificationNotifier(this.ref) : super(NotificationState()) {
    _startListening();
  }

  void _startListening() async {
    // Assuming user ID 1 for now, in a real app this would come from an AuthProvider
    // Map 192.168.178.57 to Android Emulator local IP if needed
    final host = Platform.isAndroid ? '192.168.178.57' : '192.168.178.57';
    final url = Uri.parse('http://$host:8080/api/notifications/stream?userId=1');
    final request = http.Request('GET', url);
    request.headers['Accept'] = 'text/event-stream';

    try {
      final response = await _client.send(request);

      response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          if (line.startsWith('data:')) {
            final jsonStr = line.substring(5).trim();
            if (jsonStr.isNotEmpty) {
              try {
                final Map<String, dynamic> data = jsonDecode(jsonStr);
                final message = NotificationMessage.fromJson(data);
                _handleNewNotification(message);
              } catch (e) {
                print("Error parsing SSE data: $e");
              }
            }
          }
        }, onError: (error) {
          print("SSE Error: $error");
        }, cancelOnError: false);
    } catch (e) {
      print("Could not connect to SSE stream: $e");
    }
  }

  void _handleNewNotification(NotificationMessage message) {
    state = state.copyWith(
      notifications: [message, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    );
    
    // Forward via UDP to AR headset!
    ref.read(arCompanionProvider.notifier).triggerUdpNotification(
      message.title, message.body, message.entityId ?? ""
    );
  }

  void markAllAsRead() {
    state = state.copyWith(unreadCount: 0);
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});
