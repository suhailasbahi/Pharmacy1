// lib/modules/pharmacy/screens/pharmacy_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/auth_service.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/providers/account_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/screens/profile_screen.dart';
import '../../reports/screens/main_report_screen.dart';
import '../widgets/pharmacy_drawer.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'companies_screen.dart';
import 'offers_screen.dart';
import 'suppliers_screen.dart';


class PharmacyHomeScreen extends StatefulWidget {
  final String selectedCity;
  final bool isGuest;

  const PharmacyHomeScreen({
    Key? key,
    required this.selectedCity,
    required this.isGuest,
  }) : super(key: key);

  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    _screens = [
      const ProductsScreen(),
      const CompaniesScreen(),
      const OffersScreen(),
       CartScreen(isGuest: widget.isGuest),
      const MyOrdersScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _loadInitialData() async {
    if (widget.isGuest) return;
    
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final pharmacyId = auth.currentUserId ?? '';
      
      await Future.wait([
        Provider.of<OrderProvider>(context, listen: false).loadOrdersForPharmacy(pharmacyId),
        Provider.of<AccountProvider>(context, listen: false).loadSuppliersForPharmacy(pharmacyId),
      ]);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onDrawerItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context);
  }

  void _onReportsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainReportScreen()),
    );
  }

  void _onDetailedReportsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>  PharmacyDetailedReportsScreen()),
    );
  }

  void _onSuppliersTap() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final pharmacyId = auth.currentUserId ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SuppliersScreen(pharmacyId: pharmacyId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final title = widget.isGuest
        ? 'تصفح كزائر - ${widget.selectedCity}'
        : '${auth.currentPharmacyName ?? 'صيدليتي'} - ${widget.selectedCity}';

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        drawer: PharmacyDrawer(
          currentIndex: _currentIndex,
          onItemSelected: _onDrawerItemSelected,
          onReportsTap: _onReportsTap,
          onDetailedReportsTap: _onDetailedReportsTap,
          onSuppliersTap: _onSuppliersTap,
        ),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'تصفح'),
            BottomNavigationBarItem(icon: Icon(Icons.business), label: 'الشركات'),
            BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'عروض'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'السلة'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'طلباتي'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}