import 'dart:math' show asin, cos, sqrt;
import '../../../../models/planning/geometry_point.dart';

/// Metric representing a single segment between two consecutive points (SRP).
class VectorSegmentMetric {
  final int index;
  final double distance;
  final double slopePercent;
  final double? z1;
  final double? z2;

  const VectorSegmentMetric({
    required this.index,
    required this.distance,
    required this.slopePercent,
    this.z1,
    this.z2,
  });
}

/// Service encapsulating all vector and curve mathematics for segment planning (SRP compliant).
class SegmentGeometryService {
  /// Calculates distance in meters between two lat/lng coordinates using the Haversine formula.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = cos;
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }

  /// Calculates the total length of a path with Catmull-Rom spline interpolation if points > 2.
  static double calculateTotalLength(List<GeometryPoint> points, double sharpness) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    final routePoints = points.length > 2 ? catmullRomSpline(points, sharpness) : points;

    for (int i = 0; i < routePoints.length - 1; i++) {
      total += calculateDistance(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }
    return total;
  }

  /// Performs Catmull-Rom spline interpolation to smoothly curve the vector line.
  static List<GeometryPoint> catmullRomSpline(
    List<GeometryPoint> points,
    double sharpness, {
    int resolution = 20,
  }) {
    if (points.length < 3) return points;

    final result = <GeometryPoint>[];

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

      for (int tInt = 0; tInt < resolution; tInt++) {
        final t = tInt / resolution;
        final t2 = t * t;
        final t3 = t2 * t;

        final tension = 1.0 - sharpness;
        final m0 = tension * 0.5;

        final b0 = -m0 * t3 + 2.0 * m0 * t2 - m0 * t;
        final b1 = (2.0 - m0) * t3 + (m0 - 3.0) * t2 + 1.0;
        final b2 = (m0 - 2.0) * t3 + (3.0 - 2.0 * m0) * t2 + m0 * t;
        final b3 = m0 * t3 - m0 * t2;

        final lat = p0.latitude * b0 + p1.latitude * b1 + p2.latitude * b2 + p3.latitude * b3;
        final lng = p0.longitude * b0 + p1.longitude * b1 + p2.longitude * b2 + p3.longitude * b3;
        final z = (p0.z ?? 0) * b0 + (p1.z ?? 0) * b1 + (p2.z ?? 0) * b2 + (p3.z ?? 0) * b3;

        result.add(GeometryPoint(latitude: lat, longitude: lng, z: z));
      }
    }
    result.add(points.last);
    return result;
  }

  /// Calculates per-segment distance and slope metrics for vector analytics.
  static List<VectorSegmentMetric> calculateVectorMetrics(List<GeometryPoint> points) {
    if (points.length < 2) return [];

    final metrics = <VectorSegmentMetric>[];
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final distance = calculateDistance(p1.latitude, p1.longitude, p2.latitude, p2.longitude);

      double slope = 0.0;
      if (distance > 0 && p1.z != null && p2.z != null) {
        slope = ((p2.z! - p1.z!) / distance) * 100;
      }

      metrics.add(VectorSegmentMetric(
        index: i + 1,
        distance: distance,
        slopePercent: slope,
        z1: p1.z,
        z2: p2.z,
      ));
    }
    return metrics;
  }
}
