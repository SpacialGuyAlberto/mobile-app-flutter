import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/db/database_helper.dart';
import '../core/network/api_service.dart';

final offlineDownloaderProvider = StateNotifierProvider<OfflineDownloaderNotifier, OfflineDownloaderState>((ref) {
  return OfflineDownloaderNotifier(
    dbHelper: DatabaseHelper.instance,
    apiService: ApiService(),
  );
});

class OfflineDownloaderState {
  final bool isDownloading;
  final double progress;
  final String statusMessage;

  OfflineDownloaderState({
    this.isDownloading = false,
    this.progress = 0.0,
    this.statusMessage = '',
  });

  OfflineDownloaderState copyWith({bool? isDownloading, double? progress, String? statusMessage}) {
    return OfflineDownloaderState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class OfflineDownloaderNotifier extends StateNotifier<OfflineDownloaderState> {
  final DatabaseHelper dbHelper;
  final ApiService apiService;

  OfflineDownloaderNotifier({required this.dbHelper, required this.apiService})
      : super(OfflineDownloaderState());

  Future<void> downloadProjectData(String projectId) async {
    if (state.isDownloading) return;

    state = state.copyWith(isDownloading: true, progress: 0.1, statusMessage: 'Fetching Project details...');
    
    try {
      // 1. Project Details
      final projectRes = await apiService.get('/projects/$projectId');
      await dbHelper.upsertCache(projectId, 'Project', jsonEncode(projectRes));

      state = state.copyWith(progress: 0.3, statusMessage: 'Fetching Clusters...');
      
      // 2. Clusters
      final clustersRes = await apiService.get('/clusters/project/$projectId');
      List clustersList = (clustersRes is Map && clustersRes.containsKey('content')) ? clustersRes['content'] : (clustersRes is List ? clustersRes : []);
      for (var cluster in clustersList) {
         if (cluster['id'] != null) {
            await dbHelper.upsertCache(cluster['id'].toString(), 'Cluster', jsonEncode(cluster));
            
            // Fetch POPs for this cluster
            try {
               final popRes = await apiService.get('/pops/cluster/${cluster['id']}');
               List popList = (popRes is Map && popRes.containsKey('content')) ? popRes['content'] : (popRes is List ? popRes : []);
               for (var pop in popList) {
                  if (pop['id'] != null) {
                     await dbHelper.upsertCache(pop['id'].toString(), 'Pop', jsonEncode(pop));
                  }
               }
            } catch (e) {
               // ignore missing pops
            }
         }
      }

      state = state.copyWith(progress: 0.7, statusMessage: 'Fetching Segments and Netzverteilers...');

      // 3. Segments
      try {
          final segmentsRes = await apiService.get('/segments/project/$projectId');
          List segmentsList = (segmentsRes is Map && segmentsRes.containsKey('content')) ? segmentsRes['content'] : (segmentsRes is List ? segmentsRes : []);
          for (var seg in segmentsList) {
              if (seg['id'] != null) {
                 await dbHelper.upsertCache(seg['id'].toString(), 'Segment', jsonEncode(seg));
              }
          }
      } catch (e) { }

      // 4. Netzverteilers
      try {
          final nvRes = await apiService.get('/netzverteilers/project/$projectId');
          List nvList = (nvRes is Map && nvRes.containsKey('content')) ? nvRes['content'] : (nvRes is List ? nvRes : []);
          for (var nv in nvList) {
              if (nv['id'] != null) {
                 await dbHelper.upsertCache(nv['id'].toString(), 'Netzverteiler', jsonEncode(nv));
              }
          }
      } catch (e) { }

      state = state.copyWith(isDownloading: false, progress: 1.0, statusMessage: 'Download complete! You can now work offline.');
      
    } catch (e) {
      state = state.copyWith(isDownloading: false, statusMessage: 'Error downloading: $e');
    }
  }
}
