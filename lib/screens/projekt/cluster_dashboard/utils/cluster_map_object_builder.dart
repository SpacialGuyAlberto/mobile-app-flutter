import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/planning/infrastructure_elements.dart';
import '../../../../models/planning/segment.dart';
import '../../../../models/utility_models.dart';
import '../utilities/utility_map_renderer.dart';

class ClusterMapData {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final CameraPosition? initialCamera;

  const ClusterMapData({
    required this.markers,
    required this.polylines,
    this.initialCamera,
  });
}

/// Dedicated builder for Google Maps markers and polylines (SRP compliant).
class ClusterMapObjectBuilder {
  static const double defaultMarkerSize = 72.0;

  BitmapDescriptor? popIcon;
  BitmapDescriptor? nvtIcon;
  BitmapDescriptor? crewIcon;

  Future<void> loadCustomIcons({double size = defaultMarkerSize}) async {
    popIcon = await createCustomMarker(Icons.business, const Color(0xFF6938EF), 'POP', size: size);
    nvtIcon = await createCustomMarker(Icons.dns, const Color(0xFF2FB080), 'NVT', size: size);
    crewIcon = await createCustomMarker(Icons.engineering, Colors.orange, 'CREW', size: size);
  }

  static Future<BitmapDescriptor> createCustomMarker(
    IconData icon,
    Color color,
    String label, {
    double size = defaultMarkerSize,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint paint = Paint()..color = color;
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = (size * 0.04).clamp(2.0, 4.0)
      ..style = PaintingStyle.stroke;

    final circleCenterY = size * 0.38;
    final circleRadius = size * 0.32;

    canvas.drawCircle(Offset(size / 2, circleCenterY), circleRadius, paint);
    canvas.drawCircle(Offset(size / 2, circleCenterY), circleRadius, borderPaint);

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    final iconFontSize = size * 0.32;
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: iconFontSize,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, circleCenterY - textPainter.height / 2),
    );

    final pillHeight = (size * 0.22).clamp(14.0, 22.0);
    final pillCenterY = size - (pillHeight / 2) - 1.5;
    final pillWidth = (size * 0.78).clamp(42.0, 70.0);

    final Paint pillPaint = Paint()..color = Colors.black87;
    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size / 2, pillCenterY),
        width: pillWidth,
        height: pillHeight,
      ),
      Radius.circular(pillHeight / 2),
    );

    canvas.drawRRect(pillRRect, pillPaint);
    canvas.drawRRect(
      pillRRect,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    final TextPainter labelPainter = TextPainter(textDirection: TextDirection.ltr);
    final labelFontSize = (size * 0.13).clamp(8.5, 11.5);
    labelPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: labelFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset((size - labelPainter.width) / 2, pillCenterY - labelPainter.height / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  ClusterMapData build({
    required List<Pop> pops,
    required List<Netzverteiler> nvts,
    required List<Segment> segments,
    required List<UtilityLine> utilities,
    LatLng? tempMarker,
    required void Function(Segment) onSegmentTapped,
    required void Function(Segment) onCrewTapped,
    required void Function(Segment) onMachineryTapped,
    void Function(UtilityLine)? onUtilityTapped,
    CameraPosition? currentInitialCamera,
    LatLng? clusterCenter,
  }) {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    for (var pop in pops) {
      if (pop.latitude != null && pop.longitude != null) {
        markers.add(Marker(
          markerId: MarkerId('pop_${pop.id}'),
          position: LatLng(pop.latitude!, pop.longitude!),
          icon: popIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: pop.name, snippet: 'POP Node'),
        ));
      }
    }

    for (var nvt in nvts) {
      if (nvt.latitude != null && nvt.longitude != null) {
        markers.add(Marker(
          markerId: MarkerId('nvt_${nvt.id}'),
          position: LatLng(nvt.latitude!, nvt.longitude!),
          icon: nvtIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: nvt.identifier, snippet: 'Netzverteiler'),
        ));
      }
    }

    for (var seg in segments) {
      if (seg.geometry.isNotEmpty) {
        final points = seg.geometry.map((g) => LatLng(g.latitude, g.longitude)).toList();

        // Outer dark border for contrast
        polylines.add(Polyline(
          polylineId: PolylineId('seg_out_${seg.id}'),
          points: points,
          color: const Color(0xFF131415),
          width: 10,
          zIndex: 1,
          consumeTapEvents: true,
          onTap: () => onSegmentTapped(seg),
        ));

        // Inner neon core
        polylines.add(Polyline(
          polylineId: PolylineId('seg_in_${seg.id}'),
          points: points,
          color: const Color(0xFF00E5FF),
          width: 5,
          zIndex: 2,
          consumeTapEvents: true,
          onTap: () => onSegmentTapped(seg),
        ));

        // Display Crew Marker if crew is assigned or in progress
        if (seg.assignedCrewId != null || seg.currentState.toString().toUpperCase().contains('INPROGRESS')) {
          final midPoint = points[points.length ~/ 2];
          markers.add(Marker(
            markerId: MarkerId('crew_${seg.id}'),
            position: midPoint,
            icon: crewIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            zIndexInt: 10,
            onTap: () => onCrewTapped(seg),
          ));

          final machineryPoint = LatLng(midPoint.latitude, midPoint.longitude + 0.00015);
          markers.add(Marker(
            markerId: MarkerId('machinery_${seg.id}'),
            position: machineryPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            zIndexInt: 9,
            onTap: () => onMachineryTapped(seg),
          ));
        }
      }
    }

    // Delegate utility polylines generation to UtilityMapRenderer (OCP & SRP)
    polylines.addAll(
      UtilityMapRenderer.buildPolylines(
        utilities,
        onUtilityTapped: onUtilityTapped,
      ),
    );

    if (tempMarker != null) {
      markers.add(Marker(
        markerId: const MarkerId('temp_marker'),
        position: tempMarker,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    CameraPosition? initialCamera = currentInitialCamera;
    if (initialCamera == null) {
      if (clusterCenter != null) {
        initialCamera = CameraPosition(target: clusterCenter, zoom: 16.0);
      } else if (nvts.isNotEmpty && nvts.first.latitude != null) {
        initialCamera = CameraPosition(target: LatLng(nvts.first.latitude!, nvts.first.longitude!), zoom: 16.0);
      } else if (pops.isNotEmpty && pops.first.latitude != null) {
        initialCamera = CameraPosition(target: LatLng(pops.first.latitude!, pops.first.longitude!), zoom: 16.0);
      } else if (segments.isNotEmpty && segments.first.geometry.isNotEmpty) {
        initialCamera = CameraPosition(
          target: LatLng(segments.first.geometry.first.latitude, segments.first.geometry.first.longitude),
          zoom: 16.0,
        );
      } else {
        initialCamera = const CameraPosition(target: LatLng(52.5200, 13.4050), zoom: 12.0);
      }
    }

    return ClusterMapData(
      markers: markers,
      polylines: polylines,
      initialCamera: initialCamera,
    );
  }
}
