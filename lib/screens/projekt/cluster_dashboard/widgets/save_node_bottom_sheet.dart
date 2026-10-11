import 'package:flutter/material.dart';
import '../../../../models/planning/infrastructure_elements.dart';

class SaveNodeData {
  final String name;
  final String? popId;

  const SaveNodeData({
    required this.name,
    this.popId,
  });
}

/// Modal bottom sheet form for naming and assigning a newly placed node (SRP compliant).
class SaveNodeBottomSheet extends StatefulWidget {
  final String activeDrawTool;
  final List<Pop> pops;
  final ValueChanged<SaveNodeData> onSave;

  const SaveNodeBottomSheet({
    super.key,
    required this.activeDrawTool,
    required this.pops,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String activeDrawTool,
    required List<Pop> pops,
    required ValueChanged<SaveNodeData> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1D21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SaveNodeBottomSheet(
        activeDrawTool: activeDrawTool,
        pops: pops,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SaveNodeBottomSheet> createState() => _SaveNodeBottomSheetState();
}

class _SaveNodeBottomSheetState extends State<SaveNodeBottomSheet> {
  String _name = '';
  String? _selectedPopId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Save ${widget.activeDrawTool}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Name / Identifier',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
            ),
            onChanged: (val) => _name = val,
          ),
          if (widget.activeDrawTool == 'Netzverteiler') ...[
            const SizedBox(height: 24),
            const Text(
              'POP (SELECT TO ASSIGN)',
              style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.pops.isEmpty)
              const Text('No POPs available in this cluster.', style: TextStyle(color: Colors.white30))
            else
              ...widget.pops.map((pop) {
                final isSelected = _selectedPopId == pop.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPopId = pop.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6938EF).withValues(alpha: 0.2) : Colors.transparent,
                      border: Border.all(color: isSelected ? const Color(0xFF6938EF) : Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: isSelected ? const Color(0xFF6938EF) : Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pop.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(pop.locationAddress, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6938EF),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onSave(SaveNodeData(name: _name, popId: _selectedPopId));
            },
            child: const Text('SAVE ELEMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}
