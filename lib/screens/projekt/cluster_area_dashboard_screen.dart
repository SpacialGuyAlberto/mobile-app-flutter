import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Cluster;
import 'package:url_launcher/url_launcher.dart';
import '../../providers/ar_companion_provider.dart';
import 'cluster_dashboard/utilities/utility_map_renderer.dart';

import '../../core/services/location_service.dart';
import '../../models/planning/enums/work_type.dart';
import '../../models/planning/enums/workflow_state.dart';
import '../../models/planning/geometry_point.dart';
import '../../models/planning/infrastructure_elements.dart';
import '../../models/planning/project.dart';
import '../../models/planning/segment.dart';
import '../../models/utility_models.dart';
import '../../widgets/interactive_map_view.dart';
import '../../widgets/segment_edit_bottom_sheet.dart';

import 'cluster_dashboard/models/cluster_element_item.dart';
import 'cluster_dashboard/services/cluster_dashboard_repository.dart';
import 'cluster_dashboard/services/cluster_offline_map_service.dart';
import 'cluster_dashboard/utilities/utility_adapter.dart';
import 'cluster_dashboard/utilities/utility_info_sheet.dart';
import 'cluster_dashboard/utilities/utility_repository.dart';
import 'cluster_dashboard/utils/cluster_map_object_builder.dart';
import 'cluster_dashboard/widgets/add_node_type_sheet.dart';
import 'cluster_dashboard/widgets/cluster_node_accordion.dart';
import 'cluster_dashboard/widgets/cluster_stats_grid.dart';
import 'cluster_dashboard/widgets/crew_info_sheet.dart';
import 'cluster_dashboard/widgets/machinery_info_sheet.dart';
import 'cluster_dashboard/widgets/save_node_bottom_sheet.dart';

/// Screen coordinating cluster dashboard data, map visualizer, and operations (SOLID compliant).
class ClusterAreaDashboardScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String clusterId;
  final double? initialLat;
  final double? initialLng;
  final IClusterDashboardRepository? repository;
  final IUtilityRepository? utilityRepository;
  final ClusterOfflineMapService? offlineMapService;
  final LocationService? locationService;
  final ClusterMapObjectBuilder? mapObjectBuilder;

  const ClusterAreaDashboardScreen({
    super.key,
    required this.projectId,
    required this.clusterId,
    this.initialLat,
    this.initialLng,
    this.repository,
    this.utilityRepository,
    this.offlineMapService,
    this.locationService,
    this.mapObjectBuilder,
  });

  @override
  ConsumerState<ClusterAreaDashboardScreen> createState() => _ClusterAreaDashboardScreenState();
}

class _ClusterAreaDashboardScreenState extends ConsumerState<ClusterAreaDashboardScreen> {
  late final IClusterDashboardRepository _repository;
  late final IUtilityRepository _utilityRepository;
  late final ClusterOfflineMapService _offlineMapService;
  late final LocationService _locationService;
  late final ClusterMapObjectBuilder _mapObjectBuilder;

  bool _isLoading = true;
  Project? _project;
  List<Pop> _pops = [];
  List<Netzverteiler> _nvts = [];
  List<Segment> _segments = [];
  List<UtilityLine> _utilities = [];
  LatLng? _clusterCenter;

  Map<String, List<ClusterElementItem>> _groupedItems = {};
  Map<String, int> _stats = {'POP': 0, 'Netzverteiler': 0, 'Segments': 0};
  String _expandedGroup = 'POP';

  ClusterMapData _mapData = const ClusterMapData(markers: {}, polylines: {});
  GoogleMapController? _mapController;

  bool isMapEditMode = false;
  String? activeDrawTool;
  LatLng? tempMarker;

  bool is3DMode = false;
  bool isPanelVisible = true;

