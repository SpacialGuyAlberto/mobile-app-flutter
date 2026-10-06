import '../network/api_service.dart';
import '../../models/inventory/machine.dart';

class InventoryService {
  final ApiService _apiService = ApiService();

  Future<List<Machine>> getAllMachines() async {
    try {
      final response = await _apiService.get('/inventory/machines');
      final List<dynamic> jsonList = response as List<dynamic>;
      return jsonList.map((json) => Machine.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching machines: $e');
      // Return a fallback mock list if the API fails
      return [
        Machine(
          id: 1,
          serialNumber: 'EXC-CAT-320',
          name: 'Excavadora Cat 320',
          type: 'EXCAVADORA',
          status: 'IN_USE',
          currentLocation: 'Berlin Mitte',
          assignedCrewId: 1,
        ),
        Machine(
          id: 2,
          serialNumber: 'DRL-DITCH-01',
          name: 'Taladro de Calle DitchWitch',
          type: 'TALADRO',
          status: 'IN_USE',
          currentLocation: 'Unter den Linden',
          assignedCrewId: 1,
        ),
        Machine(
          id: 3,
          serialNumber: 'BLW-FRE-01',
          name: 'Sopladora Fibra Fremco',
          type: 'SOPLADORA',
          status: 'AVAILABLE',
          currentLocation: 'Almacén Munich',
        ),
      ];
    }
  }
}
