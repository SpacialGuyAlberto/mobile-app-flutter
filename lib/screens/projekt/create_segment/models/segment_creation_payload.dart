import '../../../../models/planning/geometry_point.dart';

/// Strongly-typed payload for segment creation (SRP & OCP compliant).
class SegmentCreationPayload {
  final String streetName;
  final String streetType;
  final String workType;
  final String soilType;
  final String trafficLevel;
  final double? ductDiameter;
  final int? assignedCrewId;
  final int? startNvtId;
  final int? endNvtId;
  final int? connectedPopId;
  final double length;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final List<GeometryPoint> points;

  const SegmentCreationPayload({
    required this.streetName,
    required this.streetType,
    required this.workType,
    required this.soilType,
    required this.trafficLevel,
    this.ductDiameter,
    this.assignedCrewId,
    this.startNvtId,
    this.endNvtId,
    this.connectedPopId,
    required this.length,
    this.plannedStartDate,
    this.plannedEndDate,
    required this.points,
  });

  Map<String, dynamic> toJson() {
    final geometry = points.map((p) => {
      'lat': p.latitude,
      'lng': p.longitude,
      'z': p.z ?? 0.0,
    }).toList();

    return {
      'streetName': streetName,
      'streetType': streetType,
      'workType': workType,
      'soilType': soilType,
      'trafficLevel': trafficLevel,
      'ductDiameter': ductDiameter,
      'assignedCrewId': assignedCrewId,
      'startNvtId': startNvtId,
      'endNvtId': endNvtId,
      'connectedPopId': connectedPopId,
      'currentState': 'PLAN',
      'length': length,
      'startLatitude': points.isNotEmpty ? points.first.latitude : null,
      'startLongitude': points.isNotEmpty ? points.first.longitude : null,
      'endLatitude': points.isNotEmpty ? points.last.latitude : null,
      'endLongitude': points.isNotEmpty ? points.last.longitude : null,
      'plannedStartDate': plannedStartDate != null
          ? '${plannedStartDate!.year}-${plannedStartDate!.month.toString().padLeft(2, '0')}-${plannedStartDate!.day.toString().padLeft(2, '0')}'
          : null,
      'plannedEndDate': plannedEndDate != null
          ? '${plannedEndDate!.year}-${plannedEndDate!.month.toString().padLeft(2, '0')}-${plannedEndDate!.day.toString().padLeft(2, '0')}'
          : null,
      'geometry': geometry,
    };
  }
}
