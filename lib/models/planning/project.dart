import 'organization.dart';
import 'segment.dart';
import 'geometry_point.dart';
import 'cluster.dart';
import 'enums/work_type.dart';

class Project {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Cluster> clusters;
  final Organization? organization;
  final double? startLatitude;
  final double? startLongitude;
  final List<GeometryPoint> geometry;
  final List<WorkType> lifecycleTodo;
  final List<WorkType> lifecycleDone;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.clusters = const [],
    this.organization,
    this.startLatitude,
    this.startLongitude,
    this.geometry = const [],
    this.lifecycleTodo = const [],
    this.lifecycleDone = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      organization: json['organization'] != null ? Organization.fromJson(json['organization']) : null,
      startLatitude: json['startLatitude']?.toDouble(),
      startLongitude: json['startLongitude']?.toDouble(),
      geometry: json['geometry'] != null 
          ? (json['geometry'] as List).map((e) => GeometryPoint.fromJson(e)).toList() 
          : const [],
      clusters: json['clusters'] != null 
          ? (json['clusters'] as List).map((e) => Cluster.fromJson(e)).toList() 
          : const [],
      lifecycleTodo: json['lifecycleTodo'] != null 
          ? (json['lifecycleTodo'] as List).map((e) => WorkType.values.firstWhere((w) => w.toString().split('.').last == e)).toList()
          : const [],
      lifecycleDone: json['lifecycleDone'] != null 
          ? (json['lifecycleDone'] as List).map((e) => WorkType.values.firstWhere((w) => w.toString().split('.').last == e)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'organization': organization?.toJson(),
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'geometry': geometry.map((e) => e.toJson()).toList(),
      'clusters': clusters.map((e) => e.toJson()).toList(),
      'lifecycleTodo': lifecycleTodo.map((e) => e.toString().split('.').last).toList(),
      'lifecycleDone': lifecycleDone.map((e) => e.toString().split('.').last).toList(),
    };
  }
}
