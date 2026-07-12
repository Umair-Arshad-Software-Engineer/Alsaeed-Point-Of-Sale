// lib/controllers/brand_controller.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/brand_model.dart';

class BrandController extends ChangeNotifier {
  final ApiService _apiService;

  List<Brand> _brands = [];
  bool _isLoading = false;
  String? _errorMessage;

  BrandController({required ApiService apiService})
      : _apiService = apiService;

  List<Brand> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Fetch all brands ─────────────────────────────────────────────────────

  Future<void> fetchBrands() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getRequest('/brands');

      if (response['success'] == true) {
        final List<dynamic> brandsJson = response['brands'] ?? [];
        _brands = brandsJson.map((json) => Brand.fromJson(json)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to load brands';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create brand ─────────────────────────────────────────────────────────

  Future<bool> createBrand({
    required String name,
    String description = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.postRequest('/brands', {
        'name': name,
        'description': description,
      });

      if (response['success'] == true) {
        await fetchBrands();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create brand';
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

  // ── Update brand ─────────────────────────────────────────────────────────

  Future<bool> updateBrand({
    required int id,
    required String name,
    String description = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.putRequest('/brands/$id', {
        'name': name,
        'description': description,
      });

      if (response['success'] == true) {
        await fetchBrands();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update brand';
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

  // ── Delete brand ─────────────────────────────────────────────────────────

  Future<bool> deleteBrand(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteRequest('/brands/$id');

      if (response['success'] == true) {
        await fetchBrands();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete brand';
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

  Brand? getBrandById(int id) {
    try {
      return _brands.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}