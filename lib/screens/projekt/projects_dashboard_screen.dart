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

  GoogleMapController? _mapController;

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

  void _onProjectSelected(String projectName) async {
    setState(() {
      selectedProject = projectName;
    });

    if (projectName == 'All Projects') {
      _loadProjects();
      return;
    }

    final project = _projects.firstWhere((p) => p.name == projectName);
    
    if (project.geometry.isNotEmpty && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(project.geometry.first.latitude, project.geometry.first.longitude),
          14.0,
        ),
      );
    }

    setState(() {
      _markers = {};
      if (project.geometry.isNotEmpty) {
        _markers.add(Marker(
          markerId: MarkerId(project.id),
          position: LatLng(project.geometry.first.latitude, project.geometry.first.longitude),
          infoWindow: InfoWindow(title: project.name, snippet: project.description),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131415), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white70),
          onPressed: () {},
        ),
        title: const Text('QUARKBAU / MANAGEMENT SYSTEM', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            if (_projects.isNotEmpty) ...[
              _buildActiveProjectCard(selectedProject == 'All Projects' ? _projects.first : _projects.firstWhere((p) => p.name == selectedProject)),
              const SizedBox(height: 24),
              _buildConstructionHealth(),
              const SizedBox(height: 32),
              _buildOtherProjectsList(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMMAND\nCENTER',
              style: TextStyle(color: Colors.white, fontSize: 42, fontFamily: 'serif', height: 1.0, letterSpacing: -0.5),
            ),
            SizedBox(height: 12),
            Text(
              'Real-time construction\noversight',
              style: TextStyle(color: Color(0xFF8A8F98), fontSize: 14, height: 1.4),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('SELECT PROJECT', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2D2E33)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedProject,
                  dropdownColor: const Color(0xFF1C1D21),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8A8F98), size: 20),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _onProjectSelected(newValue);
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
        ),
      ],
    );
  }

  Widget _buildActiveProjectCard(Project project) {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                ),
                child: const Text('ACTIVE PROJECT', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('GLOBAL\nPROGRESS', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('78%', style: TextStyle(color: Colors.white, fontSize: 32, fontFamily: 'serif')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(project.name, style: const TextStyle(color: Colors.white, fontSize: 36, fontFamily: 'serif', height: 1.1)),
          const SizedBox(height: 24),
          Text(project.description ?? 'High-speed fiber optic deployment in the district. Total underground cabling.', style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProjectStat('TOTAL\nSEGMENTS', '0'),
              _buildProjectStat('START\nDATE', project.startDate?.toLocal().toString().split(' ')[0] ?? '2025-02-01'),
              _buildProjectStat('TARGET\nCOMPLETION', project.endDate?.toLocal().toString().split(' ')[0] ?? '2025-08-31'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildConstructionHealth() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D21),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONSTRUCTION HEALTH', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _buildHealthBar('PERMIT COMPLIANCE', '94%', 0.94, Colors.greenAccent),
          const SizedBox(height: 32),
          _buildHealthBar('SAFETY SCORE (RSA-21)', '98/100', 0.98, Colors.blueAccent),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (_projects.isNotEmpty) {
                  final activeProject = selectedProject == 'All Projects' ? _projects.first : _projects.firstWhere((p) => p.name == selectedProject);
                  context.push('/project_clusters/${activeProject.id}');
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('MANAGE PROJECT DETAILS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHealthBar(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 2,
        ),
      ],
    );
  }

  Widget _buildOtherProjectsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Projects',
          style: TextStyle(color: Colors.white, fontSize: 32, fontFamily: 'serif'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage fiber optic deployment projects',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 24),
        ..._projects.where((p) => p.name != selectedProject && (selectedProject != 'All Projects' || _projects.first.id != p.id)).map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                    Text(p.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('COMPLETED', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(p.description ?? 'High-speed fiber optic deployment. Underground cabling.', style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
                const SizedBox(height: 24),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('START:\n${p.startDate?.toLocal().toString().split(' ')[0] ?? '2025-03-15'}', style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontFamily: 'monospace')),
                    Text('END:\n${p.endDate?.toLocal().toString().split(' ')[0] ?? '2025-11-30'}', style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontFamily: 'monospace'), textAlign: TextAlign.right),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/project_clusters/${p.id}');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('VIEW DETAILS', style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('EDIT', style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