  bool _isOffline = false;
  File? _offlineMapFile;
  bool _isDownloading = false;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _clusterCenter = LatLng(widget.initialLat!, widget.initialLng!);
    }
    _repository = widget.repository ?? ClusterDashboardRepository();
    _utilityRepository = widget.utilityRepository ?? UtilityRepository();
    _offlineMapService = widget.offlineMapService ?? ClusterOfflineMapService();
    _locationService = widget.locationService ?? LocationService();
    _mapObjectBuilder = widget.mapObjectBuilder ?? ClusterMapObjectBuilder();

    _checkOfflineStatus();
    _requestLocationPermission();
    _initCustomIconsAndLoad();
  }

  Future<void> _initCustomIconsAndLoad() async {
    try {
      await _mapObjectBuilder.loadCustomIcons();
    } catch (_) {
      // In headless or test environments where canvas is not available
    }
    await _loadClusterData();
  }

  Future<void> _checkOfflineStatus() async {
    final offline = await _offlineMapService.checkIsOffline();
    final file = await _offlineMapService.getOfflineMapFile(widget.clusterId);

    if (mounted) {
      setState(() {
        _isOffline = offline;
        _offlineMapFile = file;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final hasPermission = await _locationService.hasPermission();
    if (mounted) {
      setState(() {
        _hasLocationPermission = hasPermission;
      });
    }
  }

  Future<void> _centerToMyLocation() async {
    if (_mapController == null) return;
    if (!_hasLocationPermission) {
      await _requestLocationPermission();
      if (!_hasLocationPermission) return;
    }

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
              tilt: is3DMode ? 60.0 : 0.0,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _downloadOfflineMap() async {
    if (_mapController == null) return;
    setState(() => _isDownloading = true);

    try {
      final file = await _offlineMapService.saveMapSnapshot(_mapController!, widget.clusterId);
      if (file != null && mounted) {
        setState(() => _offlineMapFile = file);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mapa guardado para uso offline exitosamente.'), backgroundColor: Colors.green),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el mapa.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _loadClusterData() async {
    setState(() => _isLoading = true);

    final pops = await _repository.fetchPops(widget.clusterId);
    final segments = await _repository.fetchSegments(widget.projectId);
    var utilities = await _utilityRepository.fetchUtilities();

    if (_clusterCenter == null) {
      final cluster = await _repository.fetchCluster(widget.clusterId);
      if (cluster?.latitude != null && cluster?.longitude != null) {
        _clusterCenter = LatLng(cluster!.latitude!, cluster.longitude!);
      } else {
        final project = await _repository.fetchProject(widget.projectId);
        _project = project;
        if (project != null) {
          final projId = int.tryParse(widget.projectId);
          if (projId != null) {
            ref.read(arCompanionProvider.notifier).setProjectId(projId, project.name);
          }
        }
        if (project?.latitude != null && project?.longitude != null) {
          _clusterCenter = LatLng(project!.latitude!, project.longitude!);
        }
      }
    }

    if (_clusterCenter == null) {
      if (pops.isNotEmpty && pops.first.latitude != null && pops.first.longitude != null) {
        _clusterCenter = LatLng(pops.first.latitude!, pops.first.longitude!);
      } else {
        final nvts = pops.expand((p) => p.nvts).toList();
        if (nvts.isNotEmpty && nvts.first.latitude != null && nvts.first.longitude != null) {
          _clusterCenter = LatLng(nvts.first.latitude!, nvts.first.longitude!);
        } else if (segments.isNotEmpty && segments.first.geometry.isNotEmpty) {
          _clusterCenter = LatLng(segments.first.geometry.first.latitude, segments.first.geometry.first.longitude);
        }
      }
    }

    // Filter out utilities from distant areas if cluster center is known
    if (_clusterCenter != null) {
      utilities = utilities.where((u) {
        final pts = UtilityMapRenderer.extractCoordinates(u.geometry);
        if (pts.isEmpty) return false;
        final first = pts.first;
        final dLat = (first.latitude - _clusterCenter!.latitude).abs();
        final dLng = (first.longitude - _clusterCenter!.longitude).abs();
        return dLat < 1.0 && dLng < 1.0;
      }).toList();
    }

    _pops = pops;
    _nvts = pops.expand((p) => p.nvts).toList();
    _segments = segments;
    _utilities = utilities;

    _stats = {
      'POP': _pops.length,
      'Netzverteiler': _nvts.length,
      'Segments': _segments.length,
      'Utilities': _utilities.length,
    };

    _groupedItems = _buildGroupedItems();
    _rebuildMap();

    if (_mapController != null && _clusterCenter != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _clusterCenter!, zoom: 16.0),
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<ClusterElementItem>> _buildGroupedItems() {
    return {
      'POP': _pops.map((pop) {
        return ClusterElementItem(
          id: pop.id,
          name: pop.name,
          status: 'ACTIVE',
          type: ClusterElementType.pop,
          originalModel: pop,
        );
      }).toList(),
      'Netzverteiler': _nvts.map((nvt) {
        return ClusterElementItem(
          id: nvt.id,
          name: nvt.identifier,
          status: 'ACTIVE',
          type: ClusterElementType.netzverteiler,
          originalModel: nvt,
        );
      }).toList(),
      'Segments': _segments.map((seg) {
        return ClusterElementItem(
          id: seg.id,
          name: 'Segment (length: ${seg.length ?? 0}m)',
          status: seg.currentState.name.toUpperCase(),
          type: ClusterElementType.segments,
          originalModel: seg,
          onTap: () => _onSegmentTapped(seg),
        );
      }).toList(),
      'Utilities': UtilityAdapter.toElementItems(_utilities, context: context),
    };
  }

  void _rebuildMap() {
    _mapData = _mapObjectBuilder.build(
      pops: _pops,
      nvts: _nvts,
      segments: _segments,
      utilities: _utilities,
      tempMarker: tempMarker,
      onSegmentTapped: _onSegmentTapped,
      onCrewTapped: _onCrewMarkerTapped,
      onMachineryTapped: _onMachineryMarkerTapped,
      onUtilityTapped: _onUtilityTapped,
      currentInitialCamera: _mapData.initialCamera,
      clusterCenter: _clusterCenter,
    );
  }

  void _onMapTapped(LatLng position) {
    if (isMapEditMode && activeDrawTool != null) {
      setState(() {
        tempMarker = position;
        _rebuildMap();
      });
      _showSaveNodeForm();
    }
  }

  void _onCrewMarkerTapped(Segment seg) {
    CrewInfoSheet.show(context, seg);
  }

  void _onMachineryMarkerTapped(Segment seg) {
    MachineryInfoSheet.show(context, seg);
  }

  void _onUtilityTapped(UtilityLine util) {
    UtilityInfoSheet.show(context, util);
  }

  void _onSegmentTapped(Segment seg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SegmentEditBottomSheet(
        segment: seg.toJson(),
        onSaved: _loadClusterData,
      ),
    );
  }

  void _showSaveNodeForm() {
    SaveNodeBottomSheet.show(
      context,
      activeDrawTool: activeDrawTool ?? '',
      pops: _pops,
      onSave: (data) => _saveNode(data),
    );
  }

  Future<void> _saveNode(SaveNodeData data) async {
    if (tempMarker == null) return;
    setState(() => _isLoading = true);

    try {
      final elevation = await _repository.fetchElevation(tempMarker!);

      if (activeDrawTool == 'POP') {
        final newPop = Pop(
          id: '',
          clusterId: widget.clusterId,
          name: data.name.isNotEmpty ? data.name : 'New POP',
          locationAddress: 'Lat: ${tempMarker!.latitude}, Lng: ${tempMarker!.longitude}',
          latitude: tempMarker!.latitude,
          longitude: tempMarker!.longitude,
          elevation: elevation,
          maxCapacityPorts: 100,
          nvts: [],
        );
        await _repository.savePop(newPop);
      } else if (activeDrawTool == 'Netzverteiler') {
        final newNvt = Netzverteiler(
          id: '',
          identifier: data.name.isNotEmpty ? data.name : 'New NVT',
          latitude: tempMarker!.latitude,
          longitude: tempMarker!.longitude,
          elevation: elevation,
          popId: data.popId ?? (_pops.isNotEmpty ? _pops.first.id : null),
        );
        await _repository.saveNetzverteiler(newNvt);
      } else if (activeDrawTool == 'Segment' || activeDrawTool == 'Acometida') {
        final newSeg = Segment(
          id: '',
          streetName: data.name.isNotEmpty ? data.name : 'New Segment',
          streetType: 'UNKNOWN',
          workType: WorkType.trenching,
          currentState: WorkflowState.plan,
          length: 50,
          elevation: elevation,
          geometry: [
            GeometryPoint(latitude: tempMarker!.latitude, longitude: tempMarker!.longitude),
            GeometryPoint(latitude: tempMarker!.latitude + 0.0005, longitude: tempMarker!.longitude + 0.0005),
          ],
        );
        await _repository.saveSegment(widget.projectId, newSeg);
      }
    } catch (_) {}

    setState(() {
      isMapEditMode = false;
      activeDrawTool = null;
      tempMarker = null;
    });

    await _loadClusterData();
  }

  Future<void> _openStreetView() async {
    final center = _mapData.initialCamera?.target ?? const LatLng(52.5200, 13.4050);
    final url = Uri.parse('google.streetview:cbll=${center.latitude},${center.longitude}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      final webUrl = Uri.parse(
        'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${center.latitude},${center.longitude}',
      );
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  void _toggle3D() {
    setState(() => is3DMode = !is3DMode);
    if (_mapController != null && _mapData.initialCamera != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _mapData.initialCamera!.target,
            zoom: 16.0,
            tilt: is3DMode ? 60.0 : 0.0,
            bearing: is3DMode ? 45.0 : 0.0,
          ),
        ),
      );
    }
  }

  void _showAddNodeBottomSheet() {
    AddNodeTypeSheet.show(
      context,
      onAddPop: () {
        setState(() {
          isMapEditMode = true;
          activeDrawTool = 'POP';
        });
      },
      onAddNetzverteiler: () {
        setState(() {
          isMapEditMode = true;
          activeDrawTool = 'Netzverteiler';
        });
      },
      onAddSegment: () async {
        double? lat, lng, zoom;
        if (_mapController != null) {
          try {
            final bounds = await _mapController!.getVisibleRegion();
            lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
            lng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
            zoom = await _mapController!.getZoomLevel();
          } catch (_) {}
        }
        String route = '/create_segment/${widget.projectId}';
        if (lat != null && lng != null && zoom != null) {
          route += '?lat=$lat&lng=$lng&zoom=$zoom';
        }
        if (mounted) {
          context.push(route);
        }
      },
      onAddAcometida: () {
        setState(() {
          isMapEditMode = true;
          activeDrawTool = 'Acometida';
        });
      },
    );
  }

  Widget _buildMapArea() {
    return Stack(
      children: [
        if (_isOffline && _offlineMapFile != null)
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.file(_offlineMapFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          )
        else
          Consumer(
            builder: (context, ref, child) {
              final arState = ref.watch(arCompanionProvider);
              Set<Marker> finalMarkers = Set.from(_mapData.markers);
              Set<Polyline> finalPolylines = Set.from(_mapData.polylines);
              
              if (arState.isBroadcasting && arState.currentLat != null && arState.currentLng != null) {
                // Dibujar un pin para indicar la posición transmitida
                finalMarkers.add(
                  Marker(
                    markerId: const MarkerId('my_companion_indicator'),
                    position: LatLng(arState.currentLat!, arState.currentLng!),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(title: 'Tú', snippet: 'GPS Broadcasting'),
                    anchor: const Offset(0.5, 0.5),
                    zIndexInt: 9999,
                  ),
                );
              }

              return InteractiveMapView(
                markers: finalMarkers,
                polylines: finalPolylines,
                initialCameraPosition: _mapData.initialCamera ?? CameraPosition(
                  target: _clusterCenter ?? const LatLng(52.52, 13.40),
                  zoom: _clusterCenter != null ? 16 : 12,
                ),
                onTap: _onMapTapped,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_clusterCenter != null) {
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: _clusterCenter!, zoom: 16.0),
                      ),
                    );
                  }
                },
                myLocationEnabled: _hasLocationPermission,
                myLocationButtonEnabled: _hasLocationPermission,
              );
            },
          ),
          
        if (_isOffline && _offlineMapFile != null)
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 16),
                  SizedBox(width: 8),
                  Text('MODO OFFLINE', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        
        // Action Buttons on Map (3D and Panel Toggle)
        Positioned(
          top: 100,
          right: 16,
          child: Column(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final arState = ref.watch(arCompanionProvider);
                  return FloatingActionButton(
                    heroTag: 'arCompanionBtn',
                    mini: true,
                    backgroundColor: arState.isBroadcasting ? const Color(0xFF6938ef) : const Color(0xFF1C1D21),
                    onPressed: () async {
                      final notifier = ref.read(arCompanionProvider.notifier);
                      // Asignar el ID de proyecto actual (parseado a int) y su nombre
                      int? projId = int.tryParse(widget.projectId);
                      if (projId != null) notifier.setProjectId(projId, _project?.name);
                      
                      if (arState.isBroadcasting) {
                        notifier.stopBroadcasting();
                      } else {
                        final error = await notifier.startBroadcasting(arState.targetIp, arState.targetPort);
                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(error),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                    },
                    child: Icon(
                      arState.isBroadcasting ? Icons.cast_connected : Icons.cast, 
                      color: arState.isBroadcasting ? Colors.white : Colors.blueAccent, 
                      size: 20
                    ),
                  );
                }
              ),
              Consumer(
                builder: (context, ref, child) {
                  final isBroadcasting = ref.watch(arCompanionProvider.select((state) => state.isBroadcasting));
                  if (!isBroadcasting) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: FloatingActionButton(
                      heroTag: 'forceCalibrateBtn',
                      mini: true,
                      backgroundColor: Colors.blueAccent,
                      onPressed: () {
                        ref.read(arCompanionProvider.notifier).forceCalibration();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Señal de calibración enviada a Unity')),
                        );
                      },
                      child: const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                    ),
                  );
                }
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'locateMeBtn',
                mini: true,
                backgroundColor: const Color(0xFF1C1D21),
                onPressed: _centerToMyLocation,
                child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'zoomInBtn',
                mini: true,
                backgroundColor: const Color(0xFF1C1D21),
                onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoomOutBtn',
                mini: true,
                backgroundColor: const Color(0xFF1C1D21),
                onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                child: const Icon(Icons.remove, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 24),
              FloatingActionButton(
                heroTag: 'svBtn',
                mini: true,
                backgroundColor: const Color(0xFF1C1D21),
                onPressed: _openStreetView,
                child: const Icon(Icons.directions_walk, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: '3dBtn',
                mini: true,
                backgroundColor: is3DMode ? const Color(0xFF6938ef) : const Color(0xFF1C1D21),
                onPressed: _toggle3D,
                child: const Icon(Icons.threed_rotation, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'panelBtn',
                mini: true,
                backgroundColor: isPanelVisible ? const Color(0xFF1C1D21) : const Color(0xFF6938ef),
                onPressed: () => setState(() => isPanelVisible = !isPanelVisible),
                child: Icon(isPanelVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white, size: 20),
              ),
              if (!_isOffline) ...[
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'downloadMapBtn',
                  mini: true,
                  backgroundColor: _isDownloading ? Colors.grey : const Color(0xFF1C1D21),
                  onPressed: _isDownloading ? null : _downloadOfflineMap,
                  child: _isDownloading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_for_offline, color: Colors.greenAccent, size: 20),
                ),
              ],
            ],
          ),
        ),

        if (isPanelVisible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF131415)],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDataPanel({ScrollController? scrollController}) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF131415)),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClusterStatsGrid(stats: _stats),
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
            ClusterNodeAccordion(
              groupedElements: _groupedItems,
              expandedGroup: _expandedGroup,
              onToggleGroup: (group) => setState(() => _expandedGroup = group),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Cluster Area', style: TextStyle(color: Colors.white)),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      children: [
                        Expanded(flex: 6, child: _buildMapArea()),
                        Container(width: 1, color: Colors.white.withValues(alpha: 0.1)),
                        Expanded(flex: 4, child: _buildDataPanel()),
                      ],
                    );
                  } else {
                    return Stack(
                      children: [
                        Positioned.fill(child: _buildMapArea()),
                        if (isPanelVisible)
                          DraggableScrollableSheet(
                            initialChildSize: 0.45,
                            minChildSize: 0.15,
                            maxChildSize: 0.9,
                            builder: (context, scrollController) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF131415),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                      offset: Offset(0, -5),
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Center(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 12),
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white30,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDataPanel(scrollController: scrollController),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  }
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNodeBottomSheet,
        backgroundColor: const Color(0xFF6938EF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Node', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
