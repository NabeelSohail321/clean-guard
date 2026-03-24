import 'package:mobile_app/services/api_service.dart';

class ReportService {
  final ApiService _apiService;

  ReportService(this._apiService);

  Future<Map<String, dynamic>> getOverallReport({
    required DateTime startDate,
    required DateTime endDate,
    String? locationId,
  }) async {
    final response = await _apiService.dio.get('/reports/overall', queryParameters: {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      if (locationId != null && locationId != 'all') 'location_id': locationId,
    });
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getInspectorLeaderboard({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiService.dio.get('/reports/inspectors', queryParameters: {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    });
    return List<Map<String, dynamic>>.from(response.data);
  }
}
