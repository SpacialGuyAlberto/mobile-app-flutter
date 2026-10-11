import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/network/api_service.dart';
import '../../models/planning/project.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/ar_companion_provider.dart';
import '../../core/config/env_config.dart';

class ProjectsDashboardScreen extends ConsumerStatefulWidget {
  const ProjectsDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectsDashboardScreen> createState() => _ProjectsDashboardScreenState();
}

class _ProjectsDashboardScreenState extends ConsumerState<ProjectsDashboardScreen> {
  String selectedProject = 'All Projects';
  bool _isLoading = true;
  String? _loadError;
  List<Project> _projects = [];
  Set<Marker> _markers = {};

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
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

      if (mounted) {
        setState(() {
          _projects = projects;
          _markers = markers;
          _isLoading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _showServerConfigDialog() async {
    final controller = TextEditingController(text: ApiService.baseUrl);
    bool isTesting = false;
    String? statusMessage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1D21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.dns_outlined, color: Color(0xFF6938ef)),
                SizedBox(width: 8),
                Text('Server Configuration', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Si la IP de tu hotspot o red cambió, actualiza la dirección del backend aquí o usa Auto-Detectar.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Backend Base URL',
                    labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6938ef))),
                  ),
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    statusMessage!,
                    style: TextStyle(
                      color: statusMessage!.startsWith('Error') ? Colors.redAccent : Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isTesting ? null : () async {
                          setDialogState(() {
                            isTesting = true;
                            statusMessage = 'Probando candidatos de conexión...';
                          });
                          final detected = await ApiService.autoDetectWorkingBaseUrl();
                          setDialogState(() {
                            isTesting = false;
                            if (detected != null) {
                              controller.text = detected;
                              statusMessage = 'Conectado exitosamente con $detected';
                            } else {
                              statusMessage = 'Error: Ningún candidato respondió.';
                            }
                          });
                        },
                        icon: isTesting 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(Icons.autorenew, size: 16, color: Color(0xFF6938ef)),
                        label: const Text('Auto-Detectar', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        controller.text = EnvConfig.backendUrl;
                      },
                      child: const Text('Usar .env', style: TextStyle(color: Color(0xFF6938ef), fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6938ef),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await ApiService.setBaseUrl(controller.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadProjects();
                },
                child: const Text('Guardar y Recargar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onProjectSelected(String projectName) async {
    if (projectName == 'All Projects') {
      setState(() {
        selectedProject = projectName;
      });
      _loadProjects();
      return;
    }

    final project = _projects.firstWhere((p) => p.name == projectName);
    
    if (project.geometry.isNotEmpty) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        
        final double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          project.geometry.first.latitude,
          project.geometry.first.longitude,
        );

        if (distanceInMeters > 50000) { // e.g. 50 km
          final distanceKm = (distanceInMeters / 1000).toStringAsFixed(1);
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1C1D21),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                    SizedBox(width: 8),
                    Text('Advertencia de Incongruencia', style: TextStyle(color: Colors.orangeAccent, fontSize: 18)),
                  ],
                ),
                content: Text(
                  '¿Estás seguro que quieres renderizar el proyecto ${project.name} que se encuentra a $distanceKm km de distancia?\n\nHabrá incongruencia gráfica entre la infraestructura renderizada y tu entorno real.',
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Renderizar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );

          if (confirm != true) {
            return; // El usuario canceló
          }
        }
      } catch (e) {
        print('Could not get location for distance validation: $e');
      }
    }

    _applyProjectSelection(project);
  }

  void _applyProjectSelection(Project project) {
    setState(() {
      selectedProject = project.name;
    });

    final projId = int.tryParse(project.id);
    if (projId != null) {
      ref.read(arCompanionProvider.notifier).setProjectId(projId, project.name);
    }

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
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : RefreshIndicator(
                onRefresh: _loadProjects,
                backgroundColor: const Color(0xFF1C1D21),
                color: const Color(0xFF6938ef),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                      ] else ...[
                        _buildEmptyOrErrorCard(),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
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
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.refresh, color: Colors.white54, size: 16),
                  tooltip: 'Refrescar proyectos',
                  onPressed: _loadProjects,
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.dns_outlined, color: Colors.white54, size: 16),
                  tooltip: 'Configuración de Servidor',
                  onPressed: _showServerConfigDialog,
                ),
                const SizedBox(width: 8),
                const Text('SELECT PROJECT', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ],
            ),
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

  Widget _buildEmptyOrErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6938ef).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded, color: Color(0xFF6938ef), size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No se encontraron proyectos',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Problema de conexión con el backend',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131415),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, size: 16, color: Colors.white38),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ApiService.baseUrl,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (_loadError != null) ...[
            const SizedBox(height: 10),
            Text(
              _loadError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6938ef),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    await ApiService.autoDetectWorkingBaseUrl();
                    await _loadProjects();
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                  label: const Text('Auto-Detectar y Reintentar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                onPressed: _showServerConfigDialog,
                icon: const Icon(Icons.settings, size: 16, color: Colors.white70),
                label: const Text('Config', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
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
              onPressed: () async {
                if (_projects.isNotEmpty) {
                  final activeProject = selectedProject == 'All Projects' ? _projects.first : _projects.firstWhere((p) => p.name == selectedProject);
                  await context.push('/project_clusters/${activeProject.id}');
                  if (mounted) _loadProjects();
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
                    Expanded(
                      child: Text(p.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
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
                        onPressed: () async {
                          await context.push('/project_clusters/${p.id}');
                          if (mounted) _loadProjects();
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
        }),
      ],
    );
  }
}
