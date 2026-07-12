class SaleItem {
  final int id;
  final int saleId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] ?? 0,
      saleId: json['sale_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product']?['name'] ?? 'Unknown',
      unitPrice: double.parse((json['unit_price'] ?? 0).toString()),
      quantity: json['quantity'] ?? 0,
      subtotal: double.parse((json['subtotal'] ?? 0).toString()),
    );
  }
}

class Sale {
  final int id;
  final String customerName;
  final String customerPhone;
  final double discount;
  final double totalPrice;
  final int soldBy;
  final String soldByName;
  final DateTime saleDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItem> items;

  Sale({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.discount,
    required this.totalPrice,
    required this.soldBy,
    required this.soldByName,
    required this.saleDate,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  // ── Convenience getters for backward compatibility ──────────────────────────
  // Used in SalePage table display (productName, quantity, productPrice columns)
  String get productName =>
      items.isNotEmpty ? items.map((i) => i.productName).join(', ') : '—';

  int get quantity =>
      items.fold(0, (sum, i) => sum + i.quantity);

  double get productPrice =>
      items.isNotEmpty ? items.first.unitPrice : 0.0;

  double get subtotal =>
      items.fold(0.0, (sum, i) => sum + i.subtotal);

  factory Sale.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];

    return Sale(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      discount: double.parse((json['discount'] ?? 0).toString()),
      totalPrice: double.parse((json['total_price'] ?? 0).toString()),
      soldBy: json['sold_by'] ?? 0,
      soldByName: json['seller']?['name'] ?? 'Unknown',
      saleDate: json['sale_date'] != null
          ? DateTime.parse(json['sale_date'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      items: itemsJson.map((e) => SaleItem.fromJson(e)).toList(),
    );
  }
}

class ReceiptItem {
  final String productName;
  final double productPrice;
  final int quantity;

  const ReceiptItem({
    required this.productName,
    required this.productPrice,
    required this.quantity,
  });
}