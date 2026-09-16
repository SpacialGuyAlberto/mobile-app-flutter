import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../core/db/database_helper.dart';
import '../core/network/project_repository.dart';
import '../models/planning/project.dart';

// Provides the singleton instance of DatabaseHelper
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// Provides the API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provides the Project Repository
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  return ProjectRepository(apiService: apiService, dbHelper: dbHelper);
});

// A FutureProvider that UI can watch to get the list of projects
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.fetchAll();
});
