import '../../models/planning/fencing_plan.dart';
import 'api_service.dart';

class FencingPlanRepository {
  final ApiService apiService;

  FencingPlanRepository({required this.apiService});

  Future<List<FencingPlan>> getFencingPlansForSegment(int segmentId) async {
    try {
      final response = await apiService.get('/planning/fencing-plans/segment/$segmentId');
      
      if (response != null && response is List) {
        return response.map((json) => FencingPlan.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching fencing plans for segment $segmentId: $e');
      return [];
    }
  }

  Future<FencingPlan?> saveFencingPlan(FencingPlan plan) async {
    try {
      final isNew = plan.id <= 0; // O la lógica que defina si es nuevo
      final endpoint = isNew 
          ? '/planning/fencing-plans' 
          : '/planning/fencing-plans/${plan.id}';
          
      // Supongamos que tu backend usa POST para crear y PUT/POST para actualizar
      final response = await apiService.post(endpoint, plan.toJson());
      
      if (response != null) {
        return FencingPlan.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error saving fencing plan: $e');
      return null;
    }
  }
}
