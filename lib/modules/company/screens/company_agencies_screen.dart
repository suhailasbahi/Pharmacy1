// lib/modules/company/screens/company_agencies_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/datasources/models/agency_model.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/product_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/loading_overlay.dart';
import 'edit_product_screen.dart';

class CompanyAgenciesScreen extends StatefulWidget {
  const CompanyAgenciesScreen({Key? key}) : super(key: key);

  @override
  State<CompanyAgenciesScreen> createState() => _CompanyAgenciesScreenState();
}

class _CompanyAgenciesScreenState extends State<CompanyAgenciesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<AgencyModel> _agencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final companyId = auth.currentCompanyId ?? 'comp_001';

      // تحميل المنتجات
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.loadProducts(companyId);

      // تحميل الوكالات
      final snapshot = await _firestore
          .collection('agencies')
          .where('companyId', isEqualTo: companyId)
          .get();
          
      final agencies = snapshot.docs
          .map((doc) => AgencyModel.fromMap(doc.id, doc.data()))
          .toList();

      setState(() {
        _agencies = agencies;
        _isLoading = false;
      });
    } catch (e) {
      SnackBarService.showError('حدث خطأ: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  void _addAgency() {
    final nameController = TextEditingController();
    bool isAdding = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('إضافة وكالة جديدة'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الوكالة'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isAdding ? null : () async {
                  if (nameController.text.trim().isEmpty) {
                    SnackBarService.showWarning('يرجى إدخال اسم الوكالة');
                    return;
                  }
                  setDialogState(() => isAdding = true);
                  try {
                    final auth = Provider.of<AuthService>(context, listen: false);
                    final newAgency = AgencyModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      companyId: auth.currentCompanyId ?? 'comp_001',
                      companyName: auth.currentCompanyName ?? 'شركة الأدوية العربية',
                      products: [],
                      isActive: true,
                    );
                    await _firestore
                        .collection('agencies')
                        .doc(newAgency.id)
                        .set(newAgency.toMap());
                    Navigator.pop(ctx);
                    await _refresh();
                    SnackBarService.showSuccess('تم إضافة الوكالة بنجاح');
                  } catch (e) {
                    setDialogState(() => isAdding = false);
                    SnackBarService.showError('خطأ: ${e.toString()}');
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editAgency(AgencyModel agency) {
    final nameController = TextEditingController(text: agency.name);
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('تعديل الوكالة'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الوكالة'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isUpdating ? null : () async {
                  if (nameController.text.trim().isEmpty) {
                    SnackBarService.showWarning('يرجى إدخال اسم الوكالة');
                    return;
                  }
                  setDialogState(() => isUpdating = true);
                  try {
                    final updatedAgency = AgencyModel(
                      id: agency.id,
                      name: nameController.text.trim(),
                      companyId: agency.companyId,
                      companyName: agency.companyName,
                      products: agency.products,
                      isActive: agency.isActive,
                    );
                    await _firestore
                        .collection('agencies')
                        .doc(agency.id)
                        .update(updatedAgency.toMap());
                    Navigator.pop(ctx);
                    await _refresh();
                    SnackBarService.showSuccess('تم تعديل الوكالة بنجاح');
                  } catch (e) {
                    setDialogState(() => isUpdating = false);
                    SnackBarService.showError('خطأ: ${e.toString()}');
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteAgency(AgencyModel agency) async {
    if (agency.products.isNotEmpty) {
      SnackBarService.showWarning('لا يمكن حذف وكالة تحتوي على منتجات. قم بحذف المنتجات أولاً.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الوكالة'),
        content: Text('هل أنت متأكد من حذف الوكالة "${agency.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    try {
      await _firestore.collection('agencies').doc(agency.id).delete();
      await _refresh();
      SnackBarService.showSuccess('تم حذف الوكالة بنجاح');
    } catch (e) {
      SnackBarService.showError('خطأ أثناء الحذف: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    
    if (_isLoading) {
      return const Scaffold(
        appBar: AppBar(title: Text('الوكالات'), centerTitle: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('الوكالات (${_agencies.length})'),
        centerTitle: true,
        actions: [
          if (auth.canManageBranches)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addAgency,
              tooltip: 'إضافة وكالة',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _agencies.isEmpty
            ? const EmptyWidget(
                title: 'لا توجد وكالات',
                icon: Icons.store,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _agencies.length,
                itemBuilder: (context, index) => AgencyManagementCard(
                  agency: _agencies[index],
                  onEdit: () => _editAgency(_agencies[index]),
                  onDelete: () => _deleteAgency(_agencies[index]),
                ),
              ),
      ),
    );
  }
}

class AgencyManagementCard extends StatelessWidget {
  final AgencyModel agency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AgencyManagementCard({
    Key? key,
    required this.agency,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final agencyProducts = productProvider.products
        .where((p) => p.agencyId == agency.id)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.store, color: AppTheme.primaryColor),
        ),
        title: Text(
          agency.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${agencyProducts.length} منتج', style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: onEdit,
              tooltip: 'تعديل',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'حذف',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        SnackBarService.showInfo('إضافة منتج للوكالة من شاشة إضافة دواء');
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة منتج'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                agencyProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد منتجات في هذه الوكالة',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: agencyProducts.length,
                        itemBuilder: (context, index) {
                          final product = agencyProducts[index];
                          final priceText = ProductHelper.getPriceWithOfferText(product, 'sanaa');
                          final hasOffer = ProductHelper.hasOffer(product, 'sanaa');
                          
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProductScreen(
                                    product: product,
                                    agencyId: agency.id,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.all(4),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.medication, size: 40, color: AppTheme.primaryColor),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                product.concentration,
                                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 4),
                                              if (hasOffer)
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      priceText['current']!,
                                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                                                    ),
                                                    Text(
                                                      priceText['original']!,
                                                      style: const TextStyle(
                                                        decoration: TextDecoration.lineThrough,
                                                        color: Colors.grey,
                                                        fontSize: 9,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else
                                                Text(
                                                  priceText['current']!,
                                                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}