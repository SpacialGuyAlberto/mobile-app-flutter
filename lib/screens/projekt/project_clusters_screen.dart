import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/glass_card.dart';

class ProjectClustersScreen extends StatelessWidget {
  final String projectId;
  const ProjectClustersScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mocked data mirroring the web-dashboard implementation
    final List<Map<String, dynamic>> clusters = [
      {
        'id': 1,
        'projectId': projectId,
        'name': 'Cluster Mitte',
        'cityArea': 'Berlin Mitte',
        'popCount': 2,
        'netzverteilerCount': 15,
        'status': 'IN_PROGRESS'
      },
      {
        'id': 2,
        'projectId': projectId,
        'name': 'Cluster Kreuzberg',
        'cityArea': 'Friedrichshain-Kreuzberg',
        'popCount': 1,
        'netzverteilerCount': 8,
        'status': 'PLANNED'
      }
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Project Clusters', style: TextStyle(color: Colors.white)),
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
          child: clusters.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: clusters.length,
                  itemBuilder: (context, index) {
                    final cluster = clusters[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          context.push('/project_clusters/$projectId/areas/${cluster['id']}');
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('🏢', style: TextStyle(fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                cluster['name'],
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                                          ),
                                          child: Text(
                                            cluster['cityArea'],
                                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildStatusBadge(cluster['status']),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${cluster['id']}',
                                        style: const TextStyle(color: Colors.white30, fontSize: 10, fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildInfoItem('POPs', cluster['popCount'].toString()),
                                  _buildInfoItem('Netzverteiler', cluster['netzverteilerCount'].toString()),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Future: open create modal/screen
        },
        backgroundColor: const Color(0xFF6938ef),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Cluster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    
    switch (status) {
      case 'IN_PROGRESS':
        bgColor = Colors.orangeAccent.withOpacity(0.1);
        textColor = Colors.orangeAccent;
        break;
      case 'COMPLETED':
        bgColor = const Color(0xFF2fb080).withOpacity(0.1);
        textColor = const Color(0xFF2fb080);
        break;
      case 'PLANNED':
      default:
        bgColor = Colors.white.withOpacity(0.05);
        textColor = Colors.white54;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No clusters found',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project cluster to get started',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
