import 'package:mobile_app/models/work_stats.dart';
import 'package:mobile_app/services/api_service.dart';

class WorkStatsService {
  final ApiService _apiService;

  WorkStatsService(this._apiService);

  Future<WorkStatsResponse> getWorkStats({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    final queryParams = {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    };

    if (userId != null && userId.isNotEmpty && userId != 'all') {
      queryParams['user_id'] = userId;
    }

    final response = await _apiService.dio.get(
      '/dashboard/work-stats',
      queryParameters: queryParams,
    );

    return WorkStatsResponse.fromJson(response.data);
  }
}
