// lib/controllers/category_controller.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category_model.dart';

class CategoryController extends ChangeNotifier {
  final ApiService _apiService;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  CategoryController({required ApiService apiService})
      : _apiService = apiService;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Fetch all categories ──────────────────────────────────────────────────

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getRequest('/categories');

      if (response['success'] == true) {
        final List<dynamic> categoriesJson = response['categories'] ?? [];
        _categories =
            categoriesJson.map((json) => Category.fromJson(json)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to load categories';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create category ──────────────────────────────────────────────────────

  Future<bool> createCategory({
    required String name,
    String description = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.postRequest('/categories', {
        'name': name,
        'description': description,
      });

      if (response['success'] == true) {
        await fetchCategories();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create category';
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

  // ── Update category ──────────────────────────────────────────────────────

  Future<bool> updateCategory({
    required int id,
    required String name,
    String description = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.putRequest('/categories/$id', {
        'name': name,
        'description': description,
      });

      if (response['success'] == true) {
        await fetchCategories();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update category';
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

  // ── Delete category ──────────────────────────────────────────────────────

  Future<bool> deleteCategory(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteRequest('/categories/$id');

      if (response['success'] == true) {
        await fetchCategories();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete category';
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

  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}