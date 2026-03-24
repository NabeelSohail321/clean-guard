import 'package:flutter/material.dart';
import 'package:mobile_app/models/dashboard_data.dart';
import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/services/admin_dashboard_service.dart';
import 'package:mobile_app/services/location_service.dart';

class DashboardProvider extends ChangeNotifier {
  final AdminDashboardService _dashboardService;
  final LocationService _locationService;

  bool _loading = true;
  String? _error;

  // Filters
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedLocationId = 'all';

  // Data
  DashboardMetrics? _metrics;
  List<CheckpointData> _inspectionsChartData = [];
  List<CheckpointData> _ticketsChartData = [];
  List<Location> _locations = [];

  DashboardProvider(this._dashboardService, this._locationService) {
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
  }
  
  // Getters
  bool get loading => _loading;
  String? get error => _error;
  
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get selectedLocationId => _selectedLocationId;
  
  DashboardMetrics? get metrics => _metrics;
  List<CheckpointData> get inspectionsChartData => _inspectionsChartData;
  List<CheckpointData> get ticketsChartData => _ticketsChartData;
  List<Location> get locations => _locations;

  // Setters with fetch
  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    fetchDashboardData();
  }

  void setLocation(String locationId) {
    _selectedLocationId = locationId;
    fetchDashboardData();
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      _locations = await _locationService.getLocations();
      await fetchDashboardData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardData() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dashboardService.getSummary(startDate: _startDate, endDate: _endDate, locationId: _selectedLocationId),
        _dashboardService.getInspectionsOverTime(startDate: _startDate, endDate: _endDate, locationId: _selectedLocationId),
        _dashboardService.getTicketsOverTime(startDate: _startDate, endDate: _endDate, locationId: _selectedLocationId),
      ]);

      _metrics = results[0] as DashboardMetrics;
      _inspectionsChartData = results[1] as List<CheckpointData>;
      _ticketsChartData = results[2] as List<CheckpointData>;
    } catch (e) {
      _error = e.toString();
      print("Dashboard Fetch Error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
