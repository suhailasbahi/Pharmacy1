// lib/modules/company/widgets/company_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/splash_screen.dart';

class CompanyDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;
  final VoidCallback? onReportsTap;
  
  const CompanyDrawer({
    Key? key,
    required this.currentIndex,
    required this.onItemSelected,
    this.onReportsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(auth),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'الرئيسية',
                  index: 0,
                  isSelected: currentIndex == 0,
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag,
                  title: 'الطلبات',
                  index: 1,
                  isSelected: currentIndex == 1,
                ),
                _buildDrawerItem(
                  icon: Icons.inventory_2,
                  title: 'المنتجات',
                  index: 2,
                  isSelected: currentIndex == 2,
                ),
                _buildDrawerItem(
                  icon: Icons.store,
                  title: 'الوكالات',
                  onTap: () => onItemSelected(3),
                  isSelected: currentIndex == 3,
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.bar_chart,
                  title: 'التقارير',
                  onTap: onReportsTap,
                ),
                if (auth.canManageBranches) ...[
                  _buildDrawerItem(
                    icon: Icons.account_tree,
                    title: 'الفروع',
                    onTap: () => onItemSelected(4),
                    isSelected: currentIndex == 4,
                  ),
                ],
                if (auth.canManageRoles) ...[
                  _buildDrawerItem(
                    icon: Icons.security,
                    title: 'الصلاحيات',
                    onTap: () => onItemSelected(5),
                    isSelected: currentIndex == 5,
                  ),
                ],
                if (auth.canManageUsers) ...[
                  _buildDrawerItem(
                    icon: Icons.manage_accounts,
                    title: 'المستخدمين',
                    onTap: () => onItemSelected(6),
                    isSelected: currentIndex == 6,
                  ),
                ],
                _buildDrawerItem(
                  icon: Icons.currency_exchange,
                  title: 'أسعار الصرف',
                  onTap: () => onItemSelected(7),
                  isSelected: currentIndex == 7,
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'حسابي',
                  index: 8,
                  isSelected: currentIndex == 8,
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'تسجيل الخروج',
                  color: Colors.red,
                  onTap: () => _logout(context, auth),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthService auth) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.business, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                auth.currentCompanyName ?? 'شركة الأدوية',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                auth.currentUserType == AppConstants.userTypeCompany ? 'شركة أدوية' : 'حساب فرعي',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    int? index,
    bool isSelected = false,
    Color color = Colors.teal,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : color),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: AppTheme.primaryColor, size: 18) : null,
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
      onTap: onTap ?? (index != null ? () => onItemSelected(index) : null),
    );
  }

  void _logout(BuildContext context, AuthService auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await auth.logout();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    }
  }
}