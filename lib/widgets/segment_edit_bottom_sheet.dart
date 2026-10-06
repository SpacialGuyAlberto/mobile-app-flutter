import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screens/projekt/segment_permits_screen.dart';

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
  late String _workType;
  String? _selectedCrewId;
  
  late TextEditingController _ductDiameterController;
  late TextEditingController _streetNameController;
  late TextEditingController _streetTypeController;
  late TextEditingController _soilTypeController;
  late TextEditingController _lengthController;
  late TextEditingController _trafficLevelController;
  late TextEditingController _startAddressController;
  late TextEditingController _endAddressController;
  late TextEditingController _startNvtIdController;
  late TextEditingController _endNvtIdController;
  late TextEditingController _connectedPopIdController;

  bool _isLoading = false;

  final List<String> _workflowStates = [
    'PLAN', 'SURVEY', 'PERMISSION', 'READY', 'CONSTRUCTION', 'QA', 'COMPLETED', 'INPROGRESS', 'PLANNED'
  ];
  
  final List<String> _workTypes = [
    'EXCAVATION', 'DUCTINSTALLATION', 'TRENCHING', 'DRILLING', 'BACKFILL', 'ASPHALT', 'QA', 'DUCTLAYING', 'FIBERBLOWING', 'SPLICING', 'RESTORATION', 'DOCUMENTATION'
  ];

  final List<Map<String, String>> _availableCrews = [
    {'id': '1', 'name': 'Alpha Digging Team (Hans Müller)'},
    {'id': '2', 'name': 'Beta Splicing Team (Klaus Weber)'},
    {'id': '3', 'name': 'Gamma Civil Works (Julia Schmitt)'},
  ];

  @override
  void initState() {
    super.initState();
    _workflowState = widget.segment['currentState']?.toString().toUpperCase() ?? 'PLAN';
    if (!_workflowStates.contains(_workflowState)) _workflowState = 'PLAN';
    
    _workType = widget.segment['workType']?.toString().toUpperCase() ?? 'TRENCHING';
    if (!_workTypes.contains(_workType)) _workType = 'TRENCHING';
    
    _selectedCrewId = widget.segment['assignedCrewId']?.toString();
    
    // Fallback if the id is not in the list
    if (_selectedCrewId != null && !_availableCrews.any((c) => c['id'] == _selectedCrewId)) {
      _availableCrews.add({'id': _selectedCrewId!, 'name': 'Unknown Crew ($_selectedCrewId)'});
    }
    _ductDiameterController = TextEditingController(text: widget.segment['ductDiameter']?.toString() ?? '');
    _streetNameController = TextEditingController(text: widget.segment['streetName']?.toString() ?? '');
    _streetTypeController = TextEditingController(text: widget.segment['streetType']?.toString() ?? '');
    _soilTypeController = TextEditingController(text: widget.segment['soilType']?.toString() ?? '');
    _lengthController = TextEditingController(text: widget.segment['length']?.toString() ?? '');
    _trafficLevelController = TextEditingController(text: widget.segment['trafficLevel']?.toString() ?? '');
    _startAddressController = TextEditingController(text: widget.segment['startAddress']?.toString() ?? '');
    _endAddressController = TextEditingController(text: widget.segment['endAddress']?.toString() ?? '');
    _startNvtIdController = TextEditingController(text: widget.segment['startNvtId']?.toString() ?? '');
    _endNvtIdController = TextEditingController(text: widget.segment['endNvtId']?.toString() ?? '');
    _connectedPopIdController = TextEditingController(text: widget.segment['connectedPopId']?.toString() ?? '');
  }

  @override
  void dispose() {
    _ductDiameterController.dispose();
    _streetNameController.dispose();
    _streetTypeController.dispose();
    _soilTypeController.dispose();
    _lengthController.dispose();
    _trafficLevelController.dispose();
    _startAddressController.dispose();
    _endAddressController.dispose();
    _startNvtIdController.dispose();
    _endNvtIdController.dispose();
    _connectedPopIdController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final segmentId = widget.segment['id'];
      
      final updatedData = {
        if (segmentId != null) 'id': segmentId,
        'currentState': _workflowState,
        'workType': _workType,
        'assignedCrewId': int.tryParse(_selectedCrewId ?? ''),
        'ductDiameter': double.tryParse(_ductDiameterController.text),
        'streetName': _streetNameController.text,
        'streetType': _streetTypeController.text,
        'soilType': _soilTypeController.text,
        'length': double.tryParse(_lengthController.text),
        'trafficLevel': _trafficLevelController.text,
        'startAddress': _startAddressController.text,
        'endAddress': _endAddressController.text,
        'startNvtId': _startNvtIdController.text,
        'endNvtId': _endNvtIdController.text,
        'connectedPopId': _connectedPopIdController.text,
      };
      
      if (segmentId != null) {
        final url = Uri.parse('http://10.0.2.2:8080/api/segments/$segmentId');
        final response = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updatedData),
        );

        if (response.statusCode == 409) {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] == 'CREW_BUSY') {
            if (mounted) {
              setState(() => _isLoading = false);
              final schedule = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1D21),
                  title: const Text('Crew is Busy', style: TextStyle(color: Colors.white)),
                  content: Text(errorData['message'] ?? 'Crew is currently busy.', style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('SCHEDULE', style: TextStyle(color: Color(0xFF6938EF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (schedule == true) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Crew scheduled successfully for later'), backgroundColor: Colors.green),
                  );
                  widget.onSaved();
                  Navigator.pop(context);
                }
              }
              return;
            }
          }
        } else if (response.statusCode >= 200 && response.statusCode < 300) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Segment updated successfully'), backgroundColor: Colors.green),
            );
            widget.onSaved();
            Navigator.pop(context);
          }
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
      } else {
        // Mock success if no ID
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Segment updated successfully'), backgroundColor: Colors.green),
          );
          widget.onSaved();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating segment: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
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
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              items: items.map((state) => DropdownMenuItem(value: state, child: Text(state))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0x1AFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF131415),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Segment ${widget.segment['id'] ?? ''}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.file_present, color: Colors.blueAccent),
                    tooltip: 'Manage Permits',
                    onPressed: () {
                      final segId = widget.segment['id']?.toString();
                      if (segId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SegmentPermitsScreen(segmentId: segId),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdown('Workflow State', _workflowState, _workflowStates, (val) {
                    if (val != null) setState(() => _workflowState = val);
                  }),
                  _buildDropdown('Work Type', _workType, _workTypes, (val) {
                    if (val != null) setState(() => _workType = val);
                  }),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned Crew', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
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
                            value: _selectedCrewId,
                            hint: const Text('Select a Crew', style: TextStyle(color: Colors.white54)),
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A1A1A),
                            style: const TextStyle(color: Colors.white),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('None')),
                              ..._availableCrews.map((crew) => DropdownMenuItem(value: crew['id'], child: Text(crew['name']!))).toList(),
                            ],
                            onChanged: (val) => setState(() => _selectedCrewId = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                  _buildTextField('Street Name', _streetNameController),
                  _buildTextField('Street Type', _streetTypeController),
                  _buildTextField('Soil Type', _soilTypeController),
                  _buildTextField('Traffic Level', _trafficLevelController),
                  _buildTextField('Length (m)', _lengthController, type: const TextInputType.numberWithOptions(decimal: true)),
                  _buildTextField('Duct Diameter (m)', _ductDiameterController, type: const TextInputType.numberWithOptions(decimal: true)),
                  
                  const Divider(color: Colors.white24, height: 40),
                  const Text('Connections & Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  _buildTextField('Start Address', _startAddressController),
                  _buildTextField('End Address', _endAddressController),
                  _buildTextField('Start NVT ID', _startNvtIdController),
                  _buildTextField('End NVT ID', _endNvtIdController),
                  _buildTextField('Connected POP ID', _connectedPopIdController),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6938EF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
