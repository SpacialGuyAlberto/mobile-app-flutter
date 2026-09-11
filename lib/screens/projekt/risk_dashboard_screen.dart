import 'package:flutter/material.dart';
// Removed lucide_icons
import '../../widgets/glass_card.dart';

class RiskDashboardScreen extends StatelessWidget {
  const RiskDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> risks = [
      {
        'title': 'Severe Weather Delay',
        'severity': 'High',
        'impact': 'Schedule',
        'project': 'Berlin Fiber Deployment',
      },
      {
        'title': 'Material Shortage (Microducts)',
        'severity': 'Medium',
        'impact': 'Cost',
        'project': 'Munich Network Expansion',
      },
      {
        'title': 'Permit Pending Approval',
        'severity': 'Low',
        'impact': 'Schedule',
        'project': 'Hamburg Pilot Segment',
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: _buildRiskSummaryCard('High Risk', '1', Colors.redAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildRiskSummaryCard('Medium Risk', '1', Colors.orangeAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildRiskSummaryCard('Low Risk', '1', Colors.greenAccent)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: risks.length,
              itemBuilder: (context, index) {
                final risk = risks[index];
                Color sevColor = risk['severity'] == 'High' 
                    ? Colors.redAccent 
                    : (risk['severity'] == 'Medium' ? Colors.orangeAccent : Colors.greenAccent);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: sevColor, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(risk['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Project: ${risk['project']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: sevColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: sevColor),
                                    ),
                                    child: Text(risk['severity'], style: TextStyle(color: sevColor, fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.blueAccent),
                                    ),
                                    child: Text('Impact: ${risk['impact']}', style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummaryCard(String title, String count, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(count, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
