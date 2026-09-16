import '../../models/planning/project.dart';
import 'offline_first_repository.dart';

class ProjectRepository extends OfflineFirstRepository<Project> {
  ProjectRepository({
    required super.apiService,
    required super.dbHelper,
  });

  @override
  String get endpoint => '/projects';

  @override
  String get entityType => 'Project';

  @override
  String extractId(Project model) => model.id;

  @override
  Project fromJson(Map<String, dynamic> json) => Project.fromJson(json);

  @override
  Map<String, dynamic> toJson(Project model) => model.toJson();
}
