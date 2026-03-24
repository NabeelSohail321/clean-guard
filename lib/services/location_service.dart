import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/services/api_service.dart';

class LocationService {
  final ApiService _apiService;

  LocationService(this._apiService);

  Future<List<Location>> getLocations() async {
    try {
      final response = await _apiService.dio.get('/locations');
      return (response.data as List).map((e) => Location.fromJson(e)).toList();
    } catch (e) {
      // Handle error or rethrow
      rethrow;
    }
  }

  Future<void> createLocation(Map<String, dynamic> data) async {
    await _apiService.dio.post('/locations', data: data);
  }

  Future<void> updateLocation(String id, Map<String, dynamic> data) async {
    await _apiService.dio.put('/locations/$id', data: data);
  }

  Future<void> deleteLocation(String id) async {
    await _apiService.dio.delete('/locations/$id');
  }
}
