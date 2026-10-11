import 'package:flutter/material.dart';

/// Modal bottom sheet allowing the user to select which node type to add (SRP compliant).
class AddNodeTypeSheet extends StatelessWidget {
  final VoidCallback onAddPop;
  final VoidCallback onAddNetzverteiler;
  final VoidCallback onAddSegment;
  final VoidCallback onAddAcometida;

  const AddNodeTypeSheet({
    super.key,
    required this.onAddPop,
    required this.onAddNetzverteiler,
    required this.onAddSegment,
    required this.onAddAcometida,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onAddPop,
    required VoidCallback onAddNetzverteiler,
    required VoidCallback onAddSegment,
    required VoidCallback onAddAcometida,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1D21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddNodeTypeSheet(
        onAddPop: onAddPop,
        onAddNetzverteiler: onAddNetzverteiler,
        onAddSegment: onAddSegment,
        onAddAcometida: onAddAcometida,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Network Element',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTile(Icons.router, Colors.purpleAccent, 'Add POP', () {
              Navigator.pop(context);
              onAddPop();
            }),
            _buildTile(Icons.settings_input_component, Colors.orangeAccent, 'Add Netzverteiler', () {
              Navigator.pop(context);
              onAddNetzverteiler();
            }),
            _buildTile(Icons.linear_scale, Colors.greenAccent, 'Add Segment', () {
              Navigator.pop(context);
              onAddSegment();
            }),
            _buildTile(Icons.home, Colors.blueAccent, 'Add Acometida', () {
              Navigator.pop(context);
              onAddAcometida();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, Color color, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
