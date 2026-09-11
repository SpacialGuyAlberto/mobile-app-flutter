import 'package:flutter/material.dart';
// Removed lucide_icons
import '../../widgets/glass_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF131415), Color(0xFF1C1D21)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const TabBar(
              indicatorColor: Color(0xFF6B4C9A),
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xFF8A8F98),
              tabs: [
                Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Materials'),
                Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Machinery'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMaterialsList(),
                  _buildMachineryList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsList() {
    final materials = [
      {'name': 'Fiber Optic Cable (Single-Mode)', 'stock': '1,200 m', 'status': 'Good'},
      {'name': 'HDPE Microducts', 'stock': '800 m', 'status': 'Good'},
      {'name': 'Splice Closures', 'stock': '15 units', 'status': 'Low Stock'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final mat = materials[index];
        final isLow = mat['status'] == 'Low Stock';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.inventory_outlined, color: Colors.blueAccent, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mat['name']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('In Stock: ${mat['stock']}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLow ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isLow ? Colors.redAccent : Colors.greenAccent),
                  ),
                  child: Text(
                    mat['status']!,
                    style: TextStyle(color: isLow ? Colors.redAccent : Colors.greenAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMachineryList() {
    final machinery = [
      {'name': 'Excavator CAT 320', 'location': 'Berlin Site', 'status': 'Active'},
      {'name': 'Trencher Vermeer TRX250', 'location': 'Munich Site', 'status': 'Maintenance'},
      {'name': 'Cable Pulling Winch', 'location': 'Warehouse', 'status': 'Available'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: machinery.length,
      itemBuilder: (context, index) {
        final mach = machinery[index];
        Color statusColor = mach['status'] == 'Active' ? Colors.greenAccent : (mach['status'] == 'Available' ? Colors.blueAccent : Colors.orangeAccent);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.agriculture_outlined, color: Colors.amber, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mach['name']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Color(0xFF8A8F98), size: 14),
                          const SizedBox(width: 4),
                          Text(mach['location']!, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  mach['status']!,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
