// lib/core/utils/company_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/models/agency_model.dart';
import 'package:app/data/datasources/models/product_model.dart';


class CompanyHelper {
  /// حساب عدد الوكالات لشركة معينة
  static Future<int> countAgencies(String companyId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('agencies')
          .where('companyId', isEqualTo: companyId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error counting agencies: $e');
      return 0;
    }
  }
  
  /// حساب عدد الوكالات لشركة معينة (نسخة متزامنة للـ FutureBuilder)
  static Future<int> countAgenciesFuture(String companyId) {
    return countAgencies(companyId);
  }
  
  /// فلترة الشركات حسب البحث
  static List<Map<String, String>> filterCompanies(
    List<Map<String, String>> companies,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return companies;
    return companies.where((c) =>
      c['name']!.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }
  
  /// الحصول على منتجات وكالة معينة
  static List<ProductModel> getAgencyProducts(
    List<ProductModel> allProducts,
    String agencyId,
  ) {
    return allProducts.where((p) => p.agencyId == agencyId).toList();
  }
}