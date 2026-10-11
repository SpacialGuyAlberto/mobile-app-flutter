import '../../../../core/network/api_service.dart';
import '../../../../models/utility_models.dart';

/// Contract for fetching civil utility infrastructure data (ISP and DIP compliant).
abstract class IUtilityRepository {
  Future<List<UtilityLine>> fetchUtilities();
}

/// Concrete implementation delegating to ApiService (SRP compliant).
class UtilityRepository implements IUtilityRepository {
  final ApiService _apiService;

  UtilityRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  @override
  Future<List<UtilityLine>> fetchUtilities() async {
    try {
      final utilsData = await _apiService.get('/v1/utilities');
      return (utilsData as List).map((e) => UtilityLine.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
