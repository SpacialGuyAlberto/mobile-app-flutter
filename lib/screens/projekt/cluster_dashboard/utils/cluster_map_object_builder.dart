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
  BitmapDescriptor? popIcon;
  BitmapDescriptor? nvtIcon;
  BitmapDescriptor? crewIcon;

  Future<void> loadCustomIcons() async {
    popIcon = await _createCustomMarker(Icons.business, const Color(0xFF6938EF), 'POP');
    nvtIcon = await _createCustomMarker(Icons.dns, const Color(0xFF2FB080), 'NVT');
    crewIcon = await _createCustomMarker(Icons.engineering, Colors.orange, 'CREW');
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
      pillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(size / 2, size - 15), width: size - 20, height: 30), const Radius.circular(15)),
      borderPaint..strokeWidth = 2.0,
    );

    TextPainter labelPainter = TextPainter(textDirection: TextDirection.ltr);
    labelPainter.text = TextSpan(text: label, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white));
    labelPainter.layout();
    labelPainter.paint(canvas, Offset((size - labelPainter.width) / 2, size - 15 - labelPainter.height / 2));

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
      if (nvts.isNotEmpty && nvts.first.latitude != null) {
        initialCamera = CameraPosition(target: LatLng(nvts.first.latitude!, nvts.first.longitude!), zoom: 16.0);
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
