import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class InteractiveMapView extends StatelessWidget {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final CameraPosition initialCameraPosition;

  const InteractiveMapView({
    Key? key,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.initialCameraPosition = const CameraPosition(
      target: LatLng(52.5200, 13.4050), // Default Berlin
      zoom: 12.0,
    ),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 300, // Or whatever parent passes down if Expanded is used, 
        // wait, if it's inside Expanded, the parent might constrain it, but we can rely on constraints.
        // Actually, the parent in ClusterArea uses Expanded(child: InteractiveMapView()), so it will stretch.
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF131415),
          border: Border.all(color: const Color(0xFF2D2E33)),
        ),
        child: GoogleMap(
          initialCameraPosition: initialCameraPosition,
          markers: markers,
          polylines: polylines,
          myLocationEnabled: false,
          mapType: MapType.hybrid, // Hybrid works well for dark themes in construction
          compassEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}
