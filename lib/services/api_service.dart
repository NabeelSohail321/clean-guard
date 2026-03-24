import 'package:dio/dio.dart';
import 'package:mobile_app/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final prefs = await SharedPreferences.getInstance();
          final userJson = prefs.getString('user');
          if (userJson != null) {
            // Simple parsing to avoid full import loop, or just store token separately
            // For now, let's assume valid JSON and extract token
             // TODO: robust token extraction
             final user = jsonDecode(userJson);
             final token = user['token'];
             if (token != null) {
               options.headers['Authorization'] = 'Bearer $token';
             }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
           // Handle 401 Unauthorized
           if (e.response?.statusCode == 401) {
             // TODO: Handle logout or refresh
           }
           // Handle 429 Too Many Requests
           if (e.response?.statusCode == 429) {
             // Retry logic could go here
           }
           return handler.next(e);
        },
      ),
    );
  }
}
