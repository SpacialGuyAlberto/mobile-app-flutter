import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/planning/geometry_point.dart';
import '../geometry/segment_geometry_service.dart';
import '../models/create_segment_metadata.dart';

class SegmentMapElements {
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const SegmentMapElements({
    required this.markers,
    required this.polylines,
  });
}

/// Helper to build context markers/polylines and the active route drawing (SRP compliant).
class SegmentMapBuilder {
  static Set<Marker> buildContextMarkers(
    CreateSegmentMetadata metadata, {
    BitmapDescriptor? popIcon,
    BitmapDescriptor? nvtIcon,
  }) {
    final markers = <Marker>{};

    for (final pop in metadata.pops) {
      if (pop['latitude'] != null && pop['longitude'] != null) {
        markers.add(Marker(
          markerId: MarkerId('pop_${pop['id']}'),
          position: LatLng(
            (pop['latitude'] as num).toDouble(),
            (pop['longitude'] as num).toDouble(),
          ),
          icon: popIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: pop['name']?.toString() ?? 'POP Node'),
        ));
      }
    }

    for (final nvt in metadata.netzverteilers) {
      if (nvt['latitude'] != null && nvt['longitude'] != null) {
        markers.add(Marker(
          markerId: MarkerId('nvt_${nvt['id']}'),
          position: LatLng(
            (nvt['latitude'] as num).toDouble(),
            (nvt['longitude'] as num).toDouble(),
          ),
          icon: nvtIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: nvt['identifier']?.toString() ?? 'Netzverteiler'),
        ));
      }
    }

    return markers;
  }

  static Set<Polyline> buildContextPolylines(CreateSegmentMetadata metadata) {
    final polylines = <Polyline>{};

    for (final seg in metadata.segmentsContext) {
      if (seg['geometry'] != null && seg['geometry'] is List && (seg['geometry'] as List).isNotEmpty) {
        final points = (seg['geometry'] as List).map((g) {
          final lat = (g['lat'] ?? g['latitude'] as num).toDouble();
          final lng = (g['lng'] ?? g['longitude'] as num).toDouble();
          return LatLng(lat, lng);
        }).toList();

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

    return polylines;
  }

  static SegmentMapElements build({
    required Set<Marker> contextMarkers,
    required Set<Polyline> contextPolylines,
    required List<GeometryPoint> points,
    required double curveSharpness,
    required void Function(int index, LatLng position) onPointDragged,
  }) {
    final markers = Set<Marker>.from(contextMarkers);
    final polylines = Set<Polyline>.from(contextPolylines);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      markers.add(Marker(
        markerId: MarkerId('point_${i + 1}'),
        position: LatLng(point.latitude, point.longitude),
        infoWindow: InfoWindow(title: 'Point ${i + 1}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        draggable: true,
        onDrag: (pos) => onPointDragged(i, pos),
        onDragEnd: (pos) => onPointDragged(i, pos),
      ));
    }

    if (points.length > 1) {
      final routePoints = points.length > 2
          ? SegmentGeometryService.catmullRomSpline(points, curveSharpness)
          : points;

      polylines.add(Polyline(
        polylineId: const PolylineId('segment_line'),
        points: routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        color: Colors.pinkAccent,
        width: 5,
        zIndex: 10,
      ));
    }

    return SegmentMapElements(markers: markers, polylines: polylines);
  }
}
