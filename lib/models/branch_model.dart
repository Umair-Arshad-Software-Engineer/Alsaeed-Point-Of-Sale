// lib/models/branch_model.dart
import 'package:alsaeed_pizza/models/user_model.dart';

class Branch {
  final int id;
  final String name;
  final String address;
  final String phone;
  final bool isActive;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? creator;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'is_active': isActive,
      'created_by': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

