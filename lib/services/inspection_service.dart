import 'package:mobile_app/models/inspection.dart';
import 'package:mobile_app/services/api_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class InspectionService {
  final ApiService _apiService;

  InspectionService(this._apiService);

  Future<List<Inspection>> getInspections({String? inspectorId}) async {
    final response = await _apiService.dio.get('/inspections', queryParameters: {
       if (inspectorId != null) 'inspector': inspectorId,
    });
    return (response.data as List).map((e) => Inspection.fromJson(e)).toList();
  }

  Future<Inspection> createInspection(Map<String, dynamic> data) async {
    final response = await _apiService.dio.post('/inspections', data: data);
    return Inspection.fromJson(response.data);
  }

  Future<Inspection> getInspection(String id) async {
    final response = await _apiService.dio.get('/inspections/$id');
    return Inspection.fromJson(response.data);
  }

  Future<String?> downloadInspectionPdf(String inspectionId) async {
    try {
      final response = await _apiService.dio.get(
        '/inspections/$inspectionId/pdf',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/inspection-$inspectionId.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.data);
        return filePath;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  Future<Inspection> assignInspection(String id, String inspectorId) async {
    final response = await _apiService.dio.patch(
      '/inspections/$id/assign',
      data: {'inspector': inspectorId, 'status': 'pending'},
    );
    return Inspection.fromJson(response.data);
  }

  Future<Inspection> updateInspection(String id, Map<String, dynamic> data) async {
    final response = await _apiService.dio.put('/inspections/$id', data: data);
    return Inspection.fromJson(response.data);
  }

  Future<Inspection> scheduleInspection(String id, DateTime date) async {
    final response = await _apiService.dio.patch('/inspections/$id/schedule', data: {
      'scheduledDate': date.toIso8601String(),
    });
    return Inspection.fromJson(response.data);
  }
}
