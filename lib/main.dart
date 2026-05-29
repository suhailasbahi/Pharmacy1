// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Services
import 'package:app/data/services/auth_service.dart';
import 'package:app/core/services/snackbar_service.dart';

// Providers
import 'package:app/data/providers/cart_provider.dart';
import 'package:app/data/providers/order_provider.dart';
import 'package:app/data/providers/product_provider.dart';
import 'package:app/data/providers/account_provider.dart';
import 'package:app/data/providers/role_provider.dart';
import 'package:app/data/providers/user_management_provider.dart';
import 'package:app/data/providers/branch_provider.dart';

// Theme
import 'package:app/core/theme/app_theme.dart';

// Screens
import 'package:app/modules/auth/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // تهيئة SnackBarService
  final snackbarKey = GlobalKey<ScaffoldMessengerState>();
  SnackBarService.initialize(snackbarKey);
  
  runApp(MyApp(snackbarKey: snackbarKey));
}

class MyApp extends StatelessWidget {
  final GlobalKey<ScaffoldMessengerState> snackbarKey;
  
  const MyApp({Key? key, required this.snackbarKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => UserManagementProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
      ],
      child: MaterialApp(
        title: 'سوق الأدوية بالجملة',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: snackbarKey,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}