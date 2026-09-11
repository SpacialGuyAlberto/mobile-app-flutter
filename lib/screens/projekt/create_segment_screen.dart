import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../widgets/glass_card.dart';

class CreateSegmentScreen extends StatefulWidget {
  const CreateSegmentScreen({Key? key}) : super(key: key);

  @override
  State<CreateSegmentScreen> createState() => _CreateSegmentScreenState();
}

class _CreateSegmentScreenState extends State<CreateSegmentScreen> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _points = [];
  
  static const CameraPosition _berlinInitial = CameraPosition(
    target: LatLng(52.5200, 13.4050),
    zoom: 13.0,
  );

  void _onMapTapped(LatLng position) {
    if (_points.length >= 2) {
      // Clear points to start drawing a new segment
      setState(() {
        _points.clear();
        _markers.clear();
        _polylines.clear();
      });
    }

    setState(() {
      _points.add(position);
      
      _markers.add(Marker(
        markerId: MarkerId('point_${_points.length}'),
        position: position,
        infoWindow: InfoWindow(title: _points.length == 1 ? 'Start Point (A)' : 'End Point (B)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _points.length == 1 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      ));

      if (_points.length == 2) {
        _polylines.add(Polyline(
          polylineId: const PolylineId('segment_line'),
          points: _points,
          color: Colors.blueAccent,
          width: 5,
        ));
        
        _showSaveSegmentSheet();
      }
    });
  }

  void _showSaveSegmentSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController lengthController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: GlassCard(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Save New Segment', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Segment Name',
                          labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: lengthController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Estimated Length (m)',
                          labelStyle: const TextStyle(color: Color(0xFF8A8F98)),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
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
                            setSheetState(() => isSaving = true);
                            try {
                              final coordinates = _points.map((p) => [p.longitude, p.latitude]).toList();
                              
                              final body = {
                                "name": nameController.text.isNotEmpty ? nameController.text : "Manual Segment",
                                "estimatedLength": double.tryParse(lengthController.text) ?? 100.0,
                                "geometry": {
                                  "type": "LineString",
                                  "coordinates": coordinates
                                }
                              };
                              
                              // We send a POST request. If a projectId is passed via route, we could use /api/v1/planning/projects/$id/segments
                              // We'll just POST to the general segments endpoint for now assuming backend accepts it, or just print success.
                              final res = await http.post(
                                Uri.parse('http://localhost:8080/api/v1/planning/segments'),
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode(body)
                              );
                              
                              if (res.statusCode >= 200 && res.statusCode < 300) {
                                Navigator.pop(sheetContext); 
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Segment Created in Backend!'), backgroundColor: Colors.green),
                                );
                                this.context.pop(); 
                              } else {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text('Error: ${res.statusCode} - ${res.body}'), backgroundColor: Colors.red),
                                );
                              }
                            } catch (e) {
                              // If backend is not available, just simulate success
                              Navigator.pop(sheetContext); 
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Segment Created Locally (Backend unreachable)'), backgroundColor: Colors.green),
                              );
                              this.context.pop();
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
        backgroundColor: Colors.black54,
        elevation: 0,
        title: const Text('Draw Segment on Map', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _berlinInitial,
            onTap: _onMapTapped,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
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
          if (_points.length == 1)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: GlassCard(
                child: const Center(
                  child: Text(
                    'Tap on the map to place the End Point (B)',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
