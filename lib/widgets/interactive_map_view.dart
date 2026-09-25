import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class InteractiveMapView extends StatelessWidget {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final CameraPosition initialCameraPosition;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;

  const InteractiveMapView({
    Key? key,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.initialCameraPosition = const CameraPosition(
      target: LatLng(52.5200, 13.4050), // Default Berlin
      zoom: 12.0,
    ),
    this.onMapCreated,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: double.infinity, // Let parent handle height instead of fixed 300
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF131415),
          border: Border.all(color: const Color(0xFF2D2E33)),
        ),
        child: GoogleMap(
          onMapCreated: onMapCreated,
          initialCameraPosition: initialCameraPosition,
          markers: markers,
          polylines: polylines,
          onTap: onTap,
          myLocationEnabled: false,
          mapType: MapType.hybrid, // Hybrid works well for dark themes in construction
          compassEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: true,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
          },
        ),
      ),
    );
  }
}

