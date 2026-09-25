
import 'crew.dart';
import 'geometry_point.dart';
import 'hazard.dart';
import 'infrastructure_elements.dart';
import 'enums/work_type.dart';
import 'enums/workflow_state.dart';

class Segment {
  final String id;

  final Crew? assignedCrew;
  final WorkType workType;
  final WorkflowState currentState;
  final String? streetName;
  final String? streetType;
  final String? soilType;
  final double? length;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final double? elevation;
  final List<GeometryPoint> geometry;
  final String? trafficLevel;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final double? ductDiameter;
  final String? startAddress;
  final String? endAddress;
  final Map<String, dynamic> customFields;
  final String? startNvtId;
  final String? endNvtId;
  final String? connectedPopId;
  final List<Hazard> hazards;
  final List<Rohrverband> rohrverband;

  const Segment({
    required this.id,
    this.assignedCrew,
    required this.workType,
    this.currentState = WorkflowState.plan,
    this.streetName,
    this.streetType,
    this.soilType,
    this.length,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.elevation,
    this.geometry = const [],
    this.trafficLevel,
    this.plannedStartDate,
    this.plannedEndDate,
    this.ductDiameter,
    this.startAddress,
    this.endAddress,
    this.customFields = const {},
    this.startNvtId,
    this.endNvtId,
    this.connectedPopId,
    this.hazards = const [],
    this.rohrverband = const [],
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      id: json['id'].toString(),
      workType: WorkType.values.firstWhere(
        (w) => w.toString().split('.').last == json['workType'],
        orElse: () => WorkType.trenching,
      ),
      currentState: WorkflowState.values.firstWhere(
        (w) => w.toString().split('.').last == json['currentState'],
        orElse: () => WorkflowState.plan,
      ),
      streetName: json['streetName'],
      streetType: json['streetType'],
      soilType: json['soilType'],
      length: json['length']?.toDouble(),
      startLatitude: json['startLatitude']?.toDouble(),
      startLongitude: json['startLongitude']?.toDouble(),
      endLatitude: json['endLatitude']?.toDouble(),
      endLongitude: json['endLongitude']?.toDouble(),
      elevation: json['elevation']?.toDouble(),
      geometry: json['geometry'] != null
          ? (json['geometry'] as List).map((e) => GeometryPoint.fromJson(e)).toList()
          : const [],
      trafficLevel: json['trafficLevel'],
      plannedStartDate: json['plannedStartDate'] != null ? DateTime.parse(json['plannedStartDate']) : null,
      plannedEndDate: json['plannedEndDate'] != null ? DateTime.parse(json['plannedEndDate']) : null,
      ductDiameter: json['ductDiameter']?.toDouble(),
      startAddress: json['startAddress'],
      endAddress: json['endAddress'],
      customFields: json['customFields'] ?? const {},
      startNvtId: json['startNvtId']?.toString(),
      endNvtId: json['endNvtId']?.toString(),
      connectedPopId: json['connectedPopId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workType': workType.toString().split('.').last,
      'currentState': currentState.toString().split('.').last,
      'streetName': streetName,
      'streetType': streetType,
      'soilType': soilType,
      'length': length,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'elevation': elevation,
      'geometry': geometry.map((e) => e.toJson()).toList(),
      'trafficLevel': trafficLevel,
      'plannedStartDate': plannedStartDate?.toIso8601String(),
      'plannedEndDate': plannedEndDate?.toIso8601String(),
      'ductDiameter': ductDiameter,
      'startAddress': startAddress,
      'endAddress': endAddress,
      'customFields': customFields,
      'startNvtId': startNvtId,
      'endNvtId': endNvtId,
      'connectedPopId': connectedPopId,
    };
  }
}
