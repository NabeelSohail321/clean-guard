import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/services/api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  Future<List<User>> getUsers() async {
    final response = await _apiService.dio.get('/users');
    return (response.data as List).map((e) => User.fromJson(e)).toList();
  }

  Future<User> getProfile(String id) async {
    final response = await _apiService.dio.get('/users/profile/$id');
    return User.fromJson(response.data);
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    await _apiService.dio.post('/users', data: data);
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    // Determine endpoint based on if it's profile update or admin update
    // Assuming admin update endpoint
    await _apiService.dio.put('/users/$id', data: data);
  }

  Future<void> deleteUser(String id) async {
    await _apiService.dio.delete('/users/$id');
  }
}
