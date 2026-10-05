import 'package:flutter/material.dart';
import '../../models/planning/fencing_plan.dart';
import '../../core/network/fencing_plan_repository.dart';
import '../../core/network/api_service.dart';
import '../../widgets/glass_card.dart';

class FencingPlanScreen extends StatefulWidget {
  final int segmentId;

  const FencingPlanScreen({Key? key, required this.segmentId}) : super(key: key);

  @override
  State<FencingPlanScreen> createState() => _FencingPlanScreenState();
}

class _FencingPlanScreenState extends State<FencingPlanScreen> {
  late FencingPlanRepository _repository;
  FencingPlan? _fencingPlan;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = FencingPlanRepository(apiService: ApiService());
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    final plans = await _repository.getFencingPlansForSegment(widget.segmentId);
    if (plans.isNotEmpty) {
      _fencingPlan = plans.first;
    } else {
      _fencingPlan = FencingPlan(id: 0, segmentId: widget.segmentId, closureType: 'PARTIAL', elements: []);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _savePlan() async {
    if (_fencingPlan == null) return;
    setState(() => _isSaving = true);
    
    final savedPlan = await _repository.saveFencingPlan(_fencingPlan!);
    if (savedPlan != null) {
      setState(() => _fencingPlan = savedPlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fencing Plan saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving Fencing Plan.'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  void _addElement() {
    setState(() {
      final newElements = List<FencingElement>.from(_fencingPlan!.elements);
      newElements.add(const FencingElement(
        id: 0,
        elementType: 'CONE',
        latitude: 0.0,
        longitude: 0.0,
      ));
      _fencingPlan = FencingPlan(
        id: _fencingPlan!.id,
        segmentId: _fencingPlan!.segmentId,
        closureType: _fencingPlan!.closureType,
        elements: newElements,
      );
    });
  }

  void _removeElement(int index) {
    setState(() {
      final newElements = List<FencingElement>.from(_fencingPlan!.elements);
      newElements.removeAt(index);
      _fencingPlan = FencingPlan(
        id: _fencingPlan!.id,
        segmentId: _fencingPlan!.segmentId,
        closureType: _fencingPlan!.closureType,
        elements: newElements,
      );
    });
  }

  void _updateClosureType(String newType) {
    setState(() {
      _fencingPlan = FencingPlan(
        id: _fencingPlan!.id,
        segmentId: _fencingPlan!.segmentId,
        closureType: newType,
        elements: _fencingPlan!.elements,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit Fencing Plan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF131415), Color(0xFF1C1D21)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Closure Type', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D2E33)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _fencingPlan?.closureType ?? 'PARTIAL',
                            dropdownColor: const Color(0xFF1C1D21),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            items: const [
                              DropdownMenuItem(value: 'PARTIAL', child: Text('Partial Closure')),
                              DropdownMenuItem(value: 'FULL', child: Text('Full Road Closure')),
                              DropdownMenuItem(value: 'SIDEWALK', child: Text('Sidewalk Only')),
                            ],
                            onChanged: (val) {
                              if (val != null) _updateClosureType(val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fencing Elements', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                            onPressed: _addElement,
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _fencingPlan!.elements.isEmpty
                            ? const Center(child: Text('No elements added yet.', style: TextStyle(color: Colors.white54)))
                            : ListView.builder(
                                itemCount: _fencingPlan!.elements.length,
                                itemBuilder: (ctx, i) {
                                  final el = _fencingPlan!.elements[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: GlassCard(
                                      child: ListTile(
                                        leading: const Icon(Icons.warning_amber, color: Colors.orangeAccent),
                                        title: Text('Element: ${el.elementType}', style: const TextStyle(color: Colors.white)),
                                        subtitle: Text('Lat: ${el.latitude}, Lng: ${el.longitude}', style: const TextStyle(color: Colors.white54)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          onPressed: () => _removeElement(i),
                                        ),
                                        onTap: () {
                                          // Aquí se podría abrir un modal para editar Lat/Lng o tipo
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _savePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text('Save Fencing Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
