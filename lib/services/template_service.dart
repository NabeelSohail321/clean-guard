import 'package:mobile_app/models/template.dart';
import 'package:mobile_app/services/api_service.dart';

class TemplateService {
  final ApiService _apiService;

  TemplateService(this._apiService);

  Future<List<Template>> getTemplates() async {
    final response = await _apiService.dio.get('/templates');
    return (response.data as List).map((e) => Template.fromJson(e)).toList();
  }

  Future<void> createTemplate(Map<String, dynamic> data) async {
    await _apiService.dio.post('/templates', data: data);
  }

  Future<void> updateTemplate(String id, Map<String, dynamic> data) async {
    await _apiService.dio.put('/templates/$id', data: data);
  }

  Future<void> deleteTemplate(String id) async {
    await _apiService.dio.delete('/templates/$id');
  }
}
