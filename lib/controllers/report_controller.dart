import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportController extends ChangeNotifier {
  final ApiService _apiService;

  List<dynamic> _reportData = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReportController({required ApiService apiService}) : _apiService = apiService;

  List<dynamic> get reportData => _reportData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReport({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url = '/sales/report';
      if (startDate != null && endDate != null) {
        url += '?start_date=${startDate.toIso8601String().split('T')[0]}&end_date=${endDate.toIso8601String().split('T')[0]}';
      }

      final response = await _apiService.getRequest(url);

      if (response['success'] == true) {
        // Ensure report is a list
        if (response['report'] is List) {
          _reportData = response['report'] as List<dynamic>;
        } else {
          _reportData = [];
        }
        notifyListeners();
      } else {
        _errorMessage = response['message'] ?? 'Failed to load report';
        _reportData = [];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _reportData = [];
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}