import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/glass_card.dart';

class WorkLogsScreen extends StatelessWidget {
  const WorkLogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> logs = [
      {
        'task': 'Trench Excavation',
        'segment': 'Segment A - Charlottenstrasse',
        'metrics': '60cm Depth, 30cm Width',
        'hours': '4.5',
        'date': 'Today',
      },
      {
        'task': 'Conduit Laying',
        'segment': 'Segment A - Charlottenstrasse',
        'metrics': '144-core Fiber installed',
        'hours': '3.0',
        'date': 'Yesterday',
      },
      {
        'task': 'Site Prep',
        'segment': 'Segment B - Friedrichstrasse',
        'hours': '2.0',
        'date': 'Oct 12, 2024',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
              child: GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Hours This Week', '24.5', Colors.greenAccent),
                    _buildStatColumn('Tasks Done', '12', Colors.blueAccent),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Logs',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.construction, color: Colors.amber, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['task'],
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  log['segment'],
                                  style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 13),
                                ),
                                if (log.containsKey('metrics')) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    log['metrics'],
                                    style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${log['hours']}h',
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log['date'],
                                style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 12),
                              ),
                            ],
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/create_log');
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text('New Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
