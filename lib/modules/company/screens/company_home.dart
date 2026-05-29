// lib/modules/company/screens/company_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/auth_service.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/providers/account_provider.dart';
import '../../../data/providers/branch_provider.dart';
import '../../../data/providers/user_management_provider.dart';
import '../../../data/providers/role_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/screens/profile_screen.dart';
import '../../reports/screens/main_report_screen.dart';
import '../widgets/company_drawer.dart';
import 'company_orders_screen.dart';
import 'my_products_screen.dart';
import 'company_agencies_screen.dart';
import 'customers_screen.dart';
import '../../admin/screens/branches_management_screen.dart';
import '../../admin/screens/roles_management_screen.dart';
import '../../admin/screens/manage_sub_accounts_screen.dart';
import '../../admin/screens/exchange_rate_settings_screen.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({Key? key}) : super(key: key);

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    _screens = [
      const CompanyDashboardProScreen(),
      const CompanyOrdersScreen(),
      const MyProductsScreen(),
      const CompanyAgenciesScreen(),
      const CustomersScreen(companyId: ''),
      const BranchesManagementScreen(),
      const RolesManagementScreen(),
      const ManageSubAccountsScreen(),
      const ExchangeRateSettingsScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final companyId = auth.currentCompanyId ?? '';
      
      // تحميل البيانات الأساسية
      await Future.wait([
        Provider.of<OrderProvider>(context, listen: false).loadOrdersForCompany(companyId),
        Provider.of<ProductProvider>(context, listen: false).loadProducts(companyId),
        Provider.of<AccountProvider>(context, listen: false).loadCustomersForCompany(companyId),
        Provider.of<BranchProvider>(context, listen: false).loadBranches(companyId),
        Provider.of<RoleProvider>(context, listen: false).loadRoles(),
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
    Navigator.pop(context); // إغلاق الدراور
  }

  void _onReportsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Column(
            children: [
              Text(
                auth.currentCompanyName ?? 'لوحة الشركة',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              const Text(
                'نظام إدارة الشركة',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
        drawer: CompanyDrawer(
          currentIndex: _currentIndex,
          onItemSelected: _onDrawerItemSelected,
          onReportsTap: _onReportsTap,
        ),
        body: _screens[_currentIndex],
        floatingActionButton: _currentIndex == 2
            ? FloatingActionButton.extended(
                backgroundColor: AppTheme.primaryColor,
                icon: const Icon(Icons.add),
                label: const Text('إضافة منتج'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddProductScreen(),
                    ),
                  );
                },
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'الطلبات'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'المنتجات'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'الوكالات'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'العملاء'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}