// lib/modules/pharmacy/screens/agencies_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/providers/cart_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/datasources/models/product_model.dart';
import '../../../data/datasources/models/agency_model.dart';
import '../../../data/providers/product_provider.dart';
import '../../../core/widgets/enhanced_product_card.dart';
import '../../../core/utils/product_helper.dart';
import '../../../core/theme/app_theme.dart';
import 'product_details_screen.dart';

class AgenciesScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const AgenciesScreen({Key? key, required this.companyId, required this.companyName}) : super(key: key);

  @override
  State<AgenciesScreen> createState() => _AgenciesScreenState();
}

class _AgenciesScreenState extends State<AgenciesScreen> {
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
      // 1. تحميل المنتجات مرة واحدة (لجميع الوكالات)
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.loadProducts(widget.companyId);
      
      // 2. تحميل الوكالات
      final snapshot = await FirebaseFirestore.instance
          .collection('agencies')
          .where('companyId', isEqualTo: widget.companyId)
          .get();
      
      final agencies = snapshot.docs
          .map((doc) => AgencyModel.fromMap(doc.id, doc.data()))
          .toList();
      
      setState(() {
        _agencies = agencies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading agencies: $e');
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final regionId = authService.currentRegionId ?? 'sanaa';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.companyName),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.companyName),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _agencies.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد وكالات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _agencies.length,
                itemBuilder: (context, index) {
                  final agency = _agencies[index];
                  return AgencyCard(agency: agency, regionId: regionId);
                },
              ),
      ),
    );
  }
}

class AgencyCard extends StatelessWidget {
  final AgencyModel agency;
  final String regionId;

  const AgencyCard({Key? key, required this.agency, required this.regionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    
    // ✅ استخدام CompanyHelper للحصول على منتجات الوكالة
    final agencyProducts = productProvider.products
        .where((p) => p.agencyId == agency.id)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.store, size: 24, color: AppTheme.primaryColor),
        ),
        title: Text(
          agency.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${agencyProducts.length} منتج', style: const TextStyle(fontSize: 12)),
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: agencyProducts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('لا توجد منتجات في هذه الوكالة', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: agencyProducts.length,
                    itemBuilder: (context, index) {
                      final product = agencyProducts[index];
                      final isInCart = cartProvider.isInCart(product.id);
                      final hasOffer = ProductHelper.hasOffer(product, regionId);
                      final priceText = ProductHelper.getPriceWithOfferText(product, regionId);
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(product: product, regionId: regionId),
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
                                    color: ProductHelper.getCategoryColor(
                                      _getCategoryFromName(product.name)
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  ),
                                  child: Stack(
                                    children: [
                                      const Center(child: Icon(Icons.medication, size: 40, color: Colors.white)),
                                      if (hasOffer)
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'عرض',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                    ],
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
          ),
        ],
      ),
    );
  }
}

// دالة مساعدة مؤقتة للوصول إلى _getCategoryFromName (يمكن نقلها إلى ProductHelper)
 String _getCategoryFromName(String name) {
    if (name.contains('بنادول') || name.contains('بروفين') || name.contains('ديكلوفيناك')) {
      return 'مسكنات';
    } else if (name.contains('أموكسيل') || name.contains('زيتروماكس')) {
      return 'مضادات حيوية';
    } else if (name.contains('فيتامين')) {
      return 'فيتامينات';
    }
    return 'أدوية';
  }
}