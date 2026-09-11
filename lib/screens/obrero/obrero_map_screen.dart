import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../widgets/glass_card.dart';

class ObreroMapScreen extends StatefulWidget {
  const ObreroMapScreen({Key? key}) : super(key: key);

  @override
  State<ObreroMapScreen> createState() => _ObreroMapScreenState();
}

class _ObreroMapScreenState extends State<ObreroMapScreen> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;

  static const CameraPosition _berlinInitial = CameraPosition(
    target: LatLng(52.5200, 13.4050),
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    _fetchAssignedSegments();
  }

  Future<void> _fetchAssignedSegments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, pass the crew ID or auth token.
      final response = await http.get(Uri.parse('http://localhost:8080/api/v1/planning/crews/1/segments'));

      if (response.statusCode == 200) {
        final List<dynamic> segments = jsonDecode(response.body);
        
        setState(() {
          for (var i = 0; i < segments.length; i++) {
            var segment = segments[i];
            List<LatLng> points = [];
            // Assuming geometry is a LineString
            for (var pt in segment['geometry']['coordinates']) {
              points.add(LatLng(pt[1], pt[0])); // geojson is lon, lat
            }

            _polylines.add(Polyline(
              polylineId: PolylineId('segment_${segment['id']}'),
              points: points,
              color: Colors.orangeAccent,
              width: 5,
            ));
            
            // Add a marker for the start of the segment
            if (points.isNotEmpty) {
              _markers.add(Marker(
                markerId: MarkerId('marker_${segment['id']}'),
                position: points.first,
                infoWindow: InfoWindow(
                  title: 'Task: ${segment['name']}',
                  snippet: 'Length: ${segment['estimatedLength']}m',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              ));
            }
          }
        });
      } else {
        // Fallback dummy data if backend is not reachable / no segments assigned
        _loadDummySegments();
      }
    } catch (e) {
      _loadDummySegments();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadDummySegments() {
    setState(() {
      _polylines.add(const Polyline(
        polylineId: PolylineId('dummy_segment'),
        points: [
          LatLng(52.5200, 13.4050),
          LatLng(52.5210, 13.4060),
          LatLng(52.5220, 13.4055),
        ],
        color: Colors.orangeAccent,
        width: 5,
      ));
      _markers.add(
        Marker(
          markerId: const MarkerId('dummy_marker'),
          position: const LatLng(52.5200, 13.4050),
          infoWindow: const InfoWindow(title: 'Task: Trenching Alexanderplatz', snippet: 'Length: 450m'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _berlinInitial,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            mapType: MapType.hybrid,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131415), // AppTheme.cardDark
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x1AFFFFFF)), // AppTheme.borderLight
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TODAY'S PROGRESS",
                          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6938EF)),
                          )
                        else
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric(theme, 'Pending', '3 Segments'),
                        _buildMetric(theme, 'Completed', '120m'),
                        _buildMetric(theme, 'Target', '150m'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/evidence_capture/SEG-CURRENT');
        },
        backgroundColor: const Color(0xFF6938EF),
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: Text(
          'CAPTURE EVIDENCE',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMetric(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}
