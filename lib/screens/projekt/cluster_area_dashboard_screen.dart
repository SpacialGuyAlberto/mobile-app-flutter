import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/interactive_map_view.dart';

class ClusterAreaDashboardScreen extends StatefulWidget {
  final String projectId;
  final String clusterId;

  const ClusterAreaDashboardScreen({
    Key? key,
    required this.projectId,
    required this.clusterId,
  }) : super(key: key);

  @override
  State<ClusterAreaDashboardScreen> createState() => _ClusterAreaDashboardScreenState();
}

class _ClusterAreaDashboardScreenState extends State<ClusterAreaDashboardScreen> {
  // Mock data mirroring the web-dashboard implementation
  final List<Map<String, dynamic>> elements = [
    {'id': 'POP-01', 'type': 'POP', 'name': 'Main POP Mitte', 'status': 'ACTIVE'},
    {'id': 'DP-01', 'type': 'DP', 'name': 'Netzverteiler A', 'status': 'ACTIVE'},
    {'id': 'DP-02', 'type': 'DP', 'name': 'Netzverteiler B', 'status': 'PLANNED'},
    {'id': 'DP-03', 'type': 'DP', 'name': 'Netzverteiler C', 'status': 'ACTIVE'},
    {'id': 'AC-01', 'type': 'ACOMETIDA', 'name': 'Route 1', 'status': 'ACTIVE'},
    {'id': 'AC-02', 'type': 'ACOMETIDA', 'name': 'Route 2', 'status': 'ACTIVE'},
    {'id': 'AC-03', 'type': 'ACOMETIDA', 'name': 'Route 3', 'status': 'PLANNED'},
    {'id': 'AC-04', 'type': 'ACOMETIDA', 'name': 'Route 4', 'status': 'ERROR'},
    {'id': 'HE-01', 'type': 'HEUP', 'name': 'House 12', 'status': 'ACTIVE'},
    {'id': 'HE-02', 'type': 'HEUP', 'name': 'House 14', 'status': 'ACTIVE'},
    {'id': 'HE-03', 'type': 'HEUP', 'name': 'House 16', 'status': 'PLANNED'},
    {'id': 'HE-04', 'type': 'HEUP', 'name': 'House 18', 'status': 'ERROR'},
  ];

  late Map<String, List<Map<String, dynamic>>> groupedElements;
  late Map<String, int> stats;
  String expandedGroup = 'POP';

  @override
  void initState() {
    super.initState();
    _calculateStatsAndGroups();
  }

  void _calculateStatsAndGroups() {
    groupedElements = {
      'POP': elements.where((e) => e['type'] == 'POP').toList(),
      'Netzverteiler': elements.where((e) => e['type'] == 'DP').toList(),
      'Acometidas': elements.where((e) => e['type'] == 'ACOMETIDA').toList(),
      'HEÜPs': elements.where((e) => e['type'] == 'HEUP').toList(),
    };

    stats = {
      'POP': groupedElements['POP']!.length,
      'Netzverteiler': groupedElements['Netzverteiler']!.length,
      'Acometidas': groupedElements['Acometidas']!.length,
      'HEÜPs': groupedElements['HEÜPs']!.length,
    };
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'POP':
        return const Color(0xFF6938ef);
      case 'DP':
      case 'Netzverteiler':
        return const Color(0xFF2fb080);
      case 'ACOMETIDA':
      case 'Acometidas':
        return const Color(0xFFfbbf24);
      case 'HEUP':
      case 'HEÜPs':
        return const Color(0xFFef4444);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Cluster Areas', style: TextStyle(color: Colors.white)),
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
        child: Column(
          children: [
            // Map Area
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  const InteractiveMapView(),
                  // Overlay gradient for seamless transition
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xFF131415),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Panel
            Expanded(
              flex: 6,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF131415),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      const Text(
                        'NETWORK NODES BREAKDOWN',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAccordionList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      children: [
        _buildStatCard('POPs', stats['POP']!, _getColorForType('POP')),
        _buildStatCard('Netzverteiler', stats['Netzverteiler']!, _getColorForType('DP')),
        _buildStatCard('Acometidas', stats['Acometidas']!, _getColorForType('ACOMETIDA')),
        _buildStatCard('HEÜPs', stats['HEÜPs']!, _getColorForType('HEUP')),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(Icons.circle, color: color, size: 12),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionList() {
    return Column(
      children: groupedElements.entries.map((entry) {
        final groupName = entry.key;
        final items = entry.value;
        final isExpanded = expandedGroup == groupName;
        final color = _getColorForType(groupName);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    expandedGroup = isExpanded ? '' : groupName;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: items.isNotEmpty ? color : Colors.white, size: 10),
                      const SizedBox(width: 12),
                      Text(
                        groupName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${items.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'NO NODES FOUND',
                              style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1),
                            ),
                          ),
                        )
                      : Column(
                          children: items.map((element) {
                            return _buildNodeItem(element);
                          }).toList(),
                        ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNodeItem(Map<String, dynamic> element) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.02)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        element['name'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${element['id']}',
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNodeStatusBadge(element['status']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    
    switch (status) {
      case 'ACTIVE':
        bgColor = const Color(0xFF2fb080).withOpacity(0.1);
        textColor = const Color(0xFF2fb080);
        break;
      case 'ERROR':
        bgColor = const Color(0xFFef4444).withOpacity(0.1);
        textColor = const Color(0xFFef4444);
        break;
      case 'PLANNED':
      default:
        bgColor = Colors.white.withOpacity(0.05);
        textColor = Colors.white54;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
