import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/sale_model.dart';

class SaleController extends ChangeNotifier {
  final ApiService _apiService;

  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _errorMessage;

  SaleController({required ApiService apiService}) : _apiService = apiService;

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchSales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getRequest('/sales');

      if (response['success'] == true) {
        final List<dynamic> salesJson = response['sales'];
        _sales = salesJson.map((json) => Sale.fromJson(json)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to load sales';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<bool> createSale({
    required List<Map<String, dynamic>> items, // [{product_id, quantity}]
    required String customerName,
    required String customerPhone,
    required double discount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.postRequest('/sales', {
        'items': items,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'discount': discount,
      });

      if (response['success'] == true) {
        await fetchSales();
        return true;
      }
      _errorMessage = response['message'] ?? 'Failed to create sale';
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<bool> updateSale({
    required int id,
    required List<Map<String, dynamic>> items, // [{product_id, quantity}]
    required String customerName,
    required String customerPhone,
    required double discount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.putRequest('/sales/$id', {
        'items': items,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'discount': discount,
      });

      if (response['success'] == true) {
        await fetchSales();
        return true;
      }
      _errorMessage = response['message'] ?? 'Failed to update sale';
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<bool> deleteSale(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteRequest('/sales/$id');

      if (response['success'] == true) {
        // Remove locally for instant UI update before fetchSales completes
        _sales.removeWhere((s) => s.id == id);
        notifyListeners();
        await fetchSales();
        return true;
      }
      _errorMessage = response['message'] ?? 'Failed to delete sale';
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Aggregates ─────────────────────────────────────────────────────────────

  double getTotalRevenue() {
    return _sales.fold(0.0, (sum, sale) => sum + sale.totalPrice);
  }

  int getTotalItemsSold() {
    // Uses the Sale.quantity getter which sums all SaleItem quantities
    return _sales.fold(0, (sum, sale) => sum + sale.quantity);
  }

  double getTotalDiscount() {
    return _sales.fold(0.0, (sum, sale) => sum + sale.discount);
  }

  int getTotalTransactions() {
    return _sales.length;
  }

  // Revenue grouped by product name across all sale items
  Map<String, double> getSalesByProduct() {
    final Map<String, double> productSales = {};
    for (final sale in _sales) {
      for (final item in sale.items) {
        productSales[item.productName] =
            (productSales[item.productName] ?? 0) + item.subtotal;
      }
    }
    return productSales;
  }

  // Revenue grouped by date (yyyy-MM-dd)
  Map<String, double> getSalesByDate() {
    final Map<String, double> dateSales = {};
    for (final sale in _sales) {
      final key =
          '${sale.saleDate.year}-${sale.saleDate.month.toString().padLeft(2, '0')}-${sale.saleDate.day.toString().padLeft(2, '0')}';
      dateSales[key] = (dateSales[key] ?? 0) + sale.totalPrice;
    }
    return dateSales;
  }

  // Revenue grouped by seller name
  Map<String, double> getSalesBySeller() {
    final Map<String, double> sellerSales = {};
    for (final sale in _sales) {
      sellerSales[sale.soldByName] =
          (sellerSales[sale.soldByName] ?? 0) + sale.totalPrice;
    }
    return sellerSales;
  }
}