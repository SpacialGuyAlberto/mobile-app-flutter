import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/location_service.dart';
import '../../models/planning/enums/work_type.dart';
import '../../models/planning/enums/workflow_state.dart';
import '../../models/planning/geometry_point.dart';
import '../../models/planning/infrastructure_elements.dart';
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
import 'cluster_dashboard/widgets/cluster_map_controls.dart';
import 'cluster_dashboard/widgets/cluster_node_accordion.dart';
import 'cluster_dashboard/widgets/cluster_stats_grid.dart';
import 'cluster_dashboard/widgets/crew_info_sheet.dart';
import 'cluster_dashboard/widgets/machinery_info_sheet.dart';
import 'cluster_dashboard/widgets/save_node_bottom_sheet.dart';

/// Screen coordinating cluster dashboard data, map visualizer, and operations (SOLID compliant).
class ClusterAreaDashboardScreen extends StatefulWidget {
  final String projectId;
  final String clusterId;
  final IClusterDashboardRepository? repository;
  final IUtilityRepository? utilityRepository;
  final ClusterOfflineMapService? offlineMapService;
  final LocationService? locationService;
  final ClusterMapObjectBuilder? mapObjectBuilder;

  const ClusterAreaDashboardScreen({
    super.key,
    required this.projectId,
    required this.clusterId,
    this.repository,
    this.utilityRepository,
    this.offlineMapService,
    this.locationService,
    this.mapObjectBuilder,
  });

  @override
  State<ClusterAreaDashboardScreen> createState() => _ClusterAreaDashboardScreenState();
}

class _ClusterAreaDashboardScreenState extends State<ClusterAreaDashboardScreen> {
  late final IClusterDashboardRepository _repository;
  late final IUtilityRepository _utilityRepository;
  late final ClusterOfflineMapService _offlineMapService;
  late final LocationService _locationService;
  late final ClusterMapObjectBuilder _mapObjectBuilder;

  bool _isLoading = true;
  List<Pop> _pops = [];
  List<Netzverteiler> _nvts = [];
  List<Segment> _segments = [];
  List<UtilityLine> _utilities = [];

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
    await _mapObjectBuilder.loadCustomIcons();
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
    final utilities = await _utilityRepository.fetchUtilities();

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
          InteractiveMapView(
            markers: _mapData.markers,
            polylines: _mapData.polylines,
            initialCameraPosition: _mapData.initialCamera ?? const CameraPosition(target: LatLng(52.52, 13.40), zoom: 12),
            onTap: _onMapTapped,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: _hasLocationPermission,
          ),

        ClusterMapControls(
          projectId: widget.projectId,
          is3DMode: is3DMode,
          isPanelVisible: isPanelVisible,
          isOffline: _isOffline,
          isDownloading: _isDownloading,
          isMapEditMode: isMapEditMode,
          activeDrawTool: activeDrawTool,
          onMyLocation: _centerToMyLocation,
          onZoomIn: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
          onZoomOut: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
          onStreetView: _openStreetView,
          onToggle3D: _toggle3D,
          onTogglePanel: () => setState(() => isPanelVisible = !isPanelVisible),
          onDownloadOfflineMap: _downloadOfflineMap,
          onCancelDraw: () {
            setState(() {
              isMapEditMode = false;
              activeDrawTool = null;
              tempMarker = null;
              _rebuildMap();
            });
          },
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
