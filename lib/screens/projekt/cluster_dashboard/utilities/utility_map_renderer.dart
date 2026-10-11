import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/utility_models.dart';

/// Strategy and builder for rendering utility lines on Google Maps (SRP & OCP compliant).
class UtilityMapRenderer {
  /// Resolves the display color according to utility type or subclass.
  static Color getUtilityColor(UtilityLine util) {
    if (util is WaterPipe) {
      return Colors.blueAccent;
    } else if (util is GasPipe) {
      return Colors.yellowAccent;
    } else if (util is ElectricityCable) {
      return Colors.redAccent;
    }

    switch (util.utilityType.toUpperCase()) {
      case 'WATER':
        return Colors.blueAccent;
      case 'GAS':
        return Colors.yellowAccent;
      case 'ELECTRICITY':
        return Colors.redAccent;
      case 'TELECOM':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  /// Extracts coordinates from dynamic JSON geometries safely.
  static List<LatLng> extractCoordinates(List<dynamic> rawGeometry) {
    final points = <LatLng>[];
    for (final item in rawGeometry) {
      if (item is Map) {
        final latNum = item['lat'] ?? item['latitude'];
        final lngNum = item['lng'] ?? item['longitude'];
        if (latNum is num && lngNum is num) {
          points.add(LatLng(latNum.toDouble(), lngNum.toDouble()));
        }
      }
    }
    return points;
  }

  /// Builds the Google Maps polylines for all provided utility lines.
  static Set<Polyline> buildPolylines(
    List<UtilityLine> utilities, {
    void Function(UtilityLine)? onUtilityTapped,
  }) {
    final polylines = <Polyline>{};

    for (final util in utilities) {
      final points = extractCoordinates(util.geometry);
      if (points.isEmpty) continue;

      final color = getUtilityColor(util);
      final id = 'util_${util.utilityType}_${util.id ?? points.first.hashCode}';

      polylines.add(Polyline(
        polylineId: PolylineId(id),
        points: points,
        color: color,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        zIndex: 0,
        consumeTapEvents: onUtilityTapped != null,
        onTap: onUtilityTapped != null ? () => onUtilityTapped(util) : null,
      ));
    }

    return polylines;
  }
}
