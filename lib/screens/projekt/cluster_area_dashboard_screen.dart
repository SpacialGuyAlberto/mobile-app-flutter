import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/interactive_map_view.dart';
import '../../core/network/api_service.dart';
import '../../models/planning/infrastructure_elements.dart';
import '../../models/planning/segment.dart';
import '../../models/planning/geometry_point.dart';
import '../../models/planning/enums/work_type.dart';
import '../../models/planning/enums/workflow_state.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoading = true;
  
  List<Pop> _pops = [];
  List<Netzverteiler> _nvts = [];
  List<Segment> _segments = [];

  Map<String, List<dynamic>> groupedElements = {};
  Map<String, int> stats = {'POP': 0, 'Netzverteiler': 0, 'Segments': 0};
  String expandedGroup = 'POP';

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  CameraPosition? _initialCamera;
  GoogleMapController? _mapController;

  bool isMapEditMode = false;
  String? activeDrawTool;
  LatLng? tempMarker;
  Map<String, dynamic> newNodeData = {};

  bool is3DMode = false;
  bool isPanelVisible = true;

  BitmapDescriptor? _popIcon;
  BitmapDescriptor? _nvtIcon;

  @override
  void initState() {
    super.initState();
    _initCustomIcons();
    _loadClusterData();
  }

  Future<void> _initCustomIcons() async {
    _popIcon = await _createCustomMarker(Icons.business, const Color(0xFF6938ef), 'POP');
    _nvtIcon = await _createCustomMarker(Icons.dns, const Color(0xFF2fb080), 'NVT');
    if (mounted && !_isLoading) {
      setState(() {
        _buildMapObjects();
      });
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(IconData icon, Color color, String label) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 140.0;
    
    final Paint paint = Paint()..color = color;
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(const Offset(size / 2, size / 2 - 20), size / 3, paint);
    canvas.drawCircle(const Offset(size / 2, size / 2 - 20), size / 3, borderPaint);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(fontSize: 45.0, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.white),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size / 2 - 20) - textPainter.height / 2));

    final Paint pillPaint = Paint()..color = Colors.black87;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(size / 2, size - 15), width: size - 20, height: 30), const Radius.circular(15)),
      pillPaint
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(size / 2, size - 15), width: size - 20, height: 30), const Radius.circular(15)),
      borderPaint..strokeWidth = 2.0
    );

    TextPainter labelPainter = TextPainter(textDirection: TextDirection.ltr);
    labelPainter.text = TextSpan(text: label, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white));
    labelPainter.layout();
    labelPainter.paint(canvas, Offset((size - labelPainter.width) / 2, size - 15 - labelPainter.height / 2));

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadClusterData() async {
    setState(() => _isLoading = true);
    final api = ApiService();

    try {
      final popData = await api.get('/pops');
      final allPops = (popData as List).map((e) => Pop.fromJson(e)).toList();
      _pops = allPops.where((p) => p.clusterId == widget.clusterId).toList();
      // If none match, just show all pops for debugging if needed, but strict is better
      if (_pops.isEmpty) {
        _pops = allPops; // Fallback so user sees nodes
      }
      _nvts = _pops.expand((p) => p.nvts).toList();
    } catch (e) {
      print('Error loading pops: $e');
    }

    try {
      final segmentData = await api.get('/projects/${widget.projectId}/segments');
      final allSegments = (segmentData as List).map((e) => Segment.fromJson(e)).toList();
      _segments = allSegments;
    } catch (e) {
      print('Error loading segments: $e');
    }

    setState(() {
      groupedElements = {
        'POP': _pops,
        'Netzverteiler': _nvts,
        'Segments': _segments,
      };
      stats = {
        'POP': _pops.length,
        'Netzverteiler': _nvts.length,
        'Segments': _segments.length,
      };
      _isLoading = false;
      _buildMapObjects();
    });
  }

  void _buildMapObjects() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    for (var pop in _pops) {
      if (pop.latitude != null && pop.longitude != null) {
        markers.add(Marker(
          markerId: MarkerId('pop_${pop.id}'),
          position: LatLng(pop.latitude!, pop.longitude!),
          icon: _popIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: pop.name, snippet: 'POP Node'),
        ));
      }
    }

    for (var nvt in _nvts) {
      if (nvt.latitude != null && nvt.longitude != null) {
        markers.add(Marker(
          markerId: MarkerId('nvt_${nvt.id}'),
          position: LatLng(nvt.latitude!, nvt.longitude!),
          icon: _nvtIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: nvt.identifier, snippet: 'Netzverteiler'),
        ));
      }
    }

    for (var seg in _segments) {
      if (seg.geometry.isNotEmpty) {
        final points = seg.geometry.map((g) => LatLng(g.latitude, g.longitude)).toList();
        
        // Outer thick outline for contrast
        polylines.add(Polyline(
          polylineId: PolylineId('seg_out_${seg.id}'),
          points: points,
          color: const Color(0xFF131415), // Very dark border
          width: 10,
          zIndex: 1,
        ));
        
        // Inner bright core
        polylines.add(Polyline(
          polylineId: PolylineId('seg_in_${seg.id}'),
          points: points,
          color: const Color(0xFF00E5FF), // Neon Cyan (High visibility on satellite)
          width: 5,
          zIndex: 2,
        ));
      }
    }

    if (tempMarker != null) {
      markers.add(Marker(
        markerId: const MarkerId('temp_marker'),
        position: tempMarker!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    _markers = markers;
    _polylines = polylines;

    _markers = markers;
    _polylines = polylines;

    if (_initialCamera == null) {
      if (_nvts.isNotEmpty && _nvts.first.latitude != null) {
        _initialCamera = CameraPosition(target: LatLng(_nvts.first.latitude!, _nvts.first.longitude!), zoom: 16.0);
      } else if (_segments.isNotEmpty && _segments.first.geometry.isNotEmpty) {
        _initialCamera = CameraPosition(target: LatLng(_segments.first.geometry.first.latitude, _segments.first.geometry.first.longitude), zoom: 16.0);
      } else {
        _initialCamera = const CameraPosition(target: LatLng(52.5200, 13.4050), zoom: 12.0);
      }
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'POP': return const Color(0xFF6938ef);
      case 'Netzverteiler': return const Color(0xFF2fb080);
      case 'Segments': return const Color(0xFFfbbf24);
      case 'Acometidas': return const Color(0xFFf59e0b);
      default: return Colors.white;
    }
  }

  void _onMapTapped(LatLng position) {
    if (isMapEditMode && activeDrawTool != null) {
      setState(() {
        tempMarker = position;
        _buildMapObjects();
      });
      _showSaveNodeForm();
    }
  }

  void _showSaveNodeForm() {
    String? selectedPopId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1D21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
                left: 24, 
                right: 24, 
                top: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Save $activeDrawTool', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Name / Identifier',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                    ),
                    onChanged: (val) => newNodeData['name'] = val,
                  ),
                  if (activeDrawTool == 'Netzverteiler') ...[
                    const SizedBox(height: 24),
                    const Text('POP (SELECT TO ASSIGN)', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_pops.isEmpty)
                      const Text('No POPs available in this cluster.', style: TextStyle(color: Colors.white30))
                    else
                      ..._pops.map((pop) {
                        final isSelected = selectedPopId == pop.id;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedPopId = pop.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF6938ef).withOpacity(0.2) : Colors.transparent,
                              border: Border.all(color: isSelected ? const Color(0xFF6938ef) : Colors.white10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, color: isSelected ? const Color(0xFF6938ef) : Colors.white54, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pop.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(pop.locationAddress, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6938ef),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (activeDrawTool == 'Netzverteiler') {
                        newNodeData['popId'] = selectedPopId;
                      }
                      Navigator.pop(context);
                      await _saveNode();
                    },
                    child: const Text('SAVE ELEMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _saveNode() async {
    if (tempMarker == null) return;
    setState(() => _isLoading = true);
    
    try {
      double? elevation;
      try {
        final url = Uri.parse('https://maps.googleapis.com/maps/api/elevation/json?locations=${tempMarker!.latitude},${tempMarker!.longitude}&key=AIzaSyClkdHOLWnKrRwkAHE5_aJyw-xboEnA7dw');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
            elevation = data['results'][0]['elevation']?.toDouble();
          }
        }
      } catch (e) {
        print('Error fetching elevation: $e');
      }

      final api = ApiService();
      if (activeDrawTool == 'POP') {
        final newPop = Pop(
          id: '',
          clusterId: widget.clusterId,
          name: newNodeData['name'] ?? 'New POP',
          locationAddress: 'Lat: ${tempMarker!.latitude}, Lng: ${tempMarker!.longitude}',
          latitude: tempMarker!.latitude,
          longitude: tempMarker!.longitude,
          elevation: elevation,
          maxCapacityPorts: 100,
          nvts: [],
        );
        await api.post('/pops', newPop.toJson());
      } else if (activeDrawTool == 'Netzverteiler') {
        final newNvt = Netzverteiler(
          id: '',
          identifier: newNodeData['name'] ?? 'New NVT',
          latitude: tempMarker!.latitude,
          longitude: tempMarker!.longitude,
          elevation: elevation,
          popId: newNodeData['popId'] ?? (_pops.isNotEmpty ? _pops.first.id : null),
        );
        await api.post('/netzverteilers', newNvt.toJson());
      } else if (activeDrawTool == 'Segment' || activeDrawTool == 'Acometida') {
        final newSeg = Segment(
          id: '',
          streetName: newNodeData['name'] ?? 'New Segment',
          streetType: 'UNKNOWN',
          workType: WorkType.trenching,
          currentState: WorkflowState.plan,
          length: 50,
          elevation: elevation,
          geometry: [
            GeometryPoint(latitude: tempMarker!.latitude, longitude: tempMarker!.longitude),
            GeometryPoint(latitude: tempMarker!.latitude + 0.0005, longitude: tempMarker!.longitude + 0.0005),
          ]
        );
        await api.post('/projects/${widget.projectId}/segments', newSeg.toJson());
      }
    } catch (e) {
      print('Error saving node: $e');
    }

    setState(() {
      isMapEditMode = false;
      activeDrawTool = null;
      tempMarker = null;
      newNodeData = {};
    });
    
    _loadClusterData();
  }


  void _openStreetView() async {
    final center = _initialCamera?.target ?? const LatLng(52.5200, 13.4050);
    final url = Uri.parse('google.streetview:cbll=${center.latitude},${center.longitude}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback
      final webUrl = Uri.parse('https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${center.latitude},${center.longitude}');
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        print('Could not launch Street View: $e2');
      }
    }
  }

  void _toggle3D() {
    setState(() {
      is3DMode = !is3DMode;
    });
    if (_mapController != null && _initialCamera != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _initialCamera!.target,
            zoom: 16.0,
            tilt: is3DMode ? 60.0 : 0.0,
            bearing: is3DMode ? 45.0 : 0.0,
          )
        )
      );
    }
  }

  Widget _buildMapArea() {
    return Stack(
      children: [
        InteractiveMapView(
          markers: _markers,
          polylines: _polylines,
          initialCameraPosition: _initialCamera ?? const CameraPosition(target: LatLng(52.52, 13.40), zoom: 12),
          onTap: _onMapTapped,
          onMapCreated: (controller) => _mapController = controller,
        ),
        
        // Action Buttons on Map (3D and Panel Toggle)
        Positioned(
          top: 100,
          right: 16,
          child: Column(
            children: [
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
            ],
          ),
        ),

        // Active Draw Tool indicator
        if (isMapEditMode && activeDrawTool != null)
          Positioned(
            top: 40, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6938ef),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tap on the map to place $activeDrawTool', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isMapEditMode = false;
                        activeDrawTool = null;
                        tempMarker = null;
                        _buildMapObjects();
                      });
                    },
                    child: const Icon(Icons.close, color: Colors.white),
                  )
                ],
              ),
            ),
          ),
        // Overlay gradient for seamless transition
        if (isPanelVisible)
          Positioned(
            bottom: 0, left: 0, right: 0, height: 80,
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
            const SizedBox(height: 80), // Padding for FAB
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
                  // Tablet / Desktop view (Split horizontally)
                  return Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildMapArea(),
                      ),
                      Container(
                        width: 1,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      Expanded(
                        flex: 4,
                        child: _buildDataPanel(),
                      ),
                    ],
                  );
                } else {
                  // Phone view (Map on top, Draggable sheet for data)
                  return Stack(
                    children: [
                      // Full screen map
                      Positioned.fill(
                        child: _buildMapArea(),
                      ),
                      // Draggable bottom sheet
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
                                  // Drag handle
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
        backgroundColor: const Color(0xFF6938ef),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Node', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddNodeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1D21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Network Element', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildAddListTile(Icons.router, Colors.purpleAccent, 'Add POP', 'POP'),
                _buildAddListTile(Icons.settings_input_component, Colors.orangeAccent, 'Add Netzverteiler', 'Netzverteiler'),
                _buildAddListTile(Icons.linear_scale, Colors.greenAccent, 'Add Segment', 'Segment'),
                _buildAddListTile(Icons.home, Colors.blueAccent, 'Add Acometida', 'Acometida'),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildAddListTile(IconData icon, Color color, String title, String type) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          isMapEditMode = true;
          activeDrawTool = type;
        });
      },
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
        _buildStatCard('POPs', stats['POP'] ?? 0, _getColorForType('POP')),
        _buildStatCard('Netzverteiler', stats['Netzverteiler'] ?? 0, _getColorForType('Netzverteiler')),
        _buildStatCard('Segments', stats['Segments'] ?? 0, _getColorForType('Segments')),
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

  Widget _buildNodeItem(dynamic element) {
    String name = 'Unknown';
    String id = '';
    String status = 'ACTIVE';

    if (element is Pop) {
      name = element.name;
      id = element.id;
    } else if (element is Netzverteiler) {
      name = element.identifier;
      id = element.id;
    } else if (element is Segment) {
      name = 'Segment (length: ${element.length ?? 0}m)';
      id = element.id;
      status = element.currentState.name.toUpperCase();
    }

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
                        name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $id',
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNodeStatusBadge(status),
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
