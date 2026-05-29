// lib/modules/pharmacy/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/datasources/models/product_model.dart';
import '../../../core/widgets/enhanced_product_card.dart';
import '../../../core/utils/product_helper.dart';
import '../../../core/services/debouncer.dart';
import '../../../core/theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer();
  
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  bool _showFilters = false;
  List<ProductModel> _products = [];
  List<String> _categories = ['الكل'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      final products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // ✅ استخدام ProductHelper للحصول على التصنيفات
      _categories = ProductHelper.getCategoriesFromProducts(products);
      
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading products: $e');
    }
  }

  void _onSearchChanged(String value) {
    _debouncer.call(() {
      setState(() {
        _searchQuery = value;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final regionId = authService.currentRegionId ?? 'sanaa';
    
    // ✅ استخدام ProductHelper للفلترة
    final products = ProductHelper.filterProducts(
      products: _products,
      searchQuery: _searchQuery,
      selectedCategory: _selectedCategory,
      regionId: regionId,
    );

    if (_isLoading) {
      return const Scaffold(
        appBar: AppBar(title: Text('تصفح الأدوية'), centerTitle: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تصفح الأدوية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showFilters ? 120 : 80),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن دواء، شركة، أو تركيز...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (_showFilters)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: _categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) => setState(() {
                              _selectedCategory = selected ? category : 'الكل';
                            }),
                            backgroundColor: Colors.grey.shade200,
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: products.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('لا توجد نتائج', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('حاول تغيير كلمة البحث أو التصنيف', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _clearSearch();
                        setState(() => _selectedCategory = 'الكل');
                      },
                      child: const Text('مسح الفلترة'),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isInCart = cartProvider.isInCart(product.id);
                  
                  return EnhancedProductCard(
                    product: product,
                    regionId: regionId,
                    isInCart: isInCart,
                    showAddToCart: true,
                    onAddToCart: () {
                      final cartItem = CartItem.fromProduct(product, regionId);
                      cartProvider.addToCart(cartItem, isCashOrder: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إضافة ${product.name} إلى السلة'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}