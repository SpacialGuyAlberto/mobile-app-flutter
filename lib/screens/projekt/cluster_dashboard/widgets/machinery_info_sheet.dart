import 'package:flutter/material.dart';
import '../../../../models/planning/segment.dart';
import '../../../inventory/machinery_list_screen.dart';

/// Modal bottom sheet displaying assigned equipment and machinery (SRP compliant).
class MachineryInfoSheet extends StatelessWidget {
  final Segment segment;

  const MachineryInfoSheet({
    super.key,
    required this.segment,
  });

  static Future<void> show(BuildContext context, Segment segment) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1D21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => MachineryInfoSheet(segment: segment),
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
                  backgroundColor: Colors.yellow.withValues(alpha: 0.2),
                  child: const Text('🚜', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Machinery - Crew ${segment.assignedCrewId ?? "Unknown"}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Working on Segment ${segment.id}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Assigned Equipment',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildEquipmentCard(
              icon: Icons.build,
              title: 'Excavadora Cat 320',
              subtitle: 'EXC-CAT-320 • IN_USE',
            ),
            const SizedBox(height: 8),
            _buildEquipmentCard(
              icon: Icons.settings,
              title: 'Taladro de Calle',
              subtitle: 'DRL-DITCH-01 • IN_USE',
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
                    MaterialPageRoute(builder: (_) => const MachineryListScreen()),
                  );
                },
                child: const Text('VIEW FULL INVENTORY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellow, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
