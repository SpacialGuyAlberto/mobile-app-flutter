import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Cluster;
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';
import '../../../../models/planning/infrastructure_elements.dart';
import '../../../../models/planning/segment.dart';
import '../../../../models/planning/cluster.dart';
import '../../../../models/planning/project.dart';

/// Contract for cluster area dashboard data operations (ISP and DIP compliant).
abstract class IClusterDashboardRepository {
  Future<List<Pop>> fetchPops(String clusterId);
  Future<List<Segment>> fetchSegments(String projectId);
  Future<Cluster?> fetchCluster(String clusterId);
  Future<Project?> fetchProject(String projectId);
  Future<double?> fetchElevation(LatLng coordinates);
  Future<void> savePop(Pop pop);
  Future<void> saveNetzverteiler(Netzverteiler nvt);
  Future<void> saveSegment(String projectId, Segment segment);
}

/// Concrete implementation delegating to ApiService and elevation HTTP provider (SRP compliant).
class ClusterDashboardRepository implements IClusterDashboardRepository {
  final ApiService _apiService;
  final http.Client _httpClient;

  ClusterDashboardRepository({
    ApiService? apiService,
    http.Client? httpClient,
  })  : _apiService = apiService ?? ApiService(),
        _httpClient = httpClient ?? http.Client();

  @override
  Future<List<Pop>> fetchPops(String clusterId) async {
    try {
      final popData = await _apiService.get('/pops');
      final allPops = (popData as List).map((e) => Pop.fromJson(e)).toList();
      final filtered = allPops.where((p) => p.clusterId == clusterId).toList();
      return filtered;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Cluster?> fetchCluster(String clusterId) async {
    try {
      final clusterData = await _apiService.get('/clusters/$clusterId');
      return Cluster.fromJson(clusterData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Project?> fetchProject(String projectId) async {
    try {
      final projectData = await _apiService.get('/projects/$projectId');
      return Project.fromJson(projectData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Segment>> fetchSegments(String projectId) async {
    try {
      final segmentData = await _apiService.get('/projects/$projectId/segments');
      return (segmentData as List).map((e) => Segment.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<double?> fetchElevation(LatLng coordinates) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/elevation/json?locations=${coordinates.latitude},${coordinates.longitude}&key=AIzaSyClkdHOLWnKrRwkAHE5_aJyw-xboEnA7dw',
      );
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
          return data['results'][0]['elevation']?.toDouble();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> savePop(Pop pop) async {
    await _apiService.post('/pops', pop.toJson());
  }

  @override
  Future<void> saveNetzverteiler(Netzverteiler nvt) async {
    await _apiService.post('/netzverteilers', nvt.toJson());
  }

  @override
  Future<void> saveSegment(String projectId, Segment segment) async {
    await _apiService.post('/projects/$projectId/segments', segment.toJson());
  }
}
