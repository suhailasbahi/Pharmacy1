// lib/modules/company/screens/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/models/product_model.dart';
import '../../../data/datasources/models/region_pricing.dart';
import '../../../data/datasources/models/bonus_model.dart';
import '../../../data/datasources/models/agency_model.dart';
import '../../../data/datasources/models/region.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/providers/product_provider.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_overlay.dart';

// نموذج مجموعة الأسعار
class _PriceGroup {
  double price;
  String currency;
  List<Region> regions;
  bool hasOffer;
  double? offerPrice;

  _PriceGroup({
    required this.price,
    required this.currency,
    required this.regions,
    this.hasOffer = false,
    this.offerPrice,
  });
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _concentrationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _pricePerPieceController = TextEditingController();
  final _pricePerCartonController = TextEditingController();
  final _piecesPerCartonController = TextEditingController();
  
  bool _requiresCooling = false;
  DateTime? _expiryDate;
  bool _isLoading = false;
  File? _selectedImage;
  String _defaultUnit = 'piece';
  BonusModel? _bonusCash;
  BonusModel? _bonusCredit;
  AgencyModel? _selectedAgency;
  List<AgencyModel> _agencies = [];
  
  final ImagePickerService _imagePicker = ImagePickerService();
  List<_PriceGroup> _priceGroups = [];
  final List<Region> _allRegions = Region.allRegions;

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  Future<void> _loadAgencies() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final companyId = auth.currentCompanyId ?? 'comp_001';
      final snapshot = await FirebaseFirestore.instance
          .collection('agencies')
          .where('companyId', isEqualTo: companyId)
          .get();
      setState(() {
        _agencies = snapshot.docs.map((doc) => AgencyModel.fromMap(doc.id, doc.data())).toList();
      });
    } catch (e) {
      debugPrint("Error loading agencies: $e");
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickFromGallery();
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _clearForm() {
    _nameController.clear();
    _scientificNameController.clear();
    _concentrationController.clear();
    _descriptionController.clear();
    _stockController.clear();
    _minOrderController.clear();
    _pricePerPieceController.clear();
    _pricePerCartonController.clear();
    _piecesPerCartonController.clear();
    setState(() {
      _requiresCooling = false;
      _expiryDate = null;
      _selectedAgency = null;
      _selectedImage = null;
      _defaultUnit = 'piece';
      _bonusCash = null;
      _bonusCredit = null;
      _priceGroups = [];
    });
  }

  // ========== دوال تسعير المحافظات ==========
  
  List<Region> _getUnassignedRegions() {
    final selectedRegionIds = _priceGroups
        .expand((group) => group.regions.map((r) => r.id))
        .toSet();
    return _allRegions.where((region) => !selectedRegionIds.contains(region.id)).toList();
  }

  List<Region> _getUnassignedRegionsForDialog(List<Region> currentSelected) {
    final otherSelectedIds = _priceGroups
        .expand((g) => g.regions.map((r) => r.id))
        .where((id) => !currentSelected.map((r) => r.id).contains(id))
        .toSet();
    return _allRegions.where((region) => 
      !otherSelectedIds.contains(region.id) || currentSelected.contains(region)
    ).toList();
  }

  void _showAddPriceDialog({_PriceGroup? existingGroup, int? editIndex}) {
    final priceController = TextEditingController(
      text: existingGroup?.price.toString() ?? '',
    );
    final offerPriceController = TextEditingController(
      text: existingGroup?.offerPrice?.toString() ?? '',
    );
    
    String selectedCurrency = existingGroup?.currency ?? 'yemen';
    bool hasOffer = existingGroup?.hasOffer ?? false;
    List<Region> selectedRegions = existingGroup?.regions != null 
        ? List.from(existingGroup!.regions) 
        : [];
    
    List<Region> availableRegions = _getUnassignedRegionsForDialog(selectedRegions);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(editIndex != null ? 'تعديل مجموعة الأسعار' : 'إضافة سعر جديد'),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر الأساسي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: const InputDecoration(labelText: 'العملة'),
                    items: const [
                      DropdownMenuItem(value: 'yemen', child: Text('ريال يمني')),
                      DropdownMenuItem(value: 'saudi', child: Text('ريال سعودي')),
                      DropdownMenuItem(value: 'dollar', child: Text('دولار أمريكي')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedCurrency = v!),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('تفعيل عرض خاص لهذه المحافظات'),
                    value: hasOffer,
                    onChanged: (val) => setDialogState(() => hasOffer = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (hasOffer)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: offerPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'سعر العرض',
                          border: OutlineInputBorder(),
                          helperText: 'السعر بعد الخصم لهذه المحافظات',
                        ),
                      ),
                    ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('اختر المحافظات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: availableRegions.length,
                      itemBuilder: (_, i) {
                        final region = availableRegions[i];
                        final isSelected = selectedRegions.contains(region);
                        return CheckboxListTile(
                          title: Text(region.name),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedRegions.add(region);
                              } else {
                                selectedRegions.remove(region);
                              }
                            });
                          },
                          dense: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(priceController.text) ?? 0;
                  if (price <= 0) {
                    SnackBarService.showWarning('يرجى إدخال سعر صحيح');
                    return;
                  }
                  if (selectedRegions.isEmpty) {
                    SnackBarService.showWarning('يرجى اختيار محافظة واحدة على الأقل');
                    return;
                  }
                  
                  final offerPrice = hasOffer ? double.tryParse(offerPriceController.text) : null;
                  if (hasOffer && (offerPrice == null || offerPrice <= 0)) {
                    SnackBarService.showWarning('يرجى إدخال سعر عرض صحيح');
                    return;
                  }
                  
                  setState(() {
                    final newGroup = _PriceGroup(
                      price: price,
                      currency: selectedCurrency,
                      regions: selectedRegions,
                      hasOffer: hasOffer,
                      offerPrice: offerPrice,
                    );
                    
                    if (editIndex != null) {
                      _priceGroups[editIndex] = newGroup;
                    } else {
                      _priceGroups.add(newGroup);
                    }
                  });
                  
                  Navigator.pop(ctx);
                },
                child: Text(editIndex != null ? 'حفظ' : 'إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _removePriceGroup(int index) {
    setState(() {
      _priceGroups.removeAt(index);
    });
  }

  List<RegionPricing> _convertToRegionPricing() {
    final List<RegionPricing> result = [];
    for (var group in _priceGroups) {
      for (var region in group.regions) {
        result.add(RegionPricing(
          regionId: region.id,
          regionName: region.name,
          price: group.price,
          currency: group.currency,
          hasOffer: group.hasOffer,
          offerPrice: group.offerPrice,
        ));
      }
    }
    return result;
  }

  Widget _buildPriceGroupCard(_PriceGroup group, int index) {
    final currencySymbol = AppConstants.getCurrencySymbol(group.currency);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: group.hasOffer ? Colors.red.shade50 : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${group.price.toStringAsFixed(2)} $currencySymbol',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (group.hasOffer && group.offerPrice != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'عرض: ${group.offerPrice!.toStringAsFixed(2)} $currencySymbol',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePriceGroup(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: group.regions.map((r) => Chip(
                label: Text(r.name),
                backgroundColor: group.hasOffer ? Colors.red.shade100 : AppTheme.primaryColor.withOpacity(0.1),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionPricingSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('تسعير المناطق والعروض', style: TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddPriceDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة سعر جديد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                ),
                const SizedBox(height: 12),
                ..._priceGroups.asMap().entries.map((entry) {
                  return _buildPriceGroupCard(entry.value, entry.key);
                }),
                if (_priceGroups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('لا توجد أسعار محددة', style: TextStyle(color: Colors.grey)),
                  ),
                if (_getUnassignedRegions().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠️ محافظات غير مسعرة: ${_getUnassignedRegions().map((r) => r.name).join(', ')}',
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusesSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('البونص (نقدي وآجل)', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          ListTile(
            title: const Text('بونص على الطلبات النقدية'),
            subtitle: TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'النسبة المئوية (مثال: 10)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                double p = double.tryParse(val) ?? 0;
                setState(() {
                  _bonusCash = p > 0 ? BonusModel(percentage: p, forCashOnly: true) : null;
                });
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('بونص على الطلبات الآجلة'),
            subtitle: TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'النسبة المئوية (مثال: 5)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                double p = double.tryParse(val) ?? 0;
                setState(() {
                  _bonusCredit = p > 0 ? BonusModel(percentage: p, forCashOnly: false) : null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addProduct() async {
    if (!_formKey.currentState!.validate()) {
      SnackBarService.showWarning('يرجى ملء جميع الحقول المطلوبة');
      return;
    }
    if (_expiryDate == null) {
      SnackBarService.showWarning('يرجى اختيار تاريخ الصلاحية');
      return;
    }
    if (_selectedAgency == null) {
      SnackBarService.showWarning('يرجى اختيار الوكالة');
      return;
    }
    if (_priceGroups.isEmpty) {
      SnackBarService.showWarning('يرجى إضافة تسعير للمناطق');
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final agencyId = _selectedAgency!.id;
      final companyId = auth.currentCompanyId ?? 'comp_001';
      final companyName = auth.currentCompanyName ?? 'شركة الأدوية العربية';

      final newProduct = ProductModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        companyId: companyId,
        companyName: companyName,
        agencyId: agencyId,
        name: _nameController.text.trim(),
        scientificName: _scientificNameController.text.trim(),
        concentration: _concentrationController.text.trim(),
        description: _descriptionController.text.trim(),
        stockQuantity: int.parse(_stockController.text),
        requiresCooling: _requiresCooling,
        imageUrl: _selectedImage?.path,
        expiryDate: _expiryDate!,
        isActive: true,
        createdAt: DateTime.now(),
        regionPrices: _convertToRegionPricing(),
        bonusCash: _bonusCash,
        bonusCredit: _bonusCredit,
        pricePerPiece: double.tryParse(_pricePerPieceController.text) ?? 0,
        pricePerCarton: double.tryParse(_pricePerCartonController.text) ?? 0,
        piecesPerCarton: int.tryParse(_piecesPerCartonController.text) ?? 1,
        defaultUnit: _defaultUnit,
        minOrderQuantity: int.tryParse(_minOrderController.text) ?? 1,
        hasOffer: false,
        offerPrice: null,
        createdBy: auth.currentUserId,
      );

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.addProduct(newProduct);
      _clearForm();
      SnackBarService.showSuccess('تم إضافة المنتج بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      SnackBarService.showError('حدث خطأ: ${e.toString()}');
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
          title: const Text('إضافة دواء جديد'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAgencyDropdown(),
                const SizedBox(height: 16),
                _buildImagePicker(),
                const SizedBox(height: 16),
                _buildTextField(_nameController, 'الاسم التجاري', Icons.medication),
                const SizedBox(height: 16),
                _buildTextField(_scientificNameController, 'الاسم العلمي', Icons.science),
                const SizedBox(height: 16),
                _buildTextField(_concentrationController, 'التركيز', Icons.straighten),
                const SizedBox(height: 16),
                _buildTextField(_descriptionController, 'وصف المنتج (اختياري)', Icons.description),
                const SizedBox(height: 16),
                _buildNumberField(_stockController, 'الكمية المتاحة', Icons.inventory),
                const SizedBox(height: 16),
                _buildMinOrderField(),
                const SizedBox(height: 16),
                _buildUnitDropdown(),
                const SizedBox(height: 16),
                _buildTextField(_pricePerPieceController, 'سعر الباكيت', Icons.currency_bitcoin, isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(_pricePerCartonController, 'سعر الكرتون', Icons.inventory, isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(_piecesPerCartonController, 'عدد الباكيتات في الكرتون', Icons.view_agenda, isNumber: true),
                const SizedBox(height: 16),
                _buildRegionPricingSection(),
                const SizedBox(height: 16),
                _buildBonusesSection(),
                const SizedBox(height: 16),
                _buildExpiryDatePicker(),
                const SizedBox(height: 16),
                _buildCoolingSwitch(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== واجهات المستخدم ==========
  
  Widget _buildAgencyDropdown() => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AgencyModel>(
            value: _selectedAgency,
            hint: const Text('اختر الوكالة'),
            isExpanded: true,
            items: _agencies.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
            onChanged: (value) => setState(() => _selectedAgency = value),
          ),
        ),
      );

  Widget _buildImagePicker() => GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('اضغط لإضافة صورة', style: TextStyle(color: Colors.grey)),
                  ],
                ),
        ),
      );

  Widget _buildTextField(TextEditingController c, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.isEmpty ? 'أدخل $label' : null,
    );
  }

  Widget _buildNumberField(TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.isEmpty ? 'أدخل $label' : null,
    );
  }

  Widget _buildMinOrderField() {
    return TextFormField(
      controller: _minOrderController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'الحد الأدنى للطلب (بالباكيت)',
        prefixIcon: const Icon(Icons.low_priority),
        suffixText: 'باكيت',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _defaultUnit,
          items: const [
            DropdownMenuItem(value: 'piece', child: Text('باكيت')),
            DropdownMenuItem(value: 'carton', child: Text('كرتون')),
          ],
          onChanged: (value) => setState(() => _defaultUnit = value!),
        ),
      ),
    );
  }

  Widget _buildExpiryDatePicker() {
    return InkWell(
      onTap: _selectExpiryDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(
              _expiryDate == null
                  ? 'اختر تاريخ الصلاحية'
                  : 'تاريخ الصلاحية: ${_expiryDate!.year}-${_expiryDate!.month}-${_expiryDate!.day}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoolingSwitch() {
    return SwitchListTile(
      title: const Text('يحتاج تبريد'),
      value: _requiresCooling,
      onChanged: (v) => setState(() => _requiresCooling = v),
      activeColor: AppTheme.primaryColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _addProduct,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('إضافة المنتج', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}