import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

class ApiService extends ChangeNotifier {
  static ApiService? _instance;
  late final http.Client client;
  String? _authToken;

  // Private constructor
  ApiService._internal();

  // Singleton factory
  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  // Initialize with HTTP client
  void initialize(http.Client httpClient) {
    client = httpClient;
  }

  String? get authToken => _authToken;

  void setAuthToken(String token) {
    _authToken = token;
    print('🔑 Token set in ApiService: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    notifyListeners();
  }

  void clearAuthToken() {
    _authToken = null;
    print('🔑 Token cleared from ApiService');
    notifyListeners();
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
      print('📤 Adding Authorization header');
    } else {
      print('⚠️ No token available for Authorization header');
    }
    return headers;
  }

  // ==================== AUTHENTICATION ENDPOINTS ====================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('📝 Registering user: $email');
      final response = await client.post(
        Uri.parse('${Constants.baseUrl}${Constants.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      print('📥 Register response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        print('✅ Registration successful');
        if (data['token'] != null) {
          setAuthToken(data['token']);
        }
        return {
          'success': true,
          'data': data,
          'token': data['token'],
          'user': data['user']
        };
      } else {
        print('❌ Registration failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      print('❌ Network error during registration: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Logging in user: $email');
      final response = await client.post(
        Uri.parse('${Constants.baseUrl}${Constants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📥 Login response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['token'] != null) {
          setAuthToken(data['token']);
          print('✅ Login successful, token stored');
        }
        return {
          'success': true,
          'data': data,
          'token': data['token'],
          'user': data['user']
        };
      } else {
        print('❌ Login failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      print('❌ Network error during login: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      print('👤 Fetching current user');
      print('🔑 Token available: ${_authToken != null}');

      final response = await client.get(
        Uri.parse('${Constants.baseUrl}${Constants.meEndpoint}'),
        headers: _getHeaders(),
      );

      print('📥 Get user response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ User fetched successfully');
        return {
          'success': true,
          'user': User.fromJson(data['user'])
        };
      } else {
        print('❌ Failed to get user: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get user'
        };
      }
    } catch (e) {
      print('❌ Network error getting user: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> verifyToken() async {
    try {
      print('🔍 Verifying token');
      final response = await client.get(
        Uri.parse('${Constants.baseUrl}/auth/verify-token'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);
      print('📥 Token verification status: ${response.statusCode}');

      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message']
      };
    } catch (e) {
      print('❌ Token verification error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      print('📋 Fetching all users');
      final response = await client.get(
        Uri.parse('${Constants.baseUrl}${Constants.usersEndpoint}'),
        headers: _getHeaders(),
      );

      print('📥 Get users response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> usersJson = data['users'];
        final List<User> users = usersJson.map((json) => User.fromJson(json)).toList();
        print('✅ Fetched ${users.length} users');
        return {
          'success': true,
          'users': users
        };
      } else {
        print('❌ Failed to get users: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get users'
        };
      }
    } catch (e) {
      print('❌ Network error getting users: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

// In api_service.dart — update createUser signature and body

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    List<int>? branchIds, // ✅ Add this
  }) async {
    try {
      print('➕ Creating user: $email');
      final response = await client.post(
        Uri.parse('${Constants.baseUrl}${Constants.usersEndpoint}'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          if (branchIds != null) 'branch_ids': branchIds, // ✅ Add this
        }),
      );

      print('📥 Create user response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        print('✅ User created successfully');
        return {'success': true, 'message': data['message'], 'user': data['user']};
      } else {
        print('❌ Failed to create user: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Failed to create user'};
      }
    } catch (e) {
      print('❌ Network error creating user: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

// In api_service.dart — update updateUser signature and body

  Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String name,
    required String email,
    required String role,
    required bool isActive,
    List<int>? branchIds, // ✅ Add this
  }) async {
    try {
      print('✏️ Updating user: $email (ID: $userId)');
      final response = await client.put(
        Uri.parse('${Constants.baseUrl}${Constants.usersEndpoint}/$userId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'role': role,
          'is_active': isActive,
          if (branchIds != null) 'branch_ids': branchIds, // ✅ Add this
        }),
      );

      print('📥 Update user response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ User updated successfully');
        return {'success': true, 'message': data['message']};
      } else {
        print('❌ Failed to update user: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Failed to update user'};
      }
    } catch (e) {
      print('❌ Network error updating user: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      print('🗑️ Deleting user ID: $userId');
      final response = await client.delete(
        Uri.parse('${Constants.baseUrl}${Constants.usersEndpoint}/$userId'),
        headers: _getHeaders(),
      );

      print('📥 Delete user response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ User deleted successfully');
        return {
          'success': true,
          'message': data['message']
        };
      } else {
        print('❌ Failed to delete user: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete user'
        };
      }
    } catch (e) {
      print('❌ Network error deleting user: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== PRODUCT ENDPOINTS ====================

  Future<Map<String, dynamic>> getAllProducts() async {
    try {
      print('📦 Fetching all products');
      final response = await client.get(
        Uri.parse('${Constants.baseUrl}${Constants.productsEndpoint}'),
        headers: _getHeaders(),
      );

      print('📥 Get products response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> productsJson = data['products'];
        final List<Product> products = productsJson.map((json) => Product.fromJson(json)).toList();
        print('✅ Fetched ${products.length} products');
        return {
          'success': true,
          'products': products
        };
      } else {
        print('❌ Failed to get products: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get products'
        };
      }
    } catch (e) {
      print('❌ Network error getting products: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getProduct(int productId) async {
    try {
      print('📦 Fetching product ID: $productId');
      final response = await client.get(
        Uri.parse('${Constants.baseUrl}${Constants.productsEndpoint}/$productId'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'product': Product.fromJson(data['product'])
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get product'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Updated createProduct without category
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required double price,
    required String description,
  }) async {
    try {
      print('➕ Creating product: $name');
      final response = await client.post(
        Uri.parse('${Constants.baseUrl}${Constants.productsEndpoint}'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'price': price,
          'description': description,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        print('✅ Product created successfully');
        return {
          'success': true,
          'message': data['message'],
          'product': data['product'] != null ? Product.fromJson(data['product']) : null
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create product'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Updated updateProduct without category
  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required double price,
    required String description,
  }) async {
    try {
      print('✏️ Updating product ID: $productId');
      final response = await client.put(
        Uri.parse('${Constants.baseUrl}${Constants.productsEndpoint}/$productId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'price': price,
          'description': description,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Product updated successfully');
        return {
          'success': true,
          'message': data['message']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update product'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      print('🗑️ Deleting product ID: $productId');
      final response = await client.delete(
        Uri.parse('${Constants.baseUrl}${Constants.productsEndpoint}/$productId'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Product deleted successfully');
        return {
          'success': true,
          'message': data['message']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== SALE ENDPOINTS ====================

  Future<Map<String, dynamic>> getAllSales() async {
    try {
      print('💰 Fetching all sales');
      final response = await client.get(
        Uri.parse('${Constants.baseUrl}${Constants.salesEndpoint}'),
        headers: _getHeaders(),
      );

      print('📥 Get sales response status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> salesJson = data['sales'];
        final List<Sale> sales = salesJson.map((json) => Sale.fromJson(json)).toList();
        print('✅ Fetched ${sales.length} sales');
        return {
          'success': true,
          'sales': sales
        };
      } else {
        print('❌ Failed to get sales: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get sales'
        };
      }
    } catch (e) {
      print('❌ Network error getting sales: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getSale(int saleId) async {
    try {
      final response = await client.get(
        Uri.parse('${Constants.baseUrl}${Constants.salesEndpoint}/$saleId'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'sale': Sale.fromJson(data['sale'])
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get sale'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> createSale({
    required int productId,
    required int quantity,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      print('💰 Creating new sale');
      final response = await client.post(
        Uri.parse('${Constants.baseUrl}${Constants.salesEndpoint}'),
        headers: _getHeaders(),
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
          'customer_name': customerName,
          'customer_phone': customerPhone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        print('✅ Sale created successfully');
        return {
          'success': true,
          'message': data['message'],
          'sale': data['sale'] != null ? Sale.fromJson(data['sale']) : null
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create sale'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateSale({
    required int saleId,
    required int productId,
    required int quantity,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      print('✏️ Updating sale ID: $saleId');
      final response = await client.put(
        Uri.parse('${Constants.baseUrl}${Constants.salesEndpoint}/$saleId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
          'customer_name': customerName,
          'customer_phone': customerPhone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Sale updated successfully');
        return {
          'success': true,
          'message': data['message']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update sale'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteSale(int saleId) async {
    try {
      print('🗑️ Deleting sale ID: $saleId');
      final response = await client.delete(
        Uri.parse('${Constants.baseUrl}${Constants.salesEndpoint}/$saleId'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Sale deleted successfully');
        return {
          'success': true,
          'message': data['message']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete sale'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('📊 Fetching sales report');
      String url = '${Constants.salesEndpoint}/report';
      if (startDate != null && endDate != null) {
        url += '?start_date=${startDate.toIso8601String().split('T')[0]}&end_date=${endDate.toIso8601String().split('T')[0]}';
      }

      final response = await client.get(
        Uri.parse('${Constants.baseUrl}$url'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Report fetched successfully');
        return {
          'success': true,
          'report': data['report'] ?? []
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get report'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== DASHBOARD ENDPOINTS ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('📊 Fetching dashboard stats');
      final response = await client.get(
        Uri.parse('${Constants.baseUrl}${Constants.dashboardStatsEndpoint}'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Dashboard stats fetched successfully');
        return {
          'success': true,
          'stats': data['stats']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get dashboard stats'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== GENERIC REQUEST METHODS ====================

  Future<Map<String, dynamic>> getRequest(String endpoint) async {
    try {
      final response = await client.get(
        Uri.parse('${Constants.baseUrl}$endpoint'),
        headers: _getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await client.post(
        Uri.parse('${Constants.baseUrl}$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> putRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await client.put(
        Uri.parse('${Constants.baseUrl}$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteRequest(String endpoint) async {
    try {
      final response = await client.delete(
        Uri.parse('${Constants.baseUrl}$endpoint'),
        headers: _getHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}