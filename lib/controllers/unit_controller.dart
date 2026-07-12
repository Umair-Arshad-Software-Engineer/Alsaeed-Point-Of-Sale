// lib/controllers/unit_controller.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/unit_model.dart';

class UnitController extends ChangeNotifier {
  final ApiService _apiService;

  List<Unit> _units = [];
  bool _isLoading = false;
  String? _errorMessage;

  UnitController({required ApiService apiService})
      : _apiService = apiService;

  List<Unit> get units => _units;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Fetch all units ──────────────────────────────────────────────────────

  Future<void> fetchUnits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getRequest('/units');

      if (response['success'] == true) {
        final List<dynamic> unitsJson = response['units'] ?? [];
        _units = unitsJson.map((json) => Unit.fromJson(json)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to load units';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create unit ──────────────────────────────────────────────────────────

  Future<bool> createUnit({
    required String name,
    String abbreviation = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.postRequest('/units', {
        'name': name,
        'abbreviation': abbreviation,
      });

      if (response['success'] == true) {
        await fetchUnits();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create unit';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update unit ──────────────────────────────────────────────────────────

  Future<bool> updateUnit({
    required int id,
    required String name,
    String abbreviation = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.putRequest('/units/$id', {
        'name': name,
        'abbreviation': abbreviation,
      });

      if (response['success'] == true) {
        await fetchUnits();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update unit';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Delete unit ──────────────────────────────────────────────────────────

  Future<bool> deleteUnit(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteRequest('/units/$id');

      if (response['success'] == true) {
        await fetchUnits();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete unit';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Unit? getUnitById(int id) {
    try {
      return _units.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}