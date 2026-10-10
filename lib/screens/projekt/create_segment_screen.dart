import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../widgets/glass_card.dart';
import '../../core/network/api_service.dart';
import '../../models/planning/geometry_point.dart';

class CreateSegmentScreen extends StatefulWidget {
  final String? projectId;
  final double? initialLat;
  final double? initialLng;
  final double? initialZoom;
  
  const CreateSegmentScreen({
    Key? key, 
    this.projectId,
    this.initialLat,
    this.initialLng,
    this.initialZoom,
  }) : super(key: key);

  @override
  State<CreateSegmentScreen> createState() => _CreateSegmentScreenState();
}

class _CreateSegmentScreenState extends State<CreateSegmentScreen> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<GeometryPoint> _points = [];
  
  double _curveSharpness = 0.85;
  bool _isVectorAnalyticsExpanded = true;
  
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _crews = [];
  List<dynamic> _netzverteilers = [];
  
  late CameraPosition _initialCamera;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    
    _initialCamera = CameraPosition(
      target: LatLng(widget.initialLat ?? 52.5200, widget.initialLng ?? 13.4050),
      zoom: widget.initialZoom ?? 13.0,
    );
    
    _loadProjectLocation();
    _loadMetadata();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    } 

    if (mounted) {
      setState(() {
        _hasLocationPermission = true;
      });
    }
  }

  List<dynamic> _pops = [];
  List<dynamic> _segmentsContext = [];
  Set<Marker> _contextMarkers = {};
  Set<Polyline> _contextPolylines = {};

  Future<void> _loadMetadata() async {
    try {
      final crewsData = await ApiService().get('/field/crews');
      if (crewsData is List) setState(() => _crews = crewsData);
    } catch (e) {
      print('Could not load crews: $e');
      setState(() => _crews = [
        {'id': 1, 'name': 'Crew Alpha (Mock)'},
        {'id': 2, 'name': 'Crew Beta (Mock)'},
        {'id': 3, 'name': 'Crew Gamma (Mock)'},
      ]);
    }
    
    try {
      final popData = await ApiService().get('/pops');
      if (popData is List) setState(() => _pops = popData);
    } catch (e) {
      print('Could not load pops: $e');
    }
    
    try {
      if (widget.projectId != null) {
        final segmentData = await ApiService().get('/projects/${widget.projectId}/segments');
        if (segmentData is List) setState(() => _segmentsContext = segmentData);
      }
    } catch (e) {
      print('Could not load segments: $e');
    }
    
    try {
      final nvtData = await ApiService().get('/netzverteilers');
      if (nvtData is List) {
        setState(() => _netzverteilers = nvtData);
        if (widget.initialLat == null && _netzverteilers.isNotEmpty && _netzverteilers.first['latitude'] != null) {
          final target = LatLng(_netzverteilers.first['latitude'], _netzverteilers.first['longitude']);
          setState(() {
            _initialCamera = CameraPosition(target: target, zoom: 16.0);
          });
          _mapController?.animateCamera(CameraUpdate.newCameraPosition(_initialCamera));
        }
      }
    } catch (e) {
      print('Could not load netzverteilers: $e');
    }
    
    _buildContextElements();
  }

  void _buildContextElements() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    for (var pop in _pops) {
      if (pop['latitude'] != null && pop['longitude'] != null) {
        markers.add(Marker(
          markerId: MarkerId('pop_${pop['id']}'),
          position: LatLng(pop['latitude'], pop['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: pop['name'] ?? 'POP Node'),
        ));
      }
    }

    for (var nvt in _netzverteilers) {
      if (nvt['latitude'] != null && nvt['longitude'] != null) {
        markers.add(Marker(
          markerId: MarkerId('nvt_${nvt['id']}'),
          position: LatLng(nvt['latitude'], nvt['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: nvt['identifier'] ?? 'Netzverteiler'),
        ));
      }
    }

    for (var seg in _segmentsContext) {
      if (seg['geometry'] != null && seg['geometry'] is List && (seg['geometry'] as List).isNotEmpty) {
        final points = (seg['geometry'] as List).map((g) => LatLng(g['lat'] ?? g['latitude'], g['lng'] ?? g['longitude'])).toList();
        
        polylines.add(Polyline(
          polylineId: PolylineId('seg_out_${seg['id']}'),
          points: points,
          color: const Color(0xFF131415),
          width: 10,
          zIndex: 1,
        ));
        
        polylines.add(Polyline(
          polylineId: PolylineId('seg_in_${seg['id']}'),
          points: points,
          color: const Color(0xFF00E5FF),
          width: 5,
          zIndex: 2,
        ));
      }
    }

    setState(() {
      _contextMarkers = markers;
      _contextPolylines = polylines;
      _rebuildMapElements();
    });
  }

  Future<void> _loadProjectLocation() async {
    if (widget.projectId == null || widget.initialLat != null) return;
    
    try {
      final projectData = await ApiService().get('/projects/${widget.projectId}');
      if (projectData['geometry'] != null && projectData['geometry'] is List && projectData['geometry'].isNotEmpty) {
        // Project has geometry, use first point
        final geom = projectData['geometry'][0];
        final target = LatLng(geom['lat'] ?? geom['latitude'], geom['lng'] ?? geom['longitude']);
        setState(() {
          _initialCamera = CameraPosition(target: target, zoom: 16.0);
        });
        _mapController?.animateCamera(CameraUpdate.newCameraPosition(_initialCamera));
      } else if (projectData['latitude'] != null && projectData['longitude'] != null) {
        final target = LatLng(projectData['latitude'], projectData['longitude']);
        setState(() {
          _initialCamera = CameraPosition(target: target, zoom: 16.0);
        });
        _mapController?.animateCamera(CameraUpdate.newCameraPosition(_initialCamera));
      }
    } catch (e) {
      print('Could not load project location: $e');
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=AIzaSyClkdHOLWnKrRwkAHE5_aJyw-xboEnA7dw');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          final target = LatLng(loc['lat'], loc['lng']);
          _mapController?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 17.0)
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not found')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error searching location: $e')));
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
            c(lat1 * p) * c(lat2 * p) * 
            (1 - c((lon2 - lon1) * p))/2;
    return 12742000 * asin(sqrt(a)); 
  }

  double _getTotalLength() {
    double total = 0;
    List<GeometryPoint> routePoints = _points;
    if (_points.length > 2) {
      routePoints = _catmullRomSpline(_points, _curveSharpness);
    }
    for (int i = 0; i < routePoints.length - 1; i++) {
      total += _calculateDistance(
        routePoints[i].latitude, routePoints[i].longitude, 
        routePoints[i+1].latitude, routePoints[i+1].longitude
      );
    }
    return total;
  }

  List<GeometryPoint> _catmullRomSpline(List<GeometryPoint> points, double sharpness) {
    if (points.length < 3) return points;
    List<GeometryPoint> result = [];
    int resolution = 20;
    
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];
      
      for (int tInt = 0; tInt < resolution; tInt++) {
        double t = tInt / resolution;
        double t2 = t * t;
        double t3 = t2 * t;
        
        double tension = 1.0 - sharpness; 
        double m0 = tension * 0.5;
        
        double b0 = -m0*t3 + 2.0*m0*t2 - m0*t;
        double b1 = (2.0-m0)*t3 + (m0-3.0)*t2 + 1.0;
        double b2 = (m0-2.0)*t3 + (3.0-2.0*m0)*t2 + m0*t;
        double b3 = m0*t3 - m0*t2;
        
        double lat = p0.latitude*b0 + p1.latitude*b1 + p2.latitude*b2 + p3.latitude*b3;
        double lng = p0.longitude*b0 + p1.longitude*b1 + p2.longitude*b2 + p3.longitude*b3;
        double z = (p0.z ?? 0)*b0 + (p1.z ?? 0)*b1 + (p2.z ?? 0)*b2 + (p3.z ?? 0)*b3;
        
        result.add(GeometryPoint(latitude: lat, longitude: lng, z: z));
      }
    }
    result.add(points.last);
    return result;
  }

  Future<void> _onMapTapped(LatLng position) async {
    final newPoint = GeometryPoint(latitude: position.latitude, longitude: position.longitude, z: 0.0);
    
    setState(() {
      _points.add(newPoint);
      _rebuildMapElements();
    });

    try {
      final url = Uri.parse('https://maps.googleapis.com/maps/api/elevation/json?locations=${position.latitude},${position.longitude}&key=AIzaSyClkdHOLWnKrRwkAHE5_aJyw-xboEnA7dw');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final elevation = data['results'][0]['elevation'];
          setState(() {
            final index = _points.indexOf(newPoint);
            if (index != -1) {
              _points[index] = GeometryPoint(latitude: position.latitude, longitude: position.longitude, z: (elevation as num).toDouble());
            }
          });
        }
      }
    } catch (e) {
      print('Failed to get elevation: $e');
    }
  }

  void _rebuildMapElements() {
    _markers.clear();
    _markers.addAll(_contextMarkers);
    
    for (int i = 0; i < _points.length; i++) {
      _markers.add(Marker(
        markerId: MarkerId('point_${i + 1}'),
        position: LatLng(_points[i].latitude, _points[i].longitude),
        infoWindow: InfoWindow(title: 'Point ${i + 1}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        draggable: true,
        onDrag: (LatLng newPos) {
          setState(() {
            _points[i] = GeometryPoint(latitude: newPos.latitude, longitude: newPos.longitude, z: _points[i].z);
            _rebuildMapElements();
          });
        },
        onDragEnd: (LatLng newPos) {
          setState(() {
            _points[i] = GeometryPoint(latitude: newPos.latitude, longitude: newPos.longitude, z: _points[i].z);
            _rebuildMapElements();
          });
        },
      ));
    }

    _polylines.clear();
    _polylines.addAll(_contextPolylines);
    
    if (_points.length > 1) {
      List<GeometryPoint> routePoints = _points;
      if (_points.length > 2) {
        routePoints = _catmullRomSpline(_points, _curveSharpness);
      }
      
      _polylines.add(Polyline(
        polylineId: const PolylineId('segment_line'),
        points: routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        color: Colors.pinkAccent,
        width: 5,
        zIndex: 10,
      ));
    }
  }

  void _undoLastPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
      _rebuildMapElements();
    });
  }

  void _showSaveSegmentSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ductDiameterController = TextEditingController();
    
    String streetType = 'residential';
    String workType = 'EXCAVATION';
    String soilType = 'ASPHALT';
    String trafficLevel = 'LOW';
    String? assignedCrewId;
    String? startNvtId;
    String? endNvtId;
    String? connectedPopId;
    
    DateTime? plannedStartDate;
    DateTime? plannedEndDate;
    
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 40),
              child: GlassCard(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Save Segment Info', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text('Calculated Length: ${_getTotalLength().toStringAsFixed(2)}m', style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Street Name (e.g. Hauptstraße)',
                            labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: streetType,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF16171A),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Street Type',
                                  labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                                ),
                                items: ['residential', 'highway', 'commercial', 'industrial'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                                onChanged: (val) { if (val != null) setSheetState(() => streetType = val); },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: workType,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF16171A),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Work Type',
                                  labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                                ),
                                items: ['EXCAVATION', 'TRENCHING', 'DUCT_INSTALLATION'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) { if (val != null) setSheetState(() => workType = val); },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: soilType,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF16171A),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Soil Type',
                                  labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                                ),
                                items: ['ASPHALT', 'SOIL', 'COBBLESTONE', 'PAVEMENT', 'MIXED'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) { if (val != null) setSheetState(() => soilType = val); },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: trafficLevel,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF16171A),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Traffic Level',
                                  labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                                ),
                                items: ['LOW', 'MEDIUM', 'HIGH'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) { if (val != null) setSheetState(() => trafficLevel = val); },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: ductDiameterController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Duct Diameter (mm) - Optional',
                            labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final selected = await showDatePicker(
                                    context: sheetContext,
                                    initialDate: plannedStartDate ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                                  );
                                  if (selected != null) {
                                    setSheetState(() => plannedStartDate = selected);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Start Date',
                                    labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    plannedStartDate != null ? '${plannedStartDate!.year}-${plannedStartDate!.month.toString().padLeft(2, '0')}-${plannedStartDate!.day.toString().padLeft(2, '0')}' : 'Select Date',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final selected = await showDatePicker(
                                    context: sheetContext,
                                    initialDate: plannedEndDate ?? plannedStartDate ?? DateTime.now(),
                                    firstDate: plannedStartDate ?? DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                                  );
                                  if (selected != null) {
                                    setSheetState(() => plannedEndDate = selected);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'End Date',
                                    labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    plannedEndDate != null ? '${plannedEndDate!.year}-${plannedEndDate!.month.toString().padLeft(2, '0')}-${plannedEndDate!.day.toString().padLeft(2, '0')}' : 'Select Date',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<String?>(
                          value: assignedCrewId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF16171A),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Assigned Crew',
                            labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('-- No Crew Assigned --', style: TextStyle(color: Colors.white54))),
                            ..._crews.map((c) => DropdownMenuItem<String?>(value: c['id']?.toString(), child: Text(c['name'] ?? 'Unknown Crew'))),
                          ],
                          onChanged: (val) { setSheetState(() => assignedCrewId = val); },
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: startNvtId,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF16171A),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Start NVT',
                                  labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(value: null, child: Text('-- None --', style: TextStyle(color: Colors.white54))),
                                  ..._netzverteilers.map((n) => DropdownMenuItem<String?>(value: n['id']?.toString(), child: Text(n['identifier'] ?? 'NVT'))),
                                ],
                                onChanged: (val) { setSheetState(() => startNvtId = val); },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: endNvtId,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF16171A),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'End NVT',
                                  labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(value: null, child: Text('-- None --', style: TextStyle(color: Colors.white54))),
                                  ..._netzverteilers.map((n) => DropdownMenuItem<String?>(value: n['id']?.toString(), child: Text(n['identifier'] ?? 'NVT'))),
                                ],
                                onChanged: (val) { setSheetState(() => endNvtId = val); },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String?>(
                          value: connectedPopId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF16171A),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Connected POP',
                            labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('-- None --', style: TextStyle(color: Colors.white54))),
                            ..._pops.map((p) => DropdownMenuItem<String?>(value: p['id']?.toString(), child: Text(p['name'] ?? 'POP'))),
                          ],
                          onChanged: (val) { setSheetState(() => connectedPopId = val); },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSaving ? null : () async {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Street Name is required')));
                                return;
                              }
                              
                              if (plannedStartDate != null && plannedEndDate != null && plannedStartDate!.isAfter(plannedEndDate!)) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(
                                  content: Text('Error: Start date must be before or equal to End date.'),
                                  backgroundColor: Colors.redAccent,
                                ));
                                return;
                              }

                              setSheetState(() => isSaving = true);
                              try {
                                List<GeometryPoint> savePoints = _points;
                                // We NO LONGER interpolate the points for the backend.
                                // We send the raw nodes, avoiding memory overflows in Unity AR due to too many vectors.
                                
                                final geometry = savePoints.map((p) => {
                                  "lat": p.latitude,
                                  "lng": p.longitude,
                                  "z": p.z ?? 0.0
                                }).toList();
                                
                                final body = {
                                  "streetName": nameController.text.trim(),
                                  "streetType": streetType,
                                  "workType": workType,
                                  "soilType": soilType,
                                  "trafficLevel": trafficLevel,
                                  "ductDiameter": double.tryParse(ductDiameterController.text),
                                  "assignedCrewId": assignedCrewId != null ? int.tryParse(assignedCrewId!) : null,
                                  "startNvtId": startNvtId != null ? int.tryParse(startNvtId!) : null,
                                  "endNvtId": endNvtId != null ? int.tryParse(endNvtId!) : null,
                                  "connectedPopId": connectedPopId != null ? int.tryParse(connectedPopId!) : null,
                                  "currentState": "PLAN",
                                  "length": _getTotalLength(),
                                  "startLatitude": _points.first.latitude,
                                  "startLongitude": _points.first.longitude,
                                  "endLatitude": _points.last.latitude,
                                  "endLongitude": _points.last.longitude,
                                  "plannedStartDate": plannedStartDate != null ? '${plannedStartDate!.year}-${plannedStartDate!.month.toString().padLeft(2, '0')}-${plannedStartDate!.day.toString().padLeft(2, '0')}' : null,
                                  "plannedEndDate": plannedEndDate != null ? '${plannedEndDate!.year}-${plannedEndDate!.month.toString().padLeft(2, '0')}-${plannedEndDate!.day.toString().padLeft(2, '0')}' : null,
                                  "geometry": geometry
                                };
                                
                                String endpoint = '/segments';
                                if (widget.projectId != null) {
                                  endpoint = '/projects/${widget.projectId}/segments';
                                }
                                
                                await ApiService().post(endpoint, body);
                                
                                Navigator.pop(sheetContext); 
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Segment Created in Backend!'), backgroundColor: Colors.green),
                                );
                                this.context.pop(); 
                              } catch (e) {
                                print('Save segment error: $e');
                                String errorMsg = e.toString();
                                if (errorMsg.contains('currently busy')) {
                                  // This is a validation error from the backend. Show a red toaster and DO NOT close the sheet.
                                  String cleanMsg = errorMsg.replaceAll('Exception: ', '');
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(content: Text(cleanMsg), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 5)),
                                  );
                                } else {
                                  // Generic error, assume offline
                                  Navigator.pop(sheetContext); 
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(content: Text('Segment Created Locally (Backend err: $errorMsg)'), backgroundColor: Colors.orange),
                                  );
                                  this.context.pop();
                                }
                              } finally {
                                setSheetState(() => isSaving = false);
                              }
                            },
                            child: isSaving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('Save Segment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search location...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent, size: 20),
                onPressed: () => _searchLocation(_searchController.text),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _searchLocation,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.white),
              onPressed: _undoLastPoint,
              tooltip: 'Undo Last Point',
            ),
        ],
      ),
      floatingActionButton: _points.length > 1
        ? FloatingActionButton.extended(
            onPressed: _showSaveSegmentSheet,
            backgroundColor: Colors.greenAccent,
            icon: const Icon(Icons.check, color: Colors.black),
            label: const Text('Confirm Segment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: _hasLocationPermission,
            mapType: MapType.hybrid,
          ),
          if (_points.isEmpty)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: GlassCard(
                child: const Center(
                  child: Text(
                    'Tap on the map to place the Start Point (A)',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          
          if (_points.length > 1)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: GlassCard(
                borderRadius: 16,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'VECTOR ANALYTICS',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Total: ${_getTotalLength().toStringAsFixed(2)}m',
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => setState(() => _isVectorAnalyticsExpanded = !_isVectorAnalyticsExpanded),
                                child: Icon(
                                  _isVectorAnalyticsExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_isVectorAnalyticsExpanded) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Curve Sharpness (R):', style: TextStyle(color: Colors.white70, fontSize: 10)),
                            Expanded(
                              child: Slider(
                                value: _curveSharpness,
                                min: 0.1,
                                max: 1.5,
                                activeColor: Colors.pinkAccent,
                                onChanged: (val) {
                                  setState(() {
                                    _curveSharpness = val;
                                    _rebuildMapElements();
                                  });
                                },
                              ),
                            ),
                            Text(_curveSharpness.toStringAsFixed(2), style: const TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _points.length - 1,
                            itemBuilder: (context, index) {
                              final p1 = _points[index];
                              final p2 = _points[index + 1];
                              
                              final distanceStr = _calculateDistance(p1.latitude, p1.longitude, p2.latitude, p2.longitude);
                              
                              double slope = 0.0;
                              if (distanceStr > 0 && p1.z != null && p2.z != null) {
                                  slope = ((p2.z! - p1.z!) / distanceStr) * 100;
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.pinkAccent.withOpacity(0.2),
                                        border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('V${index + 1}', style: const TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    Text('${distanceStr.toStringAsFixed(2)}m', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          slope == 0 ? '0.00%' : (slope > 0 ? '▲ ${slope.toStringAsFixed(2)}%' : '▼ ${(-slope).toStringAsFixed(2)}%'),
                                          style: TextStyle(
                                            color: slope == 0 ? Colors.white70 : (slope > 0 ? Colors.greenAccent : Colors.redAccent),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace'
                                          ),
                                        ),
                                        Text(
                                          'Z1: ${p1.z?.toStringAsFixed(1) ?? '0.0'}m, Z2: ${p2.z?.toStringAsFixed(1) ?? '0.0'}m',
                                          style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace'),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
