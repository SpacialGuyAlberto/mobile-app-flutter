import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/location_service.dart';
import '../../models/planning/geometry_point.dart';
import '../../widgets/glass_card.dart';

import 'create_segment/geometry/segment_geometry_service.dart';
import 'create_segment/models/create_segment_metadata.dart';
import 'create_segment/models/segment_creation_payload.dart';
import 'create_segment/services/create_segment_repository.dart';
import 'create_segment/utils/segment_map_builder.dart';
import 'create_segment/widgets/save_segment_bottom_sheet.dart';
import 'create_segment/widgets/vector_analytics_card.dart';

/// Screen for interactive vector routing and segment creation (SOLID compliant).
class CreateSegmentScreen extends StatefulWidget {
  final String? projectId;
  final double? initialLat;
  final double? initialLng;
  final double? initialZoom;
  final ICreateSegmentRepository? repository;
  final LocationService? locationService;

  const CreateSegmentScreen({
    super.key,
    this.projectId,
    this.initialLat,
    this.initialLng,
    this.initialZoom,
    this.repository,
    this.locationService,
  });

  @override
  State<CreateSegmentScreen> createState() => _CreateSegmentScreenState();
}

class _CreateSegmentScreenState extends State<CreateSegmentScreen> {
  late final ICreateSegmentRepository _repository;
  late final LocationService _locationService;

  final TextEditingController _searchController = TextEditingController();
  final List<GeometryPoint> _points = [];

  double _curveSharpness = 0.85;
  bool _isVectorAnalyticsExpanded = true;
  bool _hasLocationPermission = false;

  late CameraPosition _initialCamera;
  GoogleMapController? _mapController;

  CreateSegmentMetadata _metadata = const CreateSegmentMetadata();
  Set<Marker> _contextMarkers = {};
  Set<Polyline> _contextPolylines = {};
  SegmentMapElements _mapElements = const SegmentMapElements(markers: {}, polylines: {});

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CreateSegmentRepository();
    _locationService = widget.locationService ?? LocationService();

    _initialCamera = CameraPosition(
      target: LatLng(widget.initialLat ?? 52.5200, widget.initialLng ?? 13.4050),
      zoom: widget.initialZoom ?? 13.0,
    );

    _checkLocationPermission();
    _loadMetadata();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final hasPermission = await _locationService.hasPermission();
    if (mounted) {
      setState(() => _hasLocationPermission = hasPermission);
    }
  }

  Future<void> _loadMetadata() async {
    final metadata = await _repository.fetchMetadata(widget.projectId);

    if (!mounted) return;

    setState(() {
      _metadata = metadata;
      _contextMarkers = SegmentMapBuilder.buildContextMarkers(metadata);
      _contextPolylines = SegmentMapBuilder.buildContextPolylines(metadata);
      _rebuildMapElements();

      if (widget.initialLat == null) {
        if (metadata.projectInitialLocation != null) {
          _initialCamera = CameraPosition(target: metadata.projectInitialLocation!, zoom: 16.0);
          _mapController?.animateCamera(CameraUpdate.newCameraPosition(_initialCamera));
        } else if (metadata.netzverteilers.isNotEmpty && metadata.netzverteilers.first['latitude'] != null) {
          final target = LatLng(
            (metadata.netzverteilers.first['latitude'] as num).toDouble(),
            (metadata.netzverteilers.first['longitude'] as num).toDouble(),
          );
          _initialCamera = CameraPosition(target: target, zoom: 16.0);
          _mapController?.animateCamera(CameraUpdate.newCameraPosition(_initialCamera));
        }
      }
    });
  }

  void _rebuildMapElements() {
    setState(() {
      _mapElements = SegmentMapBuilder.build(
        contextMarkers: _contextMarkers,
        contextPolylines: _contextPolylines,
        points: _points,
        curveSharpness: _curveSharpness,
        onPointDragged: (index, newPos) {
          setState(() {
            _points[index] = GeometryPoint(
              latitude: newPos.latitude,
              longitude: newPos.longitude,
              z: _points[index].z,
            );
            _rebuildMapElements();
          });
        },
      );
    });
  }

  Future<void> _searchLocation(String query) async {
    final target = await _repository.searchGeocodeLocation(query);
    if (target != null && mounted) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 17.0)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found')),
      );
    }
  }

  Future<void> _onMapTapped(LatLng position) async {
    final newPoint = GeometryPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      z: 0.0,
    );

    setState(() {
      _points.add(newPoint);
      _rebuildMapElements();
    });

    final elevation = await _repository.fetchElevation(position);
    if (elevation != null && mounted) {
      setState(() {
        final index = _points.indexOf(newPoint);
        if (index != -1) {
          _points[index] = GeometryPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            z: elevation,
          );
        }
      });
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
    final length = SegmentGeometryService.calculateTotalLength(_points, _curveSharpness);

    SaveSegmentBottomSheet.show(
      context,
      calculatedLength: length,
      points: List.unmodifiable(_points),
      metadata: _metadata,
      onSave: (payload) => _handleSaveSegment(payload),
    );
  }

  Future<void> _handleSaveSegment(SegmentCreationPayload payload) async {
    try {
      await _repository.saveSegment(widget.projectId, payload);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Segment Created in Backend!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('currently busy')) {
        final cleanMsg = errorMsg.replaceAll('Exception: ', '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cleanMsg),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Segment Created Locally (Backend err: $errorMsg)'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop();
        }
      }
    }
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
              contentPadding: EdgeInsets.zero,
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
            markers: _mapElements.markers,
            polylines: _mapElements.polylines,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: _hasLocationPermission,
            mapType: MapType.hybrid,
          ),
          if (_points.isEmpty)
            const Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: GlassCard(
                child: Center(
                  child: Text(
                    'Tap on the map to place the Start Point (A)',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          VectorAnalyticsCard(
            points: _points,
            curveSharpness: _curveSharpness,
            isExpanded: _isVectorAnalyticsExpanded,
            onToggleExpand: (val) => setState(() => _isVectorAnalyticsExpanded = val),
            onSharpnessChanged: (val) {
              setState(() {
                _curveSharpness = val;
                _rebuildMapElements();
              });
            },
          ),
        ],
      ),
    );
  }
}
