import 'package:flutter/material.dart';
import '../../../../models/planning/segment.dart';
import '../../../bauleiter/crew_detail_screen.dart';

/// Modal bottom sheet showing crew assignment details for a segment (SRP compliant).
class CrewInfoSheet extends StatelessWidget {
  final Segment segment;

  const CrewInfoSheet({
    super.key,
    required this.segment,
  });

  static Future<void> show(BuildContext context, Segment segment) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1D21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => CrewInfoSheet(segment: segment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: const Icon(Icons.engineering, color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crew ID: ${segment.assignedCrewId ?? "Unknown"}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Working on Segment ${segment.id}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6938EF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrewDetailScreen(crewId: segment.assignedCrewId?.toString() ?? "1"),
                    ),
                  );
                },
                child: const Text('VIEW CREW DETAILS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
