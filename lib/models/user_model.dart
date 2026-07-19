// lib/models/user_model.dart
import 'branch_model.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final Branch? branch; // ✅ single branch, not a list

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.branch,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('🔄 User.fromJson received: $json');

    Branch? branch;
    if (json['branch'] != null && json['branch'] is Map<String, dynamic>) {
      branch = Branch.fromJson(json['branch']);
    }

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      isActive: _parseBool(json['is_active'] ?? json['isActive'] ?? true),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      branch: branch,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return true;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      print('⚠️ Error parsing date: $value');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'branch_id': branch?.id,
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
}