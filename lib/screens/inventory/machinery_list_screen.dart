import 'package:flutter/material.dart';
import '../../core/services/inventory_service.dart';
import '../../models/inventory/machine.dart';
import '../../widgets/glass_card.dart';
import '../bauleiter/crew_detail_screen.dart';

class MachineryListScreen extends StatefulWidget {
  const MachineryListScreen({Key? key}) : super(key: key);

  @override
  _MachineryListScreenState createState() => _MachineryListScreenState();
}

class _MachineryListScreenState extends State<MachineryListScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<Machine> _machines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    setState(() {
      _isLoading = true;
    });
    
    final machines = await _inventoryService.getAllMachines();
    
    setState(() {
      _machines = machines;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Inventory: Machinery', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
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
            ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _machines.length,
                itemBuilder: (context, index) {
                  final machine = _machines[index];
                  return _buildMachineCard(machine);
                },
              ),
        ),
      ),
    );
  }

  Widget _buildMachineCard(Machine machine) {
    IconData icon;
    switch (machine.type.toUpperCase()) {
      case 'EXCAVADORA':
        icon = Icons.construction;
        break;
      case 'TALADRO':
        icon = Icons.build;
        break;
      case 'VEHICULO':
        icon = Icons.directions_car;
        break;
      default:
        icon = Icons.settings;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.yellow, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    machine.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${machine.serialNumber} • ${machine.status}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  if (machine.assignedCrewId != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CrewDetailScreen(crewId: machine.assignedCrewId.toString()),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6938EF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF6938EF).withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.engineering, color: Color(0xFF6938EF), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Assigned to Crew ${machine.assignedCrewId}',
                              style: const TextStyle(color: Color(0xFF6938EF), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          machine.currentLocation ?? 'Sin asignar',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
