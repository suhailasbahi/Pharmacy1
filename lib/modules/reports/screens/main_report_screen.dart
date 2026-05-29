// lib/modules/reports/screens/main_report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/snackbar_service.dart';
import 'package:app/core/utils/date_filter_type.dart';
import '../data/report_repository.dart';
import '../analytics/sales_analyzer.dart';
import '../analytics/product_analyzer.dart';
import '../analytics/customer_analyzer.dart';
import '../analytics/region_analyzer.dart';
import '../analytics/supplier_analyzer.dart';
import '../analytics/trend_analyzer.dart';
import '../models/report_models.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/metric_card.dart';
import '../widgets/report_loading.dart';
import 'tabs/sales_report_tab.dart';
import 'tabs/products_report_tab.dart';
import 'tabs/customers_report_tab.dart';
import 'tabs/regions_report_tab.dart';
import 'tabs/suppliers_report_tab.dart';
import 'tabs/advanced_report_tab.dart';
import 'package:app/core/exports.dart';
import 'package:app/core/utils/date_filter_type.dart';
import 'package:app/core/utils/date_filter_helper.dart';
import 'package:app/modules/reports/widgets/report_filter_bar.dart';

class MainReportScreen extends StatefulWidget {
  const MainReportScreen({Key? key}) : super(key: key);

  @override
  State<MainReportScreen> createState() => _MainReportScreenState();
}

class _MainReportScreenState extends State<MainReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportRepository _repository = ReportRepository();
  
  // State
  bool _isLoading = true;
  DateFilterType _selectedFilter = DateFilterType.month;
  DateTime? _customStart;
  DateTime? _customEnd;
  String? _selectedBranchId;
  String? _selectedStatus;
  
  // Data
  List<OrderModel> _orders = [];
  SalesSummary? _salesSummary;
  OrderStatusStats? _orderStats;
  List<ProductReport> _topProducts = [];
  List<CustomerReport> _topCustomers = [];
  List<RegionReport> _topRegions = [];
  List<SupplierReport> _topSuppliers = [];
  TrendAnalysis? _trendAnalysis;
  
  // User type
  bool _isCompany = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _getTabCount(), vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTabCount() {
    final auth = Provider.of<AuthService>(context, listen: false);
    _isCompany = auth.currentUserType == 'company';
    return 5; // المبيعات، المنتجات، العملاء/الموردين، المناطق، المتقدم
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final companyId = auth.currentCompanyId;
      final pharmacyId = auth.currentUserId;
      
      if (_isCompany && companyId != null) {
        _orders = await _repository.getCompanyOrders(
          companyId: companyId,
          branchId: _selectedBranchId,
          dateFilter: _selectedFilter,
          customStart: _customStart,
          customEnd: _customEnd,
          statuses: _selectedStatus != null ? [_selectedStatus!] : null,
        );
      } else if (!_isCompany && pharmacyId != null) {
        _orders = await _repository.getPharmacyOrders(
          pharmacyId: pharmacyId,
          dateFilter: _selectedFilter,
          customStart: _customStart,
          customEnd: _customEnd,
          statuses: _selectedStatus != null ? [_selectedStatus!] : null,
        );
      }
      
      await _calculateAllStats();
      
    } catch (e) {
      SnackBarService.showError('حدث خطأ أثناء تحميل البيانات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _calculateAllStats() async {
    _salesSummary = await SalesAnalyzer.getSalesSummary(_orders);
    _orderStats = await SalesAnalyzer.getOrderStats(_orders);
    _topProducts = await ProductAnalyzer.getTopProductsByQuantity(_orders);
    _topCustomers = await CustomerAnalyzer.getTopCustomers(_orders);
    _topRegions = await RegionAnalyzer.getTopRegions(_orders);
    _topSuppliers = await SupplierAnalyzer.getTopSuppliers(_orders);
    _trendAnalysis = await TrendAnalyzer.analyzeSalesTrend(_orders);
  }

  Future<void> _refresh() async {
    _repository.clearOrdersCache();
    await _loadData();
  }

  void _onFilterChanged(DateFilterType filter, {DateTime? customStart, DateTime? customEnd}) {
    setState(() {
      _selectedFilter = filter;
      _customStart = customStart;
      _customEnd = customEnd;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: ReportLoading(message: 'جاري تحميل البيانات...'),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _buildTabs(),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          ReportFilterBar(
            selectedFilter: _selectedFilter,
            onFilterChanged: _onFilterChanged,
            selectedBranchId: _selectedBranchId,
            onBranchChanged: _isCompany ? (id) => setState(() => _selectedBranchId = id) : null,
            selectedStatus: _selectedStatus,
            onStatusChanged: (status) => setState(() => _selectedStatus = status),
            onRefresh: _refresh,
            showBranchFilter: _isCompany,
            showStatusFilter: true,
          ),
          
          // KPIs (only show if data exists)
          if (_salesSummary != null)
            _buildKPIs(),
          
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _buildTabsContent(),
            ),
          ),
        ],
      ),
    );
  }

  List<Tab> _buildTabs() {
    return [
      const Tab(text: 'المبيعات', icon: Icon(Icons.attach_money)),
      const Tab(text: 'المنتجات', icon: Icon(Icons.medication)),
      Tab(text: _isCompany ? 'العملاء' : 'الموردين', icon: Icon(_isCompany ? Icons.people : Icons.business)),
      const Tab(text: 'المناطق', icon: Icon(Icons.location_on)),
      const Tab(text: 'تحليلات متقدمة', icon: Icon(Icons.insights)),
    ];
  }

  List<Widget> _buildTabsContent() {
    return [
      SalesReportTab(orders: _orders, salesSummary: _salesSummary),
      ProductsReportTab(orders: _orders),
      _isCompany
          ? CustomersReportTab(orders: _orders, topCustomers: _topCustomers)
          : SuppliersReportTab(orders: _orders, topSuppliers: _topSuppliers),
      RegionsReportTab(orders: _orders, topRegions: _topRegions),
      AdvancedReportTab(orders: _orders, trendAnalysis: _trendAnalysis),
    ];
  }

  Widget _buildKPIs() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: MetricCard(
              title: 'إجمالي المبيعات',
              value: _salesSummary!.totalSales,
              icon: Icons.attach_money,
              color: Colors.green,
              unit: 'ر.ي',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MetricCard(
              title: 'عدد الطلبات',
              value: _salesSummary!.totalOrders.toDouble(),
              icon: Icons.shopping_cart,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MetricCard(
              title: 'متوسط الطلب',
              value: _salesSummary!.averageOrderValue,
              icon: Icons.analytics,
              color: Colors.orange,
              unit: 'ر.ي',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MetricCard(
              title: 'نمو المبيعات',
              value: _trendAnalysis?.growthRate ?? 0,
              icon: (_trendAnalysis?.growthRate ?? 0) >= 0 ? Icons.trending_up : Icons.trending_down,
              color: (_trendAnalysis?.growthRate ?? 0) >= 0 ? Colors.green : Colors.red,
              unit: '%',
            ),
          ),
        ],
      ),
    );
  }
}