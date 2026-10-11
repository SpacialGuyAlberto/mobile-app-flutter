import 'package:flutter/material.dart';
import '../../../../models/planning/geometry_point.dart';
import '../../../../widgets/glass_card.dart';
import '../models/create_segment_metadata.dart';
import '../models/segment_creation_payload.dart';

/// Modal bottom sheet form for inputting and validating segment parameters (SRP compliant).
class SaveSegmentBottomSheet extends StatefulWidget {
  final double calculatedLength;
  final List<GeometryPoint> points;
  final CreateSegmentMetadata metadata;
  final Future<void> Function(SegmentCreationPayload payload) onSave;

  const SaveSegmentBottomSheet({
    super.key,
    required this.calculatedLength,
    required this.points,
    required this.metadata,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required double calculatedLength,
    required List<GeometryPoint> points,
    required CreateSegmentMetadata metadata,
    required Future<void> Function(SegmentCreationPayload payload) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SaveSegmentBottomSheet(
        calculatedLength: calculatedLength,
        points: points,
        metadata: metadata,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SaveSegmentBottomSheet> createState() => _SaveSegmentBottomSheetState();
}

class _SaveSegmentBottomSheetState extends State<SaveSegmentBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ductDiameterController = TextEditingController();

  String _streetType = 'residential';
  String _workType = 'EXCAVATION';
  String _soilType = 'ASPHALT';
  String _trafficLevel = 'LOW';
  String? _assignedCrewId;
  String? _startNvtId;
  String? _endNvtId;
  String? _connectedPopId;

  DateTime? _plannedStartDate;
  DateTime? _plannedEndDate;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ductDiameterController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Street Name is required')),
      );
      return;
    }

    if (_plannedStartDate != null &&
        _plannedEndDate != null &&
        _plannedStartDate!.isAfter(_plannedEndDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Start date must be before or equal to End date.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = SegmentCreationPayload(
        streetName: _nameController.text.trim(),
        streetType: _streetType,
        workType: _workType,
        soilType: _soilType,
        trafficLevel: _trafficLevel,
        ductDiameter: double.tryParse(_ductDiameterController.text),
        assignedCrewId: _assignedCrewId != null ? int.tryParse(_assignedCrewId!) : null,
        startNvtId: _startNvtId != null ? int.tryParse(_startNvtId!) : null,
        endNvtId: _endNvtId != null ? int.tryParse(_endNvtId!) : null,
        connectedPopId: _connectedPopId != null ? int.tryParse(_connectedPopId!) : null,
        length: widget.calculatedLength,
        plannedStartDate: _plannedStartDate,
        plannedEndDate: _plannedEndDate,
        points: widget.points,
      );

      await widget.onSave(payload);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 40,
      ),
      child: GlassCard(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Save Segment Info',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Calculated Length: ${widget.calculatedLength.toStringAsFixed(2)}m',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Street Name (e.g. Hauptstraße)',
                    labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _streetType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF16171A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Street Type',
                          labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['residential', 'highway', 'commercial', 'industrial']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _streetType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _workType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF16171A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Work Type',
                          labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['EXCAVATION', 'TRENCHING', 'DUCT_INSTALLATION']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _workType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _soilType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF16171A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Soil Type',
                          labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['ASPHALT', 'SOIL', 'COBBLESTONE', 'PAVEMENT', 'MIXED']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _soilType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _trafficLevel,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF16171A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Traffic Level',
                          labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['LOW', 'MEDIUM', 'HIGH']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _trafficLevel = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ductDiameterController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Duct Diameter (mm) - Optional',
                    labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _plannedStartDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (selected != null) {
                            setState(() => _plannedStartDate = selected);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _plannedStartDate != null
                                ? '${_plannedStartDate!.year}-${_plannedStartDate!.month.toString().padLeft(2, '0')}-${_plannedStartDate!.day.toString().padLeft(2, '0')}'
                                : 'Select Date',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _plannedEndDate ?? _plannedStartDate ?? DateTime.now(),
                            firstDate: _plannedStartDate ?? DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (selected != null) {
                            setState(() => _plannedEndDate = selected);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _plannedEndDate != null
                                ? '${_plannedEndDate!.year}-${_plannedEndDate!.month.toString().padLeft(2, '0')}-${_plannedEndDate!.day.toString().padLeft(2, '0')}'
                                : 'Select Date',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _assignedCrewId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF16171A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Assigned Crew',
                    labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('-- No Crew Assigned --', style: TextStyle(color: Colors.white54)),
                    ),
                    ...widget.metadata.crews.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c['id']?.toString(),
                        child: Text(c['name']?.toString() ?? 'Unknown Crew'),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _assignedCrewId = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _startNvtId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF16171A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Start NVT',
                          labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('-- None --', style: TextStyle(color: Colors.white54)),
                          ),
                          ...widget.metadata.netzverteilers.map(
                            (n) => DropdownMenuItem<String?>(
                              value: n['id']?.toString(),
                              child: Text(n['identifier']?.toString() ?? 'NVT'),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _startNvtId = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _endNvtId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF16171A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'End NVT',
                          labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('-- None --', style: TextStyle(color: Colors.white54)),
                          ),
                          ...widget.metadata.netzverteilers.map(
                            (n) => DropdownMenuItem<String?>(
                              value: n['id']?.toString(),
                              child: Text(n['identifier']?.toString() ?? 'NVT'),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _endNvtId = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _connectedPopId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF16171A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Connected POP',
                    labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('-- None --', style: TextStyle(color: Colors.white54)),
                    ),
                    ...widget.metadata.pops.map(
                      (p) => DropdownMenuItem<String?>(
                        value: p['id']?.toString(),
                        child: Text(p['name']?.toString() ?? 'POP'),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _connectedPopId = val),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Text('Save Segment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
