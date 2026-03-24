import 'package:dio/dio.dart';
import 'package:mobile_app/models/dashboard_data.dart';
import 'package:mobile_app/services/api_service.dart';

class AdminDashboardService {
  final ApiService _apiService;

  AdminDashboardService(this._apiService);

  Future<DashboardMetrics> getSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? locationId,
  }) async {
    final response = await _apiService.dio.get('/dashboard/summary', queryParameters: {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      if (locationId != null && locationId != 'all') 'location_id': locationId,
    });
    return DashboardMetrics.fromJson(response.data);
  }

  Future<List<CheckpointData>> getInspectionsOverTime({
    required DateTime startDate,
    required DateTime endDate,
    String? locationId,
  }) async {
    final response = await _apiService.dio.get('/dashboard/inspections_over_time', queryParameters: {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      if (locationId != null && locationId != 'all') 'location_id': locationId,
    });
    return (response.data as List).map((e) => CheckpointData.fromJson(e)).toList();
  }

  Future<List<CheckpointData>> getTicketsOverTime({
     required DateTime startDate,
     required DateTime endDate,
     String? locationId,
  }) async {
    final response = await _apiService.dio.get('/dashboard/tickets_over_time', queryParameters: {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      if (locationId != null && locationId != 'all') 'location_id': locationId,
    });
     return (response.data as List).map((e) => CheckpointData.fromJson(e)).toList();
  }
}
