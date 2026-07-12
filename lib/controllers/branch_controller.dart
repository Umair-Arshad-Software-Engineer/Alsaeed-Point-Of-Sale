import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/branch_model.dart';
import '../models/user_model.dart';

class BranchController extends ChangeNotifier {
  final ApiService _apiService;

  List<Branch> _branches = [];
  final Map<int, List<User>> _branchUsers = {};
  bool _isLoading = false;
  String? _errorMessage;

  BranchController({required ApiService apiService}) : _apiService = apiService;

  List<Branch> get branches => _branches;
  Map<int, List<User>> get branchUsers => _branchUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<User> getUsersForBranch(int branchId) => _branchUsers[branchId] ?? [];

  Future<void> fetchBranches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.getRequest('/branches');
      if (response['success'] == true) {
        final List<dynamic> json = response['branches'] ?? [];
        _branches = json.map((j) => Branch.fromJson(j)).toList();
        // Pre-populate branch users from embedded data if API returns them
        // for (final branch in _branches) {
        //   if (branch.assignedUsers != null) {
        //     _branchUsers[branch.id] = branch.assignedUsers!;
        //   }
        // }
      } else {
        _errorMessage = response['message'] ?? 'Failed to load branches';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBranchUsers(int branchId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.getRequest('/branches/$branchId/users');
      if (response['success'] == true) {
        final List<dynamic> json = response['users'] ?? [];
        _branchUsers[branchId] = json.map((j) => User.fromJson(j)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to load branch users';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBranch({
    required String name,
    required String address,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.postRequest('/branches', {
        'name': name,
        'address': address,
        'phone': phone,
      });
      if (response['success'] == true) {
        await fetchBranches();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create branch';
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

  Future<bool> updateBranch({
    required int branchId,
    required String name,
    required String address,
    required String phone,
    required bool isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.putRequest('/branches/$branchId', {
        'name': name,
        'address': address,
        'phone': phone,
        'is_active': isActive,
      });
      if (response['success'] == true) {
        await fetchBranches();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update branch';
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

  Future<bool> deleteBranch(int branchId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.deleteRequest('/branches/$branchId');
      if (response['success'] == true) {
        _branchUsers.remove(branchId);
        await fetchBranches();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete branch';
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

  Future<bool> assignUsersToBranch({
    required int branchId,
    required List<int> userIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.postRequest(
        '/branches/$branchId/assign',
        {'userIds': userIds},
      );
      if (response['success'] == true) {
        // Refresh both branches and this branch's users
        await fetchBranches();
        await fetchBranchUsers(branchId);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to assign users';
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

  Branch? getBranchById(int id) {
    try {
      return _branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}