import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';
import '../models/create_segment_metadata.dart';
import '../models/segment_creation_payload.dart';

/// Contract for segment creation data and geocoding operations (ISP & DIP compliant).
abstract class ICreateSegmentRepository {
  Future<CreateSegmentMetadata> fetchMetadata(String? projectId);
  Future<LatLng?> searchGeocodeLocation(String query);
  Future<double?> fetchElevation(LatLng position);
  Future<void> saveSegment(String? projectId, SegmentCreationPayload payload);
}

/// Concrete repository implementation isolating network, geocoding, and elevation (SRP).
class CreateSegmentRepository implements ICreateSegmentRepository {
  final ApiService _apiService;
  final http.Client _httpClient;

  CreateSegmentRepository({
    ApiService? apiService,
    http.Client? httpClient,
  })  : _apiService = apiService ?? ApiService(),
        _httpClient = httpClient ?? http.Client();

  @override
  Future<CreateSegmentMetadata> fetchMetadata(String? projectId) async {
    List<dynamic> crews = [];
    List<dynamic> pops = [];
    List<dynamic> netzverteilers = [];
    List<dynamic> segmentsContext = [];
    LatLng? projectLocation;

    try {
      final crewsData = await _apiService.get('/field/crews');
      if (crewsData is List) crews = crewsData;
    } catch (_) {
      crews = [
        {'id': 1, 'name': 'Crew Alpha (Mock)'},
        {'id': 2, 'name': 'Crew Beta (Mock)'},
        {'id': 3, 'name': 'Crew Gamma (Mock)'},
      ];
    }

    try {
      final popData = await _apiService.get('/pops');
      if (popData is List) pops = popData;
    } catch (_) {}

    try {
      final nvtData = await _apiService.get('/netzverteilers');
      if (nvtData is List) netzverteilers = nvtData;
    } catch (_) {}

    if (projectId != null) {
      try {
        final segmentData = await _apiService.get('/projects/$projectId/segments');
        if (segmentData is List) segmentsContext = segmentData;
      } catch (_) {}

      try {
        final projectData = await _apiService.get('/projects/$projectId');
        if (projectData['geometry'] != null &&
            projectData['geometry'] is List &&
            (projectData['geometry'] as List).isNotEmpty) {
          final geom = projectData['geometry'][0];
          projectLocation = LatLng(
            (geom['lat'] ?? geom['latitude'] as num).toDouble(),
            (geom['lng'] ?? geom['longitude'] as num).toDouble(),
          );
        } else if (projectData['latitude'] != null && projectData['longitude'] != null) {
          projectLocation = LatLng(
            (projectData['latitude'] as num).toDouble(),
            (projectData['longitude'] as num).toDouble(),
          );
        }
      } catch (_) {}
    }

    return CreateSegmentMetadata(
      crews: crews,
      pops: pops,
      netzverteilers: netzverteilers,
      segmentsContext: segmentsContext,
      projectInitialLocation: projectLocation,
    );
  }

  @override
  Future<LatLng?> searchGeocodeLocation(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=AIzaSyClkdHOLWnKrRwkAHE5_aJyw-xboEnA7dw',
      );
      final res = await _httpClient.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<double?> fetchElevation(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/elevation/json?locations=${position.latitude},${position.longitude}&key=AIzaSyClkdHOLWnKrRwkAHE5_aJyw-xboEnA7dw',
      );
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final elevation = data['results'][0]['elevation'];
          return (elevation as num).toDouble();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveSegment(String? projectId, SegmentCreationPayload payload) async {
    final endpoint = projectId != null ? '/projects/$projectId/segments' : '/segments';
    await _apiService.post(endpoint, payload.toJson());
  }
}
