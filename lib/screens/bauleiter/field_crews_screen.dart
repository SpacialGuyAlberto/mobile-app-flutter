import 'package:flutter/material.dart';
// Removed lucide_icons
import '../../widgets/glass_card.dart';

class FieldCrewsScreen extends StatelessWidget {
  const FieldCrewsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> crews = [
      {
        'name': 'Alpha Digging Team',
        'foreman': 'Hans Müller',
        'members': 4,
        'project': 'Berlin Fiber Deployment',
      },
      {
        'name': 'Beta Splicing Team',
        'foreman': 'Klaus Weber',
        'members': 2,
        'project': 'Munich Network Expansion',
      },
      {
        'name': 'Gamma Civil Works',
        'foreman': 'Julia Schmitt',
        'members': 5,
        'project': 'Idle',
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF131415), Color(0xFF1C1D21)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: crews.length,
        itemBuilder: (context, index) {
          final crew = crews[index];
          final isIdle = crew['project'] == 'Idle';
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                            child: Icon(Icons.group_outlined, color: Colors.blueAccent),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            crew['name'],
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isIdle ? Colors.orangeAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isIdle ? Colors.orangeAccent : Colors.greenAccent),
                        ),
                        child: Text(
                          isIdle ? 'Idle' : 'Active',
                          style: TextStyle(color: isIdle ? Colors.orangeAccent : Colors.greenAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: Color(0xFF8A8F98), size: 16),
                      const SizedBox(width: 8),
                      Text('Foreman: ${crew['foreman']}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.work_outline, color: Color(0xFF8A8F98), size: 16),
                      const SizedBox(width: 8),
                      Text('Assigned: ${crew['project']}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
