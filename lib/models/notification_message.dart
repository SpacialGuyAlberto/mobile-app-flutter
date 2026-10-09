class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  
  // Newly added to match backend
  final String? channel;
  final String? entityId;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.eventType,
    required this.payload,
    required this.timestamp,
    this.channel,
    this.entityId,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      eventType: json['eventType'] ?? '',
      payload: json['payload'] ?? {},
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      channel: json['channel'] ?? '',
      entityId: json['entityId'] ?? '',
    );
  }
}
