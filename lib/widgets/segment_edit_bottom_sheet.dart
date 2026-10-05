import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SegmentEditBottomSheet extends StatefulWidget {
  final Map<String, dynamic> segment;
  final VoidCallback onSaved;

  const SegmentEditBottomSheet({
    Key? key,
    required this.segment,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<SegmentEditBottomSheet> createState() => _SegmentEditBottomSheetState();
}

class _SegmentEditBottomSheetState extends State<SegmentEditBottomSheet> {
  late String _workflowState;
  late TextEditingController _crewIdController;
  late TextEditingController _ductDiameterController;
  bool _isLoading = false;

  final List<String> _workflowStates = [
    'PLAN',
    'TRENCH_OPEN',
    'BLOWN',
    'COMPLETED',
  ];

  @override
  void initState() {
    super.initState();
    _workflowState = widget.segment['currentState'] ?? 'PLAN';
    if (!_workflowStates.contains(_workflowState)) {
      _workflowState = 'PLAN';
    }
    
    _crewIdController = TextEditingController(
      text: widget.segment['assignedCrewId']?.toString() ?? '',
    );
    _ductDiameterController = TextEditingController(
      text: widget.segment['ductDiameter']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _crewIdController.dispose();
    _ductDiameterController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedData = {
        'currentState': _workflowState,
        'assignedCrewId': int.tryParse(_crewIdController.text),
        'ductDiameter': double.tryParse(_ductDiameterController.text),
      };

      // In a real app we would call the update endpoint. For now we simulate it.
      // await http.put(
      //   Uri.parse('http://localhost:8080/api/v1/planning/segments/${widget.segment['id']}'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode(updatedData),
      // );
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Segment updated successfully'), backgroundColor: Colors.green),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating segment: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF131415),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Segment ${widget.segment['id'] ?? ''}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Workflow State Dropdown
            Text(
              'Workflow State',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _workflowState,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  items: _workflowStates.map((state) {
                    return DropdownMenuItem(
                      value: state,
                      child: Text(state.replaceAll('_', ' ')),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _workflowState = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Assigned Crew ID
            Text(
              'Assigned Crew ID',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _crewIdController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0x1AFFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'e.g. 1',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 20),
            
            // Duct Diameter
            Text(
              'Duct Diameter (m)',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ductDiameterController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0x1AFFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'e.g. 0.05',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 30),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6938EF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
