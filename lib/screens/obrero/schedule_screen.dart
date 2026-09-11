import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final List<Map<String, dynamic>> schedule = [
      {
        'time': '08:00 AM',
        'task': 'Safety Briefing',
        'location': 'Site Office A',
        'isCompleted': true,
      },
      {
        'time': '09:00 AM',
        'task': 'Begin Trenching',
        'location': 'Segment A - Charlottenstrasse',
        'isCompleted': true,
      },
      {
        'time': '01:00 PM',
        'task': 'Lay Conduit Pipes',
        'location': 'Segment A - Charlottenstrasse',
        'isCompleted': false,
      },
      {
        'time': '04:00 PM',
        'task': 'Site Cleanup & Handover',
        'location': 'Segment A - Charlottenstrasse',
        'isCompleted': false,
      },
    ];

    return Container(
      color: AppTheme.backgroundDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: schedule.length,
        itemBuilder: (context, index) {
          final item = schedule[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    item['time'],
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item['isCompleted'] ? Colors.green.withOpacity(0.3) : AppTheme.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['isCompleted'] ? Icons.check_circle : Icons.circle_outlined,
                          color: item['isCompleted'] ? Colors.green : AppTheme.textMuted,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['task'],
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: item['isCompleted'] ? AppTheme.textMuted : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: item['isCompleted'] ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, color: AppTheme.primaryColor, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item['location'],
                                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
