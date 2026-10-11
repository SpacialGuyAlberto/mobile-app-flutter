import 'infrastructure_elements.dart';

class Cluster {
  final String id;
  final String name;
  final String? description;
  final String projectId;
  final String? projectManagerId;
  final List<Pop> pops;
  final double? latitude;
  final double? longitude;

  const Cluster({
    required this.id,
    required this.name,
    this.description,
    required this.projectId,
    this.projectManagerId,
    this.pops = const [],
    this.latitude,
    this.longitude,
  });

  factory Cluster.fromJson(Map<String, dynamic> json) {
    return Cluster(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      projectId: json['projectId']?.toString() ?? json['project']?['id']?.toString() ?? '',
      projectManagerId: json['projectManagerId']?.toString() ?? json['projectManager']?['id']?.toString(),
      pops: json['pops'] != null 
          ? (json['pops'] as List).map((e) => Pop.fromJson(e)).toList() 
          : const [],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'projectId': projectId,
      'projectManagerId': projectManagerId,
      'pops': pops.map((e) => e.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
