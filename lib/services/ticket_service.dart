import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/models/ticket.dart';

class TicketService {
  final ApiService _apiService;

  TicketService(this._apiService);

  Future<List<Ticket>> getTickets({String? assignedTo}) async {
    final response = await _apiService.dio.get('/tickets', queryParameters: {
      if (assignedTo != null) 'assignedTo': assignedTo,
    });
    return (response.data as List).map((e) => Ticket.fromJson(e)).toList();
  }

  Future<void> createTicket(Map<String, dynamic> data) async {
    await _apiService.dio.post('/tickets', data: data);
  }

  Future<void> updateTicket(String id, Map<String, dynamic> data) async {
    await _apiService.dio.put('/tickets/$id', data: data);
  }

  Future<void> assignTicket(String id, String userId) async {
    await _apiService.dio.patch('/tickets/$id/assign', data: {'assignedTo': userId});
  }

  Future<void> scheduleTicket(String id, DateTime date) async {
    await _apiService.dio.patch('/tickets/$id/schedule', data: {'scheduledDate': date.toIso8601String()});
  }

  Future<void> resolveTicket(String id, String notes, List<String> images) async {
    // Note: Assuming images are already base64 encoded strings or URLs
    await _apiService.dio.put('/tickets/$id', data: {
      'status': 'resolved',
      'resolutionNotes': notes,
      'resolutionImages': images,
      'resolvedAt': DateTime.now().toIso8601String(),
    });
  }
}
