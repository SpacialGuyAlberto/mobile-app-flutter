import 'package:flutter/material.dart';
import '../../models/notification_message.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationMessage notification;

  const NotificationDetailScreen({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String badgeText = "UPDATE";
    Color badgeColor = Colors.blueAccent;
    if (notification.title.contains('Completada')) { badgeText = "COMPLETED"; badgeColor = const Color(0xFF34d399); }
    else if (notification.title.contains('Bloqueado')) { badgeText = "BLOCKED"; badgeColor = const Color(0xFFef4444); }
    else if (notification.title.contains('IN_PROGRESS')) { badgeText = "IN PROGRESS"; badgeColor = const Color(0xFF60a5fa); }
    else if (notification.title.contains('Planificado')) { badgeText = "PLAN"; badgeColor = const Color(0xFFa78bfa); }
    else if (notification.title.contains('HOLD')) { badgeText = "HOLD"; badgeColor = const Color(0xFFfbbf24); }

    return Scaffold(
      backgroundColor: const Color(0xFF121316),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16171A),
        elevation: 0,
        title: const Text('LOG DETAILS', style: TextStyle(fontFamily: 'monospace', letterSpacing: 2.0, fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16171A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('STATUS OVERVIEW', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontFamily: 'monospace')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: badgeColor.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      notification.title.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      notification.body,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Divider(color: Colors.white.withOpacity(0.05), thickness: 1),
                    const SizedBox(height: 24),
                    _buildDetailRow('EVENT TYPE', notification.eventType.isNotEmpty ? notification.eventType : 'SYSTEM_UPDATE'),
                    const SizedBox(height: 16),
                    _buildDetailRow('LOG TIME', '${notification.timestamp.hour.toString().padLeft(2, '0')}:${notification.timestamp.minute.toString().padLeft(2, '0')} - ${notification.timestamp.day.toString().padLeft(2, '0')}/${notification.timestamp.month.toString().padLeft(2, '0')}/${notification.timestamp.year}'),
                    const SizedBox(height: 16),
                    _buildDetailRow('LOG ID', notification.id.isEmpty ? 'AUTO-GEN-LOG' : notification.id),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Optional action buttons related to the event could go here
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // This could open the segment edit screen in the future
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: badgeColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: badgeColor.withOpacity(0.05),
                  ),
                  child: Text('VIEW ASSOCIATED SEGMENT', style: TextStyle(color: badgeColor, fontSize: 12, letterSpacing: 1.5, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1.5, fontFamily: 'monospace')),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
        ),
      ],
    );
  }
}
