class Constants {
  // For iOS Simulator or Android Emulator - use localhost
  static const String baseUrl = 'http://localhost:3000/api';

  // Auth Endpoints
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String meEndpoint = '/auth/me';
  static const String usersEndpoint = '/auth/users';
  static const String verifyTokenEndpoint = '/auth/verify-token';

  // Branch Endpoints (NEW)
  static const String branchesEndpoint = '/branches';

  // Product Endpoints
  static const String productsEndpoint = '/products';

  // Sale Endpoints
  static const String salesEndpoint = '/sales';

  // Dashboard Endpoints
  static const String dashboardStatsEndpoint = '/dashboard/stats';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}