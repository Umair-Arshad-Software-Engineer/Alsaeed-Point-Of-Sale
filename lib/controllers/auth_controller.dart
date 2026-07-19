// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AuthController extends ChangeNotifier {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  User? _currentUser;
  List<User> _allUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  AuthController({required ApiService apiService}) : _apiService = apiService;

  User? get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  })
  async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📝 Starting registration for: $email');
      final result = await _apiService.register(
        name: name,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        final token = result['token'] as String;
        final userData = result['user'] as Map<String, dynamic>;

        print('✅ Registration successful, saving auth data');
        await _saveAuthData(token, userData);
        _currentUser = User.fromJson(userData);
        _apiService.setAuthToken(token);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? 'Registration failed';
        print('❌ Registration failed: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      print('❌ Registration error: $_errorMessage');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  })
  async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔐 Starting login for: $email');
      final result = await _apiService.login(
        email: email,
        password: password,
      );

      print('Login result: $result');

      if (result['success'] == true) {
        final token = result['token'] as String;
        final userData = result['user'] as Map<String, dynamic>;

        print('✅ Login successful, token received: ${token.substring(0, 20)}...');
        print('User data: $userData');

        await _saveAuthData(token, userData);

        final savedToken = await _secureStorage.read(key: _tokenKey);
        print('Token saved successfully: ${savedToken != null}');

        _currentUser = User.fromJson(userData);
        _apiService.setAuthToken(token);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? 'Login failed';
        print('❌ Login failed: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      print('❌ Login error: $_errorMessage');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    try {
      print('💾 Saving auth data to secure storage');

      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _userKey, value: jsonEncode(userData));

      final verifyToken = await _secureStorage.read(key: _tokenKey);
      final verifyUser = await _secureStorage.read(key: _userKey);

      print('Token saved: ${verifyToken != null}');
      print('User data saved: ${verifyUser != null}');

      if (verifyToken == null || verifyUser == null) {
        throw Exception('Failed to save authentication data');
      }

      print('✅ Auth data saved successfully');
    } catch (e) {
      print('❌ Error saving auth data: $e');
      rethrow;
    }
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Loading user from storage');
      final token = await _secureStorage.read(key: _tokenKey);

      if (token != null && token.isNotEmpty) {
        print('✅ Token found in storage');
        _apiService.setAuthToken(token);

        print('🔍 Verifying token...');
        final verifyResult = await _apiService.verifyToken();

        if (verifyResult['success'] == true) {
          print('✅ Token verified, fetching user data');
          final result = await _apiService.getCurrentUser();

          if (result['success'] == true) {
            // Extract user from response
            Map<String, dynamic> userData;
            if (result['user'] is User) {
              _currentUser = result['user'] as User;
            } else if (result['user'] is Map) {
              _currentUser = User.fromJson(result['user'] as Map<String, dynamic>);
            } else {
              print('❌ Unexpected user data format');
              await logout();
              _isLoading = false;
              notifyListeners();
              return;
            }

            print('✅ User loaded: ${_currentUser?.email} (Role: ${_currentUser?.role})');

            // Check if super admin to fetch all users
            if (_currentUser?.isSuperAdmin == true) {
              print('👑 Super admin detected, fetching all users');
              await fetchAllUsers();
            } else {
              print('👤 Regular user, skipping user list fetch');
              // Clear users list for non-super admins
              _allUsers = [];
            }
          } else {
            print('❌ Failed to get user data: ${result['message']}');
            await logout();
          }
        } else {
          print('❌ Token verification failed');
          await logout();
        }
      } else {
        print('⚠️ No token found in storage');
      }
    } catch (e) {
      print('❌ Error loading user: $e');
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      print('📋 Fetching all users from AuthController');
      final result = await _apiService.getAllUsers();
      print('📋 getAllUsers result: $result');

      if (result['success'] == true) {
        // Check if users is a List
        if (result['users'] != null && result['users'] is List) {
          // The list should already contain User objects from ApiService
          final usersList = result['users'] as List;

          // Verify each item is a User object
          _allUsers = usersList.where((item) => item is User).cast<User>().toList();

          print('✅ Fetched ${_allUsers.length} users successfully');
        } else {
          print('⚠️ No users found or invalid format');
          _allUsers = [];
        }
      } else {
        final errorMsg = result['message'] ?? 'Unknown error';
        print('❌ Failed to fetch users: $errorMsg');
        _allUsers = [];
      }
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ Error fetching users: $e');
      print('📋 Stack trace: $stackTrace');
      _allUsers = [];
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    int? branchId, // ✅ single branch id instead of List<int>? branchIds
  })
  async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('➕ Creating new user: $email');
      final result = await _apiService.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
        branchId: branchId,
      );

      if (result['success'] == true) {
        print('✅ User created successfully');
        await fetchAllUsers();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? 'Failed to create user';
        print('❌ Failed to create user: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      print('❌ Create user error: $_errorMessage');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser({
    required int userId,
    required String name,
    required String email,
    required String role,
    required bool isActive,
    int? branchId, // ✅ single branch id instead of List<int>? branchIds
  })
  async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('✏️ Updating user ID: $userId');
      final result = await _apiService.updateUser(
        userId: userId,
        name: name,
        email: email,
        role: role,
        isActive: isActive,
        branchId: branchId,
      );

      if (result['success'] == true) {
        print('✅ User updated successfully');
        await fetchAllUsers();

        if (_currentUser?.id == userId) {
          final userData = {
            'id': userId,
            'name': name,
            'email': email,
            'role': role,
            'is_active': isActive,
            'created_at': _currentUser?.createdAt.toIso8601String(),
          };
          _currentUser = User.fromJson(userData);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? 'Failed to update user';
        print('❌ Failed to update user: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      print('❌ Update user error: $_errorMessage');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🗑️ Deleting user ID: $userId');
      final result = await _apiService.deleteUser(userId);

      if (result['success'] == true) {
        print('✅ User deleted successfully');
        await fetchAllUsers();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? 'Failed to delete user';
        print('❌ Failed to delete user: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      print('❌ Delete user error: $_errorMessage');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    print('🚪 Logging out user');
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    _currentUser = null;
    _allUsers = [];
    _apiService.clearAuthToken();
    _errorMessage = null;
    notifyListeners();
    print('✅ Logout complete');
  }

  Future<void> clearAllStorage() async {
    print('🗑️ Clearing all storage');
    await _secureStorage.deleteAll();
    _currentUser = null;
    _allUsers = [];
    _apiService.clearAuthToken();
    _errorMessage = null;
    notifyListeners();
    print('✅ All storage cleared');
  }

  Future<bool> changeUserPassword({
    required int userId,
    required String newPassword,
  })
  async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.changeUserPassword(
        userId: userId,
        newPassword: newPassword,
      );
      _isLoading = false;
      if (result['success'] != true) {
        _errorMessage = result['message'] as String? ?? 'Failed to change password';
      }
      notifyListeners();
      return result['success'] == true;
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


}