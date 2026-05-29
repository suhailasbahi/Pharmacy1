// lib/modules/auth/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import 'splash_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUserModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(auth),
            const SizedBox(height: 24),
            _buildInfoCard(auth, user),
            const SizedBox(height: 24),
            _buildStatsCard(auth),
            const SizedBox(height: 24),
            _buildLogoutButton(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthService auth) {
    final isCompany = auth.currentUserType == AppConstants.userTypeCompany;
    final name = isCompany
        ? (auth.currentCompanyName ?? 'شركة غير مسماة')
        : (auth.currentPharmacyName ?? 'صيدلية غير مسماة');
    
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            name.isNotEmpty ? name[0] : (isCompany ? 'ش' : 'ص'),
            style: const TextStyle(fontSize: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: AppTheme.headline3,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isCompany ? Colors.blue.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isCompany ? 'شركة أدوية' : 'صيدلية',
            style: TextStyle(
              color: isCompany ? Colors.blue.shade800 : Colors.green.shade800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(AuthService auth, dynamic user) {
    final isCompany = auth.currentUserType == AppConstants.userTypeCompany;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.email, 'البريد الإلكتروني', auth.currentUserId ?? 'غير متوفر'),
            const Divider(),
            _buildInfoRow(Icons.phone, 'رقم الهاتف', user?.phone ?? 'غير متوفر'),
            if (user?.regionId != null) ...[
              const Divider(),
              _buildInfoRow(Icons.location_on, 'المحافظة', _getRegionName(user!.regionId)),
            ],
            if (!isCompany && user?.licenseNumber != null) ...[
              const Divider(),
              _buildInfoRow(Icons.verified, 'رقم الترخيص', user!.licenseNumber!),
            ],
            if (user?.createdAt != null) ...[
              const Divider(),
              _buildInfoRow(Icons.calendar_today, 'تاريخ التسجيل', DateUtilsHelper.formatDate(user!.createdAt)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(AuthService auth) {
    // يمكن إضافة إحصائيات مثل عدد الطلبات، إجمالي المشتريات، إلخ
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات سريعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // يمكن إضافة إحصائيات هنا لاحقاً
            const Center(
              child: Text('سيتم إضافة الإحصائيات قريباً', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService auth) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _logout(context, auth),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  String _getRegionName(String regionId) {
    try {
      return Region.allRegions.firstWhere((r) => r.id == regionId).name;
    } catch (e) {
      return regionId;
    }
  }

  Future<void> _logout(BuildContext context, AuthService auth) async {
    final confirmed = await showDialog<bool>(
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
    ) ?? false;
    
    if (confirmed) {
      await auth.logout();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
      SnackBarService.showSuccess('تم تسجيل الخروج بنجاح');
    }
  }
}