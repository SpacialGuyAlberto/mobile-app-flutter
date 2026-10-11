import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/segment_edit_bottom_sheet.dart';

class BauleiterMapScreen extends StatefulWidget {
  const BauleiterMapScreen({Key? key}) : super(key: key);

  @override
  State<BauleiterMapScreen> createState() => _BauleiterMapScreenState();
}

class _BauleiterMapScreenState extends State<BauleiterMapScreen> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = false;

  static const CameraPosition _berlinInitial = CameraPosition(
    target: LatLng(52.5200, 13.4050),
    zoom: 13.0,
  );

  Future<void> _uploadAndExtractLines() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _isLoading = true;
      _polylines.clear();
      _markers.clear();
    });

    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('${ApiService.baseHost}/api/v1/planning/segment-recognition/process-raster')
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> segments = data['segments'] ?? [];

        setState(() {
          for (var i = 0; i < segments.length; i++) {
            var segment = segments[i];
            List<LatLng> points = [];
            for (var pt in segment['geometry']['coordinates']) {
              // Usually GeoJSON is [longitude, latitude]
              points.add(LatLng(pt[1], pt[0]));
            }

            _polylines.add(Polyline(
              polylineId: PolylineId('segment_$i'),
              points: points,
              color: Colors.blueAccent,
              width: 5,
              consumeTapEvents: true,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => SegmentEditBottomSheet(
                    segment: segment,
                    onSaved: () {
                      // Optionally refresh or sync data
                    },
                  ),
                );
              },
            ));
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extracted ${segments.length} segments!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to extract lines'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            top: 20,
            left: 20,
            right: 20,
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Project Manager View',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Access project data and extract fiber lines using AI.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _uploadAndExtractLines,
                        icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.upload_file),
                        label: Text(_isLoading ? 'Processing via AI...' : 'Upload Planauskunft'),
                      ),
                    ),
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
