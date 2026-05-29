// lib/modules/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/models/region.dart';
import '../../company/screens/company_home.dart';
import '../../pharmacy/screens/pharmacy_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  
  // State
  String _userType = AppConstants.userTypePharmacy;
  String _selectedRegionId = 'sanaa';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _selectedRegionId = Region.allRegions.first.id;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      SnackBarService.showError('كلمة المرور غير متطابقة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        userType: _userType,
        licenseNumber: _licenseController.text.trim(),
        regionId: _selectedRegionId,
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      SnackBarService.showSuccess('تم إنشاء الحساب بنجاح!');

      if (authService.currentUserType == AppConstants.userTypeCompany) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompanyHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PharmacyHomeScreen(
              selectedCity: _selectedRegionId,
              isGuest: false,
            ),
          ),
        );
      }
    } catch (e) {
      SnackBarService.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء حساب جديد'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنشأة',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) => value!.isEmpty ? 'أدخل اسم المنشأة' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'البريد الإلكتروني مطلوب';
                      if (!value.contains('@')) return 'بريد إلكتروني غير صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) => value!.isEmpty ? 'رقم الهاتف مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // License
                  TextFormField(
                    controller: _licenseController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الترخيص',
                      prefixIcon: Icon(Icons.verified),
                    ),
                    validator: (value) => value!.isEmpty ? 'رقم الترخيص مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان (اختياري)',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Region
                  DropdownButtonFormField<String>(
                    value: _selectedRegionId,
                    decoration: const InputDecoration(
                      labelText: 'المحافظة',
                      border: OutlineInputBorder(),
                    ),
                    items: Region.allRegions.map((region) {
                      return DropdownMenuItem(
                        value: region.id,
                        child: Text(region.name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedRegionId = value!),
                    validator: (value) => value == null ? 'اختر المحافظة' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // User Type
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _userType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: AppConstants.userTypePharmacy,
                            child: Text('صيدلية (مشتري)'),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.userTypeCompany,
                            child: Text('شركة أدوية (بائع)'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _userType = value!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
                      if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'تأكيد كلمة المرور مطلوب' : null,
                  ),
                  const SizedBox(height: 32),
                  
                  // Register Button
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('إنشاء حساب', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}