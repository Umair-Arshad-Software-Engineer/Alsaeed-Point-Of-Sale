// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'controllers/auth_controller.dart';
import 'controllers/branch_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/brand_controller.dart';
import 'controllers/unit_controller.dart';
import 'controllers/sale_controller.dart';
import 'controllers/report_controller.dart';
import 'services/api_service.dart';
import 'views/login_page.dart';
import 'views/register_page.dart';
import 'views/home_page.dart';

void main() {
  // Initialize ApiService singleton
  final apiService = ApiService.instance;
  apiService.initialize(http.Client());

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the ApiService instance
        ChangeNotifierProvider.value(value: apiService),

        // AuthController
        ChangeNotifierProvider(
          create: (context) => AuthController(apiService: apiService),
        ),

        // ProductController
        ChangeNotifierProvider(
          create: (context) => ProductController(apiService: apiService),
        ),

        // CategoryController
        ChangeNotifierProvider(
          create: (context) => CategoryController(apiService: apiService),
        ),

        // BrandController
        ChangeNotifierProvider(
          create: (context) => BrandController(apiService: apiService),
        ),

        // UnitController
        ChangeNotifierProvider(
          create: (context) => UnitController(apiService: apiService),
        ),

        // SaleController
        ChangeNotifierProvider(
          create: (context) => SaleController(apiService: apiService),
        ),

        // ReportController
        ChangeNotifierProvider(
          create: (context) => ReportController(apiService: apiService),
        ),
        //BranchController
        ChangeNotifierProvider(
          create: (_) => BranchController(apiService: ApiService.instance),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'POS Management System',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginPage(),
          '/register': (context) => RegisterPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}