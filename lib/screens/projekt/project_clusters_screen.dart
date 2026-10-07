import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_service.dart';

class ProjectClustersScreen extends StatefulWidget {
  final String projectId;
  const ProjectClustersScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<ProjectClustersScreen> createState() => _ProjectClustersScreenState();
}

class _ProjectClustersScreenState extends State<ProjectClustersScreen> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  String _projectName = 'Loading...';
  List<Map<String, dynamic>> _clusters = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      // Fetch project details
      final projectData = await api.get('/projects/${widget.projectId}');
      _projectName = projectData['name'] ?? 'Project ${widget.projectId}';

      // Fetch all clusters
      final clustersData = await api.get('/clusters');
      final allClusters = List<Map<String, dynamic>>.from(clustersData);
      
      // Filter by projectId
      final projectClusters = allClusters.where((c) => c['projectId'].toString() == widget.projectId.toString()).toList();
      
      // Calculate popCount and netzverteilerCount for the UI
      for (var c in projectClusters) {
        final pops = c['pops'] as List? ?? [];
        c['popCount'] = pops.length;
        int nvtCount = 0;
        for (var p in pops) {
          final nvts = p['nvts'] as List? ?? [];
          nvtCount += nvts.length;
        }
        c['netzverteilerCount'] = nvtCount;
        c['description'] = c['description'] ?? 'No description provided.';
        c['name'] = c['name'] ?? 'Cluster ${c['id']}';
      }

      if (mounted) {
        setState(() {
          _clusters = projectClusters;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading clusters: $e');
      if (mounted) {
        setState(() {
          _projectName = 'Project ${widget.projectId}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131415),

      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, color: Colors.white54, size: 14),
                  SizedBox(width: 8),
                  Text('BACK TO PROJECTS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _projectName,
              style: const TextStyle(color: Colors.white, fontSize: 42, fontFamily: 'serif', height: 1.0, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Manage project areas, fiber optic deployment segments,\nand materials',
              style: TextStyle(color: Color(0xFF8A8F98), fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 48),
            
            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('CLUSTERS', 0),
                  const SizedBox(width: 24),
                  _buildTab('SEGMENTS', 1),
                  const SizedBox(width: 24),
                  _buildTab('PROJECT MATERIALS', 2),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6938ef),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text('NEW CLUSTER', style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Clusters List
            ..._clusters.map((cluster) => _buildClusterCard(cluster)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white30,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildClusterCard(Map<String, dynamic> cluster) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D21),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.business, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    cluster['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF6938ef).withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ID: ${cluster['id']}',
                  style: const TextStyle(color: Color(0xFF6938ef), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              cluster['description'],
              style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('POPS', cluster['popCount'].toString()),
              _buildStat('NETZVERTEILER', cluster['netzverteilerCount'].toString()),
              const SizedBox(width: 32), // Spacer
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push('/project_clusters/${widget.projectId}/areas/${cluster['id']}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('MANAGE AREAS', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'serif')),
      ],
    );
  }
}
