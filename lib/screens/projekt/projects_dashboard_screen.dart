import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/interactive_map_view.dart';
import '../../core/network/api_service.dart';
import '../../models/planning/project.dart';

class ProjectsDashboardScreen extends StatefulWidget {
  const ProjectsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsDashboardScreen> createState() => _ProjectsDashboardScreenState();
}

class _ProjectsDashboardScreenState extends State<ProjectsDashboardScreen> {
  String selectedProject = 'All Projects';
  bool _isLoading = true;
  List<Project> _projects = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final data = await api.get('/projects');
      final List<dynamic> jsonList = data;
      
      final projects = jsonList.map((json) => Project.fromJson(json)).toList();
      final markers = <Marker>{};

      for (var p in projects) {
        if (p.geometry.isNotEmpty) {
          markers.add(Marker(
            markerId: MarkerId(p.id),
            position: LatLng(p.geometry.first.latitude, p.geometry.first.longitude),
            infoWindow: InfoWindow(title: p.name, snippet: p.description),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ));
        }
      }

      setState(() {
        _projects = projects;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading projects: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildKPIGrid(),
              const SizedBox(height: 20),
              _buildMapPlaceholder(),
              const SizedBox(height: 20),
              _buildHighRiskPanel(),
              const SizedBox(height: 20),
              _buildActionCenter(),
              const SizedBox(height: 20),
              _buildActiveProjectsOverview(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create_segment'),
        backgroundColor: Colors.greenAccent,
        icon: const Icon(Icons.add_location_alt, color: Colors.black),
        label: const Text('Create Segment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMMAND CENTER',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const Text(
          'Real-time construction oversight',
          style: TextStyle(color: Color(0xFF8A8F98), fontSize: 14),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2D2E33)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedProject,
              dropdownColor: const Color(0xFF1C1D21),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8A8F98)),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedProject = newValue;
                  });
                }
              },
              items: ['All Projects', ..._projects.map((p) => p.name)]
                  .toSet()
                  .toList()
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildKPICard('ACTIVE PROJECTS', '3', '+12 vs last month', Colors.greenAccent),
        _buildKPICard('TOTAL SEGMENTS', '142', '+8 vs last month', Colors.blueAccent),
        _buildKPICard('ACTIVE CREWS', '24', '+3 vs last month', Colors.orangeAccent),
        _buildKPICard('HIGH RISK', '5', '+5 vs last month', Colors.redAccent),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, String trend, Color trendColor) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 11, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(Icons.arrow_upward, color: trendColor, size: 12),
              const SizedBox(width: 4),
              Text(trend, style: TextStyle(color: trendColor, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: const Border(bottom: BorderSide(color: Color(0xFF2D2E33))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Interactive GIS View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Icon(Icons.fullscreen, color: Color(0xFF8A8F98)),
              ],
            ),
          ),
          
          // Using our new InteractiveMapView
          InteractiveMapView(markers: _markers),

          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white.withOpacity(0.02),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.greenAccent, 'Projects'),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.orangeAccent, 'Crews'),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.redAccent, 'Risks'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildHighRiskPanel() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥 High Risk Segments', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Color(0xFF2D2E33), borderRadius: BorderRadius.circular(10)),
                child: const Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildRiskItem('Segment #402', 'Severe Weather Delay', '+4d'),
          const SizedBox(height: 12),
          _buildRiskItem('Segment #118', 'Material Shortage', '+2d'),
        ],
      ),
    );
  }

  Widget _buildRiskItem(String title, String cause, String delay) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(cause, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Text(delay, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActionCenter() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚡ Action Center', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildActionItem('Approve Extra Materials', 'Segment #118 needs 500m Microducts', Icons.check_circle_outline),
          const SizedBox(height: 12),
          _buildActionItem('Review Permit Renewal', 'Berlin Mitte Zone B expiring soon', Icons.description_outlined),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String desc, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.blueAccent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 12)),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Review', style: TextStyle(color: Colors.blueAccent)),
        )
      ],
    );
  }

  Widget _buildActiveProjectsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active Projects Overview', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text('Refresh', style: TextStyle(color: Colors.blueAccent))),
          ],
        ),
        const SizedBox(height: 8),
        if (_projects.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No active projects found.', style: TextStyle(color: Colors.white70)),
          )
        else
          Column(
            children: _projects.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildProjectListItem(
                  p.id, 
                  p.name, 
                  'Starts: ${p.startDate?.toLocal().toString().split(' ')[0] ?? 'TBD'}', 
                  0.5
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildProjectListItem(String id, String name, String dates, double progress) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.push('/project_clusters/$id');
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Icon(Icons.arrow_forward_ios, color: Color(0xFF8A8F98), size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(dates, style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 12)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            )
          ],
        ),
      ),
    );
  }
}
